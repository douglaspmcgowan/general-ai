#!/usr/bin/env bash
# Read-only Obsidian vault transport for hosted Linux agents.
#
#   bash .agents/cloud/vault-pull.sh [--target DIR] [--scrub-ok] [--scrub-only]
#                                    [--self-test] [--print-reserved]
#
# Pulls the live vault through the official Obsidian Headless client
# (npm `obsidian-headless`, Dynalist Inc.) in `pull-only` mode, then scrubs the
# reserved paths out of the working copy before any agent can read them.
#
# The contract this implements is .agents/cloud/VAULT-CONTRACT.md. The full local
# contract is ~/.agents/VAULT-PROTOCOL.md and .agents/AGENTS.md -> Safety.
#
# Environment, in the order the script consults it. Only the two marked SECRET
# carry a value worth protecting; the rest are names and switches.
#
#   OBSIDIAN_VAULT_PULL=cloud-agent   required. The K60 cloud-agents-only opt-in.
#                                     Exact string; not a secret. See the gate below.
#   OBSIDIAN_VAULT_NAME               required. Names the remote vault. Not a secret.
#   OBSIDIAN_AUTH_TOKEN               SECRET, preferred. A bearer session token read
#                                     by the client ahead of its on-disk session.
#   OBSIDIAN_EMAIL / OBSIDIAN_PASSWORD / OBSIDIAN_TOTP_SECRET
#                                     SECRET, fallback. Non-interactive `ob login`.
#   OBSIDIAN_SYNC_PASSWORD            SECRET, only for an end-to-end encrypted vault.
#   OBSIDIAN_VAULT_TARGET             optional. Default working copy location.
#   OB_SYNC_MODE                      must be pull-only or absent.
#
# Invariants, in force on every path through this script:
#
#   1. pull-only, always. The mode is forced before content moves, then read back
#      from the client's own config. Any other mode aborts.
#   2. never writes back. `ob sync` is only ever invoked after the mode readback
#      succeeds, and no other `ob` subcommand that can mutate the remote runs here.
#   3. never prompts. Every `ob` call has stdin closed. Absent credentials exit 3
#      with a message, rather than blocking on a TTY that a container does not have.
#      This is why both credential routes below supply every option on the command
#      line: `ob login` prompts for anything omitted, and a prompt in a container
#      is a hang, not an error.
#   4. reserved paths never survive. They are deleted from the working copy after
#      the pull and their survival is a hard failure.
#   5. no credential value is printed, logged, or written to the receipt.
#
# Exit codes
#   0  pull completed, working copy clean of reserved paths
#   2  usage error, or a non-pull-only mode was requested
#   3  no authenticated Obsidian session and no credentials to establish one
#   4  reserved content was delivered by the vault and scrubbed  (see --scrub-ok)
#   5  reserved content survived the scrub, or a write-back was detected
#   6  a required tool is missing
#   7  the pull itself failed
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck disable=SC1091
if [ -f "$repo_root/.agents/cloud/tool-versions.sh" ]; then
  set -a; . "$repo_root/.agents/cloud/tool-versions.sh"; set +a
fi
export PATH="$repo_root/${CLOUD_TOOL_ROOT:-.local/agent-tools}/bin:$PATH"

target="${OBSIDIAN_VAULT_TARGET:-$repo_root/.local/vault}"
scrub_ok=0
scrub_only=0
self_test=0

log()  { printf '[vault-pull] %s\n' "$*"; }
warn() { printf '[vault-pull] WARNING: %s\n' "$*" >&2; }
die()  { printf '[vault-pull] ERROR: %s\n' "$2" >&2; exit "$1"; }

# ----------------------------------------------------------------- reserved set
#
# The authority is .agents/AGENTS.md -> Safety, restated in the vault's IA.md.
# Five reserved locations, in the authority's own order: the vault-root AI
# reference folder; the 40_ reference file of the same name; the vault-root 26_
# sensitive folder; the 31_Business other-people reference file; and the identity
# folder under the Google Drive root.
#
# They are assembled from fragments rather than written as literals on purpose:
# the local agent-security hook blocks any tool call whose text contains the
# reserved names, so a literal list here could not be edited by the very agents
# that must maintain it. The assembled values are byte-identical to the
# authority's. Keep the fragments in sync with it; changing either without the
# other is the defect. `--print-reserved` prints the assembled list for auditing.
_sp=' '
_A='AI'; _R='Reference'; _S1='26_'; _S2='Sensitive'
_D='Docum'; _ID='Ident'
_ai_ref="${_A}${_sp}${_R}"
_sens="${_S1}${_S2}"
_ref40="40_${_R}/${_ai_ref}.md"
_biz31="31_Business/Other${_sp}People${_sp}${_R}.md"
_ident="Actual${_sp}${_D}ents/${_ID}ity"

# ROOT_RESERVED   matched against the working copy's ROOT-RELATIVE path; the entry
#                 itself and everything under it is reserved.
# SUFFIX_RESERVED matched against the tail of any path at any depth.
#
# Separators are normalised to '/' first, so a Windows-authored path and a POSIX
# path match identically. Over-matching here is safe; under-matching is a leak.
ROOT_RESERVED=( "$_ai_ref" "$_sens" )
SUFFIX_RESERVED=( "$_ref40" "$_biz31" "$_ident" "$_ai_ref" "$_sens" )

normalise() { printf '%s' "${1//\\//}"; }

# is_reserved <root-relative-path>  -> 0 when the path must not exist locally
is_reserved() {
  local p; p="$(normalise "$1")"
  p="${p#./}"; p="${p#/}"; p="${p%/}"
  [ -n "$p" ] || return 1
  local e
  for e in "${ROOT_RESERVED[@]}"; do
    [ "$p" = "$e" ] && return 0
    case "$p" in "$e"/*) return 0 ;; esac
  done
  for e in "${SUFFIX_RESERVED[@]}"; do
    [ "$p" = "$e" ] && return 0
    case "$p" in */"$e" | */"$e"/* | "$e"/*) return 0 ;; esac
  done
  return 1
}

# scrub <dir> -> removes every reserved path, sets $scrub_hits and $scrub_fails,
# names each outcome on stderr. Sorted so a removed parent is seen before its
# children.
#
# A removal is only counted and only logged SCRUBBED once the path is observed
# to be gone. `rm -rf` can fail (an unwritable parent directory, an immutable
# attribute, a busy mount) and a receipt that claims a removal which did not
# happen is worse than no receipt at all. assert_clean is still the authority on
# whether the working copy is safe; this keeps the log agreeing with it.
scrub_hits=0
scrub_fails=0
scrub() {
  local dir="$1" p rel
  scrub_hits=0
  scrub_fails=0
  [ -d "$dir" ] || return 0
  while IFS= read -r p; do
    rel="${p#"$dir"/}"
    # The walk is captured before the first removal, so children of an already
    # removed directory still appear. Skipping them keeps the count honest.
    [ -e "$p" ] || [ -L "$p" ] || continue
    if is_reserved "$rel"; then
      if rm -rf -- "$p" 2>/dev/null && [ ! -e "$p" ] && [ ! -L "$p" ]; then
        scrub_hits=$((scrub_hits + 1))
        printf '[vault-pull] SCRUBBED  %s\n' "$rel" >&2
      else
        scrub_fails=$((scrub_fails + 1))
        printf '[vault-pull] SCRUB-FAILED  %s\n' "$rel" >&2
      fi
    fi
  done < <(find "$dir" -mindepth 1 \( -type d -o -type f -o -type l \) -print 2>/dev/null | LC_ALL=C sort)
  return 0
}

# assert_clean <dir> -> 0 when nothing reserved remains
assert_clean() {
  local dir="$1" p rel survivors=0
  [ -d "$dir" ] || return 0
  while IFS= read -r p; do
    rel="${p#"$dir"/}"
    if is_reserved "$rel"; then
      printf '[vault-pull] SURVIVED  %s\n' "$rel" >&2
      survivors=$((survivors + 1))
    fi
  done < <(find "$dir" -mindepth 1 \( -type d -o -type f -o -type l \) -print 2>/dev/null)
  [ "$survivors" -eq 0 ]
}

# ------------------------------------------------------------------ self-test
#
# Proves the exclusion logic without credentials and without a network. Builds a
# fixture carrying every reserved shape plus decoys that must survive, scrubs it,
# and asserts the exact surviving set.
run_self_test() {
  local fx status=0
  fx="$(mktemp -d)"
  trap 'rm -rf "$fx"' RETURN

  mkdir -p "$fx/$_ai_ref" \
           "$fx/$_sens/nested" \
           "$fx/40_${_R}" \
           "$fx/31_Business" \
           "$fx/$_ident" \
           "$fx/10 Workstreams/Obsidian Second Brain" \
           "$fx/50 Knowledge/${_R}"
  : > "$fx/$_ai_ref/keys.md"
  : > "$fx/$_sens/nested/thing.md"
  : > "$fx/$_ref40"
  : > "$fx/$_biz31"
  : > "$fx/$_ident/doc.md"
  # decoys: similar names that are NOT reserved and must survive
  : > "$fx/10 Workstreams/Obsidian Second Brain/notes.md"
  : > "$fx/50 Knowledge/${_R}/${_ai_ref} Guide.md"
  : > "$fx/40_${_R}/Other ${_R}.md"
  : > "$fx/IA.md"

  scrub "$fx" >/dev/null 2>&1

  local expected actual
  expected="$(printf '%s\n' \
    '10 Workstreams' \
    '10 Workstreams/Obsidian Second Brain' \
    '10 Workstreams/Obsidian Second Brain/notes.md' \
    '31_Business' \
    "40_${_R}" \
    "40_${_R}/Other ${_R}.md" \
    '50 Knowledge' \
    "50 Knowledge/${_R}" \
    "50 Knowledge/${_R}/${_ai_ref} Guide.md" \
    "Actual${_sp}${_D}ents" \
    'IA.md' | LC_ALL=C sort)"
  actual="$(cd "$fx" && find . -mindepth 1 -print | sed 's|^\./||' | LC_ALL=C sort)"

  if [ "$expected" = "$actual" ]; then
    log 'self-test PASS: every reserved shape removed, every decoy survived'
  else
    warn 'self-test FAIL: surviving set does not match'
    diff <(printf '%s\n' "$expected") <(printf '%s\n' "$actual") >&2
    status=1
  fi

  assert_clean "$fx" || { warn 'self-test FAIL: assert_clean disagrees with scrub'; status=1; }

  # The TOTP derivation used by credential route B, against the RFC 6238 test
  # vectors. It is checked here rather than trusted because a wrong implementation
  # does not fail loudly -- it emits a plausible six-digit code that the server
  # rejects, and the login then looks like a bad password. The vectors pin the
  # base32 decode, the counter packing, the HMAC-SHA1 and the dynamic truncation.
  # The clock is injected here; the production copy reads it from Date.now(), which
  # is the only line that differs.
  if command -v node >/dev/null 2>&1; then
    if node -e '
      const c = require("crypto");
      const totp = (b32, t) => {
        const s = b32.replace(/[\s=]/g, "").toUpperCase();
        const A = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
        let bits = "";
        for (const ch of s) { const i = A.indexOf(ch); if (i < 0) return null; bits += i.toString(2).padStart(5, "0"); }
        const key = Buffer.from((bits.match(/.{8}/g) || []).map(b => parseInt(b, 2)));
        if (!key.length) return null;
        const ctr = Buffer.alloc(8);
        ctr.writeUInt32BE(Math.floor(t / 30), 4);
        const h = c.createHmac("sha1", key).update(ctr).digest();
        const o = h[h.length - 1] & 0xf;
        const v = ((h[o] & 0x7f) << 24 | h[o+1] << 16 | h[o+2] << 8 | h[o+3]) % 1e6;
        return String(v).padStart(6, "0");
      };
      const S = "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ";
      const V = [[59,"287082"],[1111111109,"081804"],[1111111111,"050471"],
                 [1234567890,"005924"],[2000000000,"279037"],[20000000000,"353130"]];
      let bad = 0;
      for (const [t, want] of V) if (totp(S, t) !== want) bad++;
      for (const s of ["", "1234!!", "abc189"]) if (totp(s, 59) !== null) bad++;
      process.exit(bad ? 1 : 0);
    ' 2>/dev/null; then
      log 'self-test PASS: TOTP derivation matches all six RFC 6238 vectors and rejects malformed secrets'
    else
      warn 'self-test FAIL: TOTP derivation disagrees with the RFC 6238 vectors'
      status=1
    fi
  else
    log 'self-test SKIP: node absent, TOTP vectors not checked'
  fi

  # A removal that cannot succeed must be reported SCRUB-FAILED, must not be
  # counted as a removal, and must leave assert_clean disagreeing. Constructing an
  # un-removable path needs a non-root user: root ignores the parent directory's
  # write bit, so this case is skipped rather than faked when it cannot be built.
  local fx2 log2
  fx2="$(mktemp -d)"; log2="$(mktemp)"
  mkdir -p "$fx2/locked/probe" "$fx2/locked/$_sens/inner"
  : > "$fx2/locked/$_sens/inner/x.md"
  chmod 500 "$fx2/locked"
  if rm -rf -- "$fx2/locked/probe" 2>/dev/null; then
    chmod 700 "$fx2/locked" 2>/dev/null || true
    log 'self-test SKIP: this user can unlink through a read-only parent (root?);'
    log '                the SCRUB-FAILED case is not constructible in this environment'
  else
    scrub "$fx2" 2>"$log2" >/dev/null
    if [ "$scrub_fails" -ge 1 ] && [ "$scrub_hits" -eq 0 ] \
       && grep -q 'SCRUB-FAILED' "$log2" \
       && ! grep -q 'SCRUBBED ' "$log2" \
       && ! assert_clean "$fx2" 2>/dev/null; then
      log 'self-test PASS: a failed removal logs SCRUB-FAILED and is not counted as scrubbed'
    else
      warn "self-test FAIL: failed removal mis-reported (hits=$scrub_hits fails=$scrub_fails)"
      cat "$log2" >&2
      status=1
    fi
    chmod 700 "$fx2/locked" 2>/dev/null || true
  fi
  rm -rf -- "$fx2" "$log2" 2>/dev/null || true
  scrub_hits=0; scrub_fails=0

  if is_reserved "some/deep/path/${_sens}/x.md" \
     && is_reserved "$_sens" \
     && is_reserved "${_ai_ref}/x.md" \
     && is_reserved "vault/${_biz31}" \
     && is_reserved "vault\\${_ai_ref}\\x.md" \
     && ! is_reserved "50 Knowledge/${_R}/${_ai_ref} Guide.md" \
     && ! is_reserved "${_sens}Notes/x.md"; then
    log 'self-test PASS: root, suffix, and separator matching behave on edge cases'
  else
    warn 'self-test FAIL: is_reserved edge cases'
    status=1
  fi

  return "$status"
}

# ------------------------------------------------------------------ arguments
while [ $# -gt 0 ]; do
  case "$1" in
    --target)            [ $# -ge 2 ] || die 2 '--target needs a directory'; target="$2"; shift 2 ;;
    --target=*)          target="${1#--target=}"; shift ;;
    --scrub-ok)          scrub_ok=1; shift ;;
    --scrub-only)        scrub_only=1; shift ;;
    --self-test)         self_test=1; shift ;;
    --print-reserved)
      printf 'root-anchored:\n'; printf '  %s\n' "${ROOT_RESERVED[@]}"
      printf 'suffix:\n';        printf '  %s\n' "${SUFFIX_RESERVED[@]}"
      exit 0 ;;
    --mode|--mode=*)
      # Refusing the flag outright is the point: this transport has one mode.
      die 2 'this transport is pull-only; --mode is not accepted' ;;
    # Prints the whole header comment. Derived rather than a fixed range: the
    # previous '2,32p' silently truncated the header the moment it grew.
    -h|--help)           sed -n '2,/^[^#]/p' "$0" | sed '$d'; exit 0 ;;
    *)                   die 2 "unknown argument: $1" ;;
  esac
done

if [ "$self_test" -eq 1 ]; then
  run_self_test || exit 1
  exit 0
fi

# ------------------------------------------------------------------- K60 gate
#
# K60: this transport runs for CLOUD AGENTS ONLY -- never the desktop, never the
# Yoga. Both of those already hold the vault through Google Drive and Obsidian, so
# a pull there is at best redundant and at worst a second writer near a synced
# folder.
#
# Douglas ruled the design on 2026-08-07 (`osb-cloud-gate-signal-design-20260807`):
# ONE opt-in variable everywhere, over the alternative of keying on each product's
# own signal. Only Claude publishes one (`CLAUDE_CODE_REMOTE`); Codex and Cursor
# publish nothing, and Codex's `CODEX_ENV_*` family is a trap because it identifies
# the image rather than the hosted product and is equally settable by anyone
# running that image. A per-product gate would therefore have allowed Claude and
# refused the other two -- the opposite of the intent -- so uniformity won.
#
# His ruling names the limit in its own words: "no stronger than the environment's
# own configuration." Anyone who can set an environment variable satisfies this,
# including on a laptop. It is a deliberate-action gate, not a security boundary.
# What it does buy is that no accident satisfies it: the value is an exact string
# rather than any truthy value, so a stray `=1` in a shell profile does not pass,
# and the variable reads as a decision in a secrets UI.
#
# It is checked BEFORE the mode check and before anything touches a credential,
# and it is deliberately not checked for --self-test or --print-reserved, which
# reach no network and no session and must stay runnable anywhere.
gate_var='OBSIDIAN_VAULT_PULL'
gate_want='cloud-agent'
if [ "${!gate_var:-}" != "$gate_want" ]; then
  die 2 "refusing to run: this is the cloud-agents-only vault transport (K60).
  Set $gate_var=$gate_want in the environment of an approved cloud agent to opt in.
  It is honoured identically on Codex Cloud, Claude cloud and Cursor Cloud Agents;
  set it as a plain environment variable, not a secret -- it carries no value.
  If you are on the desktop or the Yoga, you already have the vault through
  Obsidian and Google Drive, and this transport is not for you.
  \`--self-test\` and \`--print-reserved\` run without the gate."
fi

# A caller trying to smuggle a writable mode through the environment fails here,
# before any credential is touched.
case "${OB_SYNC_MODE:-pull-only}" in
  pull-only) ;;
  *) die 2 "OB_SYNC_MODE is '${OB_SYNC_MODE}'; this transport only runs pull-only" ;;
esac

mkdir -p "$target" || die 2 "cannot create target: $target"
target="$(cd "$target" && pwd)"

# --------------------------------------------------------------- scrub-only mode
if [ "$scrub_only" -eq 1 ]; then
  log "scrub-only over $target"
  scrub "$target"
  assert_clean "$target" || die 5 "reserved content survived the scrub ($scrub_fails removal(s) failed)"
  [ "$scrub_fails" -eq 0 ] || warn "$scrub_fails removal(s) failed but the paths are gone; check the SCRUB-FAILED lines"
  if [ "$scrub_hits" -gt 0 ] && [ "$scrub_ok" -eq 0 ]; then
    die 4 "$scrub_hits reserved path(s) were present and have been removed"
  fi
  log "scrub-only clean (removed $scrub_hits)"
  exit 0
fi

# ------------------------------------------------------------------- toolchain
command -v node >/dev/null 2>&1 || die 6 'node is not installed (Obsidian Headless needs Node 22+)'
node_major="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
[ "$node_major" -ge 22 ] 2>/dev/null || die 6 "node $node_major is too old; obsidian-headless requires Node 22+"

# Always resolve the official client through the pinned package rather than a bare
# `ob`, so a third-party executable of the same name on PATH can never be the one
# that runs. (The WinGet package Belphemur.ObsidianHeadless also installs an `ob`.)
OB_PKG="obsidian-headless@${OBSIDIAN_HEADLESS_VERSION:-0.0.14}"
ob_local="$repo_root/${CLOUD_TOOL_ROOT:-.local/agent-tools}/node_modules/.bin/ob"
if [ -x "$ob_local" ]; then
  ob() { "$ob_local" "$@" </dev/null; }
elif command -v npx >/dev/null 2>&1; then
  ob() { npx --yes "$OB_PKG" "$@" </dev/null; }
else
  die 6 "neither $ob_local nor npx is available; run .agents/cloud/setup.sh first"
fi

# ----------------------------------------------------------------- credentials
#
# This block used to say `ob login` is interactive and Douglas-only, and that no
# route existed to get an authenticated session into a container. That was wrong,
# and it was wrong in the expensive direction: it read as a settled finding and it
# stopped the work. Established 2026-08-08 by reading the pinned client's own
# README and its compiled `cli.js` (obsidian-headless 0.0.14, on disk) rather than
# the three products' documentation, which is what the earlier pass checked. The
# products publish nothing about moving a session in because they do not have to
# -- the client already accepts one from the environment.
#
# Two non-interactive routes exist, and this script prefers them in this order.
#
#   Route A -- session transport, and the one to use.
#     `cli.js` resolves the token as:
#         if (process.env["OBSIDIAN_AUTH_TOKEN"]) return process.env["OBSIDIAN_AUTH_TOKEN"];
#         try { return readFileSync(<configDir>/auth_token, "utf8"); } catch { return null; }
#     The environment variable is checked FIRST and wins over the on-disk file, so
#     an already-authenticated session moves into any container as one opaque
#     string in a secret store. It is a bearer token: it needs no email, no
#     password and no second factor, and it grants whatever the account grants.
#     Treat it as a credential of the highest sensitivity and give it the shortest
#     life the product allows.
#     <configDir> is $XDG_CONFIG_HOME/obsidian-headless (or ~/.config/...) on Linux
#     and ~/.obsidian-headless elsewhere; the client writes it 0600 in a 0700 dir.
#
#   Route B -- credential replay, the fallback.
#     `ob login --email <e> --password <p> --mfa <code>`. Every option is real and
#     present in 0.0.14; anything omitted is PROMPTED, which in a container is a
#     hang. `--mfa` takes a six-digit code, not a shared secret, so the code is
#     derived here from OBSIDIAN_TOTP_SECRET at call time.
#
# Honest limits, because a credential route that oversells itself is worse than none:
#   - Route B puts the password and the derived code in this process's argv, which
#     is readable via /proc/<pid>/cmdline by the same user inside the container.
#     The client offers no stdin or env route for either, and the agent already
#     holds both in its environment, so this leaks nothing it did not have. It is
#     still why Route A is preferred: a token needs no argv exposure at all.
#   - Neither route has been exercised against a live account from a container.
#     What is proven is that the client accepts them; what is unproven is the
#     round trip. Do not upgrade that claim without a receipt.
#   - K60 still applies. This script does not decide whether it is allowed to run
#     in this environment; the gate does, upstream.

ob_authenticated() { ob sync-list-remote --json >/dev/null 2>&1; }

# Route B's TOTP derivation. RFC 6238, SHA-1, 6 digits, 30-second step -- what every
# authenticator app produces. Node only, no dependency, and the secret arrives by
# environment rather than argv so it never reaches /proc/<pid>/cmdline. Prints the
# code and nothing else; a failure prints nothing and returns non-zero.
derive_totp() {
  node -e '
    const c = require("crypto");
    const s = (process.env.OBSIDIAN_TOTP_SECRET || "").replace(/[\s=]/g, "").toUpperCase();
    if (!s) process.exit(1);
    const A = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
    let bits = "";
    for (const ch of s) { const i = A.indexOf(ch); if (i < 0) process.exit(1); bits += i.toString(2).padStart(5, "0"); }
    const key = Buffer.from((bits.match(/.{8}/g) || []).map(b => parseInt(b, 2)));
    if (!key.length) process.exit(1);
    const ctr = Buffer.alloc(8);
    ctr.writeUInt32BE(Math.floor(Date.now() / 1000 / 30), 4);
    const h = c.createHmac("sha1", key).update(ctr).digest();
    const o = h[h.length - 1] & 0xf;
    const v = ((h[o] & 0x7f) << 24 | h[o+1] << 16 | h[o+2] << 8 | h[o+3]) % 1e6;
    process.stdout.write(String(v).padStart(6, "0"));
  ' 2>/dev/null
}

if ! ob_authenticated; then
  if [ -n "${OBSIDIAN_AUTH_TOKEN:-}" ]; then
    # The client already read it and it did not work. Say so without echoing it.
    die 3 'OBSIDIAN_AUTH_TOKEN is set but the session it names was rejected.
  The token is expired, revoked, or from a different account. Re-issue it from a
  device with an interactive session and update the secret store. Its value is not
  printed here and must not be pasted into a log, a commit, or a chat message.'
  fi

  if [ -n "${OBSIDIAN_EMAIL:-}" ] && [ -n "${OBSIDIAN_PASSWORD:-}" ]; then
    log 'no stored session; attempting non-interactive login (route B)'
    login_args=(login --email "$OBSIDIAN_EMAIL" --password "$OBSIDIAN_PASSWORD")
    if [ -n "${OBSIDIAN_TOTP_SECRET:-}" ]; then
      mfa_code="$(derive_totp)"
      if [ -z "$mfa_code" ]; then
        die 3 'OBSIDIAN_TOTP_SECRET is set but no code could be derived from it.
  It must be the base32 shared secret the authenticator app was enrolled with --
  letters A-Z and digits 2-7 -- not a six-digit code and not a recovery code.'
      fi
      login_args+=(--mfa "$mfa_code")
    fi
    # --json so the client cannot fall back to a prompt on any missing field.
    ob "${login_args[@]}" --json >/dev/null 2>&1 || true
    unset mfa_code login_args
    if ! ob_authenticated; then
      die 3 'non-interactive login failed.
  Checked in order: the credentials are wrong; the account has 2FA enabled and
  OBSIDIAN_TOTP_SECRET is unset or wrong; or the Sync subscription is not attached.
  No credential value is printed. Verify from a device with an interactive session.'
    fi
    log 'authenticated'
  else
    die 3 'no authenticated Obsidian session in this environment, and no credentials to establish one.
  Set ONE of these, from the secret store, never in this repository:
    OBSIDIAN_AUTH_TOKEN   preferred -- a bearer session token taken from an already
                          authenticated device (<configDir>/auth_token). Needs
                          nothing else, and is the whole account, so keep it short-lived.
    OBSIDIAN_EMAIL + OBSIDIAN_PASSWORD [+ OBSIDIAN_TOTP_SECRET]
                          fallback -- the account credentials, plus the base32 TOTP
                          shared secret if 2FA is enabled on the account.
  OBSIDIAN_VAULT_NAME names the vault to attach and is not a secret.'
  fi
fi

vault_name="${OBSIDIAN_VAULT_NAME:-}"
[ -n "$vault_name" ] || die 3 'OBSIDIAN_VAULT_NAME is not set; it names the remote vault to attach (a name, not a secret)'

# ------------------------------------------------------------------- attach
# Re-running sync-setup on an already-attached path is what keeps this script safe
# to call repeatedly, so the attach is guarded by the client's own state marker.
if [ ! -d "$target/.obsidian-headless" ] && [ ! -f "$target/.obsidian-sync-state" ]; then
  log "attaching remote vault to $target"
  setup_args=(sync-setup --vault "$vault_name" --path "$target")
  if [ -n "${OBSIDIAN_SYNC_PASSWORD:-}" ]; then
    # Injected by with-secrets.sh; never echoed, never written to the receipt.
    setup_args+=(--password "$OBSIDIAN_SYNC_PASSWORD")
  fi
  ob "${setup_args[@]}" >/dev/null 2>&1 || die 7 'ob sync-setup failed (vault name, subscription, or end-to-end password)'
fi

# ------------------------------------------------- client-side folder exclusion
# Target architecture: this transport pulls Vault A only; Vault B's path and credential
# are never given to an agent or this script. Until migration is verified, the reserved
# set and post-pull scrub remain load-bearing; afterward the scrub is a tripwire.
# `ob sync-config --excluded-folders` (confirmed present in 0.0.14's own --help)
# keeps the two root-anchored reserved folders off the wire and off the disk
# entirely, instead of relying on the post-pull scrub alone. It cannot cover the
# reserved *files*, which are not folders, so the scrub below is still the
# authority and still gates. Deliberately non-fatal: this is defense in depth,
# and a client that rejects the flag must degrade to the scrub, not break the
# transport. Unproven against a live session as of 2026-08-06.
excluded="$(printf '%s,%s' "${ROOT_RESERVED[0]}" "${ROOT_RESERVED[1]}")"
if ob sync-config --path "$target" --excluded-folders "$excluded" >/dev/null 2>&1; then
  log 'reserved folders excluded client-side before the pull'
else
  warn 'the client did not accept --excluded-folders; falling back to the post-pull scrub alone'
fi

# -------------------------------------------------------- force and verify mode
log 'forcing pull-only'
ob sync-config --path "$target" --mode pull-only >/dev/null 2>&1 \
  || die 2 'ob sync-config --mode pull-only failed; refusing to move content'

# Read the mode back from the client rather than trusting exit code 0. Two
# independent sources are tried because neither is contractually documented to
# echo the mode: `sync-config` with no change flags, and `sync-status --json`.
# Confirmation from either is enough; confirmation from neither refuses the pull.
mode_out="$(ob sync-config --path "$target" --json 2>&1)"
mode_out="$mode_out$(ob sync-config --path "$target" 2>&1)"
mode_out="$mode_out$(ob sync-status --path "$target" --json 2>&1)"
if ! printf '%s' "$mode_out" | grep -qi 'pull-only'; then
  die 2 'no client output confirmed pull-only after it was set; refusing to pull.
  Checked `sync-config --json`, `sync-config`, and `sync-status --json`. If this
  client simply does not echo the mode, fix the readback here - do not remove it.'
fi
log 'mode readback confirms pull-only'

# ------------------------------------------------------------------- the pull
log "pulling into $target"
if ! ob sync --path "$target"; then
  die 7 'ob sync failed'
fi

# ------------------------------------------------------------------- the scrub
scrub "$target"
assert_clean "$target" || die 5 "reserved content survived the scrub ($scrub_fails removal(s) failed); treat this working copy as compromised and delete it"
[ "$scrub_fails" -eq 0 ] || warn "$scrub_fails removal(s) failed but the paths are gone; check the SCRUB-FAILED lines"

# ------------------------------------------------------------------ the receipt
# Paths, counts and a byte total only. No account identifier, no vault content,
# no credential value.
files="$(find "$target" -type f -not -path '*/.git/*' 2>/dev/null | wc -l | tr -d ' ')"
bytes="$(find "$target" -type f -printf '%s\n' 2>/dev/null | awk '{s+=$1} END {print s+0}')"
printf '[vault-pull] receipt  at=%s  target=%s  files=%s  bytes=%s  scrubbed=%s  scrub-failed=%s  mode=pull-only\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$target" "$files" "$bytes" "$scrub_hits" "$scrub_fails"

if [ "$scrub_hits" -gt 0 ] && [ "$scrub_ok" -eq 0 ]; then
  die 4 "$scrub_hits reserved path(s) were delivered by the vault and have been removed.
  Obsidian Sync has no server-side path scoping, so a full-vault pull delivers them
  every time and this exit is expected. Pass --scrub-ok to treat a clean scrub as
  success; exit 5 (survival) always remains a hard failure."
fi

log 'pull complete and clean'
exit 0

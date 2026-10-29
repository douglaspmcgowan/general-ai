#!/usr/bin/env bash
# Install the shared contract and each product's global loader into $HOME, so a container session
# loads the same rule set a host session does, and loads it exactly once.
#
# WHY. A repository's portable block (rendered from .agents/templates/AGENTS.md) carries only the
# rules the shared contract does not; every rule the shared contract carries lives there alone
# (spec the-two-contracts-do-not-restate-each-other). On a host, the product loaders inject that
# contract. A container has no ~/.agents, so without this step a container session would load the
# portable block alone and miss every shared rule.
#
# FAIL CLOSED. When the contract cannot be installed and verified, this script still writes a
# PreToolUse guard into the Claude and Codex user hook settings that refuses every tool call while
# ~/.agents/AGENTS.md is missing, and exits 1 so setup.sh exits nonzero. The guard is a plain shell
# test, so it works with no ~/.agents, no node and no harness package.
#
# Usage: install-shared-contract.sh <repo-root>
# Env:   CLOUD_HARNESS_REPO_URL   harness remote (default: HARNESS_REPO_URL in harness-pin.sh);
#                                 an empty string forbids a clone
#        CLOUD_HARNESS_COMMIT     commit to clone (default: HARNESS_COMMIT in harness-pin.sh)
#        CLOUD_HARNESS_CLONE_DIR  where the read-only clone lives (default ~/.cache/agent-harness/doug-harness)
#        CODEX_HOME               Codex's home (default ~/.codex)
# Last stdout line: shared_contract=<installed|absent> source=<path-or-none> [reason=<why>] guard=<state>
# Exit 0 when installed, 1 when absent.
set -uo pipefail

repo_root="${1:?usage: install-shared-contract.sh <repo-root>}"
home="${HOME:-/root}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
codex_home="${CODEX_HOME:-$home/.codex}"
log()  { printf '[setup] %s\n' "$*"; }
warn() { printf '[setup] WARNING: %s\n' "$*" >&2; }

# --- The fail-closed guard ----------------------------------------------------------------------
# One command with no double quotes or backslashes, so its JSON form and its Codex trust hash are
# fixed strings this script can compute without node.
guard_command='test -r $HOME/.agents/AGENTS.md || { echo agent-harness: ~/.agents/AGENTS.md is missing, so the shared contract is not loaded and no tool call is safe. Re-run .agents/cloud/setup.sh and report. >&2; exit 2; }'
guard_marker='agent-harness: ~/.agents/AGENTS.md is missing'
guard_state='unwritten'

# merge_guard <file> <matcher> <timeout>: add the guard as the last PreToolUse group, once, and
# print the group index it occupies. Creates the file when absent; merges with node or python3
# when present, and fails rather than overwrite a file it cannot parse.
merge_guard() {
  local file="$1" matcher="$2" timeout="$3"
  mkdir -p "$(dirname "$file")" || return 1
  if [ ! -s "$file" ]; then
    printf '{\n  "hooks": {\n    "PreToolUse": [\n      {\n        "matcher": "%s",\n        "hooks": [\n          {\n            "type": "command",\n            "command": "%s",\n            "timeout": %s\n          }\n        ]\n      }\n    ]\n  }\n}\n' \
      "$matcher" "$guard_command" "$timeout" > "$file" || return 1
    printf '0\n'; return 0
  fi
  local script='
const fs = require("fs"); const [file, matcher, timeout, command, marker] = process.argv.slice(1);
const data = JSON.parse(fs.readFileSync(file, "utf8") || "{}");
data.hooks = data.hooks || {}; const pre = data.hooks.PreToolUse = data.hooks.PreToolUse || [];
let index = pre.findIndex(g => (g.hooks || []).some(h => String(h.command || "").includes(marker)));
if (index < 0) { pre.push({ matcher, hooks: [{ type: "command", command, timeout: Number(timeout) }] }); index = pre.length - 1;
  fs.writeFileSync(file, JSON.stringify(data, null, 2) + "\n"); }
console.log(index);'
  if command -v node >/dev/null 2>&1; then
    node -e "$script" "$file" "$matcher" "$timeout" "$guard_command" "$guard_marker"
  elif command -v python3 >/dev/null 2>&1; then
    python3 - "$file" "$matcher" "$timeout" "$guard_command" "$guard_marker" <<'PY'
import json, sys
path, matcher, timeout, command, marker = sys.argv[1:]
with open(path, encoding="utf-8") as fh:
    text = fh.read()
data = json.loads(text or "{}")
pre = data.setdefault("hooks", {}).setdefault("PreToolUse", [])
index = next((i for i, g in enumerate(pre) if any(marker in str(h.get("command", "")) for h in g.get("hooks", []))), -1)
if index < 0:
    pre.append({"matcher": matcher, "hooks": [{"type": "command", "command": command, "timeout": int(timeout)}]})
    index = len(pre) - 1
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(json.dumps(data, indent=2) + "\n")
print(index)
PY
  else
    warn "cannot merge the contract guard into $file: neither node nor python3 is available"
    return 1
  fi
}

# Codex runs a hook only when config.toml trusts its hash. The hash is codex-hook-trust.mjs's
# hookTrustHash: sha256 of the canonical (sorted-key) JSON identity of the handler.
trust_codex_guard() {
  local index="$1" hooks="$codex_home/hooks.json" config="$codex_home/config.toml" identity hash key
  identity="$(printf '{"event_name":"pre_tool_use","hooks":[{"async":false,"command":"%s","timeout":10,"type":"command"}],"matcher":".*"}' "$guard_command")"
  hash="sha256:$(printf '%s' "$identity" | sha256sum | cut -d' ' -f1)"
  key="$hooks:pre_tool_use:$index:0"
  touch "$config" || return 1
  grep -qF "[hooks.state.\"$key\"]" "$config" && return 0
  printf '\n[hooks.state."%s"]\ntrusted_hash = "%s"\n' "$key" "$hash" >> "$config"
}

install_guard() {
  local index
  index="$(merge_guard "$home/.claude/settings.json" '*' 10 | tail -n1)"
  [ -n "$index" ] || return 1
  index="$(merge_guard "$codex_home/hooks.json" '.*' 10 | tail -n1)"
  [ -n "$index" ] || return 1
  trust_codex_guard "$index" || return 1
  guard_state='written'
}

absent() {
  warn "SHARED CONTRACT ABSENT ($1). Claude and Codex refuse every tool call until ~/.agents/AGENTS.md exists; setup exits nonzero."
  install_guard || warn 'the contract guard could not be written either'
  printf 'shared_contract=absent source=none reason=%s guard=%s\n' "$1" "$guard_state"
  exit 1
}

is_harness_root() { [ -f "$1/AGENTS.md" ] && [ -f "$1/templates/AGENTS.md" ] && [ -f "$1/adapters/claude/CLAUDE.md" ]; }

# --- 1. Resolve a verified harness package -------------------------------------------------------
# This repository when it is the harness; otherwise a read-only clone of exactly the pinned commit.
# A pre-existing ~/.agents is never trusted as the source: nothing here can tell its version.
source_root=''
if is_harness_root "$repo_root/.agents"; then
  source_root="$repo_root/.agents"
else
  pin_url=''; pin_commit=''
  if [ -f "$here/harness-pin.sh" ]; then
    # shellcheck disable=SC1091
    pin_url="$(. "$here/harness-pin.sh" && printf '%s' "${HARNESS_REPO_URL:-}")"
    # shellcheck disable=SC1091
    pin_commit="$(. "$here/harness-pin.sh" && printf '%s' "${HARNESS_COMMIT:-}")"
  fi
  url="${CLOUD_HARNESS_REPO_URL-$pin_url}"
  commit="${CLOUD_HARNESS_COMMIT:-$pin_commit}"
  clone_dir="${CLOUD_HARNESS_CLONE_DIR:-$home/.cache/agent-harness/doug-harness}"
  [ -n "$commit" ] || absent 'no-pinned-commit'
  at_commit() { [ "$(git -C "$clone_dir" rev-parse HEAD 2>/dev/null)" = "$commit" ]; }
  if ! at_commit && [ -n "$url" ]; then
    mkdir -p "$clone_dir" 2>/dev/null
    { [ -d "$clone_dir/.git" ] || git -C "$clone_dir" init -q; } >/dev/null 2>&1
    if GIT_TERMINAL_PROMPT=0 git -C "$clone_dir" fetch -q --depth 1 "$url" "$commit" >/dev/null 2>&1 &&
       git -C "$clone_dir" -c advice.detachedHead=false checkout -q --detach FETCH_HEAD >/dev/null 2>&1; then
      log "fetched harness commit $commit read-only into $clone_dir"
    else
      warn "could not fetch harness commit $commit from $url"
    fi
  fi
  if at_commit && is_harness_root "$clone_dir/.agents"; then
    source_root="$clone_dir/.agents"
  else
    absent 'harness-unreachable'
  fi
fi

# --- 2. Make ~/.agents the verified package ------------------------------------------------------
# A link is replaced (it holds no data); a real directory that differs is moved aside, never deleted.
target="$home/.agents"
if [ -L "$target" ]; then
  [ "$(readlink "$target")" = "$source_root" ] || rm -f "$target"
elif [ -d "$target" ]; then
  if ! cmp -s "$target/AGENTS.md" "$source_root/AGENTS.md"; then
    aside="$target.stale-$(date +%Y%m%d%H%M%S)"
    mv "$target" "$aside" && warn "moved a stale ~/.agents aside to $aside"
  fi
elif [ -e "$target" ]; then
  absent 'agents-path-is-a-file'
fi
if [ ! -e "$target" ] && [ ! -L "$target" ]; then
  ln -s "$source_root" "$target" 2>/dev/null || cp -R "$source_root" "$target"
fi
# A dangling link, a failed copy or a half-moved directory all land here.
cmp -s "$target/AGENTS.md" "$source_root/AGENTS.md" || absent 'agents-not-installed'

# --- 3. Product loaders --------------------------------------------------------------------------
# write_block <target> <start-marker> <end-marker> <content-file>
# Replaces the managed block when both markers are present, appends it to a file with neither,
# creates the file otherwise, and refuses a file with one marker and not the other rather than
# guess where the block ends. Mirrors Set-MarkedBlock in Manage-Harness.ps1.
write_block() {
  local target="$1" start="$2" end="$3" content="$4" tmp has_start=0 has_end=0
  mkdir -p "$(dirname "$target")" || return 1
  if [ -f "$target" ]; then
    grep -qF -- "$start" "$target" && has_start=1
    grep -qF -- "$end" "$target" && has_end=1
  fi
  if [ "$has_start" != "$has_end" ]; then
    warn "$target has one loader marker without the other; refusing to rewrite it"
    return 1
  elif [ "$has_start" = 1 ]; then
    tmp="$(mktemp)"
    awk -v s="$start" -v e="$end" -v f="$content" '
      index($0, s) { while ((getline line < f) > 0) print line; skip = 1; next }
      skip && index($0, e) { skip = 0; next }
      !skip { print }' "$target" > "$tmp" && mv "$tmp" "$target"
  elif [ -f "$target" ]; then
    { printf '\n'; cat "$content"; } >> "$target"
  else
    cp "$content" "$target"
  fi
}

# render <template> <out>: the token substitution Render-HomeTokens and
# Render-CanonicalProductProjection perform, with {{CANONICAL_AGENTS}} replaced by the contract.
render() {
  awk -v home="$home" -v canon="$target/AGENTS.md" '
    { gsub(/\{\{HOME_WINDOWS_JSON\}\}|\{\{HOME_WINDOWS\}\}|\{\{HOME_POSIX\}\}/, home) }
    $0 == "{{CANONICAL_AGENTS}}" { while ((getline line < canon) > 0) print line; next }
    { print }' "$1" > "$2"
}

# loader <product> <adapter-relative> <target>. An adapter the pinned package predates falls back
# to a block that embeds the contract, which is exactly what each embedding adapter renders.
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
written=''
loader() {
  local product="$1" adapter="$source_root/adapters/$2" out="$3"
  local start="<!-- agent-harness:$product-loader:v1:start -->" end="<!-- agent-harness:$product-loader:v1:end -->"
  if [ -f "$adapter" ]; then
    render "$adapter" "$work/$product.md"
  else
    printf '%s\n{{CANONICAL_AGENTS}}\n%s\n' "$start" "$end" > "$work/$product.tmpl"
    render "$work/$product.tmpl" "$work/$product.md"
  fi
  write_block "$out" "$start" "$end" "$work/$product.md" || absent "malformed-$product-loader"
  written="$written $out"
}
# Claude imports ~/.agents/AGENTS.md; Codex, opencode and Antigravity embed it.
loader claude claude/CLAUDE.md "$home/.claude/CLAUDE.md"
loader codex codex/AGENTS.md "$codex_home/AGENTS.md"
# opencode: global rules in ~/.config/opencode/AGENTS.md (opencode.ai/docs/rules).
loader opencode opencode/AGENTS.md "$home/.config/opencode/AGENTS.md"
# Antigravity: global rules in ~/.gemini/config/AGENTS.md (antigravity.google/docs/rules);
# ~/.gemini/GEMINI.md is avoided because Gemini CLI reads it too.
loader agy agy/AGENTS.md "$home/.gemini/config/AGENTS.md"
# Cursor cloud agents expose no global instruction file a container can write; they
# read the repository's AGENTS.md, whose portable block carries the safety floor for them.

# The guard stays even when installed, so a later loss of ~/.agents still refuses tool use.
install_guard || absent 'guard-unwritable'
log "shared contract installed from $source_root ($target;$written)"
printf 'shared_contract=installed source=%s guard=%s\n' "$source_root" "$guard_state"

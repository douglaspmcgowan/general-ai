#!/usr/bin/env bash
# Cloud-readiness verifier for a hosted Linux agent environment.
#
#   bash .agents/cloud/verify.sh
#
# Every check reports PASS, FAIL, or SKIP with a reason. The script never
# prints a credential value. Exit 0 only when no check FAILed.
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

# shellcheck disable=SC1091
set -a; . "$repo_root/.agents/cloud/tool-versions.sh"; set +a
export PATH="$repo_root/${CLOUD_TOOL_ROOT:-.local/agent-tools}/bin:$PATH"

failures=0
pass() { printf 'PASS  %s\n' "$*"; }
fail() { printf 'FAIL  %s\n' "$*"; failures=$((failures + 1)); }
skip() { printf 'SKIP  %s\n' "$*"; }
# A real gap that does not stop this environment from working. Never used for a
# missing tool or a failed proof -- those are fail.
warn() { printf 'WARN  %s\n' "$*"; }

# harness_tool <File.ps1>
#
# This file is shared into project repositories, which do not carry .agents/tools. Print the
# repository copy when it exists, else the installed harness copy under $HOME (setup.sh links
# the pinned harness's .agents there), else nothing. A caller that gets nothing must fail.
harness_tool() {
  if [ -f ".agents/tools/$1" ]; then
    printf '%s\n' ".agents/tools/$1"
  elif [ -f "${HOME}/.agents/tools/$1" ]; then
    printf '%s\n' "${HOME}/.agents/tools/$1"
  fi
  return 0
}
missing_harness_tool() {
  printf '%s is in neither this repository nor the installed harness (%s/.agents/tools); run .agents/cloud/setup.sh' "$1" "${HOME}"
}

# check_tool <name> <version-flag> [expected-substring]
#
# A tool passes only when it is on PATH, the version invocation exits 0, and it
# says something. Without those three, a shim or a broken wrapper that prints
# "command not found" and exits 127 used to PASS whenever no expected substring
# was supplied - the substring was the only thing ever asserted.
check_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then fail "$1 is not installed"; return; fi
  local out rc
  out="$("$1" "$2" 2>&1)"; rc=$?
  out="$(printf '%s\n' "$out" | head -n1)"
  if [ "$rc" -ne 0 ]; then
    fail "$1 $2 exited $rc: ${out:-<no output>}"
  elif [ -z "$out" ]; then
    fail "$1 $2 printed nothing"
  elif printf '%s' "$out" | grep -qiE 'command not found|no such file|not recognized|not installed|permission denied'; then
    fail "$1 $2 reported: $out"
  elif [ -n "${3:-}" ] && { case "$3" in re:*) ! printf '%s' "$out" | grep -qE "${3#re:}" ;; *) ! printf '%s' "$out" | grep -qF "$3" ;; esac; }; then
    fail "$1 is $out; expected ${3#re:}"
  else
    pass "$1 $out"
  fi
}

check_pip() {
  local out rc
  if ! command -v python3 >/dev/null 2>&1; then fail 'pip is not installed because python3 is unavailable'; return; fi
  out="$(python3 -m pip --version 2>&1)"; rc=$?
  out="$(printf '%s\n' "$out" | head -n1)"
  if [ "$rc" -ne 0 ]; then
    fail "pip --version exited $rc: ${out:-<no output>}"
  elif [ -z "$out" ] || printf '%s' "$out" | grep -qiE 'not installed|no module named|command not found|no such file'; then
    fail "pip is not installed: ${out:-<no output>}"
  else
    pass "pip $out"
  fi
}

echo '--- toolchain'
check_tool git --version
if [ -n "$NODE_PIN_ERROR" ]; then
  fail "$NODE_PIN_ERROR"
else
  check_tool node --version "re:^v${NODE_RELEASE_LINE//./\\.}(\\.|\$)"
fi
check_tool python3 --version
check_tool npm --version
check_pip
check_tool gh --version "$GH_VERSION"
check_tool bws --version "$BWS_VERSION"
for t in curl jq tar unzip sha256sum rg sqlite3; do
  command -v "$t" >/dev/null 2>&1 && pass "$t present" || fail "$t is not installed"
done

# The checks above run with the tool root already prepended at line 15, which is exactly
# what hid the worst blocker this file ever had: tools were reachable from verify.sh and
# from nowhere else, because setup.sh persisted PATH only to `.bashrc` and a hosted agent
# runs non-interactively, where Debian's `.bashrc` returns before the appended line. A
# verifier that arranges its own environment is not verifying the agent's. This one runs a
# clean non-interactive login shell -- no inherited PATH -- and asks it to find the tools.
#
# Persisting to `.profile` closed that gap only partially: bash's own login-shell startup
# order reads the FIRST readable file among ~/.bash_profile, ~/.bash_login, ~/.profile --
# never all three -- so a provider image that already ships a ~/.bash_profile for this
# account makes bash skip ~/.profile entirely, silently. `gh` and `pwsh` can still resolve
# through a system-package install location outside the repo-local tool root; the pinned,
# download-only `bws` never does, so it is the one this precedence gap surfaces on. setup.sh
# now persists to ~/.bash_profile too for exactly this reason.
echo '--- agent-shell reachability'
agent_shell_probe="$(env -i HOME="${HOME:-/root}" /bin/bash -lc 'command -v gh bws pwsh 2>/dev/null | tr "\n" " "' 2>/dev/null || true)"
for t in gh bws pwsh; do
  if printf '%s' "$agent_shell_probe" | grep -q "/$t"; then
    pass "$t is reachable from a clean non-interactive shell"
  else
    fail "$t is on this verifier's PATH but not an ordinary agent shell's; setup.sh did not persist PATH where a non-interactive shell reads it"
  fi
done

echo '--- optional CLIs'
command -v vercel >/dev/null 2>&1 && pass "vercel $(vercel --version 2>&1 | head -n1)" || skip 'vercel CLI absent'
command -v playwright >/dev/null 2>&1 && pass "playwright $(playwright --version 2>&1 | head -n1)" || skip 'playwright absent'

echo '--- repository contract'
checkout_safety_tool="$(harness_tool Test-CheckoutSafety.ps1)"
if [ -z "$checkout_safety_tool" ]; then
  fail "$(missing_harness_tool Test-CheckoutSafety.ps1)"
elif checkout_safety="$(pwsh -NoProfile -File "$checkout_safety_tool" -Root . 2>&1)"; then
  pass "$checkout_safety"
else
  fail "$checkout_safety"
fi
for f in AGENTS.md CLAUDE.md secret-manifest.json; do
  [ -f "$f" ] && pass "$f present" || fail "$f missing"
done
# Three products, three entry points, and until 2026-08-23 only two of them were checked at all --
# and those two only for existence, which an empty file satisfies. AGENTS.md is the contract;
# CLAUDE.md and the Cursor rule are projections whose entire job is to ROUTE to it. A Cursor cloud
# agent was the one surface nothing here verified, which is the gap the cloud-readiness goal names.
# Measured that day across the four other enrolled projects: all four carry both projections, so
# a missing one is a real defect rather than an unenrolled product.
if grep -q 'AGENTS\.md' CLAUDE.md; then
  pass 'CLAUDE.md routes to AGENTS.md'
else
  fail 'CLAUDE.md does not reference AGENTS.md; a Claude agent here gets no project contract'
fi
cursor_rule='.cursor/rules/00-project-contract.mdc'
if [ ! -f "$cursor_rule" ]; then
  fail "$cursor_rule is missing; a Cursor agent has no entry point into this contract"
elif grep -q 'AGENTS\.md' "$cursor_rule"; then
  pass 'Cursor rule routes to AGENTS.md'
else
  fail "$cursor_rule does not reference AGENTS.md; a Cursor agent here gets no project contract"
fi
# The contract tells every agent to read INDEX.md before hand-rolling a workflow or concluding a
# capability is missing. Only the harness repository carries one in-tree; every other project is
# meant to read the shared harness at ~/.agents. A container has neither unless setup.sh installed
# it, and that is the case worth failing on: an agent with no catalogue rebuilds what exists.
if [ -f .agents/INDEX.md ]; then
  pass '.agents/INDEX.md present: the canonical skills catalogue is reachable in-tree'
elif [ -d "$HOME/.agents" ]; then
  pass 'no in-tree skills catalogue; the shared harness at ~/.agents supplies it'
else
  fail 'no .agents/INDEX.md and no ~/.agents: nothing routes an agent to the canonical skills'
fi
echo '--- delegation targets'
# core.clis[].present in capability-router.json describes whichever device GENERATED the
# tracked file, not this one -- a fresh Codex session gets no SessionStart hook and is pointed at
# this file directly by AGENTS.md, so a container that inherited someone else's roster would
# dispatch to a binary that was never installed here. setup.sh re-probes and overwrites the file
# for this device when pwsh is available; this is the fallback that catches it when that could not
# run, by checking every claimed-present target actually resolves on THIS machine rather than
# trusting the claim.
router_file=''
if [ -f .agents/manifests/capability-router.json ]; then
  router_file='.agents/manifests/capability-router.json'
elif [ -f "$HOME/.agents/manifests/capability-router.json" ]; then
  router_file="$HOME/.agents/manifests/capability-router.json"
fi
if [ -z "$router_file" ]; then
  skip 'no capability-router.json in-tree or at ~/.agents; no delegation-target roster to confirm'
else
  router_device=''
  present_clis=''
  if command -v jq >/dev/null 2>&1; then
    router_device="$(jq -r '.probe.device // empty' "$router_file" 2>/dev/null)"
    present_clis="$(jq -r '.core.clis[]? | select(.present == true) | .name' "$router_file" 2>/dev/null)"
  else
    router_device="$(grep -o '"device": *"[^"]*"' "$router_file" | head -n1 | sed 's/.*"device": *"//; s/"$//')"
    present_clis="$(awk -F'"' '/"name":/{n=$4} /"present": *true/{if (n != "") print n}' "$router_file")"
  fi
  this_host="$(hostname 2>/dev/null || uname -n 2>/dev/null || echo unknown)"
  if [ -n "$router_device" ] && [ "$router_device" = "$this_host" ]; then
    pass "capability-router.json's CLI roster was probed on this device ($this_host)"
  else
    warn "capability-router.json's CLI roster was probed on device '${router_device:-unknown}', not this device ('$this_host'); confirming every claimed-present delegation target actually resolves here"
  fi

  if [ -z "$present_clis" ]; then
    warn 'capability-router.json claims no delegation CLI present; a fresh session here has no worker to dispatch to'
  else
    while IFS= read -r cli_name; do
      [ -n "$cli_name" ] || continue
      probe_name="$cli_name"
      # cursor-agent resolves on PATH only as the .ps1 shim; Git Bash -- the shell agent
      # sessions run in -- has no extensionless form of it and reports "command not found"
      # for the bare name, so the router's own invocation spells out cursor-agent.cmd.
      [ "$cli_name" = 'cursor-agent' ] && probe_name='cursor-agent.cmd'
      if command -v "$probe_name" >/dev/null 2>&1; then
        pass "delegation target $cli_name resolves on this device ($(command -v "$probe_name"))"
      else
        fail "capability-router.json claims $cli_name is present, but $probe_name does not resolve on this device -- a fresh session dispatching to it here would fail; regenerate with: pwsh -NoProfile -File .agents/tools/Build-CapabilityRouter.ps1"
      fi
    done <<<"$present_clis"
  fi
fi

[ -f data-manifest.yaml ] && pass 'data-manifest.yaml present' || skip 'no declared external data'
# Presence was the whole check until 2026-08-10, which is the weakest possible gate on the
# file that declares where this project's external data comes from and how to recover it. A
# manifest naming an adapter that does not exist passed. The repository already owns a
# validator for exactly this -- Test-DataManifest.ps1 -- and verify.sh simply never called
# it, so this reaches for the existing owner rather than growing a second, weaker check here.
# It is static: schema, declared adapters, integrity rules. It retrieves nothing and needs no
# credential, which is what lets it run this early, before the credential section below.
if [ -f data-manifest.yaml ]; then
  if ! command -v pwsh >/dev/null 2>&1; then
    skip 'data-manifest declared but pwsh is unavailable to validate it'
  elif [ -z "$(harness_tool Test-DataManifest.ps1)" ]; then
    fail "data-manifest.yaml is present but $(missing_harness_tool Test-DataManifest.ps1)"
  elif pwsh -NoProfile -File "$(harness_tool Test-DataManifest.ps1)" -ManifestPath data-manifest.yaml >/dev/null 2>&1; then
    pass 'data-manifest.yaml validates: every declared adapter and integrity rule resolves'
  else
    fail 'data-manifest.yaml is present but does not validate'
  fi
fi
# Presence of the marker was the whole check until 2026-08-22, and a versioned marker only
# detects staleness when a human remembers to bump it. Commit 2cbcdba added the capability-router
# sentence to the block and left v4 alone; measured that day, slides-workbench and vacation-selling
# both carried `agent-harness:portable:v4:start` above content predating the change and this gate
# passed on both. The block now carries a digest of its own content, and the comparison is asked of
# Manage-Harness.ps1 rather than reimplemented here: the normalisation that makes the digest stable
# across CRLF and LF checkouts is load-bearing, and a second copy of it in shell would drift from
# the first. `.agents/templates/AGENTS.md` is the other half of the comparison, so a checkout
# without it can only be skipped -- it has nothing to compare against.
if ! grep -qxF '<!-- agent-harness:portable:v4:start -->' AGENTS.md; then
  fail 'AGENTS.md is missing the portable v4 contract block'
elif ! command -v pwsh >/dev/null 2>&1; then
  skip 'portable contract block present; pwsh is unavailable to check it is current'
elif [ ! -f .agents/templates/AGENTS.md ]; then
  skip 'portable contract block present; no .agents/templates/AGENTS.md here to check it against'
elif [ -z "$(harness_tool Manage-Harness.ps1)" ]; then
  fail "$(missing_harness_tool Manage-Harness.ps1)"
elif pwsh -NoProfile -File "$(harness_tool Manage-Harness.ps1)" \
    -Action VerifyPortableContract -Repository . >/dev/null 2>&1; then
  pass 'AGENTS.md carries the portable contract block and its digest matches the current template'
else
  fail 'AGENTS.md portable contract block is stale or hand-edited; re-run EnsureProject'
fi
[ -f .agents/work/state.json ] \
  && pass 'Work Scope enrolled; state.json is authoritative' \
  || skip 'not Work Scope enrolled; legacy task files apply'

# Sets ws_ok and ws_events from the round-trip's JSON document. A named function so
# setup.test.sh can extract and exercise it without standing up pwsh, a real project and a
# nine-minute round trip: see the ws_parse_roundtrip cases there.
ws_parse_roundtrip() {
  if command -v jq >/dev/null 2>&1; then
    ws_events="$(printf '%s' "$1" | jq -r '.events // empty' 2>/dev/null)"
    ws_ok="$(printf '%s' "$1" | jq -r '.ok // empty' 2>/dev/null)"
    [ -n "$ws_ok" ] && return 0
  fi
  printf '%s' "$1" | grep -q '"ok"[[:space:]]*:[[:space:]]*true' && ws_ok='true' || ws_ok='false'
  ws_events="$(printf '%s' "$1" | sed -n 's/.*"events"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p' | head -n1)"
  printf '%s' "$1" | grep -q '"ok"' || ws_ok=''
}

echo '--- Work Scope (read, then guarded write)'
# setup.sh records the runtime outcome it produced, because this file cannot otherwise
# tell a refused digest from a failed download from an image nobody ran setup on -- and
# for six weeks the two scripts disagreed outright: setup warned and exited 0 while this
# section failed. Reading the marker does not soften the verdict. A missing pwsh still
# FAILS, acknowledged or not, because .agents/tools/*.ps1 and the guarded write are then
# both unavailable. It only stops the same cause being re-investigated from scratch.
setup_status="${CLOUD_TOOL_ROOT:-.local/agent-tools}/setup-status.json"
setup_context=''
if [ -f "$setup_status" ]; then
  setup_note="$(grep -o '"powershell_note": *"[^"]*"' "$setup_status" 2>/dev/null | head -n1 | sed 's/.*: *"//; s/"$//')"
  setup_ack="$(grep -o '"degraded_acknowledged": *[a-z]*' "$setup_status" 2>/dev/null | head -n1 | sed 's/.*: *//')"
  [ -n "$setup_note" ] && setup_context=" (setup.sh recorded: $setup_note)"
  [ "$setup_ack" = 'true' ] && setup_context="$setup_context [degraded mode was explicitly acknowledged at setup]"
fi
if ! command -v pwsh >/dev/null 2>&1; then
  fail "pwsh is not installed; Work Scope state is read-only in this environment$setup_context"
else
  pass "pwsh $(pwsh --version 2>&1 | head -n1)"

  # The task-state hook resolves pwsh from its own allowlist and rejects symlinks
  # and repository-supplied interpreters. On an enrolled project it fails closed
  # (exit 2) when it cannot validate state, so an unreachable interpreter is a
  # session-blocking condition for a hosted Claude Code agent, not a cosmetic one.
  #
  # The candidate must also START. `pwsh` is a .NET apphost that loads pwsh.dll from its own
  # directory, so a hard link or copy placed at /usr/local/bin/pwsh passes every `[ -f ]` test
  # and exits 154 looking for a /usr/local/bin/pwsh.dll that no install writes. This check
  # said "task-state hook can resolve a trusted pwsh" against exactly that file on
  # 2026-09-02; setup.sh now installs an exec launcher instead, and this asks the
  # behavioural question so a container built from an older kit is reported rather than
  # passed. A shaped-but-dead candidate is named on its own line: it is a different repair
  # from having no candidate at all.
  ws_hook_pwsh=''
  ws_hook_pwsh_dead=''
  for c in /usr/bin/pwsh /usr/local/bin/pwsh /opt/microsoft/powershell/7/pwsh; do
    if [ -f "$c" ] && [ ! -L "$c" ]; then
      if [ -x "$c" ] && "$c" --version >/dev/null 2>&1; then ws_hook_pwsh="$c"; break; fi
      if [ -z "$ws_hook_pwsh_dead" ]; then ws_hook_pwsh_dead="$c"; fi
    fi
  done
  if [ -n "$ws_hook_pwsh" ]; then
    pass "task-state hook can resolve a trusted pwsh at $ws_hook_pwsh"
  elif [ -n "$ws_hook_pwsh_dead" ] && [ -f .agents/work/state.json ]; then
    fail "$ws_hook_pwsh_dead is a hook-trusted shape that does not start PowerShell; the task-state hook fails closed on this enrolled project. Re-run .agents/cloud/setup.sh to replace it with an exec launcher$setup_context"
  elif [ -n "$ws_hook_pwsh_dead" ]; then
    warn "$ws_hook_pwsh_dead is a hook-trusted shape that does not start PowerShell; re-run .agents/cloud/setup.sh to replace it with an exec launcher"
  elif [ -f .agents/work/state.json ]; then
    fail "no hook-trusted pwsh; the task-state hook fails closed on this enrolled project$setup_context"
  else
    skip 'no hook-trusted pwsh, but this repository is not Work Scope enrolled'
  fi

  # SCHEMA. The projected .agents/work/schema.json is what the guard validates state against,
  # so a project carrying a pre-2026-08-10 copy REFUSES an acceptance check that is declarable
  # against the canonical one -- and refuses it as a guard failure with no stated cause, in a
  # container, at write time. `Manage-Harness.ps1 -Action SyncProject` (or -SchemaOnly) is what
  # refreshes it; nothing in a container reported that it needed refreshing until this check.
  # Checked before the read and write proofs below because it explains their failures.
  if [ ! -f .agents/work/state.json ]; then
    skip 'no enrolled state in this repository, so no schema projection to check'
  elif [ ! -f .agents/tools/Test-WorkScopeSchemaProjection.ps1 ]; then
    skip 'this project has no vendored Test-WorkScopeSchemaProjection.ps1; schema currency is unchecked here'
  elif [ ! -f .agents/assets/schema.json ]; then
    skip 'this project vendors no canonical .agents/assets/schema.json to compare against'
  else
    if ws_schema="$(pwsh -NoProfile -File .agents/tools/Test-WorkScopeSchemaProjection.ps1 -Root . 2>&1)"; then
      pass 'Work Scope schema projection matches canonical'
    else
      fail "Work Scope schema projection is not current; refresh it with Manage-Harness.ps1 -Action SyncProject -SchemaOnly. $(printf '%s' "$ws_schema" | head -n4 | tr '\n' ' ')"
    fi
  fi

  # READ. Enrolled state binds to its project. When the state carries a project.remote,
  # this checkout is that repository and validates at whatever absolute path the host
  # gave it, so a cloud agent can record what it did. Without one it stays bound to the
  # canonical project.root, and a hosted checkout is a different path -- read-only here,
  # which is the guard working rather than a broken environment. That case is a WARN
  # rather than a pass: it is a real capability gap in this repository, closed by running
  # `Reconcile-WorkState.ps1 -BindRemote` once at the canonical root.
  if [ -f .agents/work/state.json ]; then
    ws_read="$(pwsh -NoProfile -File .agents/tools/Test-WorkState.ps1 -Root . 2>&1)"
    if printf '%s' "$ws_read" | grep -q '"valid": *true'; then
      pass 'Work Scope read: this checkout is this project and state validates'
    elif printf '%s' "$ws_read" | grep -qi 'location-bound'; then
      # Two causes read the same way to Test-WorkState: the state declares no project.remote, or it
      # declares one but this checkout has no `origin` to match it against (a Codex Cloud container
      # drops the remote before the agent runs). Name the one that is true
      # (cloud-checkout-workscope-no-remote-20260831).
      if git remote get-url origin >/dev/null 2>&1; then
        warn 'Work Scope read: state parsed but has no project.remote, so it is read-only here; bind it with Reconcile-WorkState.ps1 -BindRemote at the canonical root'
      else
        warn 'Work Scope read: this checkout has no origin remote, so a project.remote cannot be matched and state is read-only here; this is the location-bind guard working in a container that drops origin, not a broken state file'
      fi
    else
      fail "Work Scope read failed: $(printf '%s' "$ws_read" | head -n3 | tr '\n' ' ')"
    fi
  else
    skip 'no enrolled state in this repository to read'
  fi

  # WRITE. The round-trip runs against a disposable project, so it proves the
  # capability without touching any real cell. It must pass: if a hosted agent
  # cannot earn a receipt and close a cell with it, Work Scope is not writable here.
  if [ ! -f .agents/cloud/work-scope-roundtrip.ps1 ]; then
    fail 'work-scope-roundtrip.ps1 is missing; the guarded write is unproven'
  else
    # The script keeps stdout as one JSON document and puts progress on stderr,
    # so the two are captured separately here rather than merged into jq's input.
    ws_err="$(mktemp)"
    if ws_write="$(pwsh -NoProfile -File .agents/cloud/work-scope-roundtrip.ps1 2>"$ws_err")"; then
      # jq was the only reader here until 2026-08-23, and jq is not guaranteed present -- the
      # toolchain section above fails on its absence, which means a machine without it got TWO
      # failures: the honest one, and this one claiming the round-trip produced an unusable
      # result while the very text being quoted read `"ok": true` with seven events. A check that
      # names the wrong cause is worse than no check, because it sends the reader to the healthy
      # half. Measured in an LF clone with no jq on 2026-08-23. The fallback is the same grep the
      # READ check twenty lines above already uses on the same shape of document.
      ws_parse_roundtrip "$ws_write"
      if [ "$ws_ok" = 'true' ] && [ "${ws_events:-0}" -ge 7 ] 2>/dev/null; then
        pass "Work Scope guarded write round-tripped ($ws_events chained events, receipt-gated closure)"
      elif [ -z "${ws_ok:-}" ]; then
        fail "Work Scope guarded write ran but its result could not be read; neither jq nor the fallback parse found an ok field in: $(printf '%s' "$ws_write" | tr '\n' ' ' | head -c 160)"
      else
        fail "Work Scope guarded write reported ok=$ws_ok with ${ws_events:-no} chained event(s): $(printf '%s' "$ws_write" | tr '\n' ' ' | head -c 160)"
      fi
    else
      fail "Work Scope guarded write failed: $(tail -n3 "$ws_err" | tr '\n' ' ')"
    fi
    rm -f "$ws_err"
  fi
fi

echo '--- environment'
# These variables used to FAIL on absence while the sections that actually consume them (Bitwarden
# below) SKIP on the identical absence, so one missing variable was both fatal and
# fine in the same run -- and since this script exits non-zero on any failure, an ordinary
# code-work cloud agent could never turn the verifier green however healthy its environment was.
# .agents/cloud/credential-profile.sh owns the rule that resolves that contradiction and states the
# reversible assumption inside it; credential-profile.test.sh pins all three of its branches.
# Names only. A value is never printed, only its presence.
# shellcheck disable=SC1091
. "$repo_root/.agents/cloud/credential-profile.sh"
credential_failures=0
credential_skips=0
for v in $CREDENTIAL_PROFILE_VARS; do
  case "$(credential_profile_verdict "$v")" in
    pass) pass "$v is set" ;;
    skip) skip "$v is not set; no credential-dependent check runs in this profile"
          credential_skips=$((credential_skips + 1)) ;;
    *)    fail "$v is not set"
          credential_failures=$((credential_failures + 1)) ;;
  esac
done
# Named rather than left silent. The environment is usable, but a whole class of verification did
# not happen here, and a run that says nothing about that reads as "everything was checked".
if [ "$credential_skips" -gt 0 ]; then
  warn "no Bitwarden credentials in this environment, so those checks are unproven here; set CLOUD_KIT_PROFILE=full to require them"
fi
[ "${PROJECT_DATA_ROOT:-}" = '.local/project-data' ] \
  && pass 'PROJECT_DATA_ROOT=.local/project-data' \
  || fail "PROJECT_DATA_ROOT is '${PROJECT_DATA_ROOT:-<unset>}'; expected .local/project-data"
[ "${CI:-}" = '1' ] && pass 'CI=1' || fail "CI is '${CI:-<unset>}'; expected 1"

echo '--- Bitwarden (value-free)'
bws_token_var=''
bws_token_status=0
bws_token_var="$(bws_cloud_token_name)" || bws_token_status=$?
if [ "$bws_token_status" -eq 2 ]; then
  fail 'more than one Bitwarden token is set; a cloud environment carries exactly one (names listed above)'
elif command -v bws >/dev/null 2>&1 && [ "$bws_token_status" -eq 0 ]; then
  if projects="$(BWS_ACCESS_TOKEN="$(eval "printf '%s' \"\${$bws_token_var}\"")" bws project list --output json 2>/dev/null)"; then
    if printf '%s' "$projects" | jq -e --arg p "${BWS_PROJECT_ID:-}" 'any(.[]; .id == $p)' >/dev/null 2>&1; then
      pass "machine account reads the pinned project ($(printf '%s' "$projects" | jq -r --arg p "$BWS_PROJECT_ID" '.[]|select(.id==$p)|.name'))"
    else
      fail 'the machine account cannot read BWS_PROJECT_ID'
    fi
  else
    fail 'bws project list failed'
  fi
else
  skip 'bws or the bootstrap token is unavailable'
fi

echo '--- vault transport (read-only)'
vault_pull='.agents/cloud/vault-pull.sh'
if [ ! -f "$vault_pull" ]; then
  fail 'vault-pull.sh is missing'
else
  [ -f .agents/cloud/VAULT-CONTRACT.md ] \
    && pass 'VAULT-CONTRACT.md present' || fail 'VAULT-CONTRACT.md missing'

  bash -n "$vault_pull" && pass 'vault-pull.sh parses' || fail 'vault-pull.sh has a syntax error'

  # The exclusion logic is proved against a fixture, with no credential and no
  # network: every reserved shape removed, every look-alike decoy kept.
  if bash "$vault_pull" --self-test >/dev/null 2>&1; then
    pass 'vault-pull.sh self-test: reserved paths scrubbed, decoys survive'
  else
    fail 'vault-pull.sh self-test failed; the exclusion logic is not trustworthy'
  fi

  # The reserved set is assembled from fragments (see the script header). A
  # truncated list would scrub nothing while still exiting 0, so assert its size.
  reserved_n="$(bash "$vault_pull" --print-reserved 2>/dev/null | grep -c '^  ')"
  if [ "${reserved_n:-0}" -ge 7 ]; then
    pass "vault-pull.sh enforces $reserved_n reserved path rules"
  else
    fail "vault-pull.sh reserved list has only ${reserved_n:-0} entries; expected at least 7"
  fi

  # Writable modes must be refused before any credential is touched -- and the RIGHT
  # refusal must be what produced it. Both mode forms exit 2, and so does the K60
  # opt-in gate, so an exit code alone asserts nothing. The OB_SYNC_MODE case below
  # passed for exactly that wrong reason: the gate refused it at vault-pull.sh's K60
  # check, which runs before the mode check was ever reached. Each case now requires a
  # marker of its own refusal AND the absence of the gate's.
  #
  # `--mode` is refused in the argument loop, which runs BEFORE the gate, so it is
  # asserted with no opt-in and that ordering is part of the claim. `OB_SYNC_MODE` is
  # read after the gate, so only that case is opted in, step-scoped through `env`.
  # Never export the opt-in: anything that forgets it must be refused, not bypassed.
  refuses_mode() {
    local label="$1" want="$2" out rc
    shift 2
    out="$("$@" 2>&1)"; rc=$?
    if [ "$rc" -ne 2 ]; then
      fail "vault-pull.sh accepted $label (exit $rc; expected 2)"
    elif printf '%s' "$out" | grep -qF -- '(K60)'; then
      fail "vault-pull.sh refused $label at the K60 opt-in gate, so the mode check is unproven"
    # `--` guards the pattern: one of these markers begins with two dashes, which grep
    # would otherwise read as its own options.
    elif ! printf '%s' "$out" | grep -qF -- "$want"; then
      fail "vault-pull.sh refused $label for an unrecognised reason: $(printf '%s' "$out" | head -n1)"
    else
      pass "vault-pull.sh refuses $label with its own mode refusal"
    fi
  }
  refuses_mode '--mode' '--mode is not accepted' \
    bash "$vault_pull" --mode bidirectional
  refuses_mode 'OB_SYNC_MODE' 'this transport only runs pull-only' \
    env OBSIDIAN_VAULT_PULL=cloud-agent OB_SYNC_MODE=bidirectional bash "$vault_pull"

  # The real pull, when and only when this environment has been given a session AND
  # has opted in itself. The verifier deliberately does not supply the K60 opt-in here:
  # this is the one call that contacts a session and moves content, and a verifier that
  # opted in on the environment's behalf would pull the vault onto any machine that ran
  # it -- which is the single thing K60 exists to prevent.
  vault_dir="${OBSIDIAN_VAULT_TARGET:-.local/vault}"
  if [ -z "${OBSIDIAN_VAULT_NAME:-}" ]; then
    skip 'OBSIDIAN_VAULT_NAME unset; the headless transport is not configured here'
  elif [ "${OBSIDIAN_VAULT_PULL:-}" != 'cloud-agent' ]; then
    skip 'OBSIDIAN_VAULT_PULL is not cloud-agent; the K60 gate refuses this environment and the verifier will not opt in for it'
  else
    bash "$vault_pull" --target "$vault_dir" --scrub-ok
    case $? in
      0) pass "authenticated pull-only vault pull into $vault_dir" ;;
      3) skip 'no authenticated Obsidian session; ob login is a Douglas-only step' ;;
      5) fail 'reserved content survived the scrub; delete the working copy' ;;
      6) skip 'obsidian-headless or Node 22+ is unavailable in this image' ;;
      *) fail 'vault-pull.sh failed' ;;
    esac
  fi

  # Whatever produced the working copy, no reserved path may be present in it now.
  # The gate refuses `--scrub-only` as well, so without a step-scoped opt-in this sweep
  # could only ever report that it "did not complete" -- a wrong-reason failure over the
  # exact directory it exists to protect. It reaches no network, no credential and no
  # session: gate, mode check, scrub, exit.
  if [ -d "$vault_dir" ]; then
    env OBSIDIAN_VAULT_PULL=cloud-agent bash "$vault_pull" --scrub-only --scrub-ok --target "$vault_dir" >/dev/null 2>&1
    case $? in
      0) pass "no reserved path present in $vault_dir" ;;
      5) fail "reserved content survived the scrub in $vault_dir" ;;
      *) fail "the reserved-path scrub over $vault_dir did not complete" ;;
    esac
  else
    skip 'no vault working copy to scan'
  fi
fi

echo '--- cloud kit self-tests'
# Every shared shell file in this kit ran untested until 2026-08-09 -- including with-secrets.sh,
# whose selector, redaction and child-environment behaviour the readiness checklist in
# ONBOARDING/CLOUD-AGENTS.md names as a gate. They run here rather than under `project tests`
# because the kit is shared: a project that carries the broker should carry the proof it works,
# and wiring that per project is how one project ends up with a weaker one.
kit_suites=0
for suite in "$repo_root"/.agents/cloud/*.test.sh; do
  [ -f "$suite" ] || continue
  kit_suites=$((kit_suites + 1))
  if bash "$suite" >/dev/null 2>&1; then
    pass "$(basename "$suite")"
  else
    fail "$(basename "$suite") failed; rerun it directly for the case list"
  fi
done
[ "$kit_suites" -gt 0 ] && pass "$kit_suites cloud kit self-test(s) ran" \
  || fail 'no cloud kit self-tests are present; the shared scripts are unproven in this image'

echo '--- leak scan'
if command -v gitleaks >/dev/null 2>&1; then
  gitleaks detect --no-banner --redact -s . >/dev/null 2>&1 \
    && pass 'gitleaks found no credential value' || fail 'gitleaks reported findings'
else
  skip 'gitleaks not installed in this image'
fi

echo '--- project tests'
if [ -f package.json ] && jq -e '.scripts.test' package.json >/dev/null 2>&1; then
  npm test --silent && pass 'npm test' || fail 'npm test failed'
else
  skip 'no npm test script'
fi
if [ -f "$repo_root/.agents/cloud/verify.project.sh" ]; then
  bash "$repo_root/.agents/cloud/verify.project.sh" && pass 'project verifier' || fail 'project verifier failed'
fi

echo
if [ "$failures" -eq 0 ]; then
  if [ "$credential_skips" -gt 0 ]; then
    echo "verify.sh: all checks passed (code-work profile: $credential_skips credential variable(s) unset, so Bitwarden went unproven)"
  else
    echo 'verify.sh: all checks passed'
  fi
  exit 0
fi
if [ "$credential_failures" -gt 0 ] && [ "$credential_failures" -eq "$failures" ]; then
  echo "verify.sh: $failures check(s) failed -- all of them are unset Bitwarden credential variables in a kit that has some of them ($CREDENTIAL_PROFILE_VARS). A half-provisioned kit fails partway through authenticated work, which is why this is fatal rather than skipped; provision the rest, or unset them all to verify as a code-work environment."
elif [ "$credential_failures" -gt 0 ]; then
  echo "verify.sh: $failures check(s) failed ($credential_failures of them unset Bitwarden credential variables; the rest are unrelated and indicate a broken environment)"
else
  echo "verify.sh: $failures check(s) failed"
fi
exit 1

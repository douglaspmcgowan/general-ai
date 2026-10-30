#!/usr/bin/env bash
# Proves install-shared-contract.sh gives a container with no ~/.agents the shared contract,
# loaded once per product, and fails closed when it cannot: the harness repository itself,
# another repository that fetches the pinned harness commit, a cached rerun, an unknown pin, an
# unreachable harness, a half-written loader, a stale or dangling ~/.agents, and the Codex trust
# hash of the guard. No network: the "remote" is a local bare repository.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
harness="$(cd "$here/.." && pwd)"
script="$here/install-shared-contract.sh"
pass_count=0
fail_count=0
pass() { printf '  ok    %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf '  FAIL  %s\n' "$1"; fail_count=$((fail_count + 1)); }
skip() { printf '  skip  %s\n' "$1"; }
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# The package the cases copy from: this repository's own .agents when the test runs inside the
# harness, otherwise a minimal inert package synthesized here. A product checkout has no canonical
# contract, so the synthetic package carries only the markers and placeholders the production
# renderer substitutes (the Claude import line, the {{CANONICAL_AGENTS}} embed, the first contract
# line) and no live instructions.
canon="$harness"
for f in AGENTS.md templates/AGENTS.md adapters/claude/CLAUDE.md adapters/codex/AGENTS.md adapters/opencode/AGENTS.md adapters/agy/AGENTS.md; do
  [ -f "$harness/$f" ] || canon=''
done
if [ -z "$canon" ]; then
  canon="$work/synthetic-package"
  mkdir -p "$canon/templates" "$canon/adapters/claude" "$canon/adapters/codex" "$canon/adapters/opencode" "$canon/adapters/agy"
  printf '# Synthetic shared contract (test fixture)\n\nInert rule: this fixture carries no live instructions.\n' > "$canon/AGENTS.md"
  printf '# Synthetic template (test fixture)\n' > "$canon/templates/AGENTS.md"
  printf '<!-- agent-harness:claude-loader:v1:start -->\n@{{HOME_POSIX}}/.agents/AGENTS.md\n<!-- agent-harness:claude-loader:v1:end -->\n' > "$canon/adapters/claude/CLAUDE.md"
  for adapter in codex opencode agy; do
    printf '<!-- agent-harness:%s-loader:v1:start -->\n{{CANONICAL_AGENTS}}\n<!-- agent-harness:%s-loader:v1:end -->\n' "$adapter" "$adapter" > "$canon/adapters/$adapter/AGENTS.md"
  done
fi

# A minimal harness package: the contract, the template that marks it as the harness, and the
# adapters the script renders.
make_package() {
  local dest="$1" adapter
  mkdir -p "$dest/templates" "$dest/adapters/claude" "$dest/adapters/codex" "$dest/adapters/opencode" "$dest/adapters/agy"
  cp "$canon/AGENTS.md" "$dest/AGENTS.md"
  cp "$canon/templates/AGENTS.md" "$dest/templates/AGENTS.md"
  for adapter in claude/CLAUDE.md codex/AGENTS.md opencode/AGENTS.md agy/AGENTS.md; do
    cp "$canon/adapters/$adapter" "$dest/adapters/$adapter"
  done
}

first_line="$(grep -m1 -v '^\s*$' "$canon/AGENTS.md")"
guard_text='agent-harness: ~/.agents/AGENTS.md is missing'
count_in() { grep -cF -- "$2" "$1" 2>/dev/null || true; }
is_installed() { case "$out" in shared_contract=installed*) return 0 ;; *) return 1 ;; esac; }
is_absent() { case "$out" in shared_contract=absent*) return 0 ;; *) return 1 ;; esac; }

# run <home> <repo> [VAR=value...]: runs the installer; sets $out (last line) and $rc.
run() {
  local home="$1" repo="$2"
  shift 2
  out="$(env HOME="$home" CODEX_HOME='' CLOUD_HARNESS_REPO_URL='' "$@" bash "$script" "$repo" 2>/dev/null)"
  rc=$?
  out="$(printf '%s\n' "$out" | tail -n1)"
}

# guard_rc <home> <settings-file>: the exit status of the installed guard command, or "none".
guard_rc() {
  local home="$1" settings="$2" guard status=0
  guard="$(grep -o '"command": "test -r [^"]*"' "$home/$settings" 2>/dev/null | head -n1 | sed 's/^"command": "//; s/"$//')"
  if [ -z "$guard" ]; then printf 'none\n'; return; fi
  HOME="$home" bash -c "$guard" >/dev/null 2>&1 || status=$?
  printf '%s\n' "$status"
}

check_installed() {
  local label="$1" home="$2" loader settings
  if [ -f "$home/.agents/AGENTS.md" ] && diff -q <(tr -d '\r' < "$home/.agents/AGENTS.md") <(tr -d '\r' < "$canon/AGENTS.md") >/dev/null; then
    pass "$label: ~/.agents/AGENTS.md is the shared contract"
  else
    fail "$label: ~/.agents/AGENTS.md missing or different"
  fi
  if [ "$(count_in "$home/.claude/CLAUDE.md" "@$home/.agents/AGENTS.md")" = 1 ]; then
    pass "$label: ~/.claude/CLAUDE.md imports it exactly once"
  else
    fail "$label: ~/.claude/CLAUDE.md import count is not 1"
  fi
  for loader in .codex/AGENTS.md .config/opencode/AGENTS.md .gemini/config/AGENTS.md; do
    if [ "$(count_in "$home/$loader" "$first_line")" = 1 ] && [ "$(count_in "$home/$loader" '{{CANONICAL_AGENTS}}')" = 0 ]; then
      pass "$label: ~/$loader embeds it exactly once"
    else
      fail "$label: ~/$loader does not embed the contract exactly once"
    fi
  done
  for settings in .claude/settings.json .codex/hooks.json; do
    if [ "$(count_in "$home/$settings" "$guard_text")" = 1 ] && [ "$(guard_rc "$home" "$settings")" = 0 ]; then
      pass "$label: ~/$settings carries the guard once, and it allows tool use"
    else
      fail "$label: ~/$settings guard missing, duplicated, or refusing with the contract present"
    fi
  done
}

# 1. The harness repository itself: its own .agents is the source; no clone.
h1="$work/h1"; mkdir -p "$h1/home" "$h1/repo"
make_package "$h1/repo/.agents"
run "$h1/home" "$h1/repo"
if is_installed && [ "$rc" = 0 ]; then pass 'harness repo: reports installed, exit 0'; else fail "harness repo: '$out' exit $rc"; fi
check_installed 'harness repo' "$h1/home"

# 2. Another repository: exactly the pinned commit is fetched from the remote.
remote="$work/remote"; mkdir -p "$remote/src"
make_package "$remote/src/.agents"
git -C "$remote/src" init -q && git -C "$remote/src" config core.autocrlf false && git -C "$remote/src" add -A &&
  git -C "$remote/src" -c core.hooksPath=/dev/null -c user.email=t@t -c user.name=t commit -qm fixture &&
  git clone -q --bare "$remote/src" "$remote/harness.git"
git -C "$remote/harness.git" config uploadpack.allowAnySHA1InWant true
pinned="$(git -C "$remote/src" rev-parse HEAD)"
h2="$work/h2"; mkdir -p "$h2/home/.claude" "$h2/repo"
printf 'user text kept\n' > "$h2/home/.claude/CLAUDE.md"
run "$h2/home" "$h2/repo" CLOUD_HARNESS_REPO_URL="$remote/harness.git" CLOUD_HARNESS_COMMIT="$pinned"
if is_installed; then pass 'other repo: reports installed from the pinned commit'; else fail "other repo: reported '$out'"; fi
check_installed 'other repo' "$h2/home"
if grep -qF 'user text kept' "$h2/home/.claude/CLAUDE.md"; then pass 'other repo: existing ~/.claude/CLAUDE.md text preserved'; else fail 'other repo: existing ~/.claude/CLAUDE.md text lost'; fi
if [ "$(git -C "$h2/home/.cache/agent-harness/doug-harness" rev-parse HEAD 2>/dev/null)" = "$pinned" ]; then
  pass 'other repo: the clone sits at exactly the pinned commit'
else
  fail 'other repo: the clone is not at the pinned commit'
fi

# 3. A cached environment re-runs setup offline: still exactly one block and one guard per file.
run "$h2/home" "$h2/repo" CLOUD_HARNESS_COMMIT="$pinned"
if is_installed; then pass 'rerun: the cached pinned clone is reused offline'; else fail "rerun: reported '$out'"; fi
check_installed 'rerun' "$h2/home"

# 4. A pin the remote does not have: never falls back to the default branch.
h4="$work/h4"; mkdir -p "$h4/home" "$h4/repo"
run "$h4/home" "$h4/repo" CLOUD_HARNESS_REPO_URL="$remote/harness.git" CLOUD_HARNESS_COMMIT=0123456789abcdef0123456789abcdef01234567
if is_absent && [ "$rc" = 1 ]; then pass 'unknown pin: reports absent, exit 1'; else fail "unknown pin: '$out' exit $rc"; fi

# 5. No harness reachable: absent, exit 1, no loader, and both guards refuse tool use.
h5="$work/h5"; mkdir -p "$h5/home" "$h5/repo"
run "$h5/home" "$h5/repo"
if is_absent && [ "$rc" = 1 ]; then pass 'unreachable: reports absent, exit 1'; else fail "unreachable: '$out' exit $rc"; fi
if [ ! -e "$h5/home/.claude/CLAUDE.md" ] && [ ! -e "$h5/home/.codex/AGENTS.md" ]; then pass 'unreachable: no loader written'; else fail 'unreachable: a loader was written with no contract'; fi
for settings in .claude/settings.json .codex/hooks.json; do
  if [ "$(guard_rc "$h5/home" "$settings")" = 2 ]; then pass "unreachable: the guard in ~/$settings refuses tool use (exit 2)"
  else fail "unreachable: ~/$settings has no refusing guard"; fi
done
if grep -qF '[hooks.state."' "$h5/home/.codex/config.toml" 2>/dev/null; then pass 'unreachable: Codex trusts the guard'; else fail 'unreachable: the Codex guard is untrusted'; fi

# 6. One loader marker without the other: refused, reported absent, the file left as it was.
h6="$work/h6"; mkdir -p "$h6/home/.codex" "$h6/repo"
make_package "$h6/repo/.agents"
printf 'mine\n<!-- agent-harness:codex-loader:v1:start -->\nhalf\n' > "$h6/home/.codex/AGENTS.md"
before="$(cat "$h6/home/.codex/AGENTS.md")"
run "$h6/home" "$h6/repo"
case "$out" in
  *reason=malformed-codex-loader*) if [ "$rc" = 1 ]; then pass 'half-written loader: refused, exit 1'; else fail "half-written loader: exit $rc"; fi ;;
  *) fail "half-written loader: reported '$out'" ;;
esac
if [ "$(cat "$h6/home/.codex/AGENTS.md")" = "$before" ]; then pass 'half-written loader: file untouched'; else fail 'half-written loader: file rewritten'; fi

# 7. A stale real ~/.agents: moved aside (never deleted) and replaced by the verified package.
h7="$work/h7"; mkdir -p "$h7/home/.agents" "$h7/repo"
make_package "$h7/repo/.agents"
printf 'an old contract\n' > "$h7/home/.agents/AGENTS.md"
run "$h7/home" "$h7/repo"
if is_installed; then pass 'stale ~/.agents: replaced and reported installed'; else fail "stale ~/.agents: reported '$out'"; fi
check_installed 'stale ~/.agents' "$h7/home"
if grep -qF 'an old contract' "$h7/home"/.agents.stale-*/AGENTS.md 2>/dev/null; then pass 'stale ~/.agents: the old copy is kept aside'
else fail 'stale ~/.agents: the old copy was lost'; fi

# 8. A dangling ~/.agents link is never reported installed while it dangles. Skipped where this
# host's ln -s cannot make a dangling link (Git Bash without symlink privilege copies instead).
h8="$work/h8"; mkdir -p "$h8/home" "$h8/repo"
make_package "$h8/repo/.agents"
if ln -s "$work/nowhere" "$h8/home/.agents" 2>/dev/null && [ -L "$h8/home/.agents" ]; then
  run "$h8/home" "$h8/repo"
  if is_installed && [ -r "$h8/home/.agents/AGENTS.md" ]; then pass 'dangling ~/.agents: repaired and verified before reporting installed'
  elif is_absent; then pass 'dangling ~/.agents: reported absent'
  else fail "dangling ~/.agents: reported '$out' with an unreadable contract"; fi
else
  skip 'dangling ~/.agents: this host cannot create a dangling symlink'
fi

# 9. The guard's Codex trust hash is the one codex-hook-trust.mjs computes.
trust_lib="$harness/tools/lib/codex-hook-trust.mjs"
if command -v node >/dev/null 2>&1 && [ -f "$trust_lib" ]; then
  if command -v cygpath >/dev/null 2>&1; then trust_url="file:///$(cygpath -m "$trust_lib")"; else trust_url="file://$trust_lib"; fi
  guard="$(grep -o '"command": "test -r [^"]*"' "$h5/home/.codex/hooks.json" | head -n1 | sed 's/^"command": "//; s/"$//')"
  expected="$(node --input-type=module -e "const { hookTrustHash } = await import(process.argv[1]); console.log(hookTrustHash('PreToolUse', '.*', { type: 'command', command: process.argv[2], timeout: 10 }, 'linux'))" "$trust_url" "$guard" 2>/dev/null)"
  if [ -n "$expected" ] && grep -qF "trusted_hash = \"$expected\"" "$h5/home/.codex/config.toml"; then
    pass 'the guard trust hash matches codex-hook-trust.mjs'
  else
    fail "the guard trust hash does not match codex-hook-trust.mjs (expected '$expected')"
  fi
else
  skip 'guard trust hash: node or codex-hook-trust.mjs unavailable'
fi

# 10. The pinned commit is a real commit of this repository's history.
# shellcheck disable=SC1091
pin_commit="$(. "$here/harness-pin.sh" && printf '%s' "$HARNESS_COMMIT")"
if [ "$canon" != "$harness" ]; then
  skip 'harness-pin.sh commit: product topology, the pinned commit lives in the harness repository'
elif git -C "$harness" cat-file -e "${pin_commit}^{commit}" 2>/dev/null; then
  pass "harness-pin.sh names a commit in this repository ($pin_commit)"
elif [ "$(git -C "$harness" rev-parse --is-shallow-repository 2>/dev/null)" = true ]; then
  skip 'harness-pin.sh commit: a shallow checkout cannot see it'
else
  fail "harness-pin.sh names a commit this repository does not have: $pin_commit"
fi

printf '\n%d passed, %d failed\n' "$pass_count" "$fail_count"
[ "$fail_count" -eq 0 ]

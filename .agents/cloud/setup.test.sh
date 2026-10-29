#!/usr/bin/env bash
# Proves setup.sh is idempotent -- the first claim ONBOARDING/CLOUD-AGENTS.md's readiness
# checklist makes, and until 2026-08-09 the only one nothing checked.
#
# It matters more than it sounds. A hosted environment re-runs setup on every resumed cached
# container, so a non-idempotent line does not fail once -- it accumulates. The concrete shape
# is `persist_path`, which appends a PATH export to ~/.bashrc and ~/.profile: without its
# grep guard, a container resumed twenty times carries twenty copies of the same export, and
# the failure is invisible because every one of them is individually correct.
#
# No network, and nothing installed. The pinned tools are stubbed on PATH reporting the exact
# versions tool-versions.sh declares, so setup takes its already-present branch; curl is
# stubbed to fail so any branch that did try to download is caught rather than silently
# reaching the internet from a test.
#
# The fixture is a throwaway repository root rather than this one. It carries the cloud scripts
# under .agents/cloud, including the readiness guide a scaffolded project receives, keeping the
# run away from the real .local/, any package-lock.json, and any setup.project.sh.

set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source_repo_root="$(cd "$here/../.." && pwd)"
# shellcheck disable=SC1091
set -a; . "$here/tool-versions.sh"; set +a
# Fixtures model a fresh code-work image. Keep host credential-profile presence out of every
# child setup run; the one partial-profile case below supplies its own value-free fixture field.
unset BITWARDEN_SECRETS_MANAGER_ACCESS_TOKEN BWS_DIGITAL_SECRETARY_ACCESS_TOKEN BWS_GENERAL_AGENTS_ACCESS_TOKEN BWS_GENERAL_AGENTS_TOKEN BWS_PHYSICAL_COMPUTER_ACCESS_TOKEN BWS_PROJECT_ID REVIEW_URL DOCKET_REVIEW_SECRET_ID CLOUD_KIT_PROFILE
# No fixture may clone the real harness. Each fixture repository carries the minimal harness
# package instead, so install-shared-contract.sh installs from it offline; the one case that
# omits it proves setup fails closed. install-shared-contract.test.sh owns the clone cases.
export CLOUD_HARNESS_REPO_URL=''
pass_count=0
fail_count=0

pass() { printf '  ok    %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf '  FAIL  %s\n' "$1"; fail_count=$((fail_count + 1)); }

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# ---------------------------------------------------------------- fixture builder
# $1 = destination root, $2 = optional sed program applied to setup.sh (for the mutation case)
build_fixture() {
  local root="$1" mutate="${2:-}" persist_clis="${3:-1}"
  mkdir -p "$root/repo/.agents/cloud" "$root/repo/.local/agent-tools/bin" "$root/home" "$root/stub"

  cp "$here/tool-versions.sh" "$root/repo/.agents/cloud/tool-versions.sh"
  cp "$here/powershell-runtime.sh" "$root/repo/.agents/cloud/powershell-runtime.sh"
  cp "$here/credential-profile.sh" "$root/repo/.agents/cloud/credential-profile.sh"
  cp "$here/FRESH-MACHINE-READINESS.md" "$root/repo/.agents/cloud/FRESH-MACHINE-READINESS.md"
  cp "$here/install-shared-contract.sh" "$root/repo/.agents/cloud/install-shared-contract.sh"
  cp "$here/harness-pin.sh" "$root/repo/.agents/cloud/harness-pin.sh"
  # The minimal harness package, so the shared contract installs offline from this repository.
  if [ "${FIXTURE_WITHOUT_HARNESS:-0}" != 1 ]; then
    mkdir -p "$root/repo/.agents/templates" "$root/repo/.agents/adapters/claude" "$root/repo/.agents/adapters/codex"
    cp "$here/../AGENTS.md" "$root/repo/.agents/AGENTS.md"
    cp "$here/../templates/AGENTS.md" "$root/repo/.agents/templates/AGENTS.md"
    cp "$here/../adapters/claude/CLAUDE.md" "$root/repo/.agents/adapters/claude/CLAUDE.md"
    cp "$here/../adapters/codex/AGENTS.md" "$root/repo/.agents/adapters/codex/AGENTS.md"
  fi
  if [ -n "$mutate" ]; then
    sed "$mutate" "$here/setup.sh" > "$root/repo/.agents/cloud/setup.sh"
  else
    cp "$here/setup.sh" "$root/repo/.agents/cloud/setup.sh"
  fi

  # Versions come from the real pin file, so a bumped pin cannot quietly desynchronise the
  # stubs from what setup.sh greps for.
  # shellcheck disable=SC1091
  set -a; . "$root/repo/.agents/cloud/tool-versions.sh"; set +a

  cat > "$root/stub/gh" <<EOF
#!/usr/bin/env bash
echo "gh version ${GH_VERSION} (2026-01-01)"
EOF
  cat > "$root/stub/bws" <<EOF
#!/usr/bin/env bash
echo "bws ${BWS_VERSION}"
EOF
  cat > "$root/stub/pwsh" <<EOF
#!/usr/bin/env bash
echo "PowerShell ${POWERSHELL_VERSION}"
EOF
  cat > "$root/stub/node" <<EOF
#!/usr/bin/env bash
echo "v${NODE_RELEASE_LINE}.0.0"
EOF
  cat > "$root/stub/python3" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = '-m' ] && [ "$2" = 'pip' ]; then
  echo 'pip 24.0'
else
  echo 'Python 3.12.0'
fi
EOF
  # Any download attempt is a test failure, not a network call.
  cat > "$root/stub/curl" <<'EOF'
#!/usr/bin/env bash
echo "curl stub refused a download: $*" >&2
exit 22
EOF
  # npm present and inert: setup's node-delivered CLI block runs its guards without
  # installing anything globally on the machine running this suite.
  cat > "$root/stub/npm" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  for tool in rg sqlite3 jq unzip; do
    printf '#!/usr/bin/env bash\nexit 0\n' > "$root/stub/$tool"
  done
  cat > "$root/stub/git-lfs" <<'EOF'
#!/usr/bin/env bash
echo 'git-lfs/3.4.1 (GitHub; linux amd64; go 1.22.2)'
EOF
  chmod +x "$root/stub/"*
  if [ "$persist_clis" = '1' ]; then
    cp "$root/stub/gh" "$root/stub/bws" "$root/stub/pwsh" "$root/repo/.local/agent-tools/bin/"
  fi
}

run_setup() {
  local root="$1" log="$2"
  ( cd "$root/repo" \
    && PATH="$root/stub:$PATH" \
       HOME="$root/home" \
       CLOUD_TOOL_ROOT=".local/agent-tools" \
       POWERSHELL_RUNTIME_PREFIX="$root/pwsh-prefix" \
       POWERSHELL_RUNTIME_LAUNCHER="$root/pwsh-bin/pwsh" \
       bash "$root/repo/.agents/cloud/setup.sh" ) >"$log" 2>&1
}

# On MSYS/Cygwin (this host's git-bash), `ln -s` onto a coreutils binary without
# symlink privilege silently falls back to a plain copy of the PE executable rather
# than a real symlink -- confirmed by `ls -la` on the copy showing a regular file at
# the source's exact byte size, not an `l...` symlink entry. That copy still needs its
# MSYS runtime DLL (msys-2.0.dll and friends) resolved via PATH or its own directory,
# and a PATH scoped to just this fixture directory supplies neither, so every one of
# those tools fails with "error while loading shared libraries" and setup.sh dies on
# its first line (`dirname "${BASH_SOURCE[0]}"`). Real Linux coreutils resolve libc via
# the system linker path, never PATH, so this dependency does not exist there -- this
# is purely this fixture's Windows-host portability gap, not a defect in setup.sh.
# Filtering `ldd` output to only `/usr/...` targets keeps this a no-op on Linux, where
# `ldd` reports `/lib/...` paths that are already resolvable without help.
copy_runtime_deps() {
  local bin="$1" dest="$2" line libpath
  command -v ldd >/dev/null 2>&1 || return 0
  while IFS= read -r line; do
    libpath="${line#*=> }"
    libpath="${libpath%% (*}"
    case "$libpath" in
      /usr/*) [ -f "$libpath" ] && [ ! -e "$dest/$(basename "$libpath")" ] && cp "$libpath" "$dest/" ;;
    esac
  done < <(ldd "$bin" 2>/dev/null)
}

# A minimal PATH provides only the commands setup needs. It deliberately omits node,
# npm, python3, and pip until fake apt-get installs their harmless fixture shims.
build_minimal_runtime_fixture() {
  local root="$1" tool candidate persist_clis="${2:-1}"
  build_fixture "$root" '' "$persist_clis"
  mkdir -p "$root/minimal"
  for tool in awk bash cat chmod cmp cp cut date dirname env find git grep head id install ln mkdir mktemp mv readlink realpath rm rmdir sed sha256sum stat tail tar touch uname; do
    candidate="$(command -v "$tool")"
    if [ -n "$candidate" ]; then
      ln -s "$candidate" "$root/minimal/$tool"
      copy_runtime_deps "$candidate" "$root/minimal"
    fi
  done
  for tool in gh bws pwsh curl; do
    ln -s "$root/stub/$tool" "$root/minimal/$tool"
  done
  for tool in rg sqlite3 jq unzip; do
    printf '#!/usr/bin/env bash\nexit 0\n' > "$root/minimal/$tool"
    chmod +x "$root/minimal/$tool"
  done
  cat > "$root/minimal/apt-get" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$FAKE_APT_LOG"
if [ "$1" = 'install' ]; then
  for package in "$@"; do
    case "$package" in
      nodejs) name=node; version="${FAKE_NODE_VERSION:-v0.0.0}" ;;
      npm) name=npm; version='10.0.0' ;;
      python3) name=python3; version='Python 3.12.0' ;;
      python3-pip) name=pip; version='pip 24.0' ;;
      git-lfs) name=git-lfs; version='git-lfs/3.4.1 (GitHub; linux amd64; go 1.22.2)' ;;
      *) continue ;;
    esac
    printf '#!/usr/bin/env bash\nprintf "%%s\\n" "%s"\n' "$version" > "$FAKE_RUNTIME_BIN/$name"
    chmod +x "$FAKE_RUNTIME_BIN/$name"
  done
fi
EOF
  chmod +x "$root/minimal/apt-get"
}

run_minimal_runtime_setup() {
  local root="$1" log="$2" node_version="${3:-v${NODE_RELEASE_LINE}.0.0}"
  ( cd "$root/repo" \
    && PATH="$root/minimal" \
       HOME="$root/home" \
       NVM_DIR="$root/home/.nvm" \
       CLOUD_TOOL_ROOT=".local/agent-tools" \
       POWERSHELL_RUNTIME_PREFIX="$root/pwsh-prefix" \
       POWERSHELL_RUNTIME_LAUNCHER="$root/pwsh-bin/pwsh" \
       FAKE_APT_LOG="$root/apt.log" \
       FAKE_RUNTIME_BIN="$root/minimal" \
       FAKE_NODE_VERSION="$node_version" \
       /bin/bash "$root/repo/.agents/cloud/setup.sh" ) >"$log" 2>&1
}

build_architecture_fixture() {
  local root="$1"
  build_minimal_runtime_fixture "$root" 0
  rm -f "$root/minimal/gh" "$root/minimal/bws" "$root/minimal/pwsh" "$root/minimal/curl" "$root/minimal/sha256sum"
  cat > "$root/minimal/uname" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$FAKE_ARCH"
EOF
cat > "$root/minimal/curl" <<'EOF'
#!/usr/bin/env bash
args="$*"
printf '%s\n' "$args" >> "$FAKE_CURL_LOG"
out=''
while [ "$#" -gt 0 ]; do
  if [ "$1" = '-o' ]; then out="$2"; shift 2; else shift; fi
done
printf '%s' "$args" > "$out"
EOF
cat > "$root/minimal/sha256sum" <<'EOF'
#!/usr/bin/env bash
set -a; . "$FAKE_TOOL_VERSIONS"; set +a
case "$(cat "$1")" in
  *gh_"$GH_VERSION"_linux_arm64*) hash="${GH_SHA256_ARM64:-missing}" ;;
  *gh_"$GH_VERSION"_linux_amd64*) hash="${GH_SHA256_AMD64:-missing}" ;;
  *bws-aarch64-unknown-linux-gnu-"$BWS_VERSION"*) hash="${BWS_SHA256_ARM64:-missing}" ;;
  *bws-x86_64-unknown-linux-gnu-"$BWS_VERSION"*) hash="${BWS_SHA256_AMD64:-missing}" ;;
  *powershell-"$POWERSHELL_VERSION"-linux-arm64*) hash="${POWERSHELL_SHA256_ARM64:-missing}" ;;
  *powershell-"$POWERSHELL_VERSION"-linux-x64*) hash="${POWERSHELL_SHA256_AMD64:-missing}" ;;
  *) hash='0000000000000000000000000000000000000000000000000000000000000000' ;;
esac
printf '%s  %s\n' "$hash" "$1"
EOF
  chmod +x "$root/minimal/uname" "$root/minimal/curl" "$root/minimal/sha256sum"
}

run_architecture_setup() {
  local root="$1" log="$2" arch="$3"
  ( cd "$root/repo" \
    && PATH="$root/minimal" \
       HOME="$root/home" \
       CLOUD_TOOL_ROOT=".local/agent-tools" \
       POWERSHELL_RUNTIME_PREFIX="$root/pwsh-prefix" \
       POWERSHELL_RUNTIME_LAUNCHER="$root/pwsh-bin/pwsh" \
       FAKE_APT_LOG="$root/apt.log" \
       FAKE_RUNTIME_BIN="$root/minimal" \
       FAKE_NODE_VERSION="v${NODE_RELEASE_LINE}.0.0" \
       FAKE_CURL_LOG="$root/curl.log" \
       FAKE_TOOL_VERSIONS="$root/repo/.agents/cloud/tool-versions.sh" \
       FAKE_ARCH="$arch" \
       /bin/bash "$root/repo/.agents/cloud/setup.sh" ) >"$log" 2>&1
}

build_verify_fixture() {
  local root="$1"
  mkdir -p "$root/repo/.agents/cloud" "$root/repo/.local/agent-tools/bin"
  cp "$here/verify.sh" "$root/repo/.agents/cloud/verify.sh"
  # Every file verify.sh SOURCES, derived from verify.sh itself rather than listed here a second
  # time. Adding credential-profile.sh to the kit broke this fixture on 2026-08-23: the copy was
  # tool-versions.sh only, verify.sh aborted at its environment section on an unbound function, and
  # three assertions about output printed AFTER that section failed while naming causes -- an
  # incompatible PROJECT_DATA_ROOT, two unproven vault-pull mode refusals -- that had nothing to do
  # with it. Only `. "..."` lines are matched: verify.project.sh is INVOKED rather than sourced, and
  # copying it would make this fixture run the whole PowerShell tool gate.
  for sourced in $(grep -oE '\. "\$repo_root/\.agents/cloud/[A-Za-z0-9._-]+"' "$here/verify.sh" | sed 's|.*/||; s|"$||'); do
    [ -f "$here/$sourced" ] && cp "$here/$sourced" "$root/repo/.agents/cloud/$sourced"
  done
  for f in PRODUCT.md secret-manifest.json; do : > "$root/repo/$f"; done
  # CLAUDE.md and the Cursor rule are checked for ROUTING, not just existence, since 2026-08-23:
  # an empty projection satisfied the old presence check while giving that product's agent no
  # contract at all. The fixture's copies have to carry the reference for the same reason the real
  # ones do. Deliberately minimal -- this fixture tests setup and verify plumbing, not the contract.
  printf '@AGENTS.md\n' > "$root/repo/CLAUDE.md"
  mkdir -p "$root/repo/.cursor/rules"
  printf 'Follow AGENTS.md at the repository root.\n' > "$root/repo/.cursor/rules/00-project-contract.mdc"
  cat > "$root/repo/.local/agent-tools/bin/git" <<'EOF'
#!/usr/bin/env bash
echo 'git version 2.0.0'
EOF
  for tool in gh bws; do cp "$root/stub/$tool" "$root/repo/.local/agent-tools/bin/$tool"; done
  cat > "$root/repo/.local/agent-tools/bin/node" <<EOF
#!/usr/bin/env bash
echo "v${NODE_RELEASE_LINE}.0.0"
EOF
  cat > "$root/repo/.local/agent-tools/bin/npm" <<'EOF'
#!/usr/bin/env bash
echo '10.0.0'
EOF
  cat > "$root/repo/.local/agent-tools/bin/python3" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = '-m' ] && [ "$2" = 'pip' ]; then echo 'pip 24.0'; else echo 'Python 3.12.0'; fi
EOF
  chmod +x "$root/repo/.local/agent-tools/bin/"*
}

run_verify() {
  local root="$1" log="$2"
  ( cd "$root/repo" && bash .agents/cloud/verify.sh ) >"$log" 2>&1
}

run_setup_without_project_data_root() {
  local root="$1" log="$2"
  ( unset PROJECT_DATA_ROOT
    cd "$root/repo" \
      && PATH="$root/stub:$PATH" \
         HOME="$root/home" \
         CLOUD_TOOL_ROOT=".local/agent-tools" \
         POWERSHELL_RUNTIME_PREFIX="$root/pwsh-prefix" \
       POWERSHELL_RUNTIME_LAUNCHER="$root/pwsh-bin/pwsh" \
         bash "$root/repo/.agents/cloud/setup.sh" ) >"$log" 2>&1
}

run_setup_with_incomplete_credentials() {
  local root="$1" log="$2"
  ( cd "$root/repo" \
    && PATH="$root/stub:$PATH" \
       HOME="$root/home" \
       CLOUD_TOOL_ROOT=".local/agent-tools" \
       POWERSHELL_RUNTIME_PREFIX="$root/pwsh-prefix" \
       POWERSHELL_RUNTIME_LAUNCHER="$root/pwsh-bin/pwsh" \
       BWS_PROJECT_ID='value-free-fixture-id' \
       bash "$root/repo/.agents/cloud/setup.sh" ) >"$log" 2>&1
}

run_verify_from_setup_profile() {
  local root="$1" log="$2"
  ( unset PROJECT_DATA_ROOT
    cd "$root/repo" \
      && HOME="$root/home" \
         PATH="$root/stub:$PATH" \
         bash -c '. "$HOME/.profile"; bash .agents/cloud/verify.sh' ) >"$log" 2>&1
}

# ============================================================ fail closed without the contract
# SETUP_TEST_SECTION=fail-closed runs only this section; Test-ContractLoaderChain.ps1 uses it to
# prove the unreachable container really fails setup, without the whole suite's runtime.
test_fail_closed() {
  # A repository that is not the harness, in a container that cannot reach the harness: setup must
  # exit nonzero, record the contract absent, and leave Claude and Codex refusing tool use.
  closed_root="$work/fail-closed"
  FIXTURE_WITHOUT_HARNESS=1 build_fixture "$closed_root"
  run_setup "$closed_root" "$work/fail-closed.log"
  closed_rc=$?
  if [ "$closed_rc" -ne 0 ]; then pass 'setup exits nonzero when the shared contract cannot be installed'
  else fail "setup exited 0 with no shared contract; see $work/fail-closed.log"; fi
  if grep -qF 'SETUP FAILED -- the shared contract' "$work/fail-closed.log"; then pass 'setup names the missing shared contract'
  else fail 'setup did not name the missing shared contract'; fi
  if grep -q '"shared_contract": "absent"' "$closed_root/repo/.local/agent-tools/setup-status.json" 2>/dev/null; then
    pass 'setup records shared_contract absent'
  else
    fail 'setup did not record shared_contract absent'
  fi
  for settings in .claude/settings.json .codex/hooks.json; do
    guard="$(grep -o '"command": "test -r [^"]*"' "$closed_root/home/$settings" 2>/dev/null | head -n1 | sed 's/^"command": "//; s/"$//')"
    guard_rc=0
    if [ -n "$guard" ]; then HOME="$closed_root/home" bash -c "$guard" >/dev/null 2>&1 || guard_rc=$?; fi
    if [ -n "$guard" ] && [ "$guard_rc" -eq 2 ]; then pass "the guard in ~/$settings refuses tool use (exit 2)"
    else fail "no refusing guard in ~/$settings (rc=$guard_rc)"; fi
  done
}
# ============================================================ project Node pin
# SETUP_TEST_SECTION=node-pin runs only this section.
test_node_pin() {
  # A reviewed project .nvmrc selects the Node release line setup and verify both require; with
  # no project pin the canonical default stays. Offline: every node is a stub under a fixture nvm.
  node_pin_fixture() {
    local root="$1" pin="$2" versions="$3" v d
    build_minimal_runtime_fixture "$root"
    for t in sort; do
      ln -s "$(command -v $t)" "$root/minimal/$t"
      copy_runtime_deps "$(command -v $t)" "$root/minimal"
    done
    printf '#!/usr/bin/env bash\necho v20.20.2\n' > "$root/minimal/node"
    printf '#!/usr/bin/env bash\necho 10.0.0\n' > "$root/minimal/npm"
    chmod +x "$root/minimal/node" "$root/minimal/npm"
    for v in $versions; do
      d="$root/home/.nvm/versions/node/v$v/bin"
      mkdir -p "$d"
      printf '#!/usr/bin/env bash\necho v%s\n' "$v" > "$d/node"
      cat > "$d/npm" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${FIXTURE_NPM_LOG:?}"
[ "${1:-}" = --version ] && { echo 10.0.0; exit 0; }
echo 'offline fixture npm refused an install' >&2
exit 97
EOF
      cat > "$d/npx" <<'EOF'
#!/usr/bin/env bash
echo 'offline fixture npx refused execution' >&2
exit 97
EOF
      chmod +x "$d/node" "$d/npm" "$d/npx"
    done
    [ -z "$pin" ] || printf '%b' "$pin" > "$root/repo/.nvmrc"
  }
  node_pin_case() { # name pin versions
    local root="$work/nodepin-$1"
    node_pin_fixture "$root" "$2" "$3"
    FIXTURE_NPM_LOG="$root/npm.log" run_minimal_runtime_setup "$root" "$work/nodepin-$1.log" 'v20.20.2'
    NP_RC=$?
    NP_LOG="$work/nodepin-$1.log"
    NP_ROOT="$root"
  }
  # Parser proof runs before setup, with no package manager or network-capable process.
  np_parse() {
    local root="$work/nodeparse-$1"
    mkdir -p "$root/repo/.agents/cloud"
    cp "$here/tool-versions.sh" "$root/repo/.agents/cloud/tool-versions.sh"
    printf '%b' "$2" > "$root/repo/.nvmrc"
    (cd "$root/repo" && . .agents/cloud/tool-versions.sh && printf 'LINE=%s\nERROR=%s\n' "$NODE_RELEASE_LINE" "$NODE_PIN_ERROR")
  }
  np_out="$(np_parse full '24.1.2\n')"
  printf '%s\n' "$np_out" | grep -qx 'LINE=24.1.2' \
    && pass 'parser preserves a full MAJOR.MINOR.PATCH pin' \
    || fail "parser did not preserve a full pin: $np_out"
  np_out="$(np_parse multiline '24\n22\n')"
  printf '%s\n' "$np_out" | grep -q 'ERROR=unsupported .nvmrc' \
    && pass 'parser refuses a long multiline pin before setup effects' \
    || fail "parser accepted a multiline pin: $np_out"
  np_out="$(np_parse huge '999999999999999999999999999999999\n')"
  printf '%s\n' "$np_out" | grep -q 'ERROR=unsupported .nvmrc' \
    && pass 'parser handles a huge major deterministically' \
    || fail "parser accepted a huge major: $np_out"
  # Selector proof uses only an explicit fixture NVM_DIR and fixture PATH.
  np_selector_root="$work/nodeselect"
  mkdir -p "$np_selector_root/home/.nvm/versions/node/v22.8.0/bin" "$np_selector_root/bin" "$np_selector_root/path"
  for np_tool in ln readlink rm sort; do
    ln -s "$(command -v "$np_tool")" "$np_selector_root/path/$np_tool"
  done
  for np_tool in node npm npx; do
    printf '#!/bin/bash\necho v22.8.0\n' > "$np_selector_root/home/.nvm/versions/node/v22.8.0/bin/$np_tool"
    chmod +x "$np_selector_root/home/.nvm/versions/node/v22.8.0/bin/$np_tool"
  done
  np_selector_fn="$(sed -n '/^select_installed_node() {$/,/^}$/p' "$here/setup.sh")"
  np_out="$(
    set -uo pipefail
    log() { printf 'LOG %s\n' "$*"; }
    have() { command -v "$1" >/dev/null 2>&1; }
    node_version_in_release_line() { [[ "$1" =~ ^v22(\.|$) ]]; }
    NODE_RELEASE_LINE=22
    bin_dir="$np_selector_root/bin"
    PATH="$np_selector_root/path"
    NVM_DIR="$np_selector_root/home/.nvm"
    export PATH NVM_DIR
    eval "$np_selector_fn"
    select_installed_node
    printf 'node=%s\nnpm=%s\nnpx=%s\n' \
      "$(readlink -f "$bin_dir/node")" "$(readlink -f "$bin_dir/npm")" "$(readlink -f "$bin_dir/npx")"
  )"
  printf '%s\n' "$np_out" | grep -q "node=$np_selector_root/home/.nvm/" \
    && printf '%s\n' "$np_out" | grep -q "npm=$np_selector_root/home/.nvm/" \
    && printf '%s\n' "$np_out" | grep -q "npx=$np_selector_root/home/.nvm/" \
    && pass 'selector binds node, npm and npx to the explicit fixture NVM_DIR' \
    || fail "selector escaped its explicit fixture boundary: $np_out"
  node_pin_case none '' '20.20.2 22.9.0 24.1.0'
  { [ "$NP_RC" -eq 0 ] && grep -q 'selected installed Node v22.9.0' "$NP_LOG"; } \
    && pass 'no project .nvmrc keeps the canonical Node 22 default when 20, 22 and 24 are installed' \
    || fail "no-pin setup did not select v22.9.0 (rc $NP_RC): $(tail -3 "$NP_LOG")"
  for np_tool in node npm npx; do
    np_target="$(readlink -f "$NP_ROOT/repo/.local/agent-tools/bin/$np_tool" 2>/dev/null || true)"
    case "$np_target" in
      "$NP_ROOT/home/.nvm/"*) pass "$np_tool resolves inside the fixture NVM_DIR" ;;
      *) fail "$np_tool escaped the fixture: ${np_target:-<missing>}" ;;
    esac
  done
  [ -s "$NP_ROOT/npm.log" ] && ! grep -qv '^install ' "$NP_ROOT/npm.log" \
    && pass 'offline install attempts reached only the refusing fixture npm' \
    || fail 'fixture npm did not deterministically record/refuse setup install attempts'
  printf '  evidence fixture_home=%s nvm_dir=%s path=%s\n' "$NP_ROOT/home" "$NP_ROOT/home/.nvm" "$NP_ROOT/repo/.local/agent-tools/bin:$NP_ROOT/minimal"
  printf '  evidence before_node=%s before_interpreter=%s\n' "$NP_ROOT/minimal/node" "$(readlink -f "$NP_ROOT/minimal/bash")"
  printf '  evidence after_node=%s after_npm=%s after_npx=%s npm_attempts=%s\n' \
    "$(readlink -f "$NP_ROOT/repo/.local/agent-tools/bin/node")" \
    "$(readlink -f "$NP_ROOT/repo/.local/agent-tools/bin/npm")" \
    "$(readlink -f "$NP_ROOT/repo/.local/agent-tools/bin/npx")" \
    "$(wc -l < "$NP_ROOT/npm.log")"
  node_pin_case p24 '24\n' '20.20.2 22.9.0 24.1.0'
  { [ "$NP_RC" -eq 0 ] && grep -q 'selected installed Node v24.1.0' "$NP_LOG"; } \
    && pass 'project .nvmrc 24 selects the installed Node 24 for setup' \
    || fail "setup ignored .nvmrc 24 (rc $NP_RC): $(grep -i 'node' "$NP_LOG" | tail -3)"
  node_pin_case p24v 'v24.1\r\n' '22.9.0 24.10.0 24.1.2'
  { [ "$NP_RC" -eq 0 ] && grep -q 'selected installed Node v24.1.2' "$NP_LOG"; } \
    && pass 'project .nvmrc v24.1 matches 24.1.x only, never 24.10' \
    || fail "partial pin matched the wrong release (rc $NP_RC): $(grep -i 'node' "$NP_LOG" | tail -3)"
  node_pin_case absent24 '24\n' '20.20.2 22.9.0'
  { [ "$NP_RC" -ne 0 ] && grep -q 'Node 24 is required' "$NP_LOG" && ! grep -q 'selected installed Node v22' "$NP_LOG"; } \
    && pass 'project .nvmrc 24 with no Node 24 installed fails clearly, with no fallback to 22' \
    || fail "absent Node 24 did not fail clearly (rc $NP_RC): $(tail -3 "$NP_LOG")"
  np_i=0
  for np_bad in 'lts/*\n' '^24\n' '24; touch PWNED\n' '$(touch PWNED)\n' '21\n' '24\n22\n' '24                                                                \n22\n' '\n' '24.x\n' 'node\n' '024\n' '99999999999999999999999999999999\n'; do
    np_i=$((np_i + 1))
    node_pin_case "bad$np_i" "$np_bad" '20.20.2 22.9.0 24.1.0'
    { [ "$NP_RC" -ne 0 ] && grep -q 'unsupported .nvmrc' "$NP_LOG" && [ ! -e "$NP_ROOT/repo/PWNED" ] && ! grep -q 'selected installed Node' "$NP_LOG"; } \
      && pass "malformed or unsupported .nvmrc is refused: $(printf '%s' "$np_bad" | head -c 20)" \
      || fail "malformed .nvmrc was not refused (rc $NP_RC): $np_bad / $(tail -2 "$NP_LOG")"
  done
  node_pin_case nul '2\x004\n' '22.9.0 24.1.0'
  { [ "$NP_RC" -ne 0 ] && grep -q 'NUL bytes are not permitted' "$NP_LOG"; } \
    && pass 'an embedded NUL cannot collapse 2<NUL>4 into Node 24' \
    || fail "an embedded NUL was not refused (rc $NP_RC): $(tail -2 "$NP_LOG")"
  np_root="$work/nodepin-symlink"
  node_pin_fixture "$np_root" '' '22.9.0 24.1.0'
  printf '24\n' > "$np_root/real-pin"; ln -s "$np_root/real-pin" "$np_root/repo/.nvmrc"
  if [ -L "$np_root/repo/.nvmrc" ]; then
    run_minimal_runtime_setup "$np_root" "$work/nodepin-symlink.log" 'v20.20.2'
    { [ $? -ne 0 ] && grep -q 'unsupported .nvmrc' "$work/nodepin-symlink.log"; } \
      && pass 'a symlinked .nvmrc is refused' \
      || fail 'a symlinked .nvmrc was accepted'
  else
    fail 'symlinked .nvmrc case could not run: this Linux host cannot create symlinks'
  fi
  # verify.sh requires the same line setup selected.
  for np_case in 'p24ok|24\n|v24.1.0|PASS  node v24.1.0' 'p24full|24.1.0\n|v24.1.0|PASS  node v24.1.0' 'p24fullbad|24.1.0\n|v24.1.1|FAIL  node is v24.1.1' 'p24bad|24\n|v22.0.0|FAIL  node is v22.0.0' 'none|-|v22.0.0|PASS  node v22.0.0' 'none20|-|v20.20.2|FAIL  node is v20.20.2' 'mal|lts/*\n|v22.0.0|FAIL  .*unsupported .nvmrc'; do
    IFS='|' read -r np_n np_pin np_ver np_expect <<<"$np_case"
    np_root="$work/nodepin-verify-$np_n"
    build_fixture "$np_root"; build_verify_fixture "$np_root"
    printf '#!/usr/bin/env bash\necho "%s"\n' "$np_ver" > "$np_root/repo/.local/agent-tools/bin/node"
    [ "$np_pin" = '-' ] || printf '%b' "$np_pin" > "$np_root/repo/.nvmrc"
    run_verify "$np_root" "$work/nodepin-verify-$np_n.log"
    grep -qE "$np_expect" "$work/nodepin-verify-$np_n.log" \
      && pass "verify.sh node check for pin '${np_pin%\n}' and node $np_ver: $np_expect" \
      || fail "verify.sh node check wrong for pin '$np_pin' node $np_ver: $(grep -i node "$work/nodepin-verify-$np_n.log" | head -3)"
  done
}
if [ "${SETUP_TEST_SECTION:-}" = fail-closed ]; then
  test_fail_closed
  printf '\nsetup.test.sh (fail-closed): %d passed, %d failed\n' "$pass_count" "$fail_count"
  [ "$fail_count" -eq 0 ] || exit 1
  exit 0
fi

if [ "${SETUP_TEST_SECTION:-}" = node-pin ]; then
  test_node_pin
  printf '
setup.test.sh (node-pin): %d passed, %d failed
' "$pass_count" "$fail_count"
  [ "$fail_count" -eq 0 ] || exit 1
  exit 0
fi

# ============================================================ 1. the real script
root="$work/real"
build_fixture "$root"

run_setup "$root" "$work/run1.log"
rc1=$?
[ "$rc1" -eq 0 ] && pass 'first run exits 0' || fail "first run exited $rc1; see $work/run1.log"
if grep -qF 'Git LFS objects hydrated' "$work/run1.log"; then
  pass 'first run hydrates Git LFS objects after fetching refs'
else
  fail 'first run did not hydrate Git LFS objects after fetching refs'
fi

first_bashrc="$(cat "$root/home/.bashrc" 2>/dev/null || true)"
first_profile="$(cat "$root/home/.profile" 2>/dev/null || true)"

if [ -n "$first_bashrc" ]; then
  pass 'first run wrote a shell profile'
else
  fail 'first run wrote no ~/.bashrc, so there is nothing to test for idempotence'
fi

run_setup "$root" "$work/run2.log"
rc2=$?
[ "$rc2" -eq 0 ] && pass 'second run exits 0' || fail "second run exited $rc2; see $work/run2.log"

# THE claim. Byte-identical, not merely "still contains" -- an appended duplicate satisfies
# a contains-check and is exactly the defect.
if [ "$first_bashrc" = "$(cat "$root/home/.bashrc" 2>/dev/null || true)" ]; then
  pass '~/.bashrc is byte-identical after a second run'
else
  fail '~/.bashrc CHANGED on the second run; setup.sh is not idempotent'
fi
if [ "$first_profile" = "$(cat "$root/home/.profile" 2>/dev/null || true)" ]; then
  pass '~/.profile is byte-identical after a second run'
else
  fail '~/.profile CHANGED on the second run; setup.sh is not idempotent'
fi

# Each export appears once. Stated separately from the comparison above because a first run
# that already double-wrote would pass the comparison and fail here.
for key in 'PROJECT_DATA_ROOT=' 'CI=' 'agent-tools/bin'; do
  n="$(grep -cF "$key" "$root/home/.bashrc" 2>/dev/null || echo 0)"
  if [ "$n" = '1' ]; then
    pass "~/.bashrc carries exactly one '$key' line"
  else
    fail "~/.bashrc carries $n '$key' lines; expected exactly 1"
  fi
done

# The pinned installers must recognise what is already there rather than reinstalling it.
for tool in gh bws pwsh; do
  if grep -qE "^\[setup\] $tool .* already present" "$work/run2.log"; then
    pass "second run detects $tool as already present"
  else
    fail "second run did not report $tool already present; it would reinstall on every resume"
  fi
done

# No download was attempted on either run. The curl stub exits 22 and writes to stderr, so a
# silent regression into the download branch is visible here even though setup keeps it
# non-fatal.
if grep -q 'curl stub refused a download' "$work/run2.log"; then
  fail 'the second run tried to download something it should have detected as present'
else
  pass 'no download was attempted on the second run'
fi

# A partial credential profile is unsafe: later authenticated checks would fail partway through
# work. Setup must stop before it reports a ready environment, while all four absent remains the
# declared code-work profile handled by credential-profile.sh.
credential_root="$work/incomplete-credentials"
build_fixture "$credential_root"
run_setup_with_incomplete_credentials "$credential_root" "$work/incomplete-credentials.log"
credential_rc=$?
if [ "$credential_rc" -ne 0 ] && grep -q 'credential profile is incomplete' "$work/incomplete-credentials.log"; then
  pass 'setup refuses an incomplete credential profile before reporting readiness'
else
  fail 'setup did not refuse an incomplete credential profile with an actionable reason'
fi

# The hosted contract owns a portable relative value. Setup may resolve it while creating
# directories, but a later shell must receive the same value that verify.sh requires.
data_root="$work/data-root-contract"
build_fixture "$data_root"
build_verify_fixture "$data_root"
run_setup_without_project_data_root "$data_root" "$work/data-root-setup.log"
run_verify_from_setup_profile "$data_root" "$work/data-root-verify.log"
if [ -d "$data_root/repo/.local/project-data" ]; then
  pass 'setup creates the repository-local project-data directory'
else
  fail 'setup did not create the repository-local project-data directory'
fi
if grep -q 'PASS  PROJECT_DATA_ROOT=.local/project-data' "$work/data-root-verify.log"; then
  pass 'unset PROJECT_DATA_ROOT survives setup and passes verification canonically'
else
  fail 'unset PROJECT_DATA_ROOT becomes incompatible between setup and verification'
fi

# ================================================== 2. minimal apt image runtime
# Break caught: omitting a runtime package from setup leaves a fresh apt-capable image
# unable to run a Node or Python project even though setup reports success.
runtime_root="$work/minimal-runtime"
build_minimal_runtime_fixture "$runtime_root"

run_minimal_runtime_setup "$runtime_root" "$work/runtime-run1.log"
runtime_rc1=$?
[ "$runtime_rc1" -eq 0 ] && pass 'minimal apt runtime setup exits 0' || fail "minimal apt runtime setup exited $runtime_rc1"

for package in nodejs npm python3 python3-pip git-lfs; do
  if grep -qF "$package" "$runtime_root/apt.log" 2>/dev/null; then
    pass "minimal apt image requests $package"
  else
    fail "minimal apt image did not request $package"
  fi
done
for tool in node npm python3 pip; do
  if [ -x "$runtime_root/minimal/$tool" ]; then
    pass "fake apt made $tool available"
  else
    fail "fake apt did not make $tool available"
  fi
done
if grep -q 'curl stub refused a download' "$work/runtime-run1.log"; then
  fail 'minimal apt runtime setup attempted a network download'
else
  pass 'minimal apt runtime setup did not reach the network'
fi

apt_first="$(cat "$runtime_root/apt.log" 2>/dev/null || true)"
run_minimal_runtime_setup "$runtime_root" "$work/runtime-run2.log"
runtime_rc2=$?
[ "$runtime_rc2" -eq 0 ] && pass 'second minimal apt runtime setup exits 0' || fail "second minimal apt runtime setup exited $runtime_rc2"
if [ "$apt_first" = "$(cat "$runtime_root/apt.log" 2>/dev/null || true)" ]; then
  pass 'minimal apt runtime packages are not reinstalled on a second run'
else
  fail 'minimal apt runtime packages were requested again on a second run'
fi

# An apt package named nodejs is not proof that it supplies the declared release line.
wrong_node_root="$work/wrong-node"
build_minimal_runtime_fixture "$wrong_node_root"
run_minimal_runtime_setup "$wrong_node_root" "$work/wrong-node.log" 'v20.0.0'
wrong_node_rc=$?
if [ "$wrong_node_rc" -ne 0 ]; then
  pass 'setup refuses an incompatible Node release before reporting readiness'
else
  fail 'setup accepted an incompatible Node release; readiness would fail only later in verify.sh'
fi
if grep -q "Node ${NODE_RELEASE_LINE} is required" "$work/wrong-node.log"; then
  pass 'setup gives an actionable remediation for an incompatible apt Node release'
else
  fail 'setup accepted an incompatible apt Node release without remediation'
fi

# Downloads must match the host architecture and verify against the corresponding pin.
arm_root="$work/arm64"
build_architecture_fixture "$arm_root"
run_architecture_setup "$arm_root" "$work/arm64.log" 'aarch64'
for asset in "gh_${GH_VERSION}_linux_arm64.tar.gz" "bws-aarch64-unknown-linux-gnu-${BWS_VERSION}.zip" "powershell-${POWERSHELL_VERSION}-linux-arm64.tar.gz"; do
  if grep -qF "$asset" "$arm_root/curl.log" 2>/dev/null; then
    pass "arm64 setup selects $asset"
  else
    fail "arm64 setup did not select $asset"
  fi
done
for tool in gh bws 'PowerShell'; do
  if grep -q "${tool} .*digest verified" "$work/arm64.log"; then
    pass "arm64 setup verifies the $tool archive digest"
  else
    fail "arm64 setup did not verify the $tool archive digest"
  fi
done

x86_root="$work/amd64"
build_architecture_fixture "$x86_root"
run_architecture_setup "$x86_root" "$work/amd64.log" 'x86_64'
for asset in "gh_${GH_VERSION}_linux_amd64.tar.gz" "bws-x86_64-unknown-linux-gnu-${BWS_VERSION}.zip" "powershell-${POWERSHELL_VERSION}-linux-x64.tar.gz"; do
  if grep -qF "$asset" "$x86_root/curl.log" 2>/dev/null; then
    pass "amd64 setup selects $asset"
  else
    fail "amd64 setup did not select $asset"
  fi
done
for tool in gh bws 'PowerShell'; do
  if grep -q "${tool} .*digest verified" "$work/amd64.log"; then
    pass "amd64 setup verifies the $tool archive digest"
  else
    fail "amd64 setup did not verify the $tool archive digest"
  fi
done

# The architecture fixture must follow the canonical version owner, not today's release text.
override_root="$work/overridden-pins"
build_architecture_fixture "$override_root"
sed -i -e 's/^GH_VERSION=.*/GH_VERSION=9.9.9/' \
       -e 's/^BWS_VERSION=.*/BWS_VERSION=8.8.8/' \
       -e 's/^POWERSHELL_VERSION=.*/POWERSHELL_VERSION=7.7.7/' \
       "$override_root/repo/.agents/cloud/tool-versions.sh"
run_architecture_setup "$override_root" "$work/overridden-pins.log" 'aarch64'
set -a; . "$override_root/repo/.agents/cloud/tool-versions.sh"; set +a
for asset in "gh_${GH_VERSION}_linux_arm64.tar.gz" "bws-aarch64-unknown-linux-gnu-${BWS_VERSION}.zip" "powershell-${POWERSHELL_VERSION}-linux-arm64.tar.gz"; do
  if grep -qF "$asset" "$override_root/curl.log" 2>/dev/null; then
    pass "overridden pin fixture selects $asset"
  else
    fail "overridden pin fixture did not select $asset"
  fi
done
for tool in gh bws 'PowerShell'; do
  if grep -q "${tool} .*digest verified" "$work/overridden-pins.log"; then
    pass "overridden pin fixture verifies the $tool archive digest"
  else
    fail "overridden pin fixture did not verify the $tool archive digest"
  fi
done

unsupported_root="$work/unsupported-arch"
build_architecture_fixture "$unsupported_root"
run_architecture_setup "$unsupported_root" "$work/unsupported-arch.log" 'mips64'
if grep -q "unsupported Linux architecture 'mips64'" "$work/unsupported-arch.log"; then
  pass 'unsupported architecture receives an actionable warning'
else
  fail 'unsupported architecture received no actionable warning'
fi
if ! grep -q '/releases/download/' "$unsupported_root/curl.log" 2>/dev/null; then
  pass 'unsupported architecture makes no incompatible archive download'
else
  fail 'unsupported architecture attempted an incompatible archive download'
fi

# ============================================== 3. current contract marker
# Break caught: accepting the retired v3 marker allows an obsolete portable contract to
# pass cloud readiness, while a current v4 contract is rejected.
verify_root="$work/verify-marker"
build_fixture "$verify_root"
build_verify_fixture "$verify_root"
# verify.sh resolves Manage-Harness.ps1 from the repository or the installed harness and fails when
# neither has it; this fixture is a project that carries the tool, so the stub pwsh answers the check.
mkdir -p "$verify_root/repo/.agents/tools"
: > "$verify_root/repo/.agents/tools/Manage-Harness.ps1"

printf '<!-- agent-harness:portable:v4:start -->\n' > "$verify_root/repo/AGENTS.md"
run_verify "$verify_root" "$work/verify-v4.log"
# 2026-08-22 replaced the marker-presence-only pass with a digest check against
# .agents/templates/AGENTS.md (verify.sh:116-136), which this fixture deliberately does
# not carry -- it has no opinion on digest currency, only on whether the v4 marker is
# recognised at all. So the only outcomes that prove the marker was accepted are PASS
# (digest matched, if a template happened to be present) or SKIP naming the reason
# (verify.sh's own documented fallback when it cannot check currency); the one outcome
# that proves it was NOT accepted is the missing-block FAIL, checked for by name.
if grep -q 'FAIL  AGENTS.md is missing the portable v4 contract block' "$work/verify-v4.log"; then
  fail 'verify did not accept the current portable v4 contract marker'
elif grep -qE 'PASS  AGENTS\.md carries the portable contract block|SKIP  portable contract block present' "$work/verify-v4.log"; then
  pass 'verify accepts the current portable v4 contract marker'
else
  fail "verify neither accepted nor explicitly rejected the v4 marker: $(grep -F 'AGENTS.md' "$work/verify-v4.log")"
fi
for tool in npm pip; do
  if grep -q "PASS  $tool" "$work/verify-v4.log"; then
    pass "verify requires and accepts $tool"
  else
    fail "verify did not require and accept $tool"
  fi
done

printf '<!-- agent-harness:portable:v3:start -->\n' > "$verify_root/repo/AGENTS.md"
run_verify "$verify_root" "$work/verify-v3.log"
if grep -q 'FAIL  AGENTS.md is missing the portable v4 contract block' "$work/verify-v3.log"; then
  pass 'verify rejects an obsolete-only portable v3 contract marker'
else
  fail 'verify did not reject an obsolete-only portable v3 contract marker'
fi

printf 'prose that mentions agent-harness:portable:v4:start but is not the marker\n' > "$verify_root/repo/AGENTS.md"
run_verify "$verify_root" "$work/verify-v4-prose.log"
if grep -q 'FAIL  AGENTS.md is missing the portable v4 contract block' "$work/verify-v4-prose.log"; then
  pass 'verify rejects a prose near-miss of the v4 contract marker'
else
  fail 'verify accepted a prose near-miss of the v4 contract marker'
fi

# ---- product entry points route to the contract, or they are not entry points
# Break caught: a Cursor cloud agent's entry point was checked by nothing, and CLAUDE.md was
# checked only for existence -- which an empty file satisfies while giving a Claude agent no
# contract. Both directions asserted here: the routing copies the fixture ships must be accepted,
# and each broken shape must be named in the failure so a reader knows which product lost its
# contract rather than only that something is missing.
printf '<!-- agent-harness:portable:v4:start -->\n' > "$verify_root/repo/AGENTS.md"
run_verify "$verify_root" "$work/verify-adapters.log"
for expected in 'PASS  CLAUDE.md routes to AGENTS.md' 'PASS  Cursor rule routes to AGENTS.md'; do
  if grep -qF "$expected" "$work/verify-adapters.log"; then
    pass "verify accepts a routing projection: ${expected#PASS  }"
  else
    fail "verify did not accept a routing projection: ${expected#PASS  }"
  fi
done

: > "$verify_root/repo/CLAUDE.md"
run_verify "$verify_root" "$work/verify-claude-empty.log"
if grep -q 'FAIL  CLAUDE.md does not reference AGENTS.md' "$work/verify-claude-empty.log"; then
  pass 'verify rejects a CLAUDE.md that routes nowhere'
else
  fail 'verify accepted an empty CLAUDE.md as a Claude entry point'
fi
printf '@AGENTS.md\n' > "$verify_root/repo/CLAUDE.md"

rm -f "$verify_root/repo/.cursor/rules/00-project-contract.mdc"
run_verify "$verify_root" "$work/verify-cursor-missing.log"
if grep -q 'FAIL  .cursor/rules/00-project-contract.mdc is missing' "$work/verify-cursor-missing.log"; then
  pass 'verify rejects a repository with no Cursor entry point'
else
  fail 'verify accepted a repository with no Cursor entry point'
fi

printf 'a rule that names no contract\n' > "$verify_root/repo/.cursor/rules/00-project-contract.mdc"
run_verify "$verify_root" "$work/verify-cursor-empty.log"
if grep -q 'FAIL  .cursor/rules/00-project-contract.mdc does not reference AGENTS.md' "$work/verify-cursor-empty.log"; then
  pass 'verify rejects a Cursor rule that routes nowhere'
else
  fail 'verify accepted a Cursor rule that routes nowhere'
fi
printf 'Follow AGENTS.md at the repository root.\n' > "$verify_root/repo/.cursor/rules/00-project-contract.mdc"

cat > "$verify_root/repo/.local/agent-tools/bin/npm" <<'EOF'
#!/usr/bin/env bash
echo 'npm is not installed' >&2
exit 127
EOF
chmod +x "$verify_root/repo/.local/agent-tools/bin/npm"
printf '<!-- agent-harness:portable:v4:start -->\n' > "$verify_root/repo/AGENTS.md"
run_verify "$verify_root" "$work/verify-no-npm.log"
if grep -q 'FAIL  npm' "$work/verify-no-npm.log"; then
  pass 'verify fails when npm is unusable'
else
  fail 'verify did not fail when npm is unusable'
fi

cat > "$verify_root/repo/.local/agent-tools/bin/npm" <<'EOF'
#!/usr/bin/env bash
echo '10.0.0'
EOF
cat > "$verify_root/repo/.local/agent-tools/bin/python3" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = '-m' ] && [ "$2" = 'pip' ]; then echo 'No module named pip' >&2; exit 1; fi
echo 'Python 3.12.0'
EOF
chmod +x "$verify_root/repo/.local/agent-tools/bin/npm" "$verify_root/repo/.local/agent-tools/bin/python3"
run_verify "$verify_root" "$work/verify-no-pip.log"
if grep -q 'FAIL  pip' "$work/verify-no-pip.log"; then
  pass 'verify fails when pip is unusable'
else
  fail 'verify did not fail when pip is unusable'
fi

# ================================================= 4. mutation: the guard must matter
# A check first observed green has not been observed working. Strip the grep guard out of
# persist_path in a COPY and require the suite's own assertion to notice -- otherwise this
# file proves only that a shell script ran twice.
mroot="$work/mutant"
build_fixture "$mroot" 's|grep -qsF "\$bin_dir" "\$target" 2>/dev/null && return 0|:|'

if grep -qF 'grep -qsF "$bin_dir"' "$mroot/repo/.agents/cloud/setup.sh"; then
  fail 'mutation did not apply; the idempotence assertion is unproven'
else
  run_setup "$mroot" "$work/mrun1.log"
  mutant_first="$(cat "$mroot/home/.bashrc" 2>/dev/null || true)"
  run_setup "$mroot" "$work/mrun2.log"
  mutant_second="$(cat "$mroot/home/.bashrc" 2>/dev/null || true)"
  if [ "$mutant_first" = "$mutant_second" ]; then
    fail 'the unguarded mutant produced an identical ~/.bashrc, so the assertion above cannot fail'
  else
    pass 'mutation check: removing the persist_path guard IS caught'
  fi
fi

# ========================================= 5. the Work Scope runtime gate
# Break caught: setup.sh reporting "setup complete" and exiting 0 after the PowerShell
# install failed. Every pwsh failure was a `warn`, which writes to stderr and does not
# exit, so the provider was told the container was ready and the agent found out when
# Test-WorkState.ps1 returned `pwsh: command not found`. verify.sh has always FAILED on
# that same condition, so the two halves of one kit disagreed.
#
# The host running this suite usually HAS pwsh, so "no pwsh in this image" has to be
# constructed rather than assumed: every PATH directory supplying one is dropped.
path_without_pwsh() {
  local dir out='' oldifs="$IFS"
  IFS=':'
  for dir in $PATH; do
    [ -n "$dir" ] || continue
    if [ -x "$dir/pwsh" ] || [ -x "$dir/pwsh.exe" ]; then continue; fi
    out="${out:+$out:}$dir"
  done
  IFS="$oldifs"
  printf '%s' "$out"
}

# $1 root, $2 log, $3 opt-out value, $4 hook-candidate path (empty = none exists)
run_setup_no_pwsh() {
  local root="$1" log="$2" ack="${3:-}" candidate="${4:-$root/absent/pwsh}"
  ( cd "$root/repo" \
    && PATH="$root/stub-nopwsh:$(path_without_pwsh)" \
       HOME="$root/home" \
       CLOUD_TOOL_ROOT=".local/agent-tools" \
       POWERSHELL_RUNTIME_PREFIX="$root/pwsh-prefix" \
       POWERSHELL_RUNTIME_LAUNCHER="$root/pwsh-bin/pwsh" \
       POWERSHELL_HOOK_CANDIDATES="$candidate" \
       CLOUD_SETUP_ALLOW_DEGRADED_POWERSHELL="$ack" \
       bash "$root/repo/.agents/cloud/setup.sh" ) >"$log" 2>&1
}

# $1 root, $2 log, $3 hook-candidate path
run_setup_with_pwsh() {
  local root="$1" log="$2" candidate="$3"
  # The final login-shell proof runs after the Work Scope branch under test. Persist this fixture
  # pwsh so an unenrolled-untrusted or hook-trusted case reaches its own expected outcome first.
  cp "$root/stub/pwsh" "$root/repo/.local/agent-tools/bin/pwsh"
  ( cd "$root/repo" \
    && PATH="$root/stub:$PATH" \
       HOME="$root/home" \
       CLOUD_TOOL_ROOT=".local/agent-tools" \
       POWERSHELL_RUNTIME_PREFIX="$root/pwsh-prefix" \
       POWERSHELL_RUNTIME_LAUNCHER="$root/pwsh-bin/pwsh" \
       POWERSHELL_HOOK_CANDIDATES="$candidate" \
       bash "$root/repo/.agents/cloud/setup.sh" ) >"$log" 2>&1
}

build_gate_fixture() {
  local root="$1"
  build_fixture "$root" '' 0
  cp "$root/stub/gh" "$root/stub/bws" "$root/repo/.local/agent-tools/bin/"
  mkdir -p "$root/stub-nopwsh" "$root/absent"
  local tool
  for tool in gh bws curl npm node python3 rg sqlite3 jq unzip; do cp "$root/stub/$tool" "$root/stub-nopwsh/$tool"; done
  chmod +x "$root/stub-nopwsh/"*
  # A hook-trusted candidate is a REAL file, never a symlink -- that is the task-state
  # hook's own rule, and the reason a repo-local pwsh does not satisfy it.
  mkdir -p "$root/hook-candidates"
  printf '#!/usr/bin/env bash\necho "PowerShell %s"\n' "$POWERSHELL_VERSION" > "$root/hook-candidates/pwsh"
  chmod +x "$root/hook-candidates/pwsh"
}

marker_of() { cat "$1/repo/.local/agent-tools/setup-status.json" 2>/dev/null || true; }

# --- no pwsh at all: must fail closed -----------------------------------------------
gate_root="$work/gate-absent"
build_gate_fixture "$gate_root"
run_setup_no_pwsh "$gate_root" "$work/gate-absent.log"
gate_rc=$?
[ "$gate_rc" -ne 0 ] \
  && pass "setup exits non-zero ($gate_rc) when the Work Scope runtime is absent" \
  || fail 'setup exited 0 with no pwsh; a broken container still reports success'
grep -q 'SETUP FAILED' "$work/gate-absent.log" \
  && pass 'the absent-runtime failure is stated unmissably, not as a stderr warning' \
  || fail 'setup did not state the absent-runtime failure unmissably'
grep -q 'setup complete' "$work/gate-absent.log" \
  && fail 'setup still claimed "setup complete" while failing closed' \
  || pass 'setup does not claim completion when it fails closed'
printf '%s' "$(marker_of "$gate_root")" | grep -q '"powershell": *"absent"' \
  && pass 'the marker records powershell=absent for a later verifier' \
  || fail 'the marker did not record powershell=absent'

# --- the opt-out is an exact string, not any truthy value ---------------------------
for bogus in 1 true yes read-only; do
  loose_root="$work/gate-loose-$bogus"
  build_gate_fixture "$loose_root"
  run_setup_no_pwsh "$loose_root" "$work/gate-loose-$bogus.log" "$bogus"
  if [ $? -ne 0 ]; then
    pass "a loose opt-out value '$bogus' does not satisfy the degraded gate"
  else
    fail "a loose opt-out value '$bogus' bypassed the degraded gate"
  fi
done

# --- the acknowledged degraded mode: exit 0, but unmissable and recorded ------------
degraded_root="$work/gate-degraded"
build_gate_fixture "$degraded_root"
run_setup_no_pwsh "$degraded_root" "$work/gate-degraded.log" 'read-only-work-scope'
degraded_rc=$?
[ "$degraded_rc" -eq 0 ] \
  && pass 'an explicitly acknowledged degraded environment still completes' \
  || fail "acknowledged degraded setup exited $degraded_rc; it should complete"
grep -q 'SETUP COMPLETED DEGRADED' "$work/gate-degraded.log" \
  && pass 'the degraded outcome is stated unmissably in the final output' \
  || fail 'the degraded outcome was not stated unmissably'
grep -q 'READ-ONLY' "$work/gate-degraded.log" \
  && pass 'the degraded banner names Work Scope as read-only' \
  || fail 'the degraded banner does not name the read-only consequence'
printf '%s' "$(marker_of "$degraded_root")" | grep -q '"degraded_acknowledged": *true' \
  && pass 'the marker records the acknowledgement machine-readably' \
  || fail 'the marker did not record the acknowledgement'

# --- pwsh present but not hook-trusted ----------------------------------------------
# Enrolled, this is session-blocking: the task-state hook rejects a repository-supplied
# interpreter and exits 2 on every prompt. Unenrolled, it is merely a gap. verify.sh
# already draws that exact line; setup now draws it in the same place.
untrusted_root="$work/gate-untrusted"
build_gate_fixture "$untrusted_root"
mkdir -p "$untrusted_root/repo/.agents/work"
printf '{}\n' > "$untrusted_root/repo/.agents/work/state.json"
run_setup_with_pwsh "$untrusted_root" "$work/gate-untrusted.log" "$untrusted_root/absent/pwsh"
if [ $? -ne 0 ]; then
  pass 'setup fails closed when an enrolled project has no hook-trusted pwsh'
else
  fail 'setup exited 0 with an untrusted pwsh on an enrolled project; the hook blocks every prompt there'
fi
# A non-zero exit alone would also be satisfied by `set -e` aborting somewhere earlier,
# which is how a gate test starts passing without the gate. Require the gate's own words.
grep -q 'SETUP FAILED' "$work/gate-untrusted.log" \
  && pass 'the enrolled-untrusted refusal comes from the gate, not an incidental abort' \
  || fail 'the enrolled-untrusted run exited non-zero without the gate reporting it'
printf '%s' "$(marker_of "$untrusted_root")" | grep -q '"powershell": *"untrusted"' \
  && pass 'the marker distinguishes untrusted from absent' \
  || fail 'the marker did not record powershell=untrusted'
printf '%s' "$(marker_of "$untrusted_root")" | grep -q '"work_scope_writable": *false' \
  && pass 'the marker records Work Scope as not writable when the hook cannot resolve pwsh' \
  || fail 'the marker did not record Work Scope as unwritable'

unenrolled_root="$work/gate-unenrolled"
build_gate_fixture "$unenrolled_root"
run_setup_with_pwsh "$unenrolled_root" "$work/gate-unenrolled.log" "$unenrolled_root/absent/pwsh"
if [ $? -eq 0 ]; then
  pass 'an untrusted pwsh on an UNENROLLED project is not treated as fatal'
else
  fail 'setup failed an unenrolled project over an untrusted pwsh; the gate is too broad'
fi

# --- the healthy path still completes, and records that it is healthy ---------------
ready_root="$work/gate-ready"
build_gate_fixture "$ready_root"
run_setup_with_pwsh "$ready_root" "$work/gate-ready.log" "$ready_root/hook-candidates/pwsh"
ready_rc=$?
[ "$ready_rc" -eq 0 ] && pass 'a hook-trusted pwsh completes setup normally' \
  || fail "setup exited $ready_rc with a hook-trusted pwsh present"
printf '%s' "$(marker_of "$ready_root")" | grep -q '"powershell": *"ready"' \
  && pass 'the marker records powershell=ready when the hook can resolve one' \
  || fail 'the marker did not record powershell=ready'
printf '%s' "$(marker_of "$ready_root")" | grep -q '"work_scope_writable": *true' \
  && pass 'the marker records Work Scope as writable' \
  || fail 'the marker did not record Work Scope as writable'

# --- a hook-trusted SHAPE that does not start PowerShell -----------------------------
# The defect this pins, measured 2026-09-02 in a container built from this kit: setup placed
# /usr/local/bin/pwsh as a HARD LINK to /opt/microsoft/powershell/7/pwsh (inode 549734,
# shared by both paths). `pwsh` is a .NET apphost that loads pwsh.dll from its own directory,
# so that link searched for /usr/local/bin/pwsh.dll, found nothing, and exited 154 on every
# invocation -- while this gate, which asked only `[ -f ] && [ ! -L ]`, recorded
# powershell=ready. The task-state hook spawns bare `pwsh` from PATH, so an enrolled project
# in that container failed closed on every prompt with a marker claiming a healthy runtime.
#
# The candidate here is shaped exactly as the hook requires and cannot run, which is the
# whole point: existence and executability are not the question, starting is.
dead_root="$work/gate-dead-candidate"
build_gate_fixture "$dead_root"
mkdir -p "$dead_root/repo/.agents/work"
printf '{}\n' > "$dead_root/repo/.agents/work/state.json"
printf '#!/bin/sh\nprintf "The application to execute does not exist: %s\\n" "/usr/local/bin/pwsh.dll" >&2\nexit 154\n' \
  > "$dead_root/hook-candidates/pwsh"
chmod +x "$dead_root/hook-candidates/pwsh"
run_setup_with_pwsh "$dead_root" "$work/gate-dead-candidate.log" "$dead_root/hook-candidates/pwsh"
if [ $? -ne 0 ]; then
  pass 'setup fails closed when the only hook-trusted candidate cannot start PowerShell'
else
  fail 'setup exited 0 against a hook candidate that exits 154; the readiness gate is shape-only'
fi
printf '%s' "$(marker_of "$dead_root")" | grep -q '"powershell": *"ready"' \
  && fail 'the marker recorded powershell=ready for a candidate that does not run' \
  || pass 'the marker refuses to record ready for a candidate that does not run'
printf '%s' "$(marker_of "$dead_root")" | grep -q 'does not start PowerShell' \
  && pass 'the marker names the dead candidate as the cause, not just the symptom' \
  || fail 'the marker did not record why the runtime is unusable'

# --- an existing broken launcher is REPLACED, not left in place ----------------------
# The original code only wrote /usr/local/bin/pwsh when nothing was there (`[ ! -e ]`), so
# the broken hard link above survived every subsequent run of setup. Repair has to be
# idempotent in the other direction too: a launcher that already works is left alone.
launcher_root="$work/launcher-repair"
build_gate_fixture "$launcher_root"
launcher_bin="$launcher_root/usr-local-bin"
mkdir -p "$launcher_bin" "$launcher_root/real-prefix"
printf '#!/bin/sh\necho "PowerShell %s"\n' "$POWERSHELL_VERSION" > "$launcher_root/real-prefix/pwsh"
chmod +x "$launcher_root/real-prefix/pwsh"
: > "$launcher_root/real-prefix/pwsh.dll"
printf '#!/bin/sh\nexit 154\n' > "$launcher_bin/pwsh"
chmod +x "$launcher_bin/pwsh"
(
  # shellcheck disable=SC1090
  POWERSHELL_VERSION="$POWERSHELL_VERSION"
  # Source only the two functions under test, with the launcher target redirected into the
  # fixture. Running the whole script would need root to write /usr/local/bin.
  sed -n '/^pwsh_candidate_runs() {/,/^}/p;/^install_pwsh_launcher() {/,/^}/p' \
    "$launcher_root/repo/.agents/cloud/setup.sh" \
    | sed "s@/usr/local/bin@$launcher_bin@g" > "$launcher_root/functions.sh"
  warn() { :; }
  # shellcheck disable=SC1090
  . "$launcher_root/functions.sh"
  install_pwsh_launcher "$launcher_root/real-prefix"
) >/dev/null 2>&1
if [ -f "$launcher_bin/pwsh" ] && [ ! -L "$launcher_bin/pwsh" ] && "$launcher_bin/pwsh" --version 2>/dev/null | grep -qF "$POWERSHELL_VERSION"; then
  pass 'a launcher that cannot start PowerShell is replaced by one that can'
else
  fail 'the broken launcher survived install_pwsh_launcher'
fi
grep -q "exec \"$launcher_root/real-prefix/pwsh\"" "$launcher_bin/pwsh" \
  && pass 'the replacement execs the pinned interpreter from its own prefix, so the apphost finds pwsh.dll' \
  || fail 'the replacement is not an exec launcher; a copy or link would break the apphost again'

# --- an existing RUNNABLE SYMLINK is replaced too: the hook gate rejects symlinks ----
symlink_root="$work/launcher-symlink"
build_gate_fixture "$symlink_root"
symlink_bin="$symlink_root/usr-local-bin"
mkdir -p "$symlink_bin" "$symlink_root/real-prefix"
printf '#!/bin/sh\necho "PowerShell %s"\n' "$POWERSHELL_VERSION" > "$symlink_root/real-prefix/pwsh"
chmod +x "$symlink_root/real-prefix/pwsh"
: > "$symlink_root/real-prefix/pwsh.dll"
ln -s "$symlink_root/real-prefix/pwsh" "$symlink_bin/pwsh"
(
  POWERSHELL_VERSION="$POWERSHELL_VERSION"
  sed -n '/^pwsh_candidate_runs() {/,/^}/p;/^install_pwsh_launcher() {/,/^}/p' \
    "$symlink_root/repo/.agents/cloud/setup.sh" \
    | sed "s@/usr/local/bin@$symlink_bin@g" > "$symlink_root/functions.sh"
  warn() { :; }
  # shellcheck disable=SC1090
  . "$symlink_root/functions.sh"
  install_pwsh_launcher "$symlink_root/real-prefix"
) >/dev/null 2>&1
if [ -f "$symlink_bin/pwsh" ] && [ ! -L "$symlink_bin/pwsh" ] && "$symlink_bin/pwsh" --version 2>/dev/null | grep -qF "$POWERSHELL_VERSION"; then
  pass 'a runnable symlink at the launcher path is replaced by a regular exec launcher'
else
  fail 'a runnable symlink survived install_pwsh_launcher; the hook gate rejects symlinks'
fi

# --- mutation: the gate must matter -------------------------------------------------
# A gate first observed red has still not been observed WORKING until removing it makes
# the assertion above go green for the wrong reason.
gate_mutant="$work/gate-mutant"
build_gate_fixture "$gate_mutant"
sed -i 's|^  exit 1$|  :|' "$gate_mutant/repo/.agents/cloud/setup.sh"
sed -i 's@^  require_ready_command pwsh || exit 1$@  :@' "$gate_mutant/repo/.agents/cloud/setup.sh"
sed -i 's@^  agent_shell_tools="\$agent_shell_tools pwsh"$@  :@' "$gate_mutant/repo/.agents/cloud/setup.sh"
if grep -qE '^  exit 1$' "$gate_mutant/repo/.agents/cloud/setup.sh"; then
  fail 'mutation did not apply; the fail-closed assertion is unproven'
else
  run_setup_no_pwsh "$gate_mutant" "$work/gate-mutant.log"
  if [ $? -eq 0 ]; then
    pass 'mutation check: removing the fail-closed exit IS caught'
  else
    fail 'the mutant still exited non-zero, so the fail-closed assertion cannot fail'
  fi
fi

# ================================ 6. vault-pull refusal markers (no network)
# Break caught: verify.sh asserted only `rc == 2` for a writable-mode refusal. The K60
# opt-in gate also exits 2 and runs BEFORE the mode check, so the OB_SYNC_MODE case was
# refused by the gate and the mode check was never reached -- a green assertion with no
# teeth. verify.sh now requires each refusal's own marker AND the absence of the gate's;
# this proves the property it depends on, against the real tracked script.
#
# Nothing here reaches a network, a credential or a session: every case exits at the
# gate or at the mode check, both of which precede the first `mkdir`.
vp="$here/vault-pull.sh"
if [ ! -f "$vp" ]; then
  fail 'vault-pull.sh is missing; its refusal markers cannot be proved'
else
  # --mode is refused in the argument loop, which runs before the gate. No opt-in.
  mode_out="$(bash "$vp" --mode bidirectional 2>&1)"; mode_rc=$?
  [ "$mode_rc" -eq 2 ] && pass '--mode exits 2' || fail "--mode exited $mode_rc; expected 2"
  printf '%s' "$mode_out" | grep -qF -- '--mode is not accepted' \
    && pass '--mode is refused by the argument loop, before the K60 gate' \
    || fail "--mode did not produce its own refusal: $(printf '%s' "$mode_out" | head -n1)"
  printf '%s' "$mode_out" | grep -qF '(K60)' \
    && fail '--mode was refused by the K60 gate, so the argument-loop refusal is unproven' \
    || pass '--mode refusal carries no K60 marker'

  # OB_SYNC_MODE is read AFTER the gate. Un-opted-in it is shadowed; this is the exact
  # defect, asserted here so it cannot silently return.
  shadow_out="$(OB_SYNC_MODE=bidirectional bash "$vp" 2>&1)"
  printf '%s' "$shadow_out" | grep -qF '(K60)' \
    && pass 'an un-opted-in OB_SYNC_MODE run is refused by the gate, not the mode check' \
    || fail 'the K60 gate no longer shadows an un-opted-in OB_SYNC_MODE run; re-check verify.sh'

  # Step-scoped opt-in, exactly as verify.sh does it, reaches the mode check.
  opted_out="$(OBSIDIAN_VAULT_PULL=cloud-agent OB_SYNC_MODE=bidirectional bash "$vp" 2>&1)"
  opted_rc=$?
  [ "$opted_rc" -eq 2 ] && pass 'an opted-in OB_SYNC_MODE run exits 2' \
    || fail "an opted-in OB_SYNC_MODE run exited $opted_rc; expected 2"
  printf '%s' "$opted_out" | grep -qF 'this transport only runs pull-only' \
    && pass 'the opted-in run is refused by the mode check itself' \
    || fail "the opted-in run did not reach the mode check: $(printf '%s' "$opted_out" | head -n1)"
  printf '%s' "$opted_out" | grep -qF '(K60)' \
    && fail 'the opted-in run was still refused by the gate' \
    || pass 'the opted-in mode refusal carries no K60 marker'

  # verify.sh's own refusal block, end to end. Asserting the markers here and not there
  # would leave the block that actually runs in a container unexecuted by anything -- and
  # it caught a real defect on the first run: the `--mode` marker begins with two dashes,
  # which grep reads as its own options unless the pattern is guarded with `--`.
  vmode_root="$work/verify-vault-modes"
  build_fixture "$vmode_root"
  build_verify_fixture "$vmode_root"
  printf '<!-- agent-harness:portable:v4:start -->\n' > "$vmode_root/repo/AGENTS.md"
  cp "$vp" "$vmode_root/repo/.agents/cloud/vault-pull.sh"
  cp "$here/VAULT-CONTRACT.md" "$vmode_root/repo/.agents/cloud/VAULT-CONTRACT.md"
  run_verify "$vmode_root" "$work/verify-vault-modes.log"
  for label in '--mode' 'OB_SYNC_MODE'; do
    if grep -qF "PASS  vault-pull.sh refuses $label with its own mode refusal" "$work/verify-vault-modes.log"; then
      pass "verify.sh proves the $label refusal is the one that fired"
    else
      fail "verify.sh did not prove the $label refusal: $(grep -F -- "$label" "$work/verify-vault-modes.log" | head -n1)"
    fi
  done

  # Mutation: make the gate refuse unconditionally in a COPY. The must-NOT-contain half
  # of verify.sh's assertion has to notice, or it is decoration.
  vp_mutant="$work/vault-pull-mutant.sh"
  sed 's|^if \[ "\${!gate_var:-}" != "\$gate_want" \]; then$|if true; then|' "$vp" > "$vp_mutant"
  if grep -qF 'if true; then' "$vp_mutant"; then
    mutant_out="$(OBSIDIAN_VAULT_PULL=cloud-agent OB_SYNC_MODE=bidirectional bash "$vp_mutant" 2>&1)"
    printf '%s' "$mutant_out" | grep -qF '(K60)' \
      && pass 'mutation check: a gate that swallows the mode check IS caught by the K60 marker' \
      || fail 'the K60 marker did not catch a gate that swallowed the mode check'
  else
    fail 'vault-pull mutation did not apply; the K60 marker assertion is unproven'
  fi
fi

# ---- ws_parse_roundtrip: reading the guarded write's result without jq
# Break caught: the guarded-write check read its result with jq only. On a machine without jq --
# which the toolchain section already fails on separately -- it reported "Work Scope guarded write
# produced an unusable result" while quoting a document that read `"ok": true` with seven events.
# The write had succeeded. A check that names the wrong cause sends the reader to the healthy half.
# Measured in an LF clone with no jq on 2026-08-23. Extracted rather than re-run end to end,
# because exercising it live needs pwsh, a real project and a nine-minute round trip.
eval "$(sed -n '/^ws_parse_roundtrip()/,/^}/p' "$here/verify.sh")"
if ! command -v ws_parse_roundtrip >/dev/null 2>&1 && ! type ws_parse_roundtrip >/dev/null 2>&1; then
  fail 'ws_parse_roundtrip could not be extracted from verify.sh; its cases are unproven'
else
  ws_case() { # name, json, expected-ok, expected-events
    ws_ok=''; ws_events=''
    ws_parse_roundtrip "$2"
    if [ "$ws_ok" = "$3" ] && [ "${ws_events:-}" = "$4" ]; then
      pass "$1"
    else
      fail "$1 (got ok='$ws_ok' events='$ws_events', wanted ok='$3' events='$4')"
    fi
  }
  ws_healthy='{
  "ok": true,
  "root": "<a disposable project root>",
  "platform": "windows",
  "events": 7,
  "receipt": "<a receipt id>"
}'
  # With jq present and with it masked off the PATH, the verdict must be the same.
  ws_case 'the healthy round-trip result reads as ok with its event count' "$ws_healthy" 'true' '7'
  ( PATH="$(printf '%s' "$PATH" | tr ':' '\n' | grep -v '/jq' | paste -sd: -)"
    ws_nojq_ok=''; ws_nojq_events=''
    ws_ok=''; ws_events=''
    ws_parse_roundtrip "$ws_healthy"
    [ "$ws_ok" = 'true' ] && [ "$ws_events" = '7' ] ) \
    && pass 'the same result reads the same with jq unavailable' \
    || fail 'the healthy round-trip result became unreadable without jq'
  ws_case 'a refused round-trip reads as not ok' '{ "ok": false, "events": 3 }' 'false' '3'
  ws_case 'a truncated chain keeps its real event count rather than passing' '{ "ok": true, "events": 4 }' 'true' '4'
  # The case that separates "the write failed" from "nothing could read the write".
  ws_case 'output carrying no ok field reads as unparseable rather than as a refusal' 'not json at all' '' ''
fi

# ============================= 7. capability router (device-scoped CLI roster)
# Break caught: core.clis[].present in capability-router.json describes whichever device
# GENERATED the tracked file. A cloud container that inherited someone else's roster would tell a
# fresh session a delegation CLI is present when it is not on this machine at all -- and a fresh
# Codex session gets no SessionStart hook, so AGENTS.md points it straight at this file with
# nothing to re-probe it. setup.sh re-probes and overwrites the file when pwsh is present;
# verify.sh checks every claimed-present target actually resolves here as the fallback for when
# that could not run.

# 7a. setup.sh invokes the real generator through pwsh when both are present.
router_root="$work/router-regen"
build_fixture "$router_root"
mkdir -p "$router_root/repo/.agents/tools" "$router_root/repo/.agents/manifests"
printf '# stub generator body; the fixture pwsh below never executes PowerShell\n' \
  > "$router_root/repo/.agents/tools/Build-CapabilityRouter.ps1"
printf '{"generated":true}\n' > "$router_root/repo/.agents/manifests/capability-router.json"
router_pwsh_log="$router_root/pwsh-invocations.log"
cat > "$router_root/stub/pwsh" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$router_pwsh_log"
echo "PowerShell ${POWERSHELL_VERSION}"
EOF
chmod +x "$router_root/stub/pwsh"
cp "$router_root/stub/pwsh" "$router_root/repo/.local/agent-tools/bin/pwsh"

run_setup "$router_root" "$work/router-regen.log"
if grep -qF 'capability-router.json regenerated for this device' "$work/router-regen.log"; then
  pass 'setup.sh regenerates capability-router.json for this device when the generator and pwsh are present'
else
  fail 'setup.sh did not report regenerating capability-router.json'
fi
if grep -qF 'Build-CapabilityRouter.ps1' "$router_pwsh_log" 2>/dev/null; then
  pass 'setup.sh actually invoked Build-CapabilityRouter.ps1 through pwsh, not merely logged success'
else
  fail 'setup.sh reported regeneration but never invoked the generator'
fi

# 7b. no generator in the tree: setup.sh must still exit 0 and say the roster may be stale,
# rather than silently proceeding as if it had confirmed anything.
router_missing_root="$work/router-missing-generator"
build_fixture "$router_missing_root"
run_setup "$router_missing_root" "$work/router-missing.log"
if grep -qF 'capability-router.json was not regenerated here' "$work/router-missing.log"; then
  pass 'setup.sh warns rather than silently proceeding when the router generator is absent'
else
  fail 'setup.sh gave no signal that capability-router.json was left unregenerated'
fi

# 7c. verify.sh: no router anywhere this reader can see -> SKIP, not a false pass or a crash.
router_verify_root="$work/router-verify"
build_fixture "$router_verify_root"
build_verify_fixture "$router_verify_root"
router_empty_home="$work/router-empty-home"
mkdir -p "$router_empty_home"
( cd "$router_verify_root/repo" && HOME="$router_empty_home" bash .agents/cloud/verify.sh ) \
  >"$work/router-verify-none.log" 2>&1
if grep -qF 'SKIP  no capability-router.json in-tree or at ~/.agents' "$work/router-verify-none.log"; then
  pass 'verify.sh skips the delegation-target check when no router is reachable'
else
  fail 'verify.sh did not skip cleanly when no capability-router.json was reachable'
fi

# 7d. verify.sh: router present, probed on THIS device, one real delegation target -- pass both
# the device-freshness line and the per-target resolution line. `git` stands in for a delegation
# CLI name here only to reuse a binary this suite is already guaranteed to run under.
this_host="$(hostname 2>/dev/null || uname -n 2>/dev/null || echo unknown)"
mkdir -p "$router_verify_root/repo/.agents/manifests"
cat > "$router_verify_root/repo/.agents/manifests/capability-router.json" <<EOF
{
  "core": {
    "clis": [
      { "name": "git", "role": "worker", "invoke": "git ...", "present": true },
      { "name": "cursor-agent", "role": "worker", "invoke": "cursor-agent.cmd -p \"<brief>\"", "present": false }
    ]
  },
  "probe": { "device": "$this_host" }
}
EOF
( cd "$router_verify_root/repo" && HOME="$router_empty_home" bash .agents/cloud/verify.sh ) \
  >"$work/router-verify-fresh.log" 2>&1
if grep -qF "PASS  capability-router.json's CLI roster was probed on this device ($this_host)" "$work/router-verify-fresh.log"; then
  pass 'verify.sh confirms a roster probed on this device is fresh'
else
  fail 'verify.sh did not confirm a same-device roster as fresh'
fi
if grep -qF 'PASS  delegation target git resolves on this device' "$work/router-verify-fresh.log"; then
  pass 'verify.sh confirms a claimed-present delegation target that actually resolves'
else
  fail 'verify.sh did not confirm a resolvable claimed-present delegation target'
fi

# 7e. verify.sh: router probed on a DIFFERENT device, and a claimed-present target that does not
# resolve here -- this is the exact defect (a stale "present" flag) and must FAIL, by name.
cat > "$router_verify_root/repo/.agents/manifests/capability-router.json" <<'EOF'
{
  "core": {
    "clis": [
      { "name": "definitely-not-a-real-cli", "role": "worker", "invoke": "nope", "present": true }
    ]
  },
  "probe": { "device": "SOME-OTHER-HOST" }
}
EOF
( cd "$router_verify_root/repo" && HOME="$router_empty_home" bash .agents/cloud/verify.sh ) \
  >"$work/router-verify-stale.log" 2>&1
if grep -qF "WARN  capability-router.json's CLI roster was probed on device 'SOME-OTHER-HOST'" "$work/router-verify-stale.log"; then
  pass 'verify.sh warns when the roster was probed on a different device'
else
  fail 'verify.sh did not warn about a cross-device roster'
fi
if grep -qF 'FAIL  capability-router.json claims definitely-not-a-real-cli is present, but definitely-not-a-real-cli does not resolve' "$work/router-verify-stale.log"; then
  pass 'verify.sh fails a claimed-present delegation target that does not resolve on this device'
else
  fail 'verify.sh did not fail an unresolvable claimed-present delegation target'
fi

# 7f. the same stale-roster case, with jq masked off PATH, must fail for the same reason through
# the awk fallback -- mirroring the jq/no-jq pairing already proven for ws_parse_roundtrip above.
( PATH="$(printf '%s' "$PATH" | tr ':' '\n' | grep -v '/jq' | paste -sd: -)"
  cd "$router_verify_root/repo" && HOME="$router_empty_home" bash .agents/cloud/verify.sh ) \
  >"$work/router-verify-stale-nojq.log" 2>&1
if grep -qF 'FAIL  capability-router.json claims definitely-not-a-real-cli is present, but definitely-not-a-real-cli does not resolve' "$work/router-verify-stale-nojq.log"; then
  pass 'verify.sh reaches the same verdict on a stale roster with jq unavailable'
else
  fail 'the delegation-target check became unusable without jq'
fi

# 8. the hook-trusted pwsh alias must be RUNNABLE, not merely non-symlink -------------
#
# work-scope.js trustedPowerShell() scans /usr/bin/pwsh, /usr/local/bin/pwsh,
# /opt/microsoft/powershell/7/pwsh and takes the first entry that is an absolute,
# non-symlink regular file whose realpath is itself. It never executes the candidate. So a
# hard link or a copy of the apphost passes that scan and is then run for the life of the
# container -- and it cannot run: pwsh resolves pwsh.dll beside argv[0], so an apphost
# reached through /usr/local/bin dies looking for /usr/local/bin/pwsh.dll. Measured in a
# cloud container on 2026-09-02: trustedPowerShell() returned /usr/local/bin/pwsh and that
# path exited 154 on `pwsh -NoProfile -c 1`.
#
# The fixture apphost below reproduces exactly that rule -- it succeeds only when a
# pwsh.dll sits beside the file being executed -- so a hard link or copy fails this test
# and only a wrapper that execs from the prefix passes it.
alias_root="$work/pwsh-alias"
mkdir -p "$alias_root/prefix" "$alias_root/bin"
cat > "$alias_root/prefix/pwsh" <<'APPHOST'
#!/bin/sh
# Stands in for the .NET apphost: refuses unless its .dll sits beside argv[0].
self_dir="$(cd "$(dirname "$0")" && pwd)"
if [ ! -f "$self_dir/pwsh.dll" ]; then
  echo "The application to execute does not exist: '$self_dir/pwsh.dll'." >&2
  exit 154
fi
echo "PowerShell 7.4.6"
APPHOST
chmod +x "$alias_root/prefix/pwsh"
: > "$alias_root/prefix/pwsh.dll"

alias_fn="$(sed -n '/^pwsh_candidate_runs() {$/,/^}$/p;/^install_pwsh_launcher() {$/,/^}$/p' "$here/setup.sh" | sed "s@/usr/local/bin@$alias_root/bin@g")"
if [ -z "$alias_fn" ]; then
  fail 'install_pwsh_launcher could not be extracted from setup.sh (renamed or reshaped?)'
else
  (
    set -uo pipefail
    log() { :; }
    warn() { printf 'WARN %s\n' "$*"; }
    eval "$alias_fn"
    install_pwsh_launcher "$alias_root/prefix"
  ) > "$work/pwsh-alias.log" 2>&1
  alias_path="$alias_root/bin/pwsh"

  if [ -f "$alias_path" ] && [ ! -L "$alias_path" ]; then
    pass 'the pwsh alias is a real non-symlink file, so the hook candidate scan accepts it'
  else
    fail 'the pwsh alias is missing or is a symlink, which trustedPowerShell() skips'
  fi

  if [ -x "$alias_path" ] && "$alias_path" --version >/dev/null 2>&1; then
    pass 'the pwsh alias actually executes (a hard link or copy of the apphost would not)'
  else
    fail 'the pwsh alias does not execute; a container would run a dead interpreter'
  fi

  # A dead alias must never be left shadowing PATH: the scan reaches the canonical prefix
  # on its own, so no alias is strictly better than a broken one.
  rm -f "$alias_path"
  rm -f "$alias_root/prefix/pwsh.dll"
  (
    set -uo pipefail
    log() { :; }
    warn() { printf 'WARN %s\n' "$*"; }
    eval "$alias_fn"
    install_pwsh_launcher "$alias_root/prefix"
  ) > "$work/pwsh-alias-dead.log" 2>&1
  if [ ! -e "$alias_path" ]; then
    pass 'an alias that does not run is removed rather than left shadowing PATH'
  else
    fail 'a non-running pwsh alias was left in place'
  fi
fi

# verify.sh runs inside a project that does not carry the harness tools: harness_tool must
# resolve each tool from the repository, else from the installed harness under $HOME, else nothing.
ht_root="$work/harness-tool"
mkdir -p "$ht_root/repo/.agents/tools" "$ht_root/home/.agents/tools" "$ht_root/bare"
: > "$ht_root/repo/.agents/tools/Fake-Tool.ps1"
: > "$ht_root/home/.agents/tools/Fake-Tool.ps1"
ht_fn="$(sed -n '/^harness_tool() {$/,/^}$/p' "$here/verify.sh")"
if [ -z "$ht_fn" ]; then
  fail 'harness_tool could not be extracted from verify.sh (missing or reshaped?)'
else
  ht_got="$(cd "$ht_root/repo" && HOME="$ht_root/home" bash -c "$ht_fn"$'\n''harness_tool Fake-Tool.ps1')"
  [ "$ht_got" = '.agents/tools/Fake-Tool.ps1' ] \
    && pass 'harness_tool prefers the repository copy' \
    || fail "harness_tool with a repo copy printed '$ht_got'"
  ht_got="$(cd "$ht_root/bare" && HOME="$ht_root/home" bash -c "$ht_fn"$'\n''harness_tool Fake-Tool.ps1')"
  [ "$ht_got" = "$ht_root/home/.agents/tools/Fake-Tool.ps1" ] \
    && pass 'harness_tool falls back to the installed harness under HOME' \
    || fail "harness_tool with only a HOME copy printed '$ht_got'"
  ht_got="$(cd "$ht_root/bare" && HOME="$ht_root/bare" bash -c "$ht_fn"$'\n''harness_tool Fake-Tool.ps1')"
  [ -z "$ht_got" ] \
    && pass 'harness_tool prints nothing when neither copy exists' \
    || fail "harness_tool with no copy printed '$ht_got'"
fi
if grep -Eq 'pwsh .*-File \.agents/tools/(Test-CheckoutSafety|Test-DataManifest|Manage-Harness)\.ps1' "$here/verify.sh"; then
  fail 'verify.sh still invokes a harness tool by a repo-relative literal path'
else
  pass 'verify.sh invokes no harness tool by a repo-relative literal path'
fi

# The Codex Cloud image defaults node to v20 but carries other Node lines under nvm.
# select_installed_node must link an already-installed node of the pinned line, never install.
nv_root="$work/nvm-select"
mkdir -p "$nv_root/stub" "$nv_root/bin" "$nv_root/nvm-hit/versions/node/v22.9.0/bin" \
  "$nv_root/nvm-hit/versions/node/v22.3.1/bin" "$nv_root/nvm-hit/versions/node/v20.1.0/bin" \
  "$nv_root/nvm-miss/versions/node/v20.1.0/bin"
printf '#!/bin/sh\necho v20.20.2\n' > "$nv_root/stub/node"
chmod +x "$nv_root/stub/node"
for nv_v in 22.9.0 22.3.1 20.1.0; do
  nv_d="$nv_root/nvm-hit/versions/node/v$nv_v/bin"
  printf '#!/bin/sh\necho v%s\n' "$nv_v" > "$nv_d/node"
  printf '#!/bin/sh\necho npm-%s\n' "$nv_v" > "$nv_d/npm"
  printf '#!/bin/sh\necho npx-%s\n' "$nv_v" > "$nv_d/npx"
  chmod +x "$nv_d/node" "$nv_d/npm" "$nv_d/npx"
done
printf '#!/bin/sh\necho v20.1.0\n' > "$nv_root/nvm-miss/versions/node/v20.1.0/bin/node"
chmod +x "$nv_root/nvm-miss/versions/node/v20.1.0/bin/node"
nv_fn="$(sed -n '/^select_installed_node() {$/,/^}$/p' "$here/setup.sh")"
if [ -z "$nv_fn" ]; then
  fail 'select_installed_node could not be extracted from setup.sh (missing or reshaped?)'
else
  nv_run() {
    ( set -uo pipefail
      log() { printf 'LOG %s\n' "$*"; }
      warn() { printf 'WARN %s\n' "$*"; }
      have() { command -v "$1" >/dev/null 2>&1; }
      NODE_RELEASE_LINE=22
      bin_dir="$nv_root/bin"
      PATH="$nv_root/stub:$PATH"
      export NVM_DIR="$1"
      eval "$nv_fn"
      select_installed_node
      rc=$?
      printf 'RC %s\nNODE %s\n' "$rc" "$(node --version)"
    ) 2>&1
  }
  nv_out="$(nv_run "$nv_root/nvm-hit")"
  printf '%s\n' "$nv_out" | grep -qx 'RC 0' \
    && pass 'select_installed_node succeeds when nvm holds a Node of the release line' \
    || fail "select_installed_node did not succeed with a v22 present: $nv_out"
  [ "$("$nv_root/bin/node" --version 2>/dev/null)" = 'v22.9.0' ] \
    && pass 'select_installed_node links the highest installed Node of the release line' \
    || fail 'the linked node is not v22.9.0'
  [ -x "$nv_root/bin/npm" ] && [ -x "$nv_root/bin/npx" ] \
    && pass 'select_installed_node links npm and npx beside node' \
    || fail 'npm or npx was not linked'
  printf '%s\n' "$nv_out" | grep -qx 'NODE v22.9.0' \
    && pass 'node on PATH reports v22.9.0 after selection' \
    || fail "node on PATH after selection: $nv_out"
  printf '%s\n' "$nv_out" | grep -q 'selected installed Node v22.9.0 from' \
    && pass 'select_installed_node logs which Node it selected' \
    || fail 'the selection was not logged'
  rm -f "$nv_root/bin/node" "$nv_root/bin/npm" "$nv_root/bin/npx"
  nv_out="$(nv_run "$nv_root/nvm-miss")"
  printf '%s\n' "$nv_out" | grep -qx 'RC 1' \
    && pass 'select_installed_node fails when nvm has no Node of the release line' \
    || fail "select_installed_node did not fail without a v22: $nv_out"
  [ ! -e "$nv_root/bin/node" ] \
    && pass 'nothing is linked when no Node of the release line is installed' \
    || fail 'a node was linked although no v22 exists'
fi

test_fail_closed
test_node_pin

printf '\nsetup.test.sh: %d passed, %d failed\n' "$pass_count" "$fail_count"
[ "$fail_count" -eq 0 ] || exit 1

#!/usr/bin/env bash
# Idempotent Linux setup for a hosted agent environment (Codex cloud, Claude Code on the web).
#
# Contract (ONBOARDING/CLOUD-AGENTS.md):
#   Codex Setup field:  set -euo pipefail; bash .agents/cloud/setup.sh
#   Claude setup script: the always-exit-0 wrapper in ONBOARDING/CLOUD-AGENTS.md step 8
#
# This script never prints a credential value and never calls `bws login`.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

readiness_guide="$repo_root/.agents/cloud/FRESH-MACHINE-READINESS.md"
if [ ! -f "$readiness_guide" ]; then
  printf '[setup] SETUP FAILED: fresh-machine readiness guide is missing: %s\n' "$readiness_guide" >&2
  exit 1
fi

# shellcheck disable=SC1091
set -a; . "$repo_root/.agents/cloud/tool-versions.sh"; set +a

tool_root="$repo_root/${CLOUD_TOOL_ROOT:-.local/agent-tools}"
bin_dir="$tool_root/bin"
mkdir -p "$bin_dir" "$repo_root/.local/project-data"

log()  { printf '[setup] %s\n' "$*"; }
warn() { printf '[setup] WARNING: %s\n' "$*" >&2; }

have() { command -v "$1" >/dev/null 2>&1; }

# Release publishers provide separate Linux archives per CPU architecture. Keep the asset
# names and their publisher SHA-256 values together with their selection so an ARM64 host
# cannot receive an x86 executable by accident.
case "$(uname -m)" in
  x86_64|amd64)
    archive_supported=1
    gh_archive_arch=amd64; gh_archive_sha256="$GH_SHA256_AMD64"
    bws_archive_target=x86_64-unknown-linux-gnu; bws_archive_sha256="$BWS_SHA256_AMD64"
    pwsh_archive_arch=x64; pwsh_archive_sha256="$POWERSHELL_SHA256_AMD64"
    ;;
  aarch64|arm64)
    archive_supported=1
    gh_archive_arch=arm64; gh_archive_sha256="$GH_SHA256_ARM64"
    bws_archive_target=aarch64-unknown-linux-gnu; bws_archive_sha256="$BWS_SHA256_ARM64"
    pwsh_archive_arch=arm64; pwsh_archive_sha256="$POWERSHELL_SHA256_ARM64"
    ;;
  *)
    archive_supported=0
    warn "unsupported Linux architecture '$(uname -m)'; provider image must preinstall gh, bws, and pwsh at their declared versions because verified archives are unavailable"
    ;;
esac

# verify_digest <file> <expected-sha256> <label>
# Returns non-zero when a digest is declared and does not match, so the caller can skip
# installing those bytes. An empty expectation warns rather than blocks, which keeps a
# newly bumped pin installable before someone has recorded its digest.
verify_digest() {
  local file="$1" expected="$2" label="$3" actual
  if [ -z "$expected" ]; then
    warn "$label has no declared SHA-256 in tool-versions.sh; installing unverified bytes"
    return 0
  fi
  if ! have sha256sum; then
    warn "sha256sum is unavailable; cannot verify $label"
    return 0
  fi
  actual="$(sha256sum "$file" | cut -d' ' -f1)"
  if [ "$actual" = "$expected" ]; then
    log "$label digest verified"
    return 0
  fi
  warn "$label DIGEST MISMATCH -- refusing to install these bytes"
  warn "  expected $expected"
  warn "  actual   $actual"
  return 1
}

# Make reviewed downloads visible to this and later phases.
case ":${PATH}:" in
  *":$bin_dir:"*) ;;
  *) export PATH="$bin_dir:$PATH" ;;
esac
if [ -n "${GITHUB_PATH:-}" ]; then echo "$bin_dir" >> "$GITHUB_PATH"; fi

# `.bashrc` alone is not enough, and the failure it produces is invisible. Debian and
# Ubuntu ship a `.bashrc` opening with `case $- in *i*) ;; *) return;; esac`, so a
# non-interactive shell returns before reaching anything appended to it -- and hosted
# agents run their commands non-interactively. `verify.sh` prepends this directory to its
# own PATH, so verification passed while the agent session that followed could not find a
# single installed tool. Write every profile that a non-interactive shell might read, and
# `/etc/profile.d` too when this environment is root.
persist_path() {
  local target="$1"
  [ -w "$(dirname "$target")" ] || return 0
  grep -qsF "$bin_dir" "$target" 2>/dev/null && return 0
  printf 'export PATH="%s:$PATH"\n' "$bin_dir" >> "$target"
  log "PATH persisted to $target"
}
persist_path "${HOME:-/root}/.bashrc"
persist_path "${HOME:-/root}/.profile"
# A LOGIN bash reads only the FIRST of .bash_profile, .bash_login, .profile that exists, so
# writing .profile is silently wasted whenever an earlier one is present -- and the GitHub
# Actions runner image ships a .bash_profile. That is the whole of the failure this guard
# reported as "a clean non-interactive shell cannot resolve persisted bws": every tool
# installed correctly and the login probe below could not see any of them. Append only to
# files that already exist; creating .bash_profile here would itself shadow .profile for
# everything else that relies on it.
for shadowing_profile in "${HOME:-/root}/.bash_profile" "${HOME:-/root}/.bash_login"; do
  [ -f "$shadowing_profile" ] && persist_path "$shadowing_profile"
done
if [ "$(id -u)" = '0' ] && mkdir -p /etc/profile.d 2>/dev/null; then
  persist_path /etc/profile.d/agent-tools.sh
fi

# Two of verify.sh's required environment values are constants rather than credentials, so
# there is no reason to make them provider-configured fields a person has to retype.
export PROJECT_DATA_ROOT="${PROJECT_DATA_ROOT:-.local/project-data}"
export CI="${CI:-1}"
for kv in "PROJECT_DATA_ROOT=$PROJECT_DATA_ROOT" "CI=$CI"; do
  for target in "${HOME:-/root}/.bashrc" "${HOME:-/root}/.profile" "${HOME:-/root}/.bash_profile" "${HOME:-/root}/.bash_login"; do
    case "$target" in
      *.bash_profile|*.bash_login) [ -f "$target" ] || continue ;;
    esac
    [ -w "$(dirname "$target")" ] || continue
    grep -qsF "${kv%%=*}=" "$target" 2>/dev/null || printf 'export %s\n' "$kv" >> "$target"
  done
done

# Credentials are optional only as a coherent code-work profile. A partly supplied profile
# cannot complete its authenticated path, so fail before setup downloads tools and reports a
# ready environment. The helper observes presence only and never prints values.
# shellcheck disable=SC1091
. "$repo_root/.agents/cloud/credential-profile.sh"
if [ "$(credential_profile)" = 'full' ]; then
  missing_credential_vars=''
  for credential_var in $CREDENTIAL_PROFILE_VARS; do
    [ "$(credential_profile_verdict "$credential_var")" = 'pass' ] || \
      missing_credential_vars="$missing_credential_vars $credential_var"
  done
  if [ -n "$missing_credential_vars" ]; then
    printf '[setup] SETUP FAILED: credential profile is incomplete; set every declared variable or unset all of them for code-work. Missing:%s\n' "$missing_credential_vars" >&2
    exit 1
  fi
fi

# ---------------------------------------------------------------- provider image
# verify.sh FAILS hard on rg and sqlite3, and nothing installed them: a stock image without
# ripgrep failed verification with no remedy anywhere in the repository. Install what the
# package manager can supply before reporting what is present, and keep it non-fatal --
# an image that already has them, or one with no apt, still proceeds to the pinned tools.
missing_pkgs=''
for pair in 'rg:ripgrep' 'sqlite3:sqlite3' 'jq:jq' 'unzip:unzip' 'curl:curl' \
            'node:nodejs' 'npm:npm' 'python3:python3' 'pip:python3-pip' 'git-lfs:git-lfs'; do
  have "${pair%%:*}" || missing_pkgs="$missing_pkgs ${pair#*:}"
done
if [ -n "$missing_pkgs" ]; then
  if have apt-get; then
    log "installing image packages:$missing_pkgs"
    sudo_cmd=''
    [ "$(id -u)" = '0' ] || { have sudo && sudo_cmd='sudo -n'; }
    # shellcheck disable=SC2086
    if $sudo_cmd apt-get update -qq >/dev/null 2>&1 && \
       $sudo_cmd env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq $missing_pkgs >/dev/null 2>&1; then
      log "image packages installed"
    else
      warn "apt-get could not install:$missing_pkgs (verify.sh will report what is still absent)"
    fi
  else
    warn "no apt-get and these are missing:$missing_pkgs"
  fi
fi

log "image tools:"
for t in git curl jq tar unzip sha256sum rg sqlite3; do
  if have "$t"; then log "  $t $( { "$t" --version 2>/dev/null || true; } | head -n1)"; else warn "  $t missing"; fi
done
node_matches_release() { have node && node --version 2>/dev/null | grep -qE "^v${NODE_RELEASE_LINE}\\."; }
# The Codex Cloud image defaults node to another line but carries others under nvm. Select an
# already-installed node of exactly the release line; installs nothing.
select_installed_node() {
  local nvm_root="${NVM_DIR:-${HOME:-/root}/.nvm}" dir cand ver
  cand=''
  while IFS= read -r dir; do
    [ -x "$dir/node" ] || continue
    "$dir/node" --version 2>/dev/null | grep -qE "^v${NODE_RELEASE_LINE}\\." || continue
    cand="$dir"
  done < <(for d in "$nvm_root"/versions/node/v"${NODE_RELEASE_LINE}".*/bin; do [ -d "$d" ] && printf '%s\n' "$d"; done | sort -V)
  [ -n "$cand" ] || return 1
  ver="$("$cand/node" --version 2>/dev/null)"
  local t
  for t in node npm npx; do
    [ -e "$cand/$t" ] || continue
    ln -sf "$cand/$t" "$bin_dir/$t" 2>/dev/null || return 1
  done
  case ":$PATH:" in
    ":$bin_dir:"*) ;;
    *) export PATH="$bin_dir:$PATH" ;;
  esac
  hash -r 2>/dev/null || true
  log "selected installed Node $ver from $cand"
  return 0
}
if ! node_matches_release; then select_installed_node || true; fi
if node_matches_release; then
  log "  node $(node --version)"
elif have node; then
  warn "Node ${NODE_RELEASE_LINE} is required but apt supplied $(node --version 2>&1 | head -n1); use a provider image with Node ${NODE_RELEASE_LINE} or an approved pinned Node installer (verify.sh will fail)"
else
  warn "  node missing (expect Node ${NODE_RELEASE_LINE})"
fi
have python3 && log "  python3 $(python3 --version 2>&1)" || warn "  python3 missing"
# Hosted briefs conventionally invoke `python`. Keep that name available wherever the image
# supplies Python 3 under its distro-specific `python3` name.
if [ ! -x "$bin_dir/python" ] && have python3; then
  rm -f "$bin_dir/python" 2>/dev/null || true
  if ln -s "$(command -v python3)" "$bin_dir/python" 2>/dev/null; then
    log "  python -> $($bin_dir/python --version 2>&1)"
  else
    warn "  could not create python compatibility alias"
  fi
fi
if ! node_matches_release; then
  printf '[setup] SETUP FAILED: Node %s is required before readiness can continue.\n' "$NODE_RELEASE_LINE" >&2
  exit 1
fi

# ------------------------------------------------------------------- gh (pinned)
if have gh && gh --version 2>/dev/null | head -n1 | grep -qF "$GH_VERSION"; then
  log "gh $GH_VERSION already present"
else
  log "installing gh $GH_VERSION"
  if [ "$archive_supported" -ne 1 ]; then
    warn "gh $GH_VERSION was not installed; no verified archive exists for this architecture"
  else
    tmp="$(mktemp -d)"
    if curl -fsSL -o "$tmp/gh.tar.gz" \
      "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${gh_archive_arch}.tar.gz"; then
    # Under `set -e` an unguarded extract turns a truncated download -- which the curl
    # guard above handles gracefully -- into a total setup abort. Guard the whole
    # extract-and-install so the failure stays local to this tool.
    if verify_digest "$tmp/gh.tar.gz" "$gh_archive_sha256" "gh $GH_VERSION" \
       && tar -xzf "$tmp/gh.tar.gz" -C "$tmp" \
       && install -m 0755 "$tmp/gh_${GH_VERSION}_linux_${gh_archive_arch}/bin/gh" "$bin_dir/gh"; then
      log "gh -> $($bin_dir/gh --version | head -n1)"
    else
      warn "gh $GH_VERSION archive could not be extracted; leaving any image-provided gh in place"
    fi
    else
    warn "gh $GH_VERSION download failed; leaving any image-provided gh in place"
    fi
    rm -rf "$tmp"
  fi
fi

# ------------------------------------------------------------------ bws (pinned)
if have bws && bws --version 2>/dev/null | grep -qF "$BWS_VERSION"; then
  log "bws $BWS_VERSION already present"
else
  log "installing bws $BWS_VERSION"
  if [ "$archive_supported" -ne 1 ]; then
    warn "bws $BWS_VERSION was not installed; no verified archive exists for this architecture"
  else
    tmp="$(mktemp -d)"
    if curl -fsSL -o "$tmp/bws.zip" \
      "https://github.com/bitwarden/sdk-sm/releases/download/bws-v${BWS_VERSION}/bws-${bws_archive_target}-${BWS_VERSION}.zip"; then
    if verify_digest "$tmp/bws.zip" "$bws_archive_sha256" "bws $BWS_VERSION" \
       && unzip -qo "$tmp/bws.zip" -d "$tmp" && install -m 0755 "$tmp/bws" "$bin_dir/bws"; then
      log "bws -> $($bin_dir/bws --version 2>&1 | head -n1)"
    else
      warn "bws $BWS_VERSION archive could not be extracted; credential retrieval will fail verification"
    fi
    else
    warn "bws $BWS_VERSION download failed; credential retrieval will fail verification"
    fi
    rm -rf "$tmp"
  fi
fi

# ----------------------------------------------------------- pwsh (Work Scope)
# Work Scope's guard, evidence, and event-chain invariants live in one PowerShell
# module. Installing the same module here (rather than reimplementing it) is what
# makes a Linux write byte-identical to a Windows one in events.jsonl.
#
# WHERE it lands matters as much as whether it lands. The task-state hook resolves
# pwsh from a fixed allowlist and rejects symlinks, so it will not execute an
# interpreter supplied by the checked-out repository. When a project is Work Scope
# enrolled and the hook cannot validate state, it fails CLOSED and exits 2 on every
# prompt. So prefer /opt/microsoft/powershell/7 -- the canonical location the hook
# already trusts -- and treat the repo-local tool root as a degraded fallback that
# serves the CLI but not the hook.
: "${POWERSHELL_PREFIXES:=/opt/microsoft/powershell/7}"

# Why this environment ended up without a pinned pwsh, carried to the gate at the
# end of the file so the failure names its own cause instead of only its symptom.
powershell_note=''

# Does this path actually START PowerShell, at the version this kit pins?
#
# WHY EXISTENCE IS NOT ENOUGH, MEASURED
#
# `pwsh` is a .NET apphost: it locates `pwsh.dll` NEXT TO ITSELF and execs that. So a hard
# link or a copy placed at /usr/local/bin/pwsh looks perfect to every `[ -f ]` test and
# cannot run at all -- it searches for /usr/local/bin/pwsh.dll, which no install ever puts
# there. On 2026-09-02 in a container built from this kit that was the live state:
# /usr/local/bin/pwsh and /opt/microsoft/powershell/7/pwsh shared inode 549734, the
# readiness gate below reported powershell=ready against it, and running it produced
#   The application to execute does not exist: '/usr/local/bin/pwsh.dll'   (exit 154)
# Every .agents/tools/*.ps1 in that container was unreachable, and the task-state hook --
# which spawns bare `pwsh` from PATH -- failed closed on an enrolled project, which is the
# exact symptom filed as five-of-six-enrolled-projects-have-no-cloud-kit-20260823.
#
# So the question this asks is behavioural: run it, and require the pinned version in its
# own output. A launcher that starts nothing is an absent interpreter, whatever it looks like.
pwsh_candidate_runs() {
  local candidate="$1"
  [ -x "$candidate" ] || return 1
  "$candidate" --version 2>/dev/null | head -n1 | grep -qF "$POWERSHELL_VERSION"
}

# Place a hook-trustable entry point at /usr/local/bin/pwsh: a regular file (the hook's scan
# rejects symlinks) that EXECS the real interpreter from its own prefix, so the apphost
# resolves pwsh.dll beside the binary rather than beside the launcher. A stale or broken
# one is replaced -- refusing to touch an existing path is what left the inode above in
# place across every re-run of this script.
install_pwsh_launcher() {
  local prefix="$1"
  [ -n "$prefix" ] || return 1
  if [ -f /usr/local/bin/pwsh ] && [ ! -L /usr/local/bin/pwsh ] && pwsh_candidate_runs /usr/local/bin/pwsh; then
    return 0
  fi
  mkdir -p /usr/local/bin 2>/dev/null || return 1
  [ -w /usr/local/bin ] || return 1
  rm -f /usr/local/bin/pwsh 2>/dev/null || true
  {
    printf '#!/bin/sh\n'
    printf '# Generated by .agents/cloud/setup.sh. Execs the pinned PowerShell from its own\n'
    printf '# prefix so the .NET apphost finds pwsh.dll beside the binary, not beside this file.\n'
    printf 'exec "%s/pwsh" "$@"\n' "$prefix"
  } > /usr/local/bin/pwsh 2>/dev/null || return 1
  chmod 0755 /usr/local/bin/pwsh 2>/dev/null || return 1
  if pwsh_candidate_runs /usr/local/bin/pwsh; then
    return 0
  fi
  rm -f /usr/local/bin/pwsh 2>/dev/null || true
  return 1
}

install_powershell() {
  local archive="$1" prefix
  for prefix in $POWERSHELL_PREFIXES; do
    if mkdir -p "$prefix" 2>/dev/null && [ -w "$prefix" ]; then
      if tar -xzf "$archive" -C "$prefix" 2>/dev/null; then
        chmod +x "$prefix/pwsh"
        ln -sf "$prefix/pwsh" "$bin_dir/pwsh"
        log "pwsh installed to $prefix (trusted by the task-state hook)"
        if install_pwsh_launcher "$prefix"; then
          log "hook-trustable pwsh launcher at /usr/local/bin/pwsh -> $prefix/pwsh"
        else
          warn "could not place a working non-symlink pwsh at /usr/local/bin/pwsh"
        fi
        return 0
      fi
    fi
  done
  mkdir -p "$tool_root/powershell"
  tar -xzf "$archive" -C "$tool_root/powershell"
  chmod +x "$tool_root/powershell/pwsh"
  ln -sf "$tool_root/powershell/pwsh" "$bin_dir/pwsh"
  warn "pwsh installed to the repo-local tool root; Work Scope tools work from the"
  warn "  shell, but the task-state hook will not trust a repository-supplied"
  warn "  interpreter and fails closed on an enrolled project. Grant write access to"
  warn "  one of: $POWERSHELL_PREFIXES"
  powershell_note="installed to the repo-local tool root because none of these were writable: $POWERSHELL_PREFIXES"
  return 0
}

if have pwsh && pwsh --version 2>/dev/null | grep -qF "$POWERSHELL_VERSION"; then
  log "pwsh $POWERSHELL_VERSION already present"
  # A resumed container takes this branch, so the launcher repair has to happen here too --
  # otherwise a /usr/local/bin/pwsh that cannot start survives every re-run of setup, which
  # is how the broken inode above outlived the install that created it. `have pwsh` says
  # something on PATH works; it says nothing about the path the task-state hook resolves.
  present_pwsh_prefix="$(dirname "$(readlink -f "$(command -v pwsh)" 2>/dev/null)" 2>/dev/null)"
  if [ -n "$present_pwsh_prefix" ] && [ -f "$present_pwsh_prefix/pwsh.dll" ]; then
    if install_pwsh_launcher "$present_pwsh_prefix"; then
      log "hook-trustable pwsh launcher at /usr/local/bin/pwsh -> $present_pwsh_prefix/pwsh"
    else
      warn "could not place a working non-symlink pwsh at /usr/local/bin/pwsh"
    fi
  fi
else
  log "installing PowerShell $POWERSHELL_VERSION"
  if [ "$archive_supported" -ne 1 ]; then
    warn "PowerShell $POWERSHELL_VERSION was not installed; no verified archive exists for this architecture"
    powershell_note="no verified archive exists for architecture $(uname -m)"
  else
    tmp="$(mktemp -d)"
    if curl -fsSL -o "$tmp/pwsh.tar.gz" \
      "https://github.com/PowerShell/PowerShell/releases/download/v${POWERSHELL_VERSION}/powershell-${POWERSHELL_VERSION}-linux-${pwsh_archive_arch}.tar.gz"; then
    if verify_digest "$tmp/pwsh.tar.gz" "$pwsh_archive_sha256" "PowerShell $POWERSHELL_VERSION"; then
      install_powershell "$tmp/pwsh.tar.gz"
      log "pwsh -> $("$bin_dir/pwsh" --version 2>&1 | head -n1)"
    else
      warn "PowerShell was not installed; Work Scope state will be read-only in this environment"
      powershell_note="the pinned archive's SHA-256 did not match tool-versions.sh; the bytes were refused"
    fi
    else
    warn "PowerShell $POWERSHELL_VERSION download failed; Work Scope state will be read-only in this environment"
    powershell_note="the pinned archive could not be downloaded"
    fi
    rm -rf "$tmp"
  fi
fi

# ---------------------------------------------- capability router (device-scoped CLI roster)
# core.clis[].present in .agents/manifests/capability-router.json describes whichever device
# GENERATED the tracked file -- almost always Douglas's own workstation, where codex, agy and
# cursor-agent are personal installs this container does not carry. A fresh session here reads
# that frozen roster: AGENTS.md points a hookless Codex straight at the file, and the SessionStart
# hook pushes core.rendered verbatim for Claude. Left alone, that is a stale claim a session would
# dispatch on. Re-probing here, once, while a real pwsh is on this device, is what turns "read the
# note in the file and regenerate it yourself" into something a session never has to do.
# verify.sh's delegation-target check is the fallback for a container where this could not run.
router_generator="$repo_root/.agents/tools/Build-CapabilityRouter.ps1"
if [ -f "$router_generator" ] && have pwsh; then
  if pwsh -NoProfile -File "$router_generator" >/dev/null 2>&1; then
    log "capability-router.json regenerated for this device (delegation CLI roster is live, not inherited)"
  else
    warn "capability-router.json regeneration failed; its delegation CLI roster may still describe another device (verify.sh checks this)"
  fi
else
  warn "capability-router.json was not regenerated here (missing generator or pwsh); its delegation CLI roster may describe another device (verify.sh checks this)"
fi

# ------------------------------------------------------- node-delivered CLIs
if have npm && node_matches_release; then
  if ! have vercel || ! vercel --version 2>/dev/null | grep -qF "$VERCEL_CLI_VERSION"; then
    log "installing vercel@$VERCEL_CLI_VERSION"
    npm install -g --no-fund --no-audit "vercel@${VERCEL_CLI_VERSION}" >/dev/null 2>&1 \
      || warn "vercel CLI install failed"
  fi
  if ! have playwright; then
    log "installing playwright@$PLAYWRIGHT_VERSION and Chromium"
    npm install -g --no-fund --no-audit "playwright@${PLAYWRIGHT_VERSION}" >/dev/null 2>&1 \
      || warn "playwright install failed"
    if have playwright; then
      playwright install --with-deps chromium >/dev/null 2>&1 \
        || playwright install chromium >/dev/null 2>&1 \
        || warn "Chromium download failed"
    fi
  fi
  # Official Obsidian Headless client, installed into the repo-local tool root so
  # `vault-pull.sh` resolves it by path and never through a bare `ob` on PATH (the
  # third-party Belphemur package installs an executable of the same name).
  # Requires Node 22+, which NODE_RELEASE_LINE already pins.
  if [ ! -x "$tool_root/node_modules/.bin/ob" ]; then
    log "installing obsidian-headless@$OBSIDIAN_HEADLESS_VERSION (read-only vault transport)"
    (cd "$tool_root" && npm install --no-fund --no-audit --no-save --prefix "$tool_root" \
       "obsidian-headless@${OBSIDIAN_HEADLESS_VERSION}" >/dev/null 2>&1) \
      || warn "obsidian-headless install failed; vault-pull.sh will fall back to npx"
  fi
else
  warn "npm is missing or Node ${NODE_RELEASE_LINE} is unavailable; vercel, playwright and obsidian-headless were not installed"
fi

# ------------------------------------------------------ repository dependencies
if [ -f "$repo_root/package-lock.json" ]; then
  log "npm ci"; npm ci --no-fund --no-audit
elif [ -f "$repo_root/pnpm-lock.yaml" ]; then
  corepack enable >/dev/null 2>&1 || true
  log "pnpm install --frozen-lockfile"; pnpm install --frozen-lockfile
elif [ -f "$repo_root/package.json" ]; then
  log "npm install"; npm install --no-fund --no-audit
fi
if [ -f "$repo_root/requirements.txt" ]; then
  log "pip install -r requirements.txt"
  python3 -m pip install --quiet -r "$repo_root/requirements.txt" || warn "pip install failed"
fi

# --------------------------------------------------------- project extension hook
if [ -f "$repo_root/.agents/cloud/setup.project.sh" ]; then
  log "running project setup extension"
  bash "$repo_root/.agents/cloud/setup.project.sh"
fi

# ------------------------------------------------- shared contract and product loaders
# The portable block in AGENTS.md carries no rule the shared contract carries, so a container
# needs the shared contract installed where each product loads it. FAIL CLOSED: the state is
# recorded below and setup then exits nonzero when it is absent; the installer has already written
# a Claude and Codex hook guard that refuses tool use while ~/.agents/AGENTS.md is missing.
shared_contract_state='absent'
shared_contract_exit=0
shared_contract_output="$(bash "$repo_root/.agents/cloud/install-shared-contract.sh" "$repo_root")" || shared_contract_exit=$?
shared_contract_line="$(printf '%s\n' "$shared_contract_output" | tail -n1)"
printf '%s\n' "$shared_contract_output" | sed '$d'
if [ "$shared_contract_exit" -eq 0 ]; then
  case "$shared_contract_line" in
    shared_contract=installed*) shared_contract_state='installed' ;;
  esac
fi

# ------------------------------------------------- product hooks (Linux)
# Manage-Harness.ps1 Install-HookPackage copies task-hooks/hooks/* to ~/.agents/hooks, and the
# dispatchers resolve security-checks-fast.js and the other legacy modules from
# ~/.agents/hooks/legacy (hooks/lib/runtime.js legacyRoots). A container has no Windows
# installer, so without this copy every hook test that runs the dispatcher without
# HARNESS_LEGACY_HOOKS fails with "was not found in any installed hooks directory".
# Copies only into an absent or empty target. An existing install is compared, never overwritten:
# identical -> logged as current; different (possibly newer) -> left as is and logged as skipped.
# No network; Linux only.
if [ "$(uname -s)" = 'Linux' ] && [ -d "$repo_root/.agents/task-hooks/hooks" ]; then
  hooks_target="${HOME:-/root}/.agents/hooks"
  if [ -d "$hooks_target" ] && [ -n "$(ls -A "$hooks_target" 2>/dev/null)" ]; then
    if diff -rq "$repo_root/.agents/task-hooks/hooks" "$hooks_target" >/dev/null 2>&1; then
      log "product hooks at $hooks_target already match the tracked tree; not copied"
    else
      log "product hooks at $hooks_target differ from the tracked tree; existing install kept, not overwritten"
    fi
  elif mkdir -p "$hooks_target" 2>/dev/null && cp -R "$repo_root/.agents/task-hooks/hooks/." "$hooks_target/" 2>/dev/null; then
    log "product hooks installed to empty $hooks_target"
  else
    warn "could not install product hooks to $hooks_target; hook tests will report missing hooks"
  fi
fi

# ------------------------------------------------- Work Scope runtime gate
# The runtime everything else depends on, checked by OUTCOME rather than by which
# install branch ran: an image that preinstalled a different supported 7.x is fine,
# and a pinned install that failed is not, whichever way it failed.
#
# Until 2026-08-22 every pwsh failure above was a `warn`, which writes to stderr and
# does not exit, so a container whose PowerShell install failed still printed "setup
# complete" and reported success to the provider. The agent discovered it later, when
# `Test-WorkState.ps1` returned `pwsh: command not found`. The genuine fail-closed path
# (`.agents/task-hooks/hooks/lib/work-scope.js` -> `task-state-dispatch.js`, exit 2)
# cannot fire in a container because no hook is wired there.
#
# verify.sh has always FAILED on exactly this condition, so the two halves of one kit
# disagreed about whether the environment was usable. The two conditions below are
# verify.sh's two hard failures restated, so setup refuses at configuration time --
# where a person is watching -- instead of leaving them for a verifier nobody reruns.
#
# The candidate list is the task-state hook's own allowlist, not $POWERSHELL_PREFIXES:
# the hook rejects symlinks and repository-supplied interpreters, so "on PATH" and
# "usable by the hook" are two different questions and both are asked.
: "${POWERSHELL_HOOK_CANDIDATES:=/usr/bin/pwsh /usr/local/bin/pwsh /opt/microsoft/powershell/7/pwsh}"

powershell_state='absent'; powershell_path=''; powershell_version=''
if have pwsh; then
  powershell_state='untrusted'
  powershell_path="$(command -v pwsh)"
  powershell_version="$(pwsh --version 2>&1 | head -n1)"
  # Both questions, in this order: is the candidate shaped the way the hook requires (a
  # regular file, not a symlink), and DOES IT START. Asking only the first is what reported
  # powershell=ready against a /usr/local/bin/pwsh that exited 154 on every invocation --
  # see pwsh_candidate_runs above for the measurement. A file that cannot run is not a
  # runtime, so the state stays 'untrusted' and the gate below refuses.
  for candidate in $POWERSHELL_HOOK_CANDIDATES; do
    if [ -f "$candidate" ] && [ ! -L "$candidate" ] && pwsh_candidate_runs "$candidate"; then
      powershell_state='ready'; powershell_path="$candidate"; break
    fi
  done
  if [ "$powershell_state" = 'untrusted' ] && [ -z "$powershell_note" ]; then
    for candidate in $POWERSHELL_HOOK_CANDIDATES; do
      if [ -f "$candidate" ] && [ ! -L "$candidate" ] && ! pwsh_candidate_runs "$candidate"; then
        powershell_note="$candidate is a regular file the hook would accept but it does not start PowerShell $POWERSHELL_VERSION"
        break
      fi
    done
  fi
fi

work_scope_enrolled=false
[ -f "$repo_root/.agents/work/state.json" ] && work_scope_enrolled=true
work_scope_writable=false
[ "$powershell_state" = 'ready' ] && work_scope_writable=true

# An exact string rather than any truthy value, matching the deliberate-action gate
# vault-pull.sh already uses: a stray `=1` in a profile must not satisfy it, and the
# variable has to read as a decision wherever it is set.
degraded_ack=false
[ "${CLOUD_SETUP_ALLOW_DEGRADED_POWERSHELL:-}" = 'read-only-work-scope' ] && degraded_ack=true

setup_blocker=''
case "$powershell_state" in
  absent)
    setup_blocker="PowerShell $POWERSHELL_VERSION is not installed. Work Scope state cannot be written, and .agents/tools/*.ps1 cannot run at all." ;;
  untrusted)
    if [ "$work_scope_enrolled" = true ]; then
      setup_blocker="pwsh resolves to $powershell_path, which the task-state hook will not trust (it rejects symlinks and repository-supplied interpreters). This project is Work Scope enrolled, so that hook fails closed and exits 2 on every prompt."
    fi ;;
esac

# The machine-readable half. verify.sh reads this to report the CAUSE of a missing
# runtime, which it otherwise cannot know, and to see whether a human acknowledged a
# degraded environment or simply never noticed one. Value-free by construction.
# Bash-builtin only, deliberately: a minimal apt image may not have `tr`, and the last
# line of setup must not be the one that needs a tool nobody installed.
json_value() { local v="${1//\\/}"; v="${v//\"/}"; printf '%s' "${v//$'\n'/ }"; }
status_file="$tool_root/setup-status.json"
cat > "$status_file" <<EOF
{
  "schema": "agent-harness/cloud-setup-status/v1",
  "powershell": "$powershell_state",
  "powershell_path": "$(json_value "$powershell_path")",
  "powershell_version": "$(json_value "$powershell_version")",
  "powershell_note": "$(json_value "$powershell_note")",
  "work_scope_enrolled": $work_scope_enrolled,
  "work_scope_writable": $work_scope_writable,
  "shared_contract": "$shared_contract_state",
  "degraded_acknowledged": $degraded_ack
}
EOF
log "recorded runtime status in $status_file (powershell=$powershell_state shared_contract=$shared_contract_state)"

if [ "$shared_contract_state" != installed ]; then
  {
    printf '\n'
    printf '========================================================================\n'
    printf '  SETUP FAILED -- the shared contract (~/.agents/AGENTS.md) is not installed\n'
    printf '========================================================================\n'
    printf '  %s\n' "$shared_contract_line"
    printf '  No session here would load the rule set; Claude and Codex refuse tool use until\n'
    printf '  it exists. Give the container network access to the pinned harness commit in\n'
    printf '  .agents/cloud/harness-pin.sh, then re-run setup.\n'
    printf '========================================================================\n'
  } >&2
  exit 1
fi

if [ -n "$setup_blocker" ] && [ "$degraded_ack" != true ]; then
  printf '[setup] SETUP FAILED: the Work Scope runtime is unusable in this environment.\n'
  {
    printf '\n'
    printf '========================================================================\n'
    printf '  SETUP FAILED -- the Work Scope runtime is unusable\n'
    printf '========================================================================\n'
    printf '  %s\n' "$setup_blocker"
    [ -n "$powershell_note" ] && printf '  Cause: %s\n' "$powershell_note"
    printf '\n'
    printf '  This exits non-zero on purpose. Reporting success here is what let a\n'
    printf '  broken container reach an agent that could read Work Scope state and\n'
    printf '  not write it. verify.sh fails on this same condition.\n'
    printf '\n'
    printf '  Fix it by giving the image a pwsh %s at one of:\n' "$POWERSHELL_VERSION"
    printf '    %s\n' "$POWERSHELL_HOOK_CANDIDATES"
    printf '  or by re-running setup with network access to the pinned archive.\n'
    printf '\n'
    printf '  To proceed anyway with a READ-ONLY, unwritable Work Scope, set:\n'
    printf '    CLOUD_SETUP_ALLOW_DEGRADED_POWERSHELL=read-only-work-scope\n'
    printf '  That is an explicit, recorded decision, not a workaround.\n'
    printf '========================================================================\n'
  } >&2
  exit 1
fi

if [ -n "$setup_blocker" ]; then
  printf '\n'
  printf '========================================================================\n'
  printf '  SETUP COMPLETED DEGRADED -- Work Scope is READ-ONLY here\n'
  printf '========================================================================\n'
  printf '  %s\n' "$setup_blocker"
  [ -n "$powershell_note" ] && printf '  Cause: %s\n' "$powershell_note"
  printf '  Acknowledged by CLOUD_SETUP_ALLOW_DEGRADED_POWERSHELL=read-only-work-scope\n'
  printf '  and recorded in %s.\n' "$status_file"
  printf '\n'
  printf '  Do not change .agents/work/state.json by hand in this environment.\n'
  printf '  Report findings instead; a guarded write is not available.\n'
  printf '========================================================================\n'
fi

# A setup run is only useful when its required command surface actually resolves. The Work Scope
# outcome above stays first so an absent or untrusted pwsh reports its own fail-closed reason.
require_ready_command() {
  local tool="$1"
  if command -v "$tool" >/dev/null 2>&1; then return 0; fi
  printf '[setup] SETUP FAILED: required command %s is unavailable after setup.\n' "$tool" >&2
  return 1
}

for tool in git curl jq tar unzip sha256sum rg sqlite3 node npm python3 python gh bws; do
  require_ready_command "$tool" || exit 1
done
if ! { [ "$powershell_state" = 'absent' ] && [ "$degraded_ack" = true ]; }; then
  require_ready_command pwsh || exit 1
fi
if ! python3 -m pip --version >/dev/null 2>&1; then
  printf '[setup] SETUP FAILED: required command pip is unavailable through python3 -m pip.\n' >&2
  exit 1
fi

# The next hosted-agent command is non-interactive. Verify the persisted tool path through that
# same shape instead of accepting setup's own inherited PATH as proof.
agent_shell_tools='gh bws python'
if ! { [ "$powershell_state" = 'absent' ] && [ "$degraded_ack" = true ]; }; then
  agent_shell_tools="$agent_shell_tools pwsh"
fi
agent_shell_probe="$(env -i HOME="${HOME:-/root}" /bin/bash --noprofile --norc -c ". \"\$HOME/.profile\"; command -v $agent_shell_tools 2>/dev/null | tr '\n' ' '" 2>/dev/null || true)"
for tool in $agent_shell_tools; do
  if ! printf '%s' "$agent_shell_probe" | grep -q "/$tool"; then
    printf '[setup] SETUP FAILED: a clean non-interactive shell cannot resolve persisted %s.\n' "$tool" >&2
    exit 1
  fi
done

# Deepen the checkout so history and sibling branches are visible.
#
# Providers hand an agent a shallow, single-ref clone. That is cheap and it is wrong for this
# repository: an agent that cannot see `agent/*` and `cloud/*` refs cannot answer "is this already
# fixed on a pending branch", and it cannot run `git log origin/master..HEAD` at all. Measured
# 2026-08-30: a cloud revalidation of 139 open items returned 124 could-not-tell for exactly this
# reason, and the one measurement it could make was a commit subject it happened to reach.
#
# Never fatal. A provider may legitimately refuse the fetch (no network, no credential, a mirror
# that serves one ref). The agent must then be TOLD its history is partial rather than left to
# infer completeness from a clone that looks ordinary.
git_depth_state='full'
if [ "$(git rev-parse --is-shallow-repository 2>/dev/null || echo unknown)" = 'true' ]; then
  if git fetch --unshallow --tags origin >/dev/null 2>&1; then
    log 'deepened a shallow clone to full history'
  else
    git_depth_state='shallow'
    warn 'clone is SHALLOW and could not be deepened; git history is partial, so any verdict that depends on history is could-not-tell, never a measured zero'
  fi
fi
if git fetch --tags origin '+refs/heads/*:refs/remotes/origin/*' >/dev/null 2>&1; then
  log "sibling refs fetched: $(git for-each-ref --format='%(refname)' refs/remotes/origin | wc -l) remote branch(es) visible"
else
  git_depth_state='partial-refs'
  warn 'could not fetch sibling refs; agent/* and cloud/* branches are INVISIBLE, so "already fixed on a branch" is could-not-tell, never absent'
fi
if command -v git-lfs >/dev/null 2>&1; then
  if git lfs pull >/dev/null 2>&1; then
    log 'Git LFS objects hydrated'
  else
    warn 'Git LFS objects could not be hydrated; LFS-backed state remains unreadable'
  fi
fi
log "git history state: $git_depth_state"

log "setup complete; follow ONBOARDING/FRESH-MACHINE-READINESS.md and verify with: bash .agents/cloud/verify.sh"

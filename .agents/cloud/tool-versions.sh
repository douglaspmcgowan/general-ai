# Reviewed base CLI pins for hosted Linux agent environments.
# Owned by ONBOARDING/CLOUD-AGENTS.md ("Required base toolchain").
# Agent CLIs use exact pins. Language runtimes use supported release lines.

# Canonical Node default. A project's reviewed `.nvmrc` replaces it (see resolve_node_release_line).
NODE_RELEASE_LINE=22
# The headless Obsidian client needs Node 22+, so no project pin may select an older major.
NODE_MIN_MAJOR=22
NODE_PIN_ERROR=''

# resolve_node_release_line
#
# The project's own `<repo>/.nvmrc` is the only override. It must be a regular file (never a
# symlink) holding one line of `[v]MAJOR[.MINOR[.PATCH]]` (at most 31 characters), read as data and never sourced or
# evaluated. The result is a dotted prefix: `24` selects any 24.x.y, `24.1` any 24.1.y, `24.1.0`
# that release only. Aliases (`lts/*`, `node`), ranges and anything else set NODE_PIN_ERROR, which
# setup.sh and verify.sh turn into a failure -- there is no fallback to another major. Nothing is
# installed or downloaded. https://github.com/nvm-sh/nvm#nvmrc
resolve_node_release_line() {
  local pin_file pin major
  pin_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/.nvmrc"
  NODE_PIN_ERROR=''
  { [ -e "$pin_file" ] || [ -L "$pin_file" ]; } || return 0
  if [ -L "$pin_file" ] || [ ! -f "$pin_file" ]; then
    NODE_PIN_ERROR="unsupported .nvmrc: $pin_file must be a regular file, not a symlink or directory"
    return 0
  fi
  pin=''
  if IFS= read -r -d '' pin < "$pin_file"; then
    NODE_PIN_ERROR="unsupported .nvmrc: NUL bytes are not permitted"
    return 0
  fi
  pin="${pin//$''/}"
  pin="${pin#"${pin%%[![:space:]]*}"}"
  pin="${pin%"${pin##*[![:space:]]}"}"
  if [ "${#pin}" -ge 32 ] || ! [[ "$pin" =~ ^v?([1-9][0-9]*)(\.(0|[1-9][0-9]*)){0,2}$ ]]; then
    NODE_PIN_ERROR="unsupported .nvmrc: expected one line of [v]MAJOR[.MINOR[.PATCH]] (for example 24), not an alias, range or multi-line value"
    return 0
  fi
  pin="${pin#v}"
  major="${pin%%.*}"
  if [ "${#major}" -lt "${#NODE_MIN_MAJOR}" ] || \
     { [ "${#major}" -eq "${#NODE_MIN_MAJOR}" ] && [[ "$major" < "$NODE_MIN_MAJOR" ]]; }; then
    NODE_PIN_ERROR="unsupported .nvmrc: Node $pin is older than the supported minimum ${NODE_MIN_MAJOR}"
    return 0
  fi
  NODE_RELEASE_LINE="$pin"
}
resolve_node_release_line
# Matches `node --version` output (v24.1.0) against NODE_RELEASE_LINE as a dotted prefix.
node_version_in_release_line() { [[ "$1" =~ ^v${NODE_RELEASE_LINE//./\.}(\.|$) ]]; }
PYTHON_RELEASE_LINE=3
GH_VERSION=2.94.0
VERCEL_CLI_VERSION=58.0.0
BWS_VERSION=2.1.0
PLAYWRIGHT_VERSION=1.61.1
# Official Obsidian Headless client (npm `obsidian-headless`, Dynalist Inc.).
# Read-only vault transport; see .agents/cloud/VAULT-CONTRACT.md. Needs Node 22+.
OBSIDIAN_HEADLESS_VERSION=0.0.14
# PowerShell 7 is the Work Scope runtime. The guarded-write tools are the only
# supported way to change `.agents/work/state.json`, so a hosted agent without
# `pwsh` can read Work Scope state but cannot legally write it.
POWERSHELL_VERSION=7.4.6

# SHA-256 of each downloaded Linux archive, keyed by CPU architecture so a release line
# binds both the selected asset and its bytes. A mismatch refuses installation. Update both
# entries for a tool when its version changes, using the publisher release metadata.
GH_SHA256_AMD64=a757f1ba6db18f4de8cbadb244843a5f89bc75b5e7c6fc127d2bd77fbd12ed62
GH_SHA256_ARM64=705a23b70b0f1b7ba4c302fdcef392ce3edaacfa7ce8e85e4d93d72ea800a538
BWS_SHA256_AMD64=ba8233c3a4aee5d43e3c73bbd04d99e9bc5aba13bbbfd06d89b073abe732b860
BWS_SHA256_ARM64=18253757286e119d450133a87eb463bf8c1ce418ce24c834f4f250d60cba6f9e
POWERSHELL_SHA256_AMD64=6f6015203c47806c5cc444c19d8ed019695e610fbd948154264bf9ca8e157561
POWERSHELL_SHA256_ARM64=c0159b03e85f44ae1e7697818a011558da6c813d0aae848bf5ac13bf435d8624

# Installation root for reviewed downloads inside the disposable environment.
CLOUD_TOOL_ROOT=.local/agent-tools

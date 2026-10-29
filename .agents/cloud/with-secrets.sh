#!/usr/bin/env bash
# Audited Bitwarden retrieval and child-process injection for hosted Linux agents.
#
#   bash .agents/cloud/with-secrets.sh <selector> [<selector>...] -- <command> [args...]
#
# This is the Linux counterpart of the Windows broker
# (.agents/tools/Invoke-WithBitwardenSecret.ps1). It enforces the same four rules:
#
#   1. only selectors declared in .agents/cloud/secret-bindings.json may resolve;
#   2. every retrieved resource must belong to the pinned BWS_PROJECT_ID;
#   3. the Bitwarden bootstrap token (whichever machine-account name this environment carries:
#      see bws_cloud_token_name in credential-profile.sh) is removed from the child environment;
#   4. every retrieved value is redacted out of child stdout and stderr.
#
# It is a misuse guard, not a security boundary: an agent holding the bootstrap
# token can call `bws` directly. See ONBOARDING/CLOUD-AGENTS.md.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
bindings="$repo_root/.agents/cloud/secret-bindings.json"
export PATH="$repo_root/.local/agent-tools/bin:$PATH"

die() { printf 'with-secrets: %s\n' "$*" >&2; exit 2; }

command -v bws >/dev/null 2>&1 || die 'the pinned bws CLI is not installed'
command -v jq  >/dev/null 2>&1 || die 'jq is required'
[ -f "$bindings" ] || die "missing credential allowlist: $bindings"
[ "$(jq -r '.schemaVersion' "$bindings")" = "1" ] || die 'secret-bindings.json must use schemaVersion 1'

selectors=()
while [ $# -gt 0 ]; do
  if [ "$1" = "--" ]; then shift; break; fi
  case "$1" in
    ''|*[!a-z0-9._-]*) die "invalid selector: $1" ;;
  esac
  selectors+=("$1"); shift
done
[ ${#selectors[@]} -gt 0 ] || die 'no selector given'
[ $# -gt 0 ] || die 'no command given after --'

# One shared resolver (credential-profile.sh) picks the environment's single machine-account
# token by name: the legacy generic name or one of the BWS_<ACCOUNT>_ACCESS_TOKEN names. Two or
# more set is refused, since an environment carries exactly one token.
# shellcheck source=credential-profile.sh
. "$(dirname "${BASH_SOURCE[0]}")/credential-profile.sh"
token_var=''
token_status=0
token_var="$(bws_cloud_token_name)" || token_status=$?
case "$token_status" in
  0) ;;
  1) die 'no Bitwarden machine-account token is set in this environment; see .agents/references/bitwarden.md' ;;
  *) die 'more than one Bitwarden token is set; a cloud environment carries exactly one (names listed above)' ;;
esac
cloud_token="$(eval "printf '%s' \"\${$token_var}\"")"
: "${BWS_PROJECT_ID:?BWS_PROJECT_ID is not set; the project pin is mandatory}"

# Every declared destination is scrubbed from the child environment, so an
# undeclared selector can never inherit another command's value.
#
# `tr -d '\r'` because this list is the one jq result that gets word-split, and a carriage
# return binds to every name except the last -- `env -u $'ALPHA\r'` scrubs nothing and says
# nothing. Production is Linux, where jq emits LF, so this was never a live hole; it surfaced
# on a Windows host running the suite, where the scrub silently covered one destination out of
# three. A guard that degrades without a word is worth one character class. The other jq
# captures below are single values compared against something, so a stray byte makes them
# refuse rather than pass quietly.
all_destinations="$(jq -r '.bindings[].environmentVariable' "$bindings" | tr -d '\r')"

umask 077
work="$(mktemp -d)"
values="$work/values"
: > "$values"
cleanup() { rm -rf "$work"; }
trap cleanup EXIT INT TERM

env_args=()
for selector in "${selectors[@]}"; do
  binding="$(jq -c --arg s "$selector" '[.bindings[] | select(.selector == $s)]' "$bindings")"
  [ "$(printf '%s' "$binding" | jq 'length')" = "1" ] \
    || die "selector '$selector' must match exactly one declared binding"

  id_var="$(printf '%s' "$binding" | jq -r '.[0].resourceIdEnvironmentVariable')"
  dest_var="$(printf '%s' "$binding" | jq -r '.[0].environmentVariable')"
  case "$dest_var" in
    BWS_ACCESS_TOKEN) die 'a binding may not target a bootstrap variable' ;;
  esac
  for token_name in $BWS_CLOUD_TOKEN_NAMES; do
    [ "$dest_var" != "$token_name" ] || die 'a binding may not target a bootstrap variable'
  done

  resource_id="$(eval "printf '%s' \"\${$id_var:-}\"")"
  [ -n "$resource_id" ] || die "$id_var is not set; it must carry the '$selector' resource ID"

  record="$(BWS_ACCESS_TOKEN="$cloud_token" \
            bws secret get "$resource_id" --output json 2>/dev/null)" \
    || die "Bitwarden could not retrieve the '$selector' resource"

  got_project="$(printf '%s' "$record" | jq -r '.projectId // ""')"
  got_id="$(printf '%s' "$record" | jq -r '.id // ""')"
  [ "$got_id" = "$resource_id" ] || die "Bitwarden returned a different resource for '$selector'"
  [ "$got_project" = "$BWS_PROJECT_ID" ] \
    || die "the '$selector' resource is outside the pinned Bitwarden project"

  value="$(printf '%s' "$record" | jq -r '.value // ""')"
  record=''
  [ -n "$value" ] || die "Bitwarden returned no value for '$selector'"

  printf '%s\n' "$value" >> "$values"
  env_args+=("$dest_var=$value")
  value=''
done

# Literal, metacharacter-safe redaction of every retrieved value.
redact() {
  awk -v vf="$values" '
    BEGIN { n = 0; while ((getline line < vf) > 0) if (length(line)) vals[++n] = line }
    {
      line = $0
      for (i = 1; i <= n; i++) {
        v = vals[i]; out = ""
        while ((p = index(line, v)) > 0) {
          out = out substr(line, 1, p - 1) "[REDACTED]"
          line = substr(line, p + length(v))
        }
        line = out line
      }
      print line
    }'
}

unset_args=(-u BWS_ACCESS_TOKEN -u BW_SESSION)
for token_name in $BWS_CLOUD_TOKEN_NAMES; do unset_args+=(-u "$token_name"); done
for d in $all_destinations; do unset_args+=(-u "$d"); done

# Output is buffered, then redacted, so the child's real exit status survives.
status=0
env "${unset_args[@]}" "${env_args[@]}" "$@" >"$work/out" 2>"$work/err" || status=$?
redact < "$work/out"
redact < "$work/err" >&2
exit "$status"

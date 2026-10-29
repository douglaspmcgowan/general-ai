#!/usr/bin/env bash
# Pins the credential-profile rule without reading this machine's credentials.
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
failures=0
ok() { printf '  ok    %s\n' "$*"; }
bad() { printf '  FAIL  %s\n' "$*"; failures=$((failures + 1)); }
# Every Bitwarden token name an environment may carry is cleared first, so the ambient host's own
# variables (a developer machine may have several) cannot leak into a case.
clean_env() {
  env -u BITWARDEN_SECRETS_MANAGER_ACCESS_TOKEN -u BWS_DIGITAL_SECRETARY_ACCESS_TOKEN \
      -u BWS_GENERAL_AGENTS_ACCESS_TOKEN -u BWS_GENERAL_AGENTS_TOKEN \
      -u BWS_PHYSICAL_COMPUTER_ACCESS_TOKEN -u BWS_PROJECT_ID -u CLOUD_KIT_PROFILE "$@"
}
verdicts() {
  clean_env "$@" \
    bash -c '
      . '"$here"'/credential-profile.sh
      out=""
      for v in $CREDENTIAL_PROFILE_VARS; do out="$out$(credential_profile_verdict "$v") "; done
      printf "%s|%s" "${out% }" "$(credential_profile)"
    '
}
expect() {
  local label="$1" want="$2" got
  shift 2
  got="$(verdicts "$@")"
  if [ "$got" = "$want" ]; then ok "$label"; else bad "$label: got '$got', wanted '$want'"; fi
}
# resolver <expected-exit> <expected-stdout> <expected-stderr-fragment> <label> [VAR=value ...]
resolver() {
  local want_status="$1" want_out="$2" want_err="$3" label="$4" out err status
  shift 4
  out="$(clean_env "$@" bash -c '. '"$here"'/credential-profile.sh; bws_cloud_token_name' 2>"${TMPDIR:-/tmp}/cp-err.$$")"; status=$?
  err="$(cat "${TMPDIR:-/tmp}/cp-err.$$")"; rm -f "${TMPDIR:-/tmp}/cp-err.$$"
  if [ "$status" -ne "$want_status" ]; then bad "$label: exit $status, wanted $want_status"; return; fi
  if [ "$out" != "$want_out" ]; then bad "$label: printed '$out', wanted '$want_out'"; return; fi
  case "$err" in *"$want_err"*) ok "$label" ;; *) bad "$label: stderr '$err' lacks '$want_err'" ;; esac
}
expect 'none set: both skip, profile is code-work' 'skip skip|code-work'
expect 'one set: the other fails, profile is full' 'pass fail|full' \
  BITWARDEN_SECRETS_MANAGER_ACCESS_TOKEN=not-a-credential
expect 'both set: both pass' 'pass pass|full' \
  BITWARDEN_SECRETS_MANAGER_ACCESS_TOKEN=not-a-credential BWS_PROJECT_ID=not-a-credential
expect 'CLOUD_KIT_PROFILE=full with none set: both fail' 'fail fail|full' CLOUD_KIT_PROFILE=full
expect 'exported empty string counts as unset' 'skip skip|code-work' \
  BITWARDEN_SECRETS_MANAGER_ACCESS_TOKEN=
# A machine-account token name stands for the token variable in the profile rule.
expect 'a machine-account name plus the project pin: both pass' 'pass pass|full' \
  BWS_DIGITAL_SECRETARY_ACCESS_TOKEN=not-a-credential BWS_PROJECT_ID=not-a-credential
expect 'a machine-account name alone: the pin fails' 'pass fail|full' \
  BWS_GENERAL_AGENTS_ACCESS_TOKEN=not-a-credential
expect 'the tolerated short General Agents alias counts as the token' 'pass pass|full' \
  BWS_GENERAL_AGENTS_TOKEN=not-a-credential BWS_PROJECT_ID=not-a-credential
# bws_cloud_token_name: one token per environment.
resolver 1 '' '' 'resolver: none set returns 1 and prints nothing'
resolver 0 'BITWARDEN_SECRETS_MANAGER_ACCESS_TOKEN' '' 'resolver: the legacy name resolves' \
  BITWARDEN_SECRETS_MANAGER_ACCESS_TOKEN=not-a-credential
resolver 0 'BWS_DIGITAL_SECRETARY_ACCESS_TOKEN' '' 'resolver: the Digital Secretary name resolves' \
  BWS_DIGITAL_SECRETARY_ACCESS_TOKEN=not-a-credential
resolver 0 'BWS_GENERAL_AGENTS_ACCESS_TOKEN' '' 'resolver: the General Agents name resolves' \
  BWS_GENERAL_AGENTS_ACCESS_TOKEN=not-a-credential
resolver 0 'BWS_GENERAL_AGENTS_TOKEN' '' 'resolver: the short General Agents alias resolves' \
  BWS_GENERAL_AGENTS_TOKEN=not-a-credential
resolver 0 'BWS_PHYSICAL_COMPUTER_ACCESS_TOKEN' '' 'resolver: the Physical Computer name resolves' \
  BWS_PHYSICAL_COMPUTER_ACCESS_TOKEN=not-a-credential
resolver 2 '' 'BWS_DIGITAL_SECRETARY_ACCESS_TOKEN BWS_GENERAL_AGENTS_ACCESS_TOKEN' \
  'resolver: two different names are refused, naming both' \
  BWS_DIGITAL_SECRETARY_ACCESS_TOKEN=not-a-credential BWS_GENERAL_AGENTS_ACCESS_TOKEN=not-a-credential
resolver 2 '' 'BITWARDEN_SECRETS_MANAGER_ACCESS_TOKEN BWS_GENERAL_AGENTS_TOKEN' \
  'resolver: the legacy name plus a machine-account name is refused' \
  BITWARDEN_SECRETS_MANAGER_ACCESS_TOKEN=not-a-credential BWS_GENERAL_AGENTS_TOKEN=not-a-credential
resolver 1 '' '' 'resolver: an empty value is not set' BWS_DIGITAL_SECRETARY_ACCESS_TOKEN=
if [ "$failures" -gt 0 ]; then
  printf 'credential-profile: %s case(s) failed\n' "$failures"
  exit 1
fi
printf 'credential-profile tests passed (17 cases)\n'

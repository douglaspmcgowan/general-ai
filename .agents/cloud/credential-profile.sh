#!/usr/bin/env bash
# Decides whether an unset credential variable is a FAILURE or an absence to report and move past.
# Sourced by verify.sh; it defines functions and touches nothing, so it is safe to source in a test.
#
# WHY THIS EXISTS. verify.sh failed on two unset Bitwarden variables while the section that consumes them skips on
# the identical absence. The same missing variable was therefore both fatal and fine in one run, and
# because the script exits non-zero on any failure, an ordinary code-work cloud agent carrying none
# of these could never turn the verifier green no matter how healthy its environment was. A gate
# nobody can pass stops being read.
#
# THE RULE, and it is the only thing this file decides:
#   * NONE of the two set -- a coherent environment. No credential work is possible here and
#     nothing pretends otherwise: every credential-dependent check already skips with a named
#     reason. Reported as SKIP plus one WARN naming what went unproven. Not a failure.
#   * SOME set and some not -- a half-provisioned kit, which is genuinely broken: the sections
#     below will attempt authenticated work and fail partway. The missing ones FAIL, as before.
#   * CLOUD_KIT_PROFILE=full -- the caller declares this environment is supposed to be fully
#     credentialed, so both is required and a missing one FAILS regardless.
#
# The reversible assumption in that rule is the first bullet: it treats "both absent" as a
# declaration of intent rather than as an oversight. CLOUD_KIT_PROFILE=full is the way to say
# otherwise, and .agents/cloud/credential-profile.test.sh pins all three branches.

# The two variables whose absence this file arbitrates. Names only -- no value is ever read here,
# and nothing in this file prints one.
CREDENTIAL_PROFILE_VARS='BITWARDEN_SECRETS_MANAGER_ACCESS_TOKEN BWS_PROJECT_ID'

# The Bitwarden machine-account token a cloud environment may carry, by name. A cloud environment
# carries exactly ONE, under its machine account's name (or the legacy generic name). The model is
# in .agents/references/bitwarden.md. BWS_GENERAL_AGENTS_TOKEN is a tolerated alias of
# BWS_GENERAL_AGENTS_ACCESS_TOKEN: it is the name one host's User variable actually carries.
# BWS_ACCESS_TOKEN is deliberately absent: it is the CLI's own variable, set per call on the
# child process, never configured in an environment.
BWS_CLOUD_TOKEN_NAMES='BITWARDEN_SECRETS_MANAGER_ACCESS_TOKEN BWS_DIGITAL_SECRETARY_ACCESS_TOKEN BWS_GENERAL_AGENTS_ACCESS_TOKEN BWS_GENERAL_AGENTS_TOKEN BWS_PHYSICAL_COMPUTER_ACCESS_TOKEN'

# bws_cloud_token_names_set -- the names from BWS_CLOUD_TOKEN_NAMES that carry a non-empty value,
# space separated, in declared order. Names only.
bws_cloud_token_names_set() {
  local v found=''
  for v in $BWS_CLOUD_TOKEN_NAMES; do
    if [ -n "$(eval "printf '%s' \"\${$v:-}\"")" ]; then found="$found $v"; fi
  done
  printf '%s' "${found# }"
}

# bws_cloud_token_name -- prints the name of the one token this environment carries.
#   exit 0  exactly one is set; its name is printed.
#   exit 1  none is set; nothing is printed.
#   exit 2  two or more different names are set; one line naming them goes to stderr, because an
#           environment with several machine-account tokens has no single reach to reason about.
# The value is never read into the output and never printed.
bws_cloud_token_name() {
  local names count
  names="$(bws_cloud_token_names_set)"
  if [ -z "$names" ]; then return 1; fi
  # shellcheck disable=SC2086
  set -- $names
  count=$#
  if [ "$count" -gt 1 ]; then
    printf 'more than one Bitwarden token is set (%s); a cloud environment carries exactly one, so unset all but its own\n' "$*" >&2
    return 2
  fi
  printf '%s' "$1"
}

# credential_profile_var_is_set <var-name> -- the Bitwarden token variable stands for any one of
# the declared token names; every other variable stands for itself.
credential_profile_var_is_set() {
  if [ "$1" = 'BITWARDEN_SECRETS_MANAGER_ACCESS_TOKEN' ]; then
    [ -n "$(bws_cloud_token_names_set)" ]
    return
  fi
  [ -n "$(eval "printf '%s' \"\${$1:-}\"")" ]
}

# credential_profile_set_count -- how many of the two carry a non-empty value.
credential_profile_set_count() {
  local v n=0
  for v in $CREDENTIAL_PROFILE_VARS; do
    if credential_profile_var_is_set "$v"; then n=$((n + 1)); fi
  done
  printf '%s' "$n"
}

# credential_profile -- 'full' when the caller declared it or either is set,
#                       'code-work' when none is set and nothing was declared.
credential_profile() {
  if [ "${CLOUD_KIT_PROFILE:-}" = 'full' ]; then printf 'full'; return; fi
  if [ "$(credential_profile_set_count)" -gt 0 ]; then printf 'full'; return; fi
  printf 'code-work'
}

# credential_profile_verdict <var-name> -- 'pass', 'fail', or 'skip' for one variable.
credential_profile_verdict() {
  if credential_profile_var_is_set "$1"; then printf 'pass'; return; fi
  if [ "$(credential_profile)" = 'code-work' ]; then printf 'skip'; else printf 'fail'; fi
}

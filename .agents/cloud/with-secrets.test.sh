#!/usr/bin/env bash
# Gate for the cloud credential broker.
#
# ONBOARDING/CLOUD-AGENTS.md's readiness checklist names this file's behaviour directly --
# "the supported credential helper rejects undeclared selectors, redacts values, and
# documents that direct BWS access remains possible" -- and the cloud test strategy asks for
# "one credential-helper redaction, selector, and child-environment test". Neither existed.
# Measured 2026-08-09: `with-secrets.sh` had no test of any kind, and neither did any other
# script under .agents/cloud/. Sync-CloudKit.test.ps1 proves the file is COPIED correctly
# between projects, which says nothing about what it does when it runs.
#
# That is the same shape as the vault-mirror guards before 2026-08-08: a guard that has
# quietly stopped working looks exactly like a guard with nothing to catch. Here the guard
# stands between an undeclared selector and a Bitwarden value, so its silence is expensive.
#
# It never contacts Bitwarden. `bws` is stubbed on PATH and the fixture declares its own
# bindings, so the suite asserts the broker's decisions rather than the vault's contents. No
# real token is read, set, or printed at any point.
#
# Deliberately a sibling file rather than a `--self-test` flag inside the broker. vault-pull.sh
# carries its self-test inline, but it also refuses `--mode` and `OB_SYNC_MODE` precisely
# because an argument that changes a transport's behaviour is a liability; adding one to a
# credential path would be the same mistake with a worse blast radius.

set -uo pipefail

broker="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/with-secrets.sh"
[ -f "$broker" ] || { printf 'with-secrets.test.sh: broker not found at %s\n' "$broker" >&2; exit 1; }

failures=0
ok()   { printf '  ok    %s\n' "$*"; }
bad()  { printf '  FAIL  %s\n' "$*"; failures=$((failures + 1)); }

# with-secrets.sh itself requires jq at runtime (it dies immediately without one), so this
# is not a test-only dependency to route around. A Linux container installs jq via
# setup.sh's apt fallback and runs this suite from verify.sh, where jq is guaranteed; this
# host is a developer machine that never promised one. Skip, naming exactly what went
# untested, rather than fail on a gap this suite cannot close and should not paper over by
# vendoring jq into a setup path.
if ! command -v jq >/dev/null 2>&1; then
    printf 'SKIP  with-secrets.test.sh: jq is not installed on this host, so none of this suite'"'"'s 31 checks ran (redaction on both streams, bootstrap/destination scrubbing, exit-status survival, the project pin, resource substitution, and the allowlist refusals). with-secrets.sh requires jq at runtime; a Linux container installs it via setup.sh and this suite runs there from verify.sh.\n'
    exit 0
fi

root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT INT TERM

# --- fixture repository -------------------------------------------------------------------
mkdir -p "$root/.agents/cloud" "$root/bin"
cp "$broker" "$root/.agents/cloud/with-secrets.sh"
# with-secrets.sh sources the shared token resolver from its own directory.
cp "$(dirname "$broker")/credential-profile.sh" "$root/.agents/cloud/credential-profile.sh"

cat > "$root/.agents/cloud/secret-bindings.json" <<'JSON'
{
  "schemaVersion": 1,
  "bindings": [
    { "selector": "alpha", "environmentVariable": "ALPHA_TOKEN", "resourceIdEnvironmentVariable": "ALPHA_RESOURCE_ID" },
    { "selector": "other", "environmentVariable": "OTHER_TOKEN", "resourceIdEnvironmentVariable": "OTHER_RESOURCE_ID" },
    { "selector": "bootstrap-target", "environmentVariable": "BWS_ACCESS_TOKEN", "resourceIdEnvironmentVariable": "BOOTSTRAP_RESOURCE_ID" },
    { "selector": "boot-legacy", "environmentVariable": "BITWARDEN_SECRETS_MANAGER_ACCESS_TOKEN", "resourceIdEnvironmentVariable": "BOOTSTRAP_RESOURCE_ID" },
    { "selector": "boot-ds", "environmentVariable": "BWS_DIGITAL_SECRETARY_ACCESS_TOKEN", "resourceIdEnvironmentVariable": "BOOTSTRAP_RESOURCE_ID" },
    { "selector": "boot-ga", "environmentVariable": "BWS_GENERAL_AGENTS_ACCESS_TOKEN", "resourceIdEnvironmentVariable": "BOOTSTRAP_RESOURCE_ID" },
    { "selector": "boot-ga-short", "environmentVariable": "BWS_GENERAL_AGENTS_TOKEN", "resourceIdEnvironmentVariable": "BOOTSTRAP_RESOURCE_ID" },
    { "selector": "boot-pc", "environmentVariable": "BWS_PHYSICAL_COMPUTER_ACCESS_TOKEN", "resourceIdEnvironmentVariable": "BOOTSTRAP_RESOURCE_ID" }
  ]
}
JSON

# `bws secret get <id> --output json`. STUB_* lets a case bend one field without a second stub.
cat > "$root/bin/bws" <<'STUB'
#!/usr/bin/env bash
[ "${1:-}" = "secret" ] && [ "${2:-}" = "get" ] || { echo 'unexpected bws call' >&2; exit 64; }
id="${3:-}"
[ "${STUB_FAIL:-}" = "1" ] && exit 1
# STUB_EXPECT_TOKEN: the stub answers only when handed the token the case expects, so a case can
# prove which environment variable the broker resolved without any value leaving the stub.
if [ -n "${STUB_EXPECT_TOKEN:-}" ] && [ "${BWS_ACCESS_TOKEN:-}" != "$STUB_EXPECT_TOKEN" ]; then exit 1; fi
printf '{"id":"%s","projectId":"%s","value":"%s"}\n' \
  "${STUB_ID_OVERRIDE:-$id}" "${STUB_PROJECT:-proj-pinned}" "${STUB_VALUE:-s3cr3t-value}"
STUB
chmod +x "$root/bin/bws"

export PATH="$root/bin:$PATH"
export BITWARDEN_SECRETS_MANAGER_ACCESS_TOKEN='stub-bootstrap-token'
export BWS_PROJECT_ID='proj-pinned'
export ALPHA_RESOURCE_ID='res-alpha'
export OTHER_RESOURCE_ID='res-other'
export BOOTSTRAP_RESOURCE_ID='res-boot'

run() {  # run <expected-exit> <label> -- <broker args...>; captures out/err
    local want="$1" label="$2"; shift 3
    out="$(bash "$root/.agents/cloud/with-secrets.sh" "$@" 2>"$root/err")"; status=$?
    err="$(cat "$root/err")"
    if [ "$status" -ne "$want" ]; then
        bad "$label: exit $status, expected $want. ${err:-$out}"
        return 1
    fi
    ok "$label"
}

# --- the value reaches the child, and only the child --------------------------------------
child="$root/child.sh"
cat > "$child" <<'CHILD'
#!/usr/bin/env bash
printf 'ALPHA=%s\n' "${ALPHA_TOKEN:-unset}"
printf 'BOOT=%s\n' "${BITWARDEN_SECRETS_MANAGER_ACCESS_TOKEN:-unset}"
printf 'BWSAT=%s\n' "${BWS_ACCESS_TOKEN:-unset}"
printf 'OTHER=%s\n' "${OTHER_TOKEN:-unset}"
printf 'to stderr: %s\n' "${ALPHA_TOKEN:-unset}" >&2
exit "${CHILD_EXIT:-0}"
CHILD
chmod +x "$child"

# A declared destination the caller did NOT select must not leak in from the parent
# environment: an undeclared selector could otherwise inherit another command's value.
export OTHER_TOKEN='inherited-from-parent'

if run 0 'a declared selector runs the child' -- alpha -- bash "$child"; then
    case "$out" in
        *'ALPHA=[REDACTED]'*) ok 'the retrieved value is redacted out of child stdout' ;;
        *'ALPHA=s3cr3t-value'*) bad 'THE SECRET REACHED STDOUT UNREDACTED' ;;
        *'ALPHA=unset'*) bad 'the destination variable never reached the child' ;;
        *) bad "unrecognised child stdout: $out" ;;
    esac
    case "$err" in
        *'[REDACTED]'*) ok 'the retrieved value is redacted out of child stderr' ;;
        *) bad "stderr was not redacted: $err" ;;
    esac
    case "$out" in
        *'BOOT=unset'*) ok 'the bootstrap token is removed from the child environment' ;;
        *) bad 'THE BOOTSTRAP TOKEN SURVIVED INTO THE CHILD ENVIRONMENT' ;;
    esac
    case "$out" in
        *'BWSAT=unset'*) ok 'BWS_ACCESS_TOKEN is removed from the child environment' ;;
        *) bad 'BWS_ACCESS_TOKEN survived into the child environment' ;;
    esac
    case "$out" in
        *'OTHER=unset'*) ok 'an unselected declared destination is scrubbed, not inherited' ;;
        *'OTHER=inherited-from-parent'*) bad 'an unselected declared destination was inherited from the parent' ;;
        *) bad "unrecognised OTHER line: $out" ;;
    esac
fi

# --- the child's exit status survives the buffering that redaction requires ----------------
CHILD_EXIT=7 run 7 "the child's exit status survives redaction" -- alpha -- bash "$child"

# --- refusals: each is exit 2 and runs no child --------------------------------------------
sentinel="$root/ran"
tattle="$root/tattle.sh"
printf '#!/usr/bin/env bash\ntouch "%s"\n' "$sentinel" > "$tattle"
chmod +x "$tattle"

refuse() {  # refuse <label> <expected message fragment> -- <args...>
    local label="$1" want="$2"; shift 3
    rm -f "$sentinel"
    bash "$root/.agents/cloud/with-secrets.sh" "$@" >"$root/out" 2>"$root/err"; local status=$?
    local err; err="$(cat "$root/err")"
    if [ "$status" -ne 2 ]; then bad "$label: exit $status, expected 2. $err"; return; fi
    case "$err" in
        *"$want"*) ;;
        *) bad "$label: refusal did not say why ('$want'): $err"; return ;;
    esac
    if [ -e "$sentinel" ]; then bad "$label: the child ran despite the refusal"; return; fi
    ok "$label"
}

refuse 'an undeclared selector is refused'   'must match exactly one declared binding' -- undeclared -- bash "$tattle"
refuse 'a selector with shell metacharacters is refused' 'invalid selector' -- 'alpha;rm' -- bash "$tattle"
refuse 'an empty selector is refused'        'invalid selector' -- '' -- bash "$tattle"
refuse 'no command after -- is refused'      'no command given' -- alpha --
refuse 'no selector is refused'              'no selector given' -- -- bash "$tattle"
refuse 'a binding targeting a bootstrap variable is refused' 'may not target a bootstrap variable' -- bootstrap-target -- bash "$tattle"
for boot_selector in boot-legacy boot-ds boot-ga boot-ga-short boot-pc; do
    refuse "a binding targeting a token name is refused ($boot_selector)" 'may not target a bootstrap variable' -- "$boot_selector" -- bash "$tattle"
done

# --- one token per environment, resolved by machine-account name -----------------------------
# Each case starts from a clean slate: the legacy variable the suite exported above is removed
# and exactly the named variables are set.
token_env() {  # token_env <VAR=value>... -- run the broker under exactly those token variables
    env -u BITWARDEN_SECRETS_MANAGER_ACCESS_TOKEN -u BWS_DIGITAL_SECRETARY_ACCESS_TOKEN \
        -u BWS_GENERAL_AGENTS_ACCESS_TOKEN -u BWS_GENERAL_AGENTS_TOKEN -u BWS_PHYSICAL_COMPUTER_ACCESS_TOKEN \
        "$@"
}
for token_name in BITWARDEN_SECRETS_MANAGER_ACCESS_TOKEN BWS_DIGITAL_SECRETARY_ACCESS_TOKEN \
                  BWS_GENERAL_AGENTS_ACCESS_TOKEN BWS_GENERAL_AGENTS_TOKEN BWS_PHYSICAL_COMPUTER_ACCESS_TOKEN; do
    out="$(token_env "$token_name=name-test-token" STUB_EXPECT_TOKEN='name-test-token' \
        bash "$root/.agents/cloud/with-secrets.sh" alpha -- bash "$child" 2>"$root/err")"; status=$?
    if [ "$status" -eq 0 ]; then
        case "$out" in
            *'ALPHA=[REDACTED]'*) ok "$token_name resolves as the environment's token" ;;
            *) bad "$token_name: the child did not receive the secret: $out" ;;
        esac
    else
        bad "$token_name: exit $status. $(cat "$root/err")"
    fi
done

# The resolved token is scrubbed from the child under whichever name it arrived.
printf '#!/usr/bin/env bash\nprintf "DS=%%s GA=%%s PC=%%s\\n" "${BWS_DIGITAL_SECRETARY_ACCESS_TOKEN:-unset}" "${BWS_GENERAL_AGENTS_ACCESS_TOKEN:-unset}" "${BWS_PHYSICAL_COMPUTER_ACCESS_TOKEN:-unset}"\n' > "$root/names-child.sh"
chmod +x "$root/names-child.sh"
out="$(token_env BWS_DIGITAL_SECRETARY_ACCESS_TOKEN=name-test-token \
    bash "$root/.agents/cloud/with-secrets.sh" alpha -- bash "$root/names-child.sh" 2>/dev/null)"
case "$out" in
    *'DS=unset GA=unset PC=unset'*) ok 'every machine-account token name is scrubbed from the child environment' ;;
    *) bad "A MACHINE-ACCOUNT TOKEN NAME SURVIVED INTO THE CHILD: $out" ;;
esac

# Two different names set: refused with one line naming both, and no child runs.
rm -f "$sentinel"
token_env BWS_DIGITAL_SECRETARY_ACCESS_TOKEN=a-token BWS_GENERAL_AGENTS_ACCESS_TOKEN=b-token \
    bash "$root/.agents/cloud/with-secrets.sh" alpha -- bash "$tattle" >"$root/out" 2>"$root/err"; status=$?
err="$(cat "$root/err")"
case "$err" in
    *'BWS_DIGITAL_SECRETARY_ACCESS_TOKEN BWS_GENERAL_AGENTS_ACCESS_TOKEN'*)
        if [ "$status" -eq 2 ] && [ ! -e "$sentinel" ]; then ok 'two different token names are refused, naming both'
        else bad "two token names: exit $status or the child ran"; fi ;;
    *) bad "two token names were not refused by name: exit $status. $err" ;;
esac

# None set: refused, no child.
rm -f "$sentinel"
token_env bash "$root/.agents/cloud/with-secrets.sh" alpha -- bash "$tattle" >"$root/out" 2>"$root/err"; status=$?
err="$(cat "$root/err")"
case "$err" in
    *'no Bitwarden machine-account token is set'*)
        if [ "$status" -eq 2 ] && [ ! -e "$sentinel" ]; then ok 'no token set is refused'
        else bad "no token: exit $status or the child ran"; fi ;;
    *) bad "no token set was not refused clearly: exit $status. $err" ;;
esac

# The project pin: a resource that exists but lives outside BWS_PROJECT_ID is refused. This is
# the rule that keeps a machine account's wider reach from becoming this repository's reach.
STUB_PROJECT='proj-somewhere-else' \
    refuse 'a resource outside the pinned project is refused' 'outside the pinned Bitwarden project' -- alpha -- bash "$tattle"

# And a vault that answers with a different resource than the one asked for.
STUB_ID_OVERRIDE='res-substituted' \
    refuse 'a substituted resource id is refused' 'returned a different resource' -- alpha -- bash "$tattle"

STUB_FAIL=1 \
    refuse 'a retrieval failure is refused rather than run without the value' 'could not retrieve' -- alpha -- bash "$tattle"

# The resource-id variable is the caller's half of the binding; without it there is nothing
# to fetch, and guessing would defeat the pin.
( unset ALPHA_RESOURCE_ID
  refuse 'a missing resource-id variable is refused' 'must carry' -- alpha -- bash "$tattle" )

# --- the allowlist itself ------------------------------------------------------------------
cp "$root/.agents/cloud/secret-bindings.json" "$root/bindings.keep"
printf '{"schemaVersion":2,"bindings":[]}\n' > "$root/.agents/cloud/secret-bindings.json"
refuse 'an unknown allowlist schema is refused' 'schemaVersion 1' -- alpha -- bash "$tattle"
rm -f "$root/.agents/cloud/secret-bindings.json"
refuse 'a missing allowlist is refused' 'missing credential allowlist' -- alpha -- bash "$tattle"
cp "$root/bindings.keep" "$root/.agents/cloud/secret-bindings.json"

if [ "$failures" -gt 0 ]; then
    printf 'with-secrets.test.sh: FAILED (%d)\n' "$failures" >&2
    exit 1
fi
printf 'with-secrets.test.sh: PASS (31 checks: redaction on both streams, bootstrap and destination scrubbing, exit-status survival, one-token-per-environment resolution by machine-account name, project pin, resource substitution, and the refusals)\n'
exit 0

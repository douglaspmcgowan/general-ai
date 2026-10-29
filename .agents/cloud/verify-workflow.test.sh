#!/usr/bin/env bash
set -eu
workflow="$(cd "$(dirname "$0")/../.." && pwd)/.github/workflows/cloud-verify.yml"
block=$(sed -n '/name: Full verifier/,/run: bash .agents\/cloud\/verify.sh/p' "$workflow")
printf '%s\n' "$block" | grep -Fq 'CLOUD_KIT_PROFILE: cloud'
if printf '%s\n' "$block" | grep -Fq 'continue-on-error: true'; then
  echo 'full verifier still hides non-secret failures' >&2
  exit 1
fi
echo 'verify-workflow.test.sh: PASS'

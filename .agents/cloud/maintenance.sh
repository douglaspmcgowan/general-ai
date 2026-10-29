#!/usr/bin/env bash
# Safe cache-resume maintenance for a warm hosted environment.
#
# Contract (ONBOARDING/CLOUD-AGENTS.md):
#   Provider Maintenance field:  set -euo pipefail; bash .agents/cloud/maintenance.sh
#
# Maintenance resumes a cached container. It must stay cheap, idempotent, and
# non-destructive: it never reinstalls the pinned toolchain and never deletes
# tracked files.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

# shellcheck disable=SC1091
set -a; . "$repo_root/.agents/cloud/tool-versions.sh"; set +a
export PATH="$repo_root/${CLOUD_TOOL_ROOT:-.local/agent-tools}/bin:$PATH"

log() { printf '[maintenance] %s\n' "$*"; }

mkdir -p "$repo_root/.local/project-data"

log "sweeping expired harness temporary artifacts"
pwsh -NoProfile -File "$repo_root/.agents/tools/Invoke-TempSweep.ps1" >/dev/null

# Dependencies drift when the cached layer predates a lockfile change.
if [ -f package-lock.json ]; then
  log "npm ci (lockfile resume)"; npm ci --no-fund --no-audit --prefer-offline
elif [ -f pnpm-lock.yaml ]; then
  corepack enable >/dev/null 2>&1 || true
  log "pnpm install --frozen-lockfile"; pnpm install --frozen-lockfile --prefer-offline
fi

if [ -f "$repo_root/.agents/cloud/maintenance.project.sh" ]; then
  log "running project maintenance extension"
  bash "$repo_root/.agents/cloud/maintenance.project.sh"
fi

log "warm environment ready"

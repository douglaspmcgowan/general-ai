# Task

## Goal

Reconcile `general-ai` with the verified repository-first harness, preserve the completed graph and second-brain research in GitHub, and leave only current coordination work active.

## Active

- None.

## Queue

- None.

## Blocked

- None.

## Needs decision

- None in this branch. Future cloud implementation and preserved OneDrive data retirement remain parked in `BACKBURNER.md`.

## Constraints

- Preserve `C:\Users\dougl\My Drive\Project Data`; do not delete, rename, or repurpose it.
- Keep the 14-repository cloud rollout plan-only through `pyrgos-ai/doug-harness` issue #16.
- Do not recreate Drive Capsule, Password Manager scaffolds, or the retired 3/4/3 retention policy.
- Do not touch the stable checkout's six Docket JSON envelopes, `_backups`, stale worktree, OneDrive tree, credentials, or another repository.
- This task owns only `C:\Users\dougl\projects\general-claude\.local\worktrees\general-ai-closeout` on branch `codex/harness-publication-closeout`.

## Completed

- [x] T1 — Replace retired transition claims with the canonical harness state | evidence: `TASK.md`, `STATUS.md`, and `MAP.md` agree with the current `agent-harness` branch and installed architecture | owner: coordination state | class: MAIN.
- [x] T2 — Preserve the four completed graph and second-brain research documents in this repository | after: T1 | evidence: all four source documents are present under `research\`; two redundant trailing blank lines were normalized for `git diff --check`; the six Docket envelopes remain untouched in the stable checkout | owner: research | class: SEQUENTIAL.
- [x] T3 — Reconcile durable status, architecture, parked work, and append-only history | after: T1-T2 | evidence: `STATUS.md`, `MAP.md`, `BACKBURNER.md`, and `LOG.md` describe the same current boundaries without active Drive Capsule, Password Manager, 3/4/3, or obsolete credential blockers | owner: project state | class: MAIN.
- [x] T3.1 — Bring generated project provenance and the empty external-data manifest onto the installed harness schema | discovered during: T4 verifier | evidence: value-safe provenance uses `agent-harness/portable-project-contract/v3`, `data-manifest.yaml` validates as version 2 with no external assets, and project verification passes | owner: generated project metadata | class: SEQUENTIAL.
- [x] T3.2 — Reconcile publication evidence from the coordinated Docket and Obsidian workstream | evidence: four research documents are mirrored to the active vault; six stable Docket cards are imported and broker-published; 166 cards pushed, zero unsafe refusals, zero pulled decisions, and all six IDs verified | owner: publication state | class: PARALLEL.
- [x] T4 — Verify and commit the isolated closeout | after: T1-T3 | evidence: project verifier, Gitleaks, `git diff --check`, source-content comparison, and adversarial stale-claim review pass; final commit recorded in the handoff | owner: verification | class: SEQUENTIAL.
- The canonical harness repository contains the complete root `ONBOARDING` flow, installed-state verification, approved Obsidian configuration capture/restore, GitHub topic discovery, project-data adapters, consolidated hooks, and the Bitwarden Secrets Manager broker.
- SQLite snapshot retention is 2 daily, 2 weekly, and 1 monthly bucket, always preserving the newest verified snapshot and at most five distinct snapshots.
- `C:\Users\dougl\My Drive\Capsule` was removed recoverably after repository onboarding passed; `C:\Users\dougl\My Drive\Project Data` remains the external artifact transport.
- `recovery\general-claude-history.bundle` remains the committed recovery source for the preserved `general-claude` history.

## Verification

`powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.agents\tools\Manage-Harness.ps1" -Action VerifyProject -Repository .`

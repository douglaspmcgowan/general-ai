# Start here on another computer

Last verified: 2026-07-31

This repository carries the coordination history, research, and recovery context for the cross-agent harness. The canonical executable harness lives in the private GitHub repository `pyrgos-ai/doug-harness`.

## Read in this order

1. Read [`handoffs/HANDOFF-CROSS-DEVICE-HARNESS-2026-07-31.md`](handoffs/HANDOFF-CROSS-DEVICE-HARNESS-2026-07-31.md).
2. Load [`handoffs/CROSS-DEVICE-CONTEXT.json`](handoffs/CROSS-DEVICE-CONTEXT.json) when an agent needs machine-readable paths, commits, hashes, Docket IDs, or pending boundaries.
3. Authenticate GitHub under the interactive user account and verify `gh auth status`.
4. Clone or download the authenticated ZIP of `pyrgos-ai/doug-harness`.
5. Follow `ONBOARDING/START-HERE.md` in that harness repository.

## State-file warning

The current default-branch `TASK.md`, `STATUS.md`, and `MAP.md` predate the repository-first cutover. They still contain retired Drive Capsule, Password Manager, 3/4/3-retention, and 160-card blocker claims.

Pause before executing those claims. The separately reviewed state-only recovery patch is:

`handoffs/patches/general-ai-state-reconciliation-2026-07-31.patch.zip`

Its digest and application boundary are recorded in the cross-device handoff and JSON manifest. Apply it through a separately owned review branch, then run `VerifyProject`.

## Current ownership boundary

Another agent owns active main-harness implementation. This repository preserves the paused harness diff as a portable patch without publishing or merging it into the harness:

`handoffs/patches/agent-harness-closeout-2026-07-31.patch.zip`

Review that patch against the active harness owner's work before applying any hunk.

## Cross-device surfaces

- GitHub: `https://github.com/douglaspmcgowan/general-ai`
- Docket: `https://vault-review-mobile.vercel.app`
- Obsidian relative folder: `Claude/Engineer`
- External project-data transport on the source computer: `C:\Users\dougl\My Drive\Project Data`

The handoff and six supporting briefs are published in Docket. The handoff and four research documents are committed to public GitHub. The active Obsidian vault contains the handoff, cloud plan, four research documents, and the separate `Codex Harness Slowness Diagnosis.md`. The JSON manifest enumerates each surface explicitly because the Docket retrospective and vault diagnosis are different documents.

No credential values belong in this repository. The Bitwarden bootstrap variable name is `BITWARDEN_SECRETS_MANAGER_ACCESS_TOKEN`; the harness onboarding process transfers its value to Windows Credential Manager and removes matching environment copies.

# Start here on another computer

Last verified: 2026-07-31

This repository carries the coordination history, research, and recovery context for the cross-agent harness. The canonical executable harness lives in the private GitHub repository `pyrgos-ai/doug-harness`.

## Read in this order

1. Read [`CROSS-DEVICE-ACCESS.md`](CROSS-DEVICE-ACCESS.md).
2. Load [`PORTABILITY-INVENTORY.yaml`](PORTABILITY-INVENTORY.yaml) for guarded per-project actions.
3. Load [`handoffs/CROSS-DEVICE-CONTEXT.json`](handoffs/CROSS-DEVICE-CONTEXT.json) when an agent needs machine-readable paths, commits, hashes, Docket IDs, or pending boundaries.
4. Authenticate GitHub under the interactive user account and verify `gh auth status`.
5. Clone or download the authenticated ZIP of `pyrgos-ai/doug-harness`.
6. Follow `ONBOARDING/START-HERE.md` in that harness repository.

## State authority

`TASK.md`, `STATUS.md`, and `MAP.md` are the current repository-first coordination authority. They retain Drive Capsule references only as explicit retirement history and preserve Google Drive solely for declared `My Drive\Project Data` artifacts.

The older reviewed state patch remains under `handoffs/patches` as recovery evidence. Do not reapply it after the current state-reconciliation merge.

## Current ownership boundary

Another agent owns active main-harness implementation. This repository preserves an older paused harness diff only as superseded recovery evidence:

`handoffs/patches/agent-harness-closeout-2026-07-31.patch.zip`

Do not apply that archive. Inspect current `pyrgos-ai/doug-harness` `master`, its task state, and the active owner branch before proposing any harness change.

## Cross-device surfaces

- GitHub: `https://github.com/douglaspmcgowan/general-ai`
- Docket: `https://vault-review-mobile.vercel.app`
- Obsidian relative folder: `Claude/Engineer`
- External project-data transport on the source computer: `C:\Users\dougl\My Drive\Project Data`

The current Docket store contains 174 cards, including the stable access-index, completion-audit, and Headless cards. GitHub and the active Obsidian vault carry the current access index and its linked research; the JSON manifest enumerates the relevant paths and stable card IDs.

No credential values belong in this repository. The Bitwarden bootstrap variable name is `BITWARDEN_SECRETS_MANAGER_ACCESS_TOKEN`; the harness onboarding process transfers its value to Windows Credential Manager and removes matching environment copies.

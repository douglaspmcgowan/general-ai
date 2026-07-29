# Task

## Goal

Reconcile the final harness/Capsule/Docket documentation, then complete the remaining human-gated credential setup.

## Active

No agent-owned work is active.

## Queue

No unattended agent work remains.

## Blocked

- [!] Complete Bitwarden Password Manager CLI authentication in one interactive PowerShell session, including the master password and emailed new-device OTP; create and fill the planned Hidden fields; bind the non-secret Docket item ID in the full-tuple broker policy; configure the reviewed bearer value in Vercel as `APP_SECRET` and the separate `BLOB_READ_WRITE_TOKEN`; then publish the 160 eligible Docket cards and verify returned IDs. Evidence: `bw status` reports unlocked, every planned field exists without exposing values, and the authenticated Docket cloud sync succeeds.

## Needs decision

- [?] Optional: approve another elevated RAMMap UAC capture and a controlled WSAIFabric stop/restart A/B test if further attribution of the roughly 4 GiB kernel pools is useful. The prior elevated snapshot attempt produced no file. Evidence: preserve a valid RAMMap snapshot and compare physical/pool counters before and after the controlled test.

## Completed

- [x] Reconciled the canonical human guide and HTML mirror with the verified final snapshot, completed three-dispatcher/task-state rollout, merged Docket implementation, and exact remaining credential gates; changed Capsule onboarding and verification commands to resolve the actual open `My Drive\Capsule` folder; passed the harness, Capsule lifecycle, portability, project, and whitespace verifiers.
- [x] Installed the canonical shared harness at `C:\Users\dougl\.agents` with global `AGENTS.md`, `MAP.md`, `DESIGN.md`, `MEMORY.md`, product adapters, baseline skills, and one manager.
- [x] Consolidated live hook wiring into `security-dispatch.js`, `task-state-dispatch.js`, and `continue-dispatch.js`; the installed hook verifier passes.
- [x] Merged private harness pull requests #2 through #6 into `master`; PR #6 merged at `0d19eeca14bc0313705cf57390e18c0f822e75a5`; and fast-forwarded `C:\Users\dougl\projects\agent-harness`.
- [x] Fixed the Capsule lifecycle in harness commit `6840e6a`: packaged `tools\Refresh-Capsule.ps1`, resolved deployed root assets, and preserved same-path account-map contents; the assembled second-snapshot sync regression passes.
- [x] Installed the corrected shared harness globally and passed `VerifyGlobal`; the active Codex `AGENTS.md` SHA-256 remained `F26ABEA21241FC2BEC069D0EC99E933EAE0BC04F2BBDB4C0354C22B137996E37`.
- [x] Merged Docket pull request #1 at `2489f7a32617eec287cf36d9a521636cc38b01f9`; personal cards now use the authenticated cloud-sync policy.
- [x] Merged Docket pull request #2 at `32d2346` and status commit `9aa727a`; archived `setup-handoff--general-claude-github` and `setup-handoff--google-drive-preferences` locally after backing up `C:\Users\dougl\.docket-local\_backups\before-stale-archive-20260729`, leaving 160 unresolved cards eligible for outbound publication.
- [x] Repointed the redline, drive-organizer, and contact-form-caller Claude launch entries to canonical project roots in commit `52a7fd1`; the JSON parsed and all three PID-scoped HTTP smoke tests returned 200.
- [x] Verified signed Microsoft RAMMap v1.63 at `C:\Users\dougl\Tools\Sysinternals\RAMMap\RAMMap64.exe`; the captured pressure sample showed 95% physical-memory use and 4.02 GiB combined paged/nonpaged pools, while the elevated snapshot attempt produced no file.
- [x] Verified GitHub CLI authentication through the interactive Windows keyring and completed the authorized repository publication.
- [x] Consolidated the human guide at `C:\Users\dougl\.agents\human-readable\README.md` with its matching HTML mirror.
- [x] Refreshed and verified the canonical Capsule at `C:\Users\dougl\My Drive\Capsule` to snapshot `20260729-081324` with 34,062 integrity records; the packaged refresh tool is present and recorded, the account map survived same-path sync, and a roughly 743.55 MB Gitleaks scan found no leaks.
- [x] Confirmed Google Drive is running and the direct local Capsule path and selected-snapshot manifest are accessible.
- [x] Migrated canonical `C:\Users\dougl\projects\general-ai` to the v3 project contract and one `TASK.md`; verified legacy sources remain recoverable under `.agents\archive`.

## Verification

- Project: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.agents\tools\Manage-Harness.ps1" -Action VerifyProject -Repository .`
- Whitespace: `git diff --check`
- Remaining Bitwarden evidence must be collected in the same interactive PowerShell process that performs login and unlock.
- Legacy migration evidence: `.agents/archive/task-state-migration/`, `.agents/archive/pre-general-ai-reconcile/`, and `.agents/archive/final-task-reconcile/`.

# Task

## Goal

Reconcile the final harness/Capsule/Docket documentation, then complete the remaining human-gated credential setup.

## Active

No agent-owned work is active.

## Queue

No unattended agent work remains.

## Blocked

- [!] Complete Bitwarden Password Manager CLI authentication in one interactive PowerShell session, including the master password and emailed new-device OTP; run the scaffold creator; then fill the empty Hidden values. Evidence: `bw status` reports unlocked and the planned Login items contain every required field without exposing values.
- [!] After the Docket fields are filled, bind the non-secret Bitwarden item ID in the full-tuple broker policy, configure the reviewed bearer value in Vercel as `APP_SECRET`, retain `BLOB_READ_WRITE_TOKEN` as the separate storage credential, publish the queued personal decisions, and verify returned card IDs. Evidence: Docket self-tests and cloud sync pass without exposing credential values.

## Needs decision

- [?] Optional: approve an elevated Microsoft RAMMap capture if kernel-pool attribution is still useful. Evidence: save the Use Counts summary without capturing credential values.

## Completed

- [x] Reconciled the canonical human guide and HTML mirror with the verified final snapshot, completed three-dispatcher/task-state rollout, merged Docket implementation, and exact remaining credential gates; changed Capsule onboarding and verification commands to resolve the actual open `My Drive\Capsule` folder; passed the harness, Capsule lifecycle, portability, project, and whitespace verifiers.
- [x] Installed the canonical shared harness at `C:\Users\dougl\.agents` with global `AGENTS.md`, `MAP.md`, `DESIGN.md`, `MEMORY.md`, product adapters, baseline skills, and one manager.
- [x] Consolidated live hook wiring into `security-dispatch.js`, `task-state-dispatch.js`, and `continue-dispatch.js`; the installed hook verifier passes.
- [x] Merged private harness pull requests #2 through #6 into `master`; PR #6 merged at `0d19eeca14bc0313705cf57390e18c0f822e75a5`; and fast-forwarded `C:\Users\dougl\projects\agent-harness`.
- [x] Merged Docket pull request #1 at `2489f7a32617eec287cf36d9a521636cc38b01f9`; personal cards now use the authenticated cloud-sync policy.
- [x] Verified GitHub CLI authentication through the interactive Windows keyring and completed the authorized repository publication.
- [x] Consolidated the human guide at `C:\Users\dougl\.agents\human-readable\README.md` with its matching HTML mirror.
- [x] Refreshed the canonical Capsule at `C:\Users\dougl\My Drive\Capsule` to snapshot `20260729-071541` with 28,462 packaged files; `README.md` is the current receiving-computer entry and `AGENT-START.md` remains a compatibility pointer.
- [x] Launched Google Drive and verified the direct local Capsule path and selected-snapshot manifest.
- [x] Migrated canonical `C:\Users\dougl\projects\general-ai` to the v3 project contract and one `TASK.md`; verified legacy sources remain recoverable under `.agents\archive`.

## Verification

- Project: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.agents\tools\Manage-Harness.ps1" -Action VerifyProject -Repository .`
- Whitespace: `git diff --check`
- Remaining Bitwarden evidence must be collected in the same interactive PowerShell process that performs login and unlock.
- Legacy migration evidence: `.agents/archive/task-state-migration/`, `.agents/archive/pre-general-ai-reconcile/`, and `.agents/archive/final-task-reconcile/`.

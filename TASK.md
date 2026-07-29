# Task

## Goal

Complete the two remaining human-gated setup actions after the verified cross-agent harness rollout.

## Active

No agent-owned work is active.

## Queue

No unattended agent work remains.

## Blocked

- [!] Complete Bitwarden Password Manager CLI authentication in one interactive PowerShell session, including the master password and emailed new-device OTP; run the scaffold creator; then fill the empty Hidden values. Evidence: `bw status` reports unlocked and the planned Login items contain every required field without exposing values.

## Needs decision

- [?] Optional: approve an elevated Microsoft RAMMap capture if kernel-pool attribution is still useful. Evidence: save the Use Counts summary without capturing credential values.

## Completed

- [x] Installed the canonical shared harness at `C:\Users\dougl\.agents` with global `AGENTS.md`, `MAP.md`, `DESIGN.md`, `MEMORY.md`, product adapters, baseline skills, and one manager.
- [x] Consolidated live hook wiring into `security-dispatch.js`, `task-state-dispatch.js`, and `continue-dispatch.js`; the installed hook verifier passes.
- [x] Merged private harness pull requests #2, #3, #4, and #5 into `master` and fast-forwarded `C:\Users\dougl\projects\agent-harness`.
- [x] Merged Docket pull request #1 at `2489f7a32617eec287cf36d9a521636cc38b01f9`; personal cards now use the authenticated cloud-sync policy.
- [x] Verified GitHub CLI authentication through the interactive Windows keyring and completed the authorized repository publication.
- [x] Consolidated the human guide at `C:\Users\dougl\.agents\human-readable\README.md` with its matching HTML mirror.
- [x] Refreshed the canonical Capsule at `C:\Users\dougl\My Drive\Capsule` to snapshot `20260729-065807` and retained `AGENT-START.md` as the receiving-computer entry.
- [x] Launched Google Drive and verified the direct local Capsule path and selected-snapshot manifest.
- [x] Migrated canonical `C:\Users\dougl\projects\general-ai` to the v3 project contract and one `TASK.md`; verified legacy sources remain recoverable under `.agents\archive`.

## Verification

- Project: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.agents\tools\Manage-Harness.ps1" -Action VerifyProject -Repository .`
- Whitespace: `git diff --check`
- Remaining Bitwarden evidence must be collected in the same interactive PowerShell process that performs login and unlock.
- Legacy migration evidence: `.agents/archive/task-state-migration/`, `.agents/archive/pre-general-ai-reconcile/`, and `.agents/archive/final-task-reconcile/`.

# Task

## Goal

Implement the approved harness-only Capsule and per-project synchronization architecture, preserve every unresolved data boundary, and complete the remaining Docket credential setup.

## Active

- [~] Implement and verify topic-discovered repository setup plus data-manifest transport, remove per-project workspace payloads from Capsule, then refresh the harness-only Capsule while preserving the active Codex rules hash.

## Queue

- [x] Merge and install the transactional Capsule pruning fix; verify junction, rollback, concurrent-refresh, exact-one, Gitleaks, and isolated-install regressions.
- [x] Reduce the live My Drive Capsule to one verified workspace payload and remove the generated old-payload quarantine.
- [x] Make `agent-harness\.agents\capsule` the sole source authority and remove the stale Git-recoverable `general-ai\capsule` duplicate.
- [x] Update the Docket protocol, Capsule source-tool resolution, and consolidated `TASK.md` verifier through independently tested commits.
- [x] Add bounded retry for transient recursive-delete races and integrate the long-path Capsule quarantine cleanup fix at harness commit `c67792d`.
- [x] Verify OneDrive application retirement: the official `C:\Windows\System32\OneDriveSetup.exe /uninstall` exited `0`, followed by zero running processes, uninstall registrations, startup entry, scheduled tasks, and Winget packages. The Windows setup stub remains present by design.
- [x] Complete the corrected interactive Bitwarden run, create all 8 scaffold receipt items, and leave the CLI locked.
- [x] Push Docket README commit `e89150e`.
- [x] Push harness commits `c67792d`, `64bd8cd`, and `64aea3d`; install the resulting global harness; pass `VerifyGlobal`; and preserve the active Codex rules hash.
- [~] Change active retention documentation from 14/8/12 to 3 daily, 4 weekly, and 3 month-end snapshots; retain milestones, latest disposable-restore evidence, dry-run review, and failure pauses.
- [~] Redefine Capsule as the shared global harness/bootstrap/repository-inventory package and remove its current per-project workspace payload.
- [ ] Implement and verify the project-sync manager using GitHub CLI account-and-topic discovery plus local path conventions. Avoid a static `repositories.json`; add an exception mechanism only when repository evidence requires one.
- [ ] Publish or connect remotes for the 11 dirty repositories without origins after preserving their exact working state; the other 16 of 27 Git repositories already have origins.
- [ ] Implement excluded/live mutable-data transport through the existing `data-manifest.yaml` extension point in 25 of 27 repositories and add the missing two manifests.
- [ ] Define explicit handling for the three non-repository project-root entries: `.obsidian` configuration, the `flight-tracker` container, and the `general-claude-incomplete` archive.
- [ ] Reconcile the human guide, HTML mirror, Capsule docs, setup stamp, project state, and exact final deployment evidence after the retention and OneDrive language lands.
- [ ] Keep the current 6,043-record Drive Capsule frozen during implementation; refresh it only after the harness-only package and project-sync/data-transport path pass end-to-end verification.

## Blocked

- [!] Fill the created Bitwarden Login items with the planned Hidden values, bind the non-secret Docket item ID in the full-tuple broker policy, configure the reviewed bearer value in Vercel as `APP_SECRET` and the separate `BLOB_READ_WRITE_TOKEN`, then publish the 160 eligible Docket cards and verify returned IDs. Keep the CLI locked outside the same interactive session used for credential work.

## Needs decision

- [?] Approve the final topic/account/local-convention selector and any proven exception cases before remote publication and data-transport implementation are declared complete.
- [?] Decide the exact retention or removal boundary for `C:\Users\dougl\OneDrive`, currently preserved at 141,008 files and 5,796,741,017 logical bytes. Account for the registered 168 Audit and Berkeley House legacy worktrees, the metadata-only Desktop comparison with 1 candidate file, Documents with 140,440 candidate files and 5,413,453,487 bytes, fully skipped Pictures, and Attachments with no `C:\Users\dougl\Attachments` counterpart. Keep the tree untouched until that decision is recorded and verified.
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
- Remaining Bitwarden value-entry and Docket publication evidence must be collected without exposing values; the CLI should return to locked state afterward.
- Legacy migration evidence: `.agents/archive/task-state-migration/`, `.agents/archive/pre-general-ai-reconcile/`, and `.agents/archive/final-task-reconcile/`.

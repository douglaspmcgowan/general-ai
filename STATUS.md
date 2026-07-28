# Status

## Portable workspace recovery — 2026-07-27

- `Nightly Agent Backups` runs daily at 2:00 AM. Its corrected installed path now scans every repository, proves each offline bundle through a clean clone, and falls back to a Gitleaks-clean current-tree bundle for partial object stores.
- The scheduler-completed snapshot selected by `Workspace\Recovery\latest.json` covers 25 repositories, including canonical `general-ai`, plus approved project data, consistent SQLite backup, product configuration, handoffs, and Quick Access.
- The full-tuple Password Manager broker is installed and fail-closed with an empty production policy until the Docket Bitwarden item exists.
- Desktop, Documents, and Pictures point to local Windows folders. Quick Access has 13 curated valid pins and no retired OneDrive or `G:\My Drive` pins.
- `C:\Users\dougl\Documents\Capsule` is built from the scheduler-selected latest snapshot; Gitleaks scanned about 114 MB with no findings and its SHA-256 integrity verifier passes.
- A disposable assembled Capsule restore recovered all 25 projects, `general-ai`, approved application data, UTF-8 filenames, and the portable shared harness without package installation, account login, or Quick Access mutation.
- Six repositories use clean current-tree bundles because of partial local object stores or older-history findings. Three still-flagged tracked files were omitted across Berkeley House, Fellowship Tracker, and Legal Solutions Website; GitHub supplies those files after login.
- Capsule now contains an explicit agent entry point, exact Google Drive retrieval instructions, a complete ongoing-sync and excluded-data map, documented retention status, expanded Bitwarden responsibilities, and contextual account prompts.
- Google Drive's live root-preference database lists `Documents` as an active selected folder. On another computer, Capsule is retrieved through `drive.google.com/drive/computers`, usually under `SEEK_TO_SERVE\Documents\Capsule`.
- Automatic snapshot deletion remains disabled. The documented retention recommendation is 14 daily, 8 weekly, and 12 month-end snapshots plus labeled milestones and the newest fully restored snapshot.

- The shared harness is installed live and published to its private GitHub authority. GitHub CLI authorization is stored in the desktop user's Windows keyring; a failure under `CodexSandboxOnline` does not establish that the desktop login is invalid.
- Docket's loopback-authentication repair is published on private GitHub at commit `33b00f4`.
- The GitHub app connector and GitHub CLI work for existing repositories. Authentication must be checked under the Windows identity that owns the keyring before any browser-login flow is started.
- Docket starts through the limited-privilege `DocketDaemon` task. The repaired local API passes loopback integration tests without a persistent passcode.
- The 94-file harness verifier and Gitleaks pass. The value-free recovery pointer is remote-verified.
- Ten repositories formerly under OneDrive have exact verified copies under `C:\Users\dougl\projects`.
- `C:\Users\dougl\projects\general-ai` is the clean canonical coordination repository. `general-claude` remains the session-owned rollback copy.
- The Flight Tracker coordination folder has an exact verified lowercase copy.
- The 168 main repository is canonical at `C:\Users\dougl\projects\168-audit`; its replacement worktree is verified under `C:\Users\dougl\Worktrees`.
- Berkeley's published completion commit has a verified replacement worktree under `C:\Users\dougl\Worktrees`.
- The old worktrees remain registered rollback copies because the active workspace ACL denies directory deletion.
- Google Drive reports up to date after Douglas updated its folder selection. Capsule and Agent Backups remain independently verifiable local folders.
- OneDrive is uninstalled. Its old data tree remains the rollback authority during active-path cutover.
- A receiving computer that already has OneDrive keeps it installed and unchanged during Capsule staging. The agent inventories known-folder mappings, unique files, collisions, and Quick Access before proposing any migration.
- Missing personal Desktop, non-General-Claude Documents, Pictures, and Attachments files have additive copies in the normal local Windows folders; existing destination files were preserved.
- Bitwarden Password Manager CLI and the full-tuple broker are installed and tested. Production tuples remain empty until Douglas creates the named Password Manager items and hidden fields.
- The local Docket contains 162 cards: 157 Skills Docket cards and five setup handoffs. Cloud publication remains pending the Docket secret handoff.
- The IDETC archive is preserved under `C:\Users\dougl\Data\Projects\idetc-writing-ide\inputs` with a matching SHA-256 copy check.

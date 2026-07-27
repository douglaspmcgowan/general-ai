# Handoff — portable agent workspace recovery

## Open this on another computer

1. Install Git, PowerShell, Google Drive for desktop, Bitwarden, Codex, Claude, and Cursor.
2. Sign into Google Drive and wait for `Documents\Agent Backups` to finish syncing.
3. Open PowerShell and run:

   ```powershell
   C:\Users\dougl\Documents\Agent Backups\Tools\Restore-AgentWorkspace.cmd -BackupRoot "C:\Users\dougl\Documents\Agent Backups\Workspace"
   ```

4. Clone the private shared harness if the restore report requests it, then run its setup verifier.
5. Sign into Bitwarden and unlock it interactively when a project needs credentials. Credential values remain outside the backup.
6. Open each project under `C:\Users\dougl\projects\<project>` and read `AGENTS.md`, `CURRENT-TASK.md`, `STATUS.md`, the latest `LOG.md` entries, and `WORK_QUEUE.md`.

## What comes back

- Git-backed projects at the recorded branch and commit.
- A local Git bundle for committed repositories without remotes.
- A reviewed file snapshot for repositories without a first commit.
- Gitleaks-clean staged, working-tree, and untracked state.
- Approved material from `C:\Users\dougl\Data\Projects`.
- Transactionally consistent SQLite snapshots, including Docket.
- Per-project handoffs.
- Selected value-safe Claude and Cursor configuration.
- The portable Quick Access folder list.

Claude, Codex, and Cursor share the private harness authority and each repository's committed operating documents. Authentication stores, product sessions, caches, `.env` files, browser profiles, restricted data, and credential values remain excluded.

## File Explorer recovery

Windows known folders now resolve to `C:\Users\dougl\Desktop`, `C:\Users\dougl\Documents`, and `C:\Users\dougl\Pictures`.

Quick Access uses a deterministic 13-folder set centered on `projects`, the local known folders, the live `C:\Users\dougl\My Drive` root, the Berkeley research parents, and Sound Recordings. The repair removes retired OneDrive and `G:\My Drive` pins.

## Nightly task

Windows Task Scheduler runs `Nightly Agent Backups` daily at 2:00 AM while Douglas is logged in. The latest verified run completed with result `0`. Each successful run writes a timestamped snapshot and advances `Workspace\Recovery\latest.json` only after Gitleaks passes.

## Secrets

The Password Manager broker admits a credential request only when the item, field, destination variable, executable, and complete argument list match one approved tuple. It strips `BW_SESSION` from the child and restores the parent environment. The production policy stays empty until the Docket item exists.

## Verified 2026-07-27

- Backup regression test passed.
- Restore regression test passed.
- Quick Access regression test passed.
- Full-tuple broker regression test passed.
- Scheduled task completed with result `0`.
- Disposable restore recovered Docket through its remote, general-claude through a Git bundle, anna-maria-mcgowan through a file snapshot, and project application data.
- Quick Access contains 13 curated valid paths with zero retired OneDrive or `G:\My Drive` pins.

# Portable agent workspace recovery

The recovery layer combines four authorities:

1. Git remotes provide repository history.
2. Nightly Agent Backups provide reviewed application data, transactionally consistent SQLite snapshots, per-project handoffs, and Gitleaks-clean uncommitted work.
3. The private shared-harness repository provides Claude, Codex, and Cursor operating context.
4. Bitwarden provides credential values after an interactive unlock on the receiving computer.

Run `Backup-AgentWorkspace.cmd` nightly through the `Nightly Agent Backups` scheduled task. On another computer, install Git, PowerShell, Google Drive, and the three agent applications; sync `Documents\Agent Backups`; then run:

```powershell
C:\Users\dougl\Documents\Agent Backups\Tools\Restore-AgentWorkspace.cmd -BackupRoot "C:\Users\dougl\Documents\Agent Backups\Workspace"
```

The restore clones every recorded project, reapplies any reviewed uncommitted snapshot, restores project application data and selected value-safe product configuration, and repairs Quick Access folder pins. Product sessions, caches, authentication stores, `.env` files, credential exports, and restricted data remain excluded.

To repair File Explorer pins on the current computer without restoring projects, run `Repair-QuickAccess.cmd` with the latest snapshot's `Recovery\quick-access.json`.

Harness test-output data roots are excluded because their authoritative content already lives in the private harness repository. The backup includes material project data under `Data\Projects`, with consistent SQLite snapshots handled separately.

The Password Manager broker accepts one policy record only when the item, field, destination environment variable, executable, and full argument list all match. It rejects mismatches before contacting Bitwarden, removes `BW_SESSION` from the child, and restores the parent environment afterward.

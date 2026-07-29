# Portable agent workspace recovery

The recovery layer combines four authorities:

1. Git remotes provide published repository history after GitHub login.
2. Nightly Agent Backups provide offline Git bundles for every repository with a commit, reviewed application data, transactionally consistent SQLite snapshots, per-project handoffs, and Gitleaks-clean uncommitted work.
3. The private shared-harness repository provides Claude, Codex, and Cursor operating context.
4. Bitwarden provides credential values after an interactive unlock on the receiving computer.

Run `Backup-AgentWorkspace.cmd` nightly through the `Nightly Agent Backups` scheduled task. On another computer, install Git, PowerShell, Google Drive, and the three agent applications; sync `Documents\Agent Backups`; then run:

```powershell
C:\Users\dougl\Documents\Agent Backups\Tools\Restore-AgentWorkspace.cmd -BackupRoot "C:\Users\dougl\Documents\Agent Backups\Workspace"
```

The restore prefers each captured offline bundle, reapplies any reviewed uncommitted snapshot, restores project application data and selected value-safe product configuration, and repairs Quick Access folder pins. For a repository with a recorded remote, the offline bundle remains attached as `capsule` and the recorded GitHub URL becomes `origin`. Every history bundle must clone successfully into an empty temporary repository during backup. An incomplete object store or older-history Gitleaks finding triggers a clean current-tree bundle. Current-tree files still flagged by that scan are excluded, the omission count is recorded, and the reduced bundle must pass Gitleaks again. Published history and omitted tracked material remain available from GitHub. Product sessions, caches, authentication stores, `.env` files, credential exports, and restricted data remain excluded.

`C:\Users\dougl\projects\agent-harness\.agents\capsule` owns the versioned Capsule tools and instructions. Those tools generate `C:\Users\dougl\My Drive\Capsule`, which packages one verified snapshot with the portable harness, application list, safe account identifiers, Bitwarden procedure, setup map, restore tools, and SHA-256 integrity records. On a receiving computer, copy the complete synchronized Capsule to a local staging folder, run `tools\Verify-Capsule.cmd`, and then run `tools\Bootstrap-Capsule.cmd`.

The default backup excludes the retained `general-claude` rollback repository after the canonical rename to `general-ai`.

## Retained `general-claude` Git history

`general-claude-history.bundle` preserves every committed ref from `C:\Users\dougl\projects\general-claude` at source `master` commit `f8c1f39ed369d8694eb9f82c50f622883bf29a7e`. It was created with `git bundle create --all`, verified as complete, cloned into an empty temporary directory, checked with `git fsck --full`, and matched back to the source `master` SHA. The original repository remains the authority for its current uncommitted working-tree state.

Verify or restore it with:

```powershell
git bundle verify "C:\Users\dougl\projects\general-ai\recovery\general-claude-history.bundle"
git clone "C:\Users\dougl\projects\general-ai\recovery\general-claude-history.bundle" "C:\Users\dougl\projects\general-claude-restored"
```

To repair File Explorer pins on the current computer without restoring projects, run `Repair-QuickAccess.cmd` with the latest snapshot's `Recovery\quick-access.json`.

Harness test-output data roots are excluded because their authoritative content already lives in the private harness repository. The backup includes material project data under `Data\Projects`, with consistent SQLite snapshots handled separately.

The Password Manager broker accepts one policy record only when the item, field, destination environment variable, executable, and full argument list all match. It rejects mismatches before contacting Bitwarden, removes `BW_SESSION` from the child, and restores the parent environment afterward.

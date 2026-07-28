# Agent entry point

If you are an agent opening this Capsule on a receiving Windows computer, read and follow these files in order:

1. `START-HERE.md` — human prerequisites, bootstrap order, and stopping conditions.
2. `SYSTEM-MAP.md` — authorities, paths, data flows, and verification commands.
3. `DATA-SYNC-AND-RETENTION.md` — ongoing updates, excluded-data routes, and snapshot retention status.
4. `SECRETS-BITWARDEN.md` — Douglas/agent responsibility boundary and the approved secret-injection workflow.
5. `NEXT-STEPS.md` — the remaining human and agent actions on both computers.
6. `manifests\accounts.json` — value-safe sign-in identifiers and explanations.
7. `manifests\software.json` — expected applications and command-line tools.

## Agent rules

- Verify `manifests\integrity.json` before restoring anything.
- Never read, request, print, log, or write a password, key, token, session value, recovery code, or vault export.
- Ask Douglas to complete account-owner login, two-factor approval, vault unlock, and credential creation or rotation.
- Restore only into a clean receiving profile. The bootstrap refuses existing project and shared-harness destinations.
- Treat GitHub, Google Drive, and Bitwarden as ongoing authorities after installation. Treat the Capsule payload as a dated recovery snapshot.
- Preserve `capsule` as the offline Git remote and use `origin` for the recorded GitHub remote.
- If OneDrive exists on the receiving computer, leave it installed and unchanged. Inventory its selected folders, Windows known-folder mappings, unique files, and Quick Access targets before proposing any migration.
- Never uninstall, disconnect, reset, delete, move, or reconfigure OneDrive during Capsule bootstrap.
- Prefer the directly synced `My Drive\Capsule` source. This source computer uses `C:\Users\dougl\My Drive\Capsule`. On another computer, discover whether Google Drive mirrors `%USERPROFILE%\My Drive` or exposes My Drive through its mounted-drive shortcut.
- Stop when an integrity check, Gitleaks scan, repository verifier, or harness verifier fails.

## First commands

```powershell
& "$env:USERPROFILE\Documents\Capsule\tools\Verify-Capsule.ps1" `
  -CapsuleRoot "$env:USERPROFILE\Documents\Capsule"

& "$env:USERPROFILE\Documents\Capsule\tools\Bootstrap-Capsule.ps1" `
  -CapsuleRoot "$env:USERPROFILE\Documents\Capsule"
```

## Stale agent-process cleanup

After the harness is installed, inspect old helper trees with:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.agents\tools\Clear-StaleAgentProcesses.ps1"
```

The tool defaults to dry-run mode. It selects only old orphaned `node.exe -> cmd.exe -> node.exe` helper trees, excludes active ChatGPT, Codex, Cursor, and Claude trees, and revalidates immediately before termination. Install the four-times-daily guarded task with:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.agents\tools\Install-StaleAgentCleanupTask.ps1"
```

After bootstrap, continue from `C:\Users\<Windows-user>\projects\general-ai\AGENTS.md`.

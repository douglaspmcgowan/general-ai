# Remaining setup checklist

## Other computer

1. Open Google Drive and locate `My Drive\Capsule\AGENT-START.md`. If My Drive is mirrored into the user profile, the path is `%USERPROFILE%\My Drive\Capsule\AGENT-START.md`.
2. Copy Capsule to a separate local staging folder outside OneDrive.
3. Run `tools\Verify-Capsule.cmd` from the staging copy.
4. If bootstrap already ran, preserve the created projects and application data. Ask the agent to reconcile the existing installation from `AGENT-START.md`.
5. Leave OneDrive installed and unchanged until its account, selected folders, known-folder mappings, unique files, collisions, and Quick Access pins have been inventoried.

## Bitwarden

1. Sign into the intended Bitwarden account.
2. Enable two-step login and retain its recovery material separately.
3. Fill only safe login identifiers in `manifests\accounts.json`.
4. Create one Login item per project/environment that needs a credential.
5. Store each credential in a hidden custom field named for the destination environment variable.
6. Create the Docket production item with a hidden `REVIEW_SECRET` field.
7. Give the agent only the value-free item ID, item label, field name, destination variable, executable path, and exact argument list.
8. Run `bw login` once per computer. Run `$env:BW_SESSION = bw unlock --raw` only in the trusted PowerShell window used for a brokered command.
9. Have the agent register the exact tuple, run `Invoke-WithBitwardenItem.test.ps1`, then publish the queued Skills Docket cards through the broker.

## Source computer

1. Wait until Google Drive reports **Up to date** for `My Drive\Capsule`.
2. In Google Drive Preferences, review the remaining computer-backup selections: Desktop, Documents, and Downloads. The portable design uses curated My Drive exports, so stop syncing those broad roots only after confirming the My Drive Capsule upload and current local copies.
3. Start the next agent session from `C:\Users\dougl\projects\general-ai`.
4. From that fresh session, reverify the old rollback worktrees and `C:\Users\dougl\OneDrive` tree before any deletion. Both remain recovery authorities during this active rollback session.

## Already installed

- The guarded stale-agent-process cleanup runs at 01:15, 07:15, 13:15, and 19:15.
- The cleanup requires a three-hour minimum age, excludes active agent trees, revalidates before termination, and logs results under `%USERPROFILE%\.agents\logs`.
- Nightly Agent Backups run at 02:00.
- The private harness GitHub authority and offline Capsule harness payload are available.

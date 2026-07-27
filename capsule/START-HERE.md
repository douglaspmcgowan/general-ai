# Capsule

Capsule rebuilds Douglas's Claude, Codex, Cursor, shared harness, project repositories, portable application data, handoffs, and File Explorer Quick Access on another Windows computer.

## Before moving the folder

1. Double-click `tools\Set-CapsuleAccounts.cmd`.
2. Enter only the account identifiers you use for Google, Bitwarden, GitHub, OpenAI, Anthropic, and Cursor.
3. Leave passwords, keys, tokens, session data, and recovery codes in Bitwarden.
4. Double-click `tools\Refresh-Integrity.cmd`.
5. Run `tools\Verify-Capsule.cmd`.
6. Copy the entire `Capsule` folder to the other computer.

## Rebuild a new computer

1. Sign into Windows with the intended Windows account.
2. Copy `Capsule` into your local `Documents` folder.
3. Double-click `tools\Bootstrap-Capsule.cmd`.
4. Sign into each application with the identifiers listed in `manifests\accounts.json`.
5. Unlock Bitwarden and follow `SECRETS-BITWARDEN.md`.
6. Open `C:\Users\<you>\projects\general-ai\general-ai.code-workspace`.
7. Run the project and harness verification commands shown in `SYSTEM-MAP.md`.

The bootstrap refuses to overwrite an existing project or shared-harness folder. Use it on a clean receiving profile.

## What is inside

- `payload\workspace\<snapshot>`: every project, offline Git bundles, uncommitted changes, approved app configuration, project application data, handoffs, and Quick Access mappings.
- `payload\harness\.agents`: portable shared cross-agent harness.
- `manifests`: safe account identifiers, software list, selected snapshot, and SHA-256 integrity records.
- `tools`: verification, restore, and Quick Access scripts.

Read `SYSTEM-MAP.md` for the connections and `SECRETS-BITWARDEN.md` for credential setup.

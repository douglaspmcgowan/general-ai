# Capsule

Capsule rebuilds Douglas's Claude, Codex, Cursor, shared harness, project repositories, portable application data, handoffs, and File Explorer Quick Access on another Windows computer.

## If an agent opened this folder

Read `AGENT-START.md` first. It contains the required reading order, safety boundary, commands, and stopping conditions.

## Before moving the folder

1. Double-click `tools\Set-CapsuleAccounts.cmd`.
2. Enter the email, username, or SSO identity described by each prompt. Examples and where-to-find guidance appear in the prompt and in `manifests\accounts.json`.
3. Leave passwords, keys, tokens, session data, and recovery codes in Bitwarden.
4. Double-click `tools\Refresh-Integrity.cmd`.
5. Run `tools\Verify-Capsule.cmd`.
6. Copy the entire `Capsule` folder to the other computer.

## Rebuild a new computer

1. Sign into Windows with the intended Windows account.
2. Open <https://drive.google.com/drive/computers> with the same Google account.
3. Open this source computer's entry, usually `SEEK_TO_SERVE`, then open `Documents\Capsule`.
4. If OneDrive is installed, leave it unchanged.
5. Download the entire folder to a new local staging path outside OneDrive, such as `C:\Users\<you>\Capsule`.
6. Run `tools\Verify-Capsule.cmd`.
7. Continue only after verification reports `PASS`.
8. Double-click `tools\Bootstrap-Capsule.cmd`.
9. Sign into each application with the identifiers listed in `manifests\accounts.json`.
10. Unlock Bitwarden and follow `SECRETS-BITWARDEN.md`.
11. Open `C:\Users\<you>\projects\general-ai\general-ai.code-workspace`.
12. Run the project and harness verification commands shown in `SYSTEM-MAP.md`.

### OneDrive on the receiving computer

Capsule bootstrap leaves OneDrive alone. The receiving agent must inventory OneDrive's folder selection, Windows Desktop/Documents/Pictures mappings, unique files, and Quick Access targets before any migration proposal. OneDrive removal or reconfiguration requires a separate reviewed task after additive copies and comparisons prove that no unique data will be lost.

Bundle-restored repositories keep the offline source as the `capsule` remote and receive the recorded GitHub URL as `origin`. After `gh auth login`, refresh any project's published history with:

```powershell
git -C "$env:USERPROFILE\projects\<project-name>" fetch origin
```

A restored `RECOVERY-OMISSIONS.md` marks a clean current-tree bundle that excluded Gitleaks-flagged tracked files. Fetch `origin` before using that project.

The bootstrap refuses to overwrite an existing project or shared-harness folder. Use it on a clean receiving profile.

## What is inside

- `payload\workspace\<snapshot>`: every project, offline Git bundles, uncommitted changes, approved app configuration, project application data, handoffs, and Quick Access mappings.
- `payload\harness\.agents`: portable shared cross-agent harness.
- `manifests`: safe account identifiers, software list, selected snapshot, and SHA-256 integrity records.
- `tools`: verification, restore, and Quick Access scripts.

Read `SYSTEM-MAP.md` for the connections and `SECRETS-BITWARDEN.md` for credential setup.
Read `DATA-SYNC-AND-RETENTION.md` for ongoing cross-computer updates, excluded files, GitHub placement, and the proposed retention policy.

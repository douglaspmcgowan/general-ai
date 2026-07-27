# Portable harness system map

```mermaid
flowchart TD
    A["Accounts: Google, Bitwarden, GitHub, OpenAI, Anthropic, Cursor"] --> B["Installed desktop apps and CLIs"]
    B --> C["Shared harness: %USERPROFILE%\\.agents"]
    C --> D["Claude adapter"]
    C --> E["Codex adapter"]
    C --> F["Cursor adapter"]
    D --> G["Repository AGENTS.md contract"]
    E --> G
    F --> G
    G --> H["Projects under %USERPROFILE%\\projects"]
    H --> I["Project data under %USERPROFILE%\\Data\\Projects"]
    H --> J["Nightly Agent Backups"]
    I --> J
    C --> J
    J --> K["Capsule payload + integrity manifest"]
    K --> L["New Windows computer"]
    A --> L
```

## Authority map

| Concern | Authority | Portable representation |
|---|---|---|
| Credentials | Bitwarden Password Manager Free | Account identifier and broker tuple metadata |
| Repository history | GitHub remotes plus offline Git bundles | `payload\workspace\...\Handoffs` |
| Uncommitted work | Nightly Agent Backups | Binary Git patches and approved untracked files |
| Shared behavior | `%USERPROFILE%\.agents` | `payload\harness\.agents` |
| Claude behavior | Shared contract plus Claude adapter | Approved product configuration |
| Codex behavior | Shared contract plus repository `AGENTS.md` | Repository bundle and shared harness |
| Cursor behavior | Shared contract plus `.cursor\rules` | Repository bundle and approved product configuration |
| Runtime application data | `%USERPROFILE%\Data\Projects\<project>` | `payload\workspace\...\Application Data\Projects` |
| File Explorer pins | Portable path manifest | `Recovery\quick-access.json` |
| Google Drive documents | Google Drive account | Resynced from Google after login |
| Machine rebuild | Capsule | Bootstrap script plus SHA-256 integrity manifest |

## Startup chain inside a project

1. The application loads its local product adapter.
2. The adapter points to the shared cross-agent contract.
3. The repository's `AGENTS.md` supplies the portable project contract.
4. `CURRENT-TASK.md`, `WORK_QUEUE.md`, `STATUS.md`, and `LOG.md` restore task state.
5. `MAP.md`, `DESIGN.md`, `VERIFY.md`, manifests, and project skills provide navigation and validation.
6. Runtime data is resolved through `PROJECT_DATA_ROOT`.
7. Secret values enter only through the approved Bitwarden broker tuple.

## Verification on the receiving computer

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\Documents\Capsule\tools\Verify-Capsule.ps1" -CapsuleRoot "$env:USERPROFILE\Documents\Capsule"
& "$env:USERPROFILE\.agents\tools\Test-HarnessSetup.cmd"
& "$env:USERPROFILE\.agents\tools\Test-AgentProjectState.cmd" -Repository "$env:USERPROFILE\projects\general-ai"
git -C "$env:USERPROFILE\projects\general-ai" status --short --branch
```

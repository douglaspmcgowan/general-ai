# Secret manifest

Project: general-claude

This generated view contains variable names and operating metadata only. Secret values, vault session keys, recovery keys, and access tokens are forbidden.

| Variable | Purpose | Provider | Trust boundary | Owner | Rotation | Consumers | Status |
|---|---|---|---|---|---|---|---|
| `PROJECT_DATA_ROOT` | Resolve the coordination project's external local-data root. | local environment or workspace adapter | local Windows machine | Douglas | when the canonical data root moves |  | configured |

Canonical source: `secret-manifest.json`
Refresh: `C:\Users\dougl\.agents\tools\Update-SecretManifest.cmd -Repository <repo>`

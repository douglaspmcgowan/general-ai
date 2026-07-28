# Bitwarden setup for project and application secrets

## What this solves

The same Bitwarden account makes credential records available on both computers. Capsule carries value-free instructions and broker policy. Bitwarden carries the secret values in its encrypted vault. A project receives a value for one approved command invocation.

This guide uses Bitwarden Password Manager Free. It supports unlimited personal vault items and cross-device vault sync. Bitwarden Secrets Manager is a separate product and is unnecessary for this desktop workflow.

## Responsibility boundary

| Douglas does | An agent can do |
|---|---|
| Create the Bitwarden account and retain the master password | Install or verify the Bitwarden desktop app and CLI |
| Enable two-step login and retain recovery material separately | Create value-free item naming plans and policy templates |
| Sign in, approve a new device, and unlock the vault | Resolve exact executable and script paths |
| Create, rotate, and revoke provider credentials | Add an approved value-free full tuple to the broker policy |
| Enter credential values into hidden Bitwarden fields | Run broker and regression checks after Douglas unlocks the CLI |

## Current remaining setup

The Bitwarden CLI, Password Manager broker, fail-closed tuple policy, and regression test are installed. The production tuple policy remains empty until the required Bitwarden items exist.

Douglas completes these human-only steps:

1. Sign into the Bitwarden desktop app and web vault with the intended account.
2. Enable two-step login and store the recovery material separately.
3. Complete the safe account identifiers in `manifests\accounts.json`; enter login email addresses or SSO labels only.
4. Create one Bitwarden Login item per project/environment that needs a credential.
5. Add each credential as a hidden custom field whose name matches the required environment-variable name.
6. For Docket publication, create the planned production item and hidden `REVIEW_SECRET` field.
7. Give the agent only the non-secret item identifier, item label, field name, destination environment-variable name, executable path, and exact argument list.
8. Run `bw login` once on the receiving computer and unlock the CLI when a brokered command is ready.

The agent then registers the exact value-free tuple, runs `Invoke-WithBitwardenItem.test.ps1`, and exercises the approved command after the vault is unlocked. Passwords, tokens, recovery codes, and field values never enter Capsule, Git, chat, or the broker policy.
| Decide which command may use a production credential | Confirm that a child process receives the variable without creating a `.env` file |

The agent must never ask Douglas to paste a secret into chat, inspect vault item JSON, enumerate vault contents, or capture `BW_SESSION`. Douglas completes every screen or prompt that reveals a master password, two-factor code, recovery code, API key, token, or session value.

## The model

Use Bitwarden Password Manager Free as the credential authority. It supports unlimited vault items and sync across devices. Keep one vault item per project or application. Each secret gets a distinct hidden custom field.

Use this naming pattern:

- Item name: `project-name — environment`
- Custom field name: the exact environment variable, such as `OPENAI_API_KEY`
- Custom field type: Hidden
- URI or Notes: purpose and rotation owner; never paste the secret into Notes

Examples:

| Vault item | Hidden custom field | Delivered environment variable |
|---|---|---|
| `flight-finder — development` | `AMADEUS_API_KEY` | `AMADEUS_API_KEY` |
| `client-portal — production` | `DATABASE_URL` | `DATABASE_URL` |
| `shared — development` | `OPENAI_API_KEY` | `OPENAI_API_KEY` |

## What belongs in each place

| Place | Store here |
|---|---|
| Bitwarden item | Secret value, service username when useful, provider URI |
| Capsule account manifest | Email or username used to select the correct account |
| Broker policy | Item ID, field name, destination variable, executable, exact arguments |
| Project `.env.example` | Variable names and safe placeholders |
| GitHub Actions settings | Repository or environment secrets used by workflows |
| Deployment provider | Hosted development, preview, and production environment values |

Local Bitwarden unlock grants access only to the trusted local process. Hosted execution uses the secret store owned by that host.

## First computer: install and sign in

1. Create or open the Bitwarden account whose login email is recorded under `Bitwarden` in `Capsule\manifests\accounts.json`.
2. Install the Bitwarden desktop app and browser extension from Bitwarden's official download page.
3. Sign in and allow the initial vault synchronization to finish.
4. In the Bitwarden web vault, open **Settings → Security → Two-step login** and enable an available method.
5. Store the recovery code in a secure physical or separately encrypted recovery location outside Capsule and Git.
6. Install the command-line client from PowerShell:

```powershell
npm install -g @bitwarden/cli
bw login
```

7. Complete `bw login` yourself. This authenticates the computer.
8. Unlock the CLI for the current terminal:

```powershell
$env:BW_SESSION = bw unlock --raw
```

The session value lives only in that PowerShell process. Do not paste it into chat, a file, or a command transcript. Run `bw lock` and close the terminal when finished.

## Create each project item

In the Bitwarden desktop or web vault:

1. Select **New** → **Login**.
2. Set the item name to `project-name — environment`.
3. Add a **Hidden** custom field for every secret.
4. Use the exact environment-variable name as the field name.
5. Save and sync.
6. Copy the item's non-secret ID from the Bitwarden web vault item URL, or obtain only the ID in your own unlocked PowerShell window:

```powershell
bw get item "project-name — environment" | ConvertFrom-Json | Select-Object -ExpandProperty id
```

The item ID is value-safe configuration metadata. Share only that ID and the field name with the agent. Never save item JSON or a CLI export in the project or Capsule.

## What Douglas gives the agent

For each approved command, provide value-safe metadata only:

1. project name and environment, such as `flight-finder development`;
2. Bitwarden item ID;
3. exact hidden-field name, such as `AMADEUS_API_KEY`;
4. exact command to authorize;
5. whether the credential is development, preview, or production.

The agent resolves the executable path, writes the full tuple, runs the value-free regression test, and tells Douglas when to unlock Bitwarden. Douglas keeps the credential value private throughout.

## Register an exact broker tuple

The broker configuration records:

- Bitwarden item ID
- custom field name
- destination environment-variable name
- exact executable path
- allowed argument pattern
- project and environment

Open this value-free policy file:

```powershell
notepad.exe "$env:USERPROFILE\.agents\tools\credential-command-policy.json"
```

Add one object to its `commands` array:

```json
{
  "purpose": "Describe the one approved operation",
  "item": "BITWARDEN_ITEM_ID",
  "field": "OPENAI_API_KEY",
  "environmentVariable": "OPENAI_API_KEY",
  "executable": "C:\\Program Files\\nodejs\\node.exe",
  "argumentList": [
    "C:\\Users\\YOUR_WINDOWS_NAME\\projects\\PROJECT\\scripts\\approved-task.js"
  ]
}
```

Resolve the executable path before writing the tuple:

```powershell
(Get-Command node.exe -CommandType Application).Source
```

Keep item IDs, field names, executable paths, and arguments in the policy. Keep secret values in Bitwarden. Use separate tuples when one credential must launch two executables or environments. Keep production tuples narrowly scoped.

## Run a project with an injected secret

1. Open PowerShell.
2. Unlock Bitwarden:

```powershell
$env:BW_SESSION = bw unlock --raw
```

3. Invoke the approved tuple:

```powershell
& "$env:USERPROFILE\.agents\tools\Invoke-WithBitwardenItem.ps1" `
  -Item "BITWARDEN_ITEM_ID" `
  -Field "OPENAI_API_KEY" `
  -EnvironmentVariable "OPENAI_API_KEY" `
  -Executable "C:\Program Files\nodejs\node.exe" `
  -ArgumentList @("C:\Users\YOUR_WINDOWS_NAME\projects\PROJECT\scripts\approved-task.js")
```

4. Confirm the target command works without creating a `.env` file.
5. Close PowerShell when finished.

The broker should pass the value directly to the approved child process. It must avoid printing, logging, copying, or writing the value.

## Second computer

1. Run the Capsule bootstrap.
2. Open `manifests\accounts.json` and use the recorded Bitwarden email to select the same account.
3. Sign into Bitwarden and complete two-factor or trusted-device approval.
4. Wait for the desktop vault to synchronize; verify the expected item names visually.
5. Install the CLI if the bootstrap could not install it:

```powershell
npm install -g @bitwarden/cli
```

6. Run `bw login`, then unlock:

```powershell
$env:BW_SESSION = bw unlock --raw
```

7. Sync the vault:

```powershell
bw sync
```

8. Run the broker regression test:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.agents\tools\Invoke-WithBitwardenItem.test.ps1"
```

9. Test one development tuple for each project before using a production tuple.

Bitwarden pulls the current encrypted vault when a new device logs in. The explicit `bw sync` step ensures the CLI has the latest copy before a broker invocation.

## Rotation and removal

For rotation:

1. Rotate the credential at the service provider.
2. Replace the hidden custom-field value in the existing Bitwarden item.
3. Sync Bitwarden on both computers.
4. Run the project verifier through the same broker tuple.
5. Revoke the previous credential at the provider.

For removal, delete the broker tuple first, revoke the credential at the provider, and then delete or archive the Bitwarden field.

## Recovery and failure cases

- `Vault is locked`: run `$env:BW_SESSION = bw unlock --raw`.
- `Not logged in`: run `bw login`.
- `More than one item matches`: use the exact item ID in the tuple.
- `Field missing`: verify the custom field name and letter case.
- `Executable rejected`: register the exact executable and intended arguments.
- `Second PC has stale data`: run `bw sync`.
- `Account unavailable`: use Bitwarden's documented account-recovery path and the separately stored recovery materials.

Never put a vault export, master password, session value, API key, access token, browser cookie, or recovery key inside Capsule.

## Official references

- Bitwarden Password Manager plans: <https://bitwarden.com/help/password-manager-plans/>
- Bitwarden CLI: <https://bitwarden.com/help/cli/>
- Bitwarden data storage: <https://bitwarden.com/help/data-storage/>
- Vault synchronization: <https://bitwarden.com/help/vault-sync/>
- Two-step login: <https://bitwarden.com/help/setup-two-step-login/>

# Bitwarden setup for project and application secrets

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

## First computer: install and sign in

1. Install the Bitwarden desktop app and browser extension.
2. Sign into the same Bitwarden account listed in `Capsule\manifests\accounts.json`.
3. Enable two-step login in the Bitwarden web vault.
4. Keep the recovery code in a secure physical or separately encrypted recovery location.
5. Install the command-line client from PowerShell:

```powershell
npm install -g @bitwarden/cli
bw login
```

6. Unlock the CLI for the current terminal:

```powershell
$env:BW_SESSION = bw unlock --raw
```

The session value lives only in that PowerShell process. Close the terminal to discard it.

## Create each project item

In the Bitwarden desktop or web vault:

1. Select **New** → **Login**.
2. Set the item name to `project-name — environment`.
3. Add a **Hidden** custom field for every secret.
4. Use the exact environment-variable name as the field name.
5. Save and sync.
6. Copy the item's non-secret ID from the CLI:

```powershell
bw get item "project-name — environment" | ConvertFrom-Json | Select-Object -ExpandProperty id
```

The item ID is safe configuration metadata. Never save the item JSON or a CLI export in the project or Capsule.

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
2. Sign into the same Bitwarden account.
3. Install the CLI if the bootstrap could not install it:

```powershell
npm install -g @bitwarden/cli
```

4. Run `bw login`, then unlock:

```powershell
$env:BW_SESSION = bw unlock --raw
```

5. Sync the vault:

```powershell
bw sync
```

6. Run the broker regression test:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.agents\tools\Invoke-WithBitwardenItem.test.ps1"
```

7. Test one development tuple for each project before using a production tuple.

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
- Two-step login: <https://bitwarden.com/help/setup-two-step-login/>

# Cross-agent global harness, storage, and offsite backup recon — v4

Date: 2026-07-24

## Executive decision

Use a layered global harness:

1. Claude and Codex retain their own global settings, hooks, permissions, and session stores.
2. `C:\Users\dougl\.agents` holds the machine-neutral storage, credential, and worktree contract.
3. Each repository uses `AGENTS.md` as its canonical project contract.
4. Each repository gives Claude a minimal `CLAUDE.md` containing `@AGENTS.md`.
5. Cursor reads the repository `AGENTS.md`; `.cursor\rules` is reserved for genuinely Cursor-specific scoped behavior.

Use per-project data directories under `C:\Users\dougl\Data\Projects`. Small disposable cache may live in an ignored repository `.local` directory. The authoritative data remains outside the Git checkout.

Use Bitwarden for personal credentials. The official CLI is installed, while login and unlock remain a human-only action.

Use Google Drive as an offsite destination through versioned encrypted backup software. The leading fit is Arq 7 writing encrypted backup records to the existing Google Drive account, accompanied by a versioned external-drive plan. Backblaze Computer Backup is the simpler alternative when Google Drive quota is insufficient or Douglas prefers a dedicated backup service.

## Mirror: the actual setup

### Harness

- `C:\Users\dougl\.claude\CLAUDE.md` and `C:\Users\dougl\.codex\AGENTS.md` had the same 202-line structure before this work, with product names and paths adapted.
- The live Claude harness was refreshed on 2026-07-24. Its `settings.json` wires 23 PreToolUse hooks, eight PostToolUse hooks, and lifecycle hooks for prompts, starts, compaction, stopping, and notifications.
- The OneDrive `claude-global-config` repository remained at a June 13 commit and therefore was not used as the live source of truth.
- Claude Code, Codex, GitHub CLI, Git, and Cursor launchers are installed.
- The new shared contract now lives under `C:\Users\dougl\.agents`.

### Storage and backup

- OneDrive and Google Drive for desktop were running during the audit.
- No Backblaze, Arq, Restic, Rclone, Duplicati, or CrashPlan command was detected.
- Windows includes `wbadmin`; no configured backup job was established.
- `General Claude` occupied roughly 1.88 GiB during the latest measurement. Its file count changed during the audit, consistent with active project work.
- The BitLocker status check was denied because the available process lacked administrator rights. Encryption status remains unverified.
- GitHub remotes cover several repositories. GitHub does not cover ignored data, local databases, or uncommitted work.

### Credentials and secret detection

- Bitwarden CLI 2026.6.0 is now installed at `C:\Users\dougl\AppData\Roaming\npm\bw.cmd`.
- Its local configuration directory was initialized without login or vault access.
- The wrapper at `C:\Users\dougl\.agents\tools\Invoke-WithBitwardenItem.cmd` injects one selected field into one child process and refuses to run while the vault is locked.
- Gitleaks configuration and CI usage exist in parts of the current setup. A machine-wide Gitleaks executable was not detected.
- Claude and Codex have secret-detection and output-scrubbing hooks.

## Updated global harness recommendation

### The portable core

The portable core contains stable personal behavior, project layout, data boundaries, credential boundaries, task-state conventions, and worktree lifecycle rules. It excludes product settings, absolute hook commands, plugin registries, session databases, caches, credentials, and machine-specific paths belonging to another computer.

This is encoded in:

- `C:\Users\dougl\.agents\CROSS-AGENT-CONTRACT.md`
- `C:\Users\dougl\.agents\WORKTREE-PROTOCOL.md`
- `C:\Users\dougl\.agents\templates\AGENTS.md`
- `C:\Users\dougl\.agents\templates\CLAUDE.md`
- `C:\Users\dougl\.agents\templates\data-manifest.yaml`

Claude imports the shared contracts from its global `CLAUDE.md`. Codex receives a global directive to read them whenever a task touches projects, data, credentials, or worktrees. Repository `AGENTS.md` gives Cursor the same project facts.

### What remains product-specific

| Surface | Product-owned material |
|---|---|
| Claude | `settings.json`, hooks and hook wiring, plugins, session history, auto-memory, notification behavior, managed worktrees |
| Codex | `config.toml`, app permissions, plugins, task/session storage, managed worktrees |
| Cursor | user rules, `.cursor\rules`, editor settings, background-agent configuration |

This boundary preserves the July 24 Claude harness update and prevents a cross-product sync from translating a hook or permission rule incorrectly.

### Project bootstrap

Each repository receives one canonical `AGENTS.md`. Claude's adapter contains:

```markdown
@AGENTS.md
```

The project contract records:

- stable checkout and data paths;
- setup, test, lint, build, and end-to-end commands;
- data and credential boundaries;
- worktree isolation rules;
- task-state locations;
- merge gates.

## Why project data lives under a separate per-project root

Douglas's proposed per-project organization is correct. Every project receives its own data folder:

```text
C:\Users\dougl\Data\Projects\flight-finder\
C:\Users\dougl\Data\Projects\idetc-writing-ide\
C:\Users\dougl\Data\Projects\boundaries-reader\
```

The distinction concerns the Git boundary. A valuable dataset placed at `repo\data` and listed in `.gitignore` remains physically inside the checkout. That creates several risks:

- `git clean -fdx` can erase ignored content.
- Deleting or replacing the checkout can erase the data.
- Additional worktrees do not automatically receive ignored files.
- Multiple worktrees may silently use different copies.
- IDE watchers, search tools, agents, antivirus, and build tools may traverse large or sensitive data.
- Source backup and data backup become difficult to audit separately.
- Windows permissions and retention policies are harder to separate.

An ignored repository folder remains useful for disposable cache:

```text
repo\.local\
```

The contract permits `.local` for data that can be regenerated. The durable project data stays in the corresponding `Data\Projects` folder. Applications read its location through `PROJECT_DATA_ROOT` or a project-specific environment variable.

This model provides locality through matching project names and durability through a separate lifecycle.

## Can applications use ordinary files?

Yes. Ordinary files are the preferred format for:

- documents;
- images and media;
- immutable source inputs;
- JSON or YAML configuration;
- CSV exports;
- append-only logs;
- portable reports.

SQLite becomes useful when an application repeatedly updates a structured collection of records. It provides:

- atomic transactions, so a multi-step update either completes coherently or rolls back;
- indexes for fast lookup;
- constraints that reject malformed relationships;
- SQL queries across related records;
- safe coordination for concurrent readers and controlled writers;
- a standard backup boundary.

A SQLite database is one ordinary file. The application gains database behavior around that file. SQLite's own guidance positions it well for local-device storage and low writer concurrency: [SQLite appropriate uses](https://www.sqlite.org/whentouse.html).

A global SQLite CLI was not installed because no current project demonstrated a need for it. Python, Node, and other application ecosystems can include SQLite through a standard library or project dependency. That keeps the required version attached to the application. The CLI can be added when a project needs manual inspection or migrations.

## Bitwarden operating boundary

Bitwarden's official Password Manager CLI supports Windows and uses a session key after interactive unlock: [Bitwarden CLI documentation](https://bitwarden.com/help/cli/).

The safe workflow is:

```powershell
& "$env:APPDATA\npm\bw.cmd" login
$env:BW_SESSION = & "$env:APPDATA\npm\bw.cmd" unlock --raw
```

Douglas performs those commands directly in the terminal. Assignment stores the session key in that terminal's environment without intentionally displaying it.

An agent then launches one credential-dependent command through:

```powershell
& "C:\Users\dougl\.agents\tools\Invoke-WithBitwardenItem.cmd" `
  -Item "<Bitwarden item name or ID>" `
  -Field password `
  -EnvironmentVariable "SERVICE_API_KEY" `
  "<application command>"
```

Finish with:

```powershell
& "$env:APPDATA\npm\bw.cmd" lock
Remove-Item Env:BW_SESSION -ErrorAction SilentlyContinue
```

The harness forbids vault enumeration, export, raw retrieval in agent transcripts, and environment dumps. Deployed applications use their hosting platform's secret facility. Bitwarden Secrets Manager can later provide machine-account injection if unattended automation becomes a real requirement: [Bitwarden Secrets Manager overview](https://bitwarden.com/help/secrets-manager-overview/).

## BitLocker

BitLocker is Windows full-drive encryption. It makes disk contents unreadable to someone who removes the drive or tries to access it outside the authorized Windows startup and sign-in path. Microsoft documents BitLocker and the simpler Device Encryption mode here: [BitLocker overview](https://support.microsoft.com/en-us/windows/security/encryption/bitlocker-overview), [Device Encryption](https://support.microsoft.com/en-US/Windows/Security/Encryption/device-encryption-in-windows).

The recovery key is essential. Hardware or firmware changes can trigger recovery, and loss of the key can make the encrypted drive inaccessible.

The current machine's encryption state could not be verified because the status command required administrator access. Enabling encryption should occur only after confirming the Windows edition, TPM/device-encryption support, and two safe recovery-key locations.

## Gitleaks

Gitleaks scans files, Git diffs, and Git history for patterns resembling API keys, passwords, and tokens. It can run locally, as a pre-commit hook, or in GitHub Actions. Its upstream documentation describes `git`, `dir`, and `stdin` scan modes: [Gitleaks repository](https://github.com/gitleaks/gitleaks).

Gitleaks is a detector. Bitwarden is the credential store. `.gitignore` reduces accidental Git inclusion. Hosting-platform secrets deliver credentials to deployed applications. The harness hooks reduce accidental display and unsafe file access. These controls reinforce one another.

The upstream project currently describes Gitleaks as feature-complete with security-patch maintenance. Existing configurations remain useful; adoption of a successor can be evaluated later.

## Reliable worktree operation

### Native path

Claude Code currently supports `claude --worktree <name>`, `EnterWorktree`, worktree-isolated subagents, `.worktreeinclude`, configurable base references, and desktop-managed worktrees: [Claude Code worktree documentation](https://code.claude.com/docs/en/worktrees).

Codex and Claude desktop tasks should use their managed worktrees when the application creates one. Cursor opens the exact resolved worktree folder. Cursor's CLI reads repository `AGENTS.md` and `CLAUDE.md`: [Cursor CLI documentation](https://docs.cursor.com/en/cli/using).

### Manual fallback

The verified helper is:

```powershell
& "C:\Users\dougl\.agents\tools\agent-worktree.cmd" create `
  -Repository "C:\Users\dougl\Projects\<repository>" `
  -Task "<task-slug>"
```

Open the exact worktree in an agent:

```powershell
& "C:\Users\dougl\.agents\tools\agent-worktree.cmd" open `
  -Repository "C:\Users\dougl\Projects\<repository>" `
  -Task "<task-slug>" `
  -Agent cursor
```

After project verification and commits:

```powershell
& "C:\Users\dougl\.agents\tools\agent-worktree.cmd" merge `
  -Repository "C:\Users\dougl\Projects\<repository>" `
  -Task "<task-slug>" `
  -TargetBranch main
```

Cleanup:

```powershell
& "C:\Users\dougl\.agents\tools\agent-worktree.cmd" remove `
  -Repository "C:\Users\dougl\Projects\<repository>" `
  -Task "<task-slug>" `
  -TargetBranch main
```

The helper refuses merge when either checkout is dirty, refuses merge from the wrong target branch, and refuses removal until the branch is merged. A disposable repository test exercised create, status, commit, merge, removal, and cleanup successfully.

The helper does not decide whether tests passed. The repository contract supplies the verifier, and the implementation agent records its results before merge.

## Offsite computer-backup landscape

### 1. Plain Google Drive streaming or mirroring

**What it is:** Drive for desktop streams or mirrors selected files between the computer and Google Drive. [Google Drive desktop modes](https://support.google.com/drive/answer/13401938)

**Best at:** cross-device access, collaboration, and keeping current files available.

**Limit:** deletions and corruption may propagate. Non-Google file versions may age out after 30 days or 100 newer versions unless explicitly retained. [Google Drive version history](https://support.google.com/drive/answer/2409045)

**Mirror verdict:** **Have.** Google Drive is running and hosts active material.

### 2. Arq 7 using Google Drive

**What it is:** Arq creates encrypted, versioned backup records and can store them in Google Drive, Backblaze B2, external disks, NAS, and several other destinations. [Arq storage locations](https://www.arqbackup.com/documentation/arq7/English.lproj/storageLocations.html)

**Best at:** reusing existing Google Drive storage while gaining backup history, client-side encryption, schedules, and restores from older backup records. [Arq 7 description](https://www.arqbackup.com/documentation/arq7/English.lproj/arq7ArqPremium.html)

**Limit:** requires an Arq license, enough Google Drive quota, a separately protected encryption password, and periodic restore tests.

**Mirror verdict:** **Gap; leading fit.**

### 3. Backblaze Computer Backup

**What it is:** a dedicated Windows/macOS endpoint-backup service that continuously selects most local user files and supports web/client restores.

**Best at:** low-administration whole-computer file backup.

**Limit:** it follows retention rules for deleted files and disconnected external drives. Extended history requires deliberate configuration. [Supported backup data](https://www.backblaze.com/computer-backup/docs/supported-backup-data), [external-drive behavior](https://help.backblaze.com/hc/en-us/articles/217665398-Backing-up-External-Hard-Drives)

**Mirror verdict:** **Gap; simplest dedicated alternative.**

### 4. Restic with Backblaze B2

**What it is:** open-source, encrypted, snapshot-based backup using block deduplication and an object-storage destination. [Restic documentation](https://restic.readthedocs.io/en/stable/010_introduction.html), [Backblaze integration](https://www.backblaze.com/docs/cloud-storage-integrate-restic-with-backblaze-b2)

**Best at:** transparent automation, explicit retention, scripting, and repository checks.

**Limit:** scheduling, credential management, monitoring, pruning, and restore drills require engineering ownership.

**Mirror verdict:** **Gap; strong advanced option.**

### 5. Restic or another backup engine through Rclone to Google Drive

**What it is:** Rclone connects Google Drive as a backend, and Restic can use Rclone's Restic service. [Rclone Restic service](https://rclone.org/commands/rclone_serve_restic/), [Rclone Google Drive backend](https://rclone.org/drive/)

**Best at:** open-source encrypted snapshots using existing Drive quota.

**Limit:** two interacting command-line systems add authentication, scheduling, failure-detection, and recovery complexity on Windows.

**Mirror verdict:** **Gap; lower fit than Arq for this computer.**

### 6. Windows external-drive backup

**What it is:** File History or other Windows-supported file backup to an attached drive. Microsoft recommends external or network storage where cloud synchronization is unsuitable: [Windows backup choices](https://support.microsoft.com/en-US/Windows/Experience/Backup-Recovery/choose-a-backup-solution-in-windows).

**Best at:** fast local restores and protection from cloud-account or internet problems.

**Limit:** an attached drive shares risks from theft, fire, power events, and some malware. It supplies the local backup leg.

**Mirror verdict:** **Partial.** Windows backup tooling exists; no configured external backup was verified.

### 7. Macrium Reflect image backup

**What it is:** full-disk or partition imaging for recovery of Windows, applications, settings, and files.

**Best at:** bare-metal recovery after drive failure or a broken operating system.

**Limit:** requires external or network capacity, rescue-media testing, and a separate offsite copy.

**Mirror verdict:** **Gap; complementary recovery layer.**

### 8. CrashPlan endpoint backup

**What it is:** managed encrypted endpoint backup with file history and administrative controls. [CrashPlan overview](https://www.crashplan.com/wp-content/uploads/CrashPlan-Overview-Feb-2024.pdf)

**Best at:** business endpoints, policy, retention, and centralized administration.

**Limit:** its management model exceeds the immediate needs of one personal Windows workstation.

**Mirror verdict:** **Gap; lower fit.**

### 9. NAS plus cloud replication

**What it is:** a local network storage appliance receives workstation backups and replicates encrypted snapshots offsite.

**Best at:** large data volumes, multiple computers, fast local restoration, and shared storage.

**Limit:** hardware cost, maintenance, monitoring, drive replacement, and secure remote replication.

**Mirror verdict:** **Gap; premature for the current measured project volume.**

## Backup comparison

| Strategy | Best at | Unique value | Weakest point | Current state |
|---|---|---|---|---|
| Plain Google Drive | collaboration and current files | already present | sync propagation and limited generic-file history | Have |
| Arq 7 → Google Drive | encrypted versioned archive using existing quota | one GUI can target Drive and an external disk | license and quota dependency | Gap; recommended |
| Backblaze Computer Backup | minimal administration | dedicated automatic endpoint backup | provider-specific retention behavior | Gap; runner-up |
| Restic → B2 | control and automation | open format, snapshots, checks | operational burden | Gap |
| Restic/Rclone → Drive | open-source use of Drive | existing quota plus encryption | two-tool complexity | Gap |
| Windows external backup | rapid local restore | no cloud needed for recovery | no offsite protection | Partial |
| Macrium image | whole-system recovery | bare-metal restore | separate offsite layer needed | Gap |
| CrashPlan | managed endpoint retention | business administration | excessive complexity for current scope | Gap |
| NAS + cloud | multi-device scale | local speed plus replication | hardware and administration | Gap |

## Recommended backup architecture

### Primary recommendation

1. Live files:
   - `C:\Users\dougl\Projects`
   - `C:\Users\dougl\Data`
   - portable harness files under `C:\Users\dougl\.agents`, `C:\Users\dougl\.claude`, and `C:\Users\dougl\.codex`, with runtime and credential exclusions
   - selected personal documents outside restricted exclusions
2. Local versioned backup:
   - external SSD through an Arq backup plan
3. Offsite versioned backup:
   - a separate Arq plan targeting Google Drive
4. Repository remote:
   - GitHub for committed source and documentation
5. Collaboration:
   - Google Drive folders where cross-device editing is valuable

Arq's encryption password and BitLocker recovery key must each have a recovery copy independent of the backed-up computer.

### Decision gate

Before purchasing or installing Arq:

1. Measure the full selected backup set after the OneDrive migration inventory.
2. Verify available Google Drive quota.
3. Confirm the external SSD capacity.
4. Confirm that any restricted data is permitted in the selected offsite service.

If Google Drive has adequate quota, proceed with Arq 7. If quota is inadequate or Douglas wants the least operational work, use Backblaze Computer Backup for the offsite leg and retain an external-drive local backup.

### Restore tests

Run quarterly:

- restore one ordinary document;
- restore one Git repository with uncommitted-test material;
- restore one SQLite database copy and open it through the application;
- restore one private test file;
- record dates, hashes, duration, and failures in a backup log.

## Implementation completed in this pass

- Created `C:\Users\dougl\Projects`.
- Created `C:\Users\dougl\Data\Projects`.
- Created `C:\Users\dougl\Data\Restricted`.
- Created `C:\Users\dougl\Worktrees`.
- Installed Bitwarden CLI 2026.6.0 without accessing vault data.
- Installed the guarded Bitwarden process wrapper.
- Installed the cross-agent contracts and repository templates.
- Added the shared contract to the Claude and Codex global harnesses after timestamped backups.
- Installed and lifecycle-tested the manual worktree helper.
- Left the active flight-tracker repository and its current task untouched.

## Remaining actions

1. Douglas performs one interactive Bitwarden login/unlock when a project first needs a credential.
2. Audit BitLocker from an administrator session and back up the recovery key before changing encryption.
3. Verify Google Drive quota and the full post-migration backup-set size.
4. Select or acquire an external SSD.
5. Install Arq 7 and run a first backup/restore rehearsal after the storage migration.
6. Apply the repository templates one project at a time, beginning with clean repositories.

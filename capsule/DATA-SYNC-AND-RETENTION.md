# Data sync and snapshot retention

## The central idea

Capsule recreates a computer from a dated, verified package. Ongoing updates come from the authority assigned to each data class. An excluded file moves only when its named authority or an approved backup route carries it.

## What updates each data class

| Data class | Ongoing authority | How another computer receives updates |
|---|---|---|
| Committed project files and history | Each project's GitHub remote | `git fetch` and reviewed `git pull`/merge |
| Uncommitted work and approved untracked files | Nightly Agent Backups | A later snapshot and refreshed Capsule |
| Shared `.agents` harness | Private `agent-harness` GitHub repository | Clone/pull the private repository, then run harness projection/setup tools |
| Repository-owned agent rules and handoffs | Project Git repository | GitHub sync |
| Mutable project application data | `%USERPROFILE%\Data\Projects\<project>` | Nightly Agent Backups, then a refreshed Capsule |
| Transactional SQLite data | Approved consistent snapshot in Agent Backups | A later snapshot and refreshed Capsule |
| Google Drive documents | Google Drive | Sign into the same Google account and wait for Drive to report up to date |
| Passwords and local-development secrets | Bitwarden Password Manager | Sign into the same Bitwarden account and sync/unlock the vault |
| GitHub Actions secrets | GitHub repository or environment settings | GitHub supplies them to approved workflows |
| Hosted application secrets | The deployment provider | Sign in to the provider; its environment settings remain authoritative |
| Claude, Codex, and Cursor server-side account data | Each product account | Sign into the same account; the provider restores the data it supports |
| File Explorer Quick Access | Capsule path manifest | `Repair-QuickAccess.ps1` recreates pins after projects are restored |

## Files that Capsule excludes

| Excluded material | Recovery route |
|---|---|
| `.env`, API keys, access tokens, passwords, and recovery codes | Recreate through Bitwarden or the deployment provider |
| Browser cookies, product sessions, caches, and local authentication stores | Sign in again on the receiving computer |
| Gitleaks-flagged tracked files omitted from a sanitized offline bundle | Authenticate GitHub CLI, fetch `origin`, and inspect `RECOVERY-OMISSIONS.md` |
| Generated dependency folders and build caches | Reinstall dependencies and rebuild from the project instructions |
| Restricted or specially protected project data | Use that project's separately approved encrypted recovery plan |
| Files outside every declared authority and backup manifest | They currently have no cross-computer recovery route; add an approved route before relying on them |

Excluded data does not move automatically through Capsule.

## Find Capsule through Google Drive on another computer

This computer currently syncs `C:\Users\dougl\Documents`, which contains `C:\Users\dougl\Documents\Capsule`.

1. Open <https://drive.google.com/drive/computers>.
2. Sign into the Google account recorded in `manifests\accounts.json`.
3. Open the source computer entry, usually `SEEK_TO_SERVE`.
4. Open `Documents\Capsule`.
5. If OneDrive is installed, leave it unchanged.
6. Download the complete folder to a new local staging path outside OneDrive, such as `C:\Users\<receiving-user>\Capsule`.
7. Run `tools\Verify-Capsule.cmd` locally before bootstrap.

Google Drive stores folders selected under **Folders from your computer** in its **Computers/Other computers** area. The web Computers view is the reliable cross-computer retrieval path. A future dedicated copy under **My Drive** would also appear directly in each computer's streamed or mirrored My Drive.

## OneDrive on the receiving computer

Leave OneDrive installed, connected, and unchanged during Capsule restore. Before any later migration:

1. inventory OneDrive's selected folders and sync status;
2. resolve the physical paths for Windows Desktop, Documents, Pictures, and other known folders;
3. identify unique files and filename collisions;
4. record Quick Access targets;
5. copy additively into approved destinations without overwriting collisions;
6. compare source and destination;
7. verify every application and shortcut that relied on an old path.

Uninstalling, disconnecting, moving, deleting, or changing OneDrive folder protection belongs to a separate reviewed task.

## Routine update cycle

### On a working computer

1. Commit and push durable project work to each project's GitHub remote.
2. Commit and push safe shared-harness changes to the private `agent-harness` repository.
3. Let Google Drive and Bitwarden finish their own synchronization.
4. Let `Nightly Agent Backups` capture local-only work and approved application data.
5. Refresh Capsule when you want a new portable recovery point.
6. Run Capsule integrity verification and Gitleaks before copying or publishing the refreshed package.

### On another computer

1. Pull or fetch every GitHub-backed project.
2. Pull the private harness repository and run its setup/projection verifier.
3. Let Google Drive and Bitwarden sync.
4. Use a newer Capsule only when local-only work or application data must be restored.
5. Re-run project and harness verification.

## Snapshot retention policy

A retention policy defines which dated backups are kept, when older backups are removed, and which recovery points are protected from automatic removal.

Current state: no automatic snapshot deletion is enabled. Capsule generations and Agent Backups accumulate. This protects recovery history while the policy is undecided and consumes increasing disk space.

Recommended policy for approval:

- keep the most recent 14 daily snapshots;
- keep 8 additional weekly snapshots;
- keep 12 additional month-end snapshots;
- keep every manually labeled milestone;
- always keep the newest snapshot that passed a full disposable restore;
- pause deletion when the newest backup, integrity check, Gitleaks scan, or restore verification fails;
- delete only through a dedicated retention tool that produces a dry-run report first.

This recommendation is documentation only. No deletion mechanism is active.

## GitHub placement

The safe Capsule source — instructions, scripts, manifests with blank account identifiers, and value-free broker policy — belongs in private GitHub and is already represented by the `general-ai` and private `agent-harness` repositories.

The assembled payload may also be carried through GitHub as encrypted release assets. Use a private repository, split every encrypted asset below GitHub's per-file release limit, keep the decryption material in Bitwarden and a separate recovery location, and scan the plaintext payload before encryption. A GitHub-only copy creates an account-bootstrap dependency, so retain a second copy in Drive or offline storage.

Regular Git history is unsuitable for the assembled payload: GitHub enforces a 100 MiB single-object limit, large changing archives permanently inflate history, and removing sensitive material from Git history requires coordinated rewriting. GitHub Releases accept assets under 2 GiB each and are the appropriate GitHub transport for versioned encrypted archives.

Official references:

- <https://docs.github.com/en/repositories/creating-and-managing-repositories/repository-limits>
- <https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases>
- <https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository>

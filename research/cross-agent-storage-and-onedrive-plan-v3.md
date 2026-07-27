# Cross-agent storage and OneDrive plan — v3

Date: 2026-07-24

## Direct answers

OneDrive can be removed safely only after a staged audit, local copy, backup, sync verification, and rollback test. Microsoft documents that unlinking or uninstalling OneDrive leaves the cloud copy available, while downloaded files remain locally available. Files On-Demand entries may exist only in the cloud, so they must be downloaded before removal. The read-only audit of `General Claude` found 60,642 files and zero files marked Offline, RecallOnDataAccess, or RecallOnOpen. OneDrive was running. This supports local availability but does not prove cloud upload completion.

The computer can be the primary home for projects and private data. A single internal drive is one copy and therefore provides no backup by itself.

GitHub should hold source code, small configuration, documentation, schemas, migrations, tests, and small reproducible fixtures. Private records, credentials, mutable databases, generated outputs, research corpora, and large binaries should live outside the repository.

The requested `DocuSign` folder was moved to the Windows Recycle Bin and verified absent from its former path.

## Storage concepts

### Database and application storage

A database is structured runtime data that an application reads and updates. SQLite stores a whole database in one local file and is a strong default for a local or single-user application. PostgreSQL or a managed database becomes useful when many machines or users must write concurrently.

Recommended local layout:

```text
C:\Users\dougl\Projects\<project>\                 source repository
C:\Users\dougl\Data\Projects\<project>\inputs\     source data
C:\Users\dougl\Data\Projects\<project>\runtime\    SQLite databases and app state
C:\Users\dougl\Data\Projects\<project>\outputs\    generated exports
C:\Users\dougl\Data\Projects\<project>\private\    sensitive records
```

The application receives these paths through configuration or environment variables. The repository contains a sample configuration and documentation; it contains no private values.

### Git LFS

Git LFS replaces a large tracked file in Git with a small pointer while the binary content lives in an LFS object store such as GitHub's. It helps with versioned models, media, CAD, or other large binary assets. It remains repository-linked storage and is unsuitable for credentials, frequently changing databases, or private records that should never enter the repository.

### DVC

DVC provides Git-like versioning for datasets and model artifacts. Small metadata files are committed to Git, while the large data lives in a configured local, network, or cloud remote. DVC becomes worthwhile when a project needs reproducible versions of a large dataset. Current small local projects can begin with ordinary folders plus a manifest.

### Restricted data folder

A restricted folder is an ordinary local directory outside every Git repository whose Windows permissions and operating rules limit access. It should be covered by full-disk encryption and an encrypted backup. The label communicates that agents and tools should access it only when a task requires it. A suitable root is:

```text
C:\Users\dougl\Data\Restricted\<project>\
```

### Repository manifest

A repository data manifest is a committed inventory that explains data dependencies without containing the data. It records fields such as:

- logical dataset name
- expected local path or environment-variable name
- source and owner
- schema or format
- sensitivity class
- version or checksum
- command that regenerates it

`data-manifest.yaml` or `docs/data.md` are adequate names. This makes a checkout understandable to Claude, Codex, Cursor, and a human collaborator.

### Excluding a file from a repository

An entry in `.gitignore` tells Git to leave matching untracked files out of normal status and commit flows. Common examples are `.env`, `node_modules/`, `*.db`, generated build folders, and `data/private/`. Ignore rules do not erase a file that Git already tracks and do not remove it from old commits.

### Dirty repository

A repository is dirty when `git status` finds changes relative to the current commit: modified, staged, deleted, or untracked files. Dirtiness often represents legitimate unfinished work. The nested `flight-tracker\base-flight-finder` repository was dirty during the audit, and Douglas reported an active Codex task working there. Its files should remain frozen until that task checkpoints or hands off its changes.

## Credential-manager recon

### Current mirror

No 1Password, Bitwarden, or KeePassXC command-line tool was detected. The global Codex harness has strong secret-detection and redaction hooks, and repositories use Gitleaks in places. Those controls catch exposure; they do not provide a canonical vault that stores and injects credentials.

### Recommendation

1Password is the best fit for this environment because its Windows application and developer CLI can inject scoped secrets into a process without keeping plaintext credentials in repository files. Bitwarden is the strongest open-source/value alternative and also provides a CLI. KeePassXC is the strict local-only option; Douglas would own database synchronization, recovery, and backups.

For deployed applications, use the hosting platform's environment-variable or secret facility. Give each application a distinct credential with the smallest practical scope. Agents should receive individual needed secrets through process injection and should never dump or inventory an entire vault.

## Worktrees from first principles

A Git repository contains a history of commits and branches. A working tree is the physical folder containing editable files for one checked-out branch. The usual project folder is already one working tree.

`git worktree add` creates another physical project folder connected to the same Git history and checked out on another branch:

```text
C:\Users\dougl\Projects\flight-finder\                    main checkout
C:\Users\dougl\Worktrees\flight-finder--award-search\     agent A branch
C:\Users\dougl\Worktrees\flight-finder--scraper-fix\      agent B branch
```

Claude, Codex, and Cursor can each open one of these folders. Each agent edits a separate physical copy, commits to its own branch, and presents the branch for review or merge. This prevents two agents from concurrently rewriting the same working files.

Worktrees share Git history, and they may still collide through shared resources: a SQLite database outside the tree, the same development port, one cloud deployment, one test account, or the same external API. Each task therefore needs its own branch, worktree, ports, temporary database, and clearly named owner where relevant. One agent should be the writer for a worktree.

Codex can create managed worktrees for tasks; Claude Code supports worktree-based sessions; Cursor can open any resulting folder. Git remains the common coordination layer across all three.

## Revised migration plan

### Step 1 — Freeze the live flight-tracker surface

Allow the current Codex task to reach a checkpoint. Record its branch, worktree path, `git status`, current task, and next verifier. Commit coherent work or preserve it through a clear handoff. This prevents migration from moving files underneath an active process.

Completion gate: no running agent is writing inside the folder being moved, and every dirty file has a named owner and disposition.

### Step 2 — Build a source/data inventory

Classify every top-level project as source, private data, generated output, archive, or mixed. Record repository roots and remotes. Identify databases, credentials, large files, lock files, `node_modules`, generated artifacts, and OneDrive-only risks. Create a proposed destination map without moving anything.

Completion gate: every top-level folder has a category, owner, destination, and backup policy.

### Step 3 — Establish the local storage roots

Create `C:\Users\dougl\Projects`, `C:\Users\dougl\Data\Projects`, `C:\Users\dougl\Data\Restricted`, and `C:\Users\dougl\Worktrees`. Keep repositories in `Projects`, runtime/private data in `Data`, and temporary agent checkouts in `Worktrees`. Turn on or verify BitLocker before placing sensitive material there.

Completion gate: permissions, encryption state, free space, and test read/write behavior are verified.

### Step 4 — Establish two independent backups

Use GitHub as the remote copy for repository content. Add an encrypted offsite backup for the local data roots and a periodic external-drive copy. Backblaze Personal Backup is the simpler whole-machine option; Restic with Backblaze B2 provides more explicit snapshot control and requires more administration.

Completion gate: restore one repository file, one SQLite database copy, and one private test file into a temporary location and verify hashes or application readability.

### Step 5 — Install and migrate to a credential manager

Adopt 1Password as the canonical credential store, migrate project secrets, rotate any credentials that may have lived in project folders, and configure scoped injection for local commands. Preserve Gitleaks and Codex secret hooks as detection layers.

Completion gate: applications run without plaintext project `.env` secrets, and secret scans pass.

### Step 6 — Refactor one project at a time

Move a project repository into `Projects`. Move its runtime/private data into the matching `Data` folder. Add `.gitignore`, `data-manifest.yaml`, `.env.example`, `AGENTS.md`, and concise task-state files where appropriate. Run tests from the new location before touching the next project.

Recommended order: clean repositories first (`boundaries-reader`, `claude-global-config`), simple non-repositories next, mixed research/app folders after their data split, and the active flight tracker last.

Completion gate per project: clean or intentionally documented `git status`, passing verifier, valid remote, restored dependencies, and documented data paths.

### Step 7 — Standardize multi-agent operation

Keep one stable main checkout per repository. Create one branch and worktree per concurrent task. Assign one writer per worktree. Give each task isolated ports and temporary databases. Merge only after tests and review. Remove completed worktrees after the branch is safely merged or preserved remotely.

Completion gate: a two-task rehearsal completes without file, port, or database collisions.

### Step 8 — Verify OneDrive, then unlink

Confirm OneDrive reports fully synced. Compare a local inventory against the cloud view, ensure all Files On-Demand content is local, and preserve a dated migration manifest. Stop backing up Documents using Microsoft's keep-on-PC flow. Unlink the PC first and work locally through a short observation period.

Completion gate: projects open, tests run, local data loads, backups restore, and cloud files remain accessible after unlinking.

### Step 9 — Uninstall OneDrive after the observation period

Once local work and restores have been proven, uninstall the OneDrive client if Douglas still wants it removed. Keep the cloud copy until the local/offsite backup system has passed another restore check.

Completion gate: uninstall completes, Windows known folders point to intended local locations, and no application path still depends on `C:\Users\dougl\OneDrive`.

## Sources

- Microsoft Support, “Turn off, disable, or uninstall OneDrive”: https://support.microsoft.com/en-US/onedrive/turn-off-disable-or-uninstall-onedrive
- Microsoft Support, “Save disk space with OneDrive Files On-Demand”: https://support.microsoft.com/en-US/onedrive/save-disk-space-with-onedrive-files-on-demand-for-windows
- Microsoft Support, “Back up your folders with OneDrive”: https://support.microsoft.com/en-US/onedrive/back-up-your-folders-with-onedrive
- GitHub Docs, “About Git Large File Storage”: https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-git-large-file-storage
- GitHub Docs, “About large files on GitHub”: https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github
- DVC command reference: https://dvc.org/doc/command-reference
- SQLite, “Appropriate Uses for SQLite”: https://www.sqlite.org/whentouse.html
- 1Password CLI: https://1password.com/downloads/command-line
- 1Password developer quickstart: https://www.1password.dev/get-started/developer-quickstart
- Bitwarden CLI: https://bitwarden.com/help/cli/
- KeePassXC: https://keepassxc.org/
- Backblaze Windows backup strategy: https://www.backblaze.com/blog/strategies-for-backing-up-windows-computers/
- Restic: https://restic.net/

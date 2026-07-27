# Refactoring `General Claude`: OneDrive, Data, Instructions, and Worktrees

## Decisions

1. Unlinking or uninstalling OneDrive is safe after online-only files are
   downloaded and Windows folder backup is deliberately stopped.
2. Active app repositories should live under a nonsynced development directory.
3. GitHub should hold source, small fixtures, schemas, manifests, and durable
   technical documentation.
4. Each independently deployable app should have one repository boundary.
5. Concurrent writing agents should receive separate branches and worktrees.
6. `AGENTS.md` should be the shared project instruction source. `CLAUDE.md`
   should import it and add only Claude-specific material.

## Removing OneDrive safely

Microsoft states that unlinking or uninstalling the OneDrive client does not
delete the cloud copy. Downloaded files remain in the local OneDrive folder;
online-only files remain accessible through OneDrive.com. Files carrying the blue
cloud status are placeholders and must be downloaded before relying on the local
copy.

Because this machine's `Documents` path is currently inside OneDrive, first check
OneDrive **Settings → Sync and backup → Manage backup**. If Documents backup is
enabled, choose **Keep the files only on my PC** when stopping that backup.
Microsoft warns that cloud-only files must be downloaded first.

Safe order:

1. Select **Download all files**, or mark the folders you need **Always keep on
   this device**.
2. Wait for the green locally available status and verify important folders
   against OneDrive.com.
3. Make a second independent backup of authored documents.
4. Stop Documents/Desktop/Pictures backup using **Keep the files only on my PC**.
5. Unlink the PC.
6. Confirm the local files and cloud copy independently.
7. Move active repositories to `C:\Users\dougl\Projects`.
8. Uninstall the OneDrive client if desired.

Unlinking is the lower-risk first step because it is easy to reverse. Uninstalling
removes the sync client. Neither action cancels storage or erases OneDrive.com.

Sources:

- [Microsoft: turn off, unlink, or uninstall OneDrive](https://support.microsoft.com/en-US/onedrive/turn-off-disable-or-uninstall-onedrive)
- [Microsoft: Files On-Demand states](https://support.microsoft.com/en-US/onedrive/save-disk-space-with-onedrive-files-on-demand-for-windows)
- [Microsoft: stop Windows folder backup](https://support.microsoft.com/en-US/onedrive/back-up-your-folders-with-onedrive)

## Which data belongs in GitHub?

Use this classification:

| Data class | Example | Storage |
|---|---|---|
| Source-controlled input | small seed JSON, schemas, lookup tables, test fixtures | Git repository |
| Reproducible generated data | builds, scrape output, generated bundles | ignored local output or object storage |
| Large versioned data | model assets, large stable datasets | Git LFS or DVC plus remote storage |
| Mutable runtime data | SQLite databases, uploads, caches, logs | application/database storage |
| Private research input | unpublished corpus, personal records, licensed text | access-controlled data home outside Git |
| Secrets | tokens, keys, passwords, connection strings | credential manager or secret store |
| Data description | schema, provenance, download instructions, checksums | Git repository |

GitHub currently recommends storing generated files outside Git and using Git LFS
for large binaries. It recommends an on-disk `.git` size below 10 GB and enforces
a 100 MB single-object limit. Small size alone does not make material appropriate
for Git: privacy, copyright, and access control remain decisive.

A private GitHub repository provides access control, yet secrets still persist in
Git history after an accidental commit. GitHub recommends environment variables,
secret managers, push protection, and pre-commit scanning.

Sources:

- [GitHub repository limits](https://docs.github.com/en/repositories/creating-and-managing-repositories/repository-limits)
- [GitHub Large File Storage](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-git-large-file-storage)
- [GitHub: storing secrets safely](https://docs.github.com/en/get-started/learning-to-code/storing-your-secrets-safely)
- [GitHub: removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)

## Data currently found in `General Claude`

The audit inspected paths and repository membership without opening secret
material.

### `boundaries-reader`

- Git repository: yes; clean against `origin/main`.
- Public/application data: `verses.json` and `book.sample.json`.
- Private/licensed source: `content-private/`.
- Generated full book: `book.json`.
- Current `.gitignore` excludes `content-private/`, `book.json`, PDFs,
  `node_modules/`, and `.vercel`.

Assessment: keep this structure. Move the canonical clone outside OneDrive. Keep
the private source in an access-controlled project-data directory and reproduce
`book.json` through the existing build process.

### `contact-form-caller`

- Git repository: absent.
- Deployment markers: Vercel configuration and local Vercel state.
- Source includes the web page, local test script, npm files, and an n8n workflow.
- `node_modules/` is present inside OneDrive.

Assessment: create a private repository for source, the workflow template,
README, and environment-variable template. Ignore `node_modules/`, `.vercel/`,
runtime logs, and real environment values. Add `AGENTS.md`, CI, and a secret scan.

### `flight-tracker`

- Top-level Git repository: absent.
- Nested repository: `base-flight-finder/`, currently pointing at the upstream
  `affromero/flight-finder` remote.
- Nested working tree: modified and untracked implementation files.
- Separate component: `fast-flights-sidecar/`, including a full Python virtual
  environment.
- Project briefs, research, runbook, status, and task files live above the nested
  Git boundary.
- Tracked static data includes `apps/web/src/data/airports.json`.

Assessment: highest-priority refactor. Preserve the dirty nested working tree
before any move. Create a Douglas-owned product repository with the web app,
sidecar source, research, runbook, and project instructions under one coherent
root if they deploy as one product. Keep `affromero/flight-finder` as an
`upstream` remote. Exclude the virtual environment, databases, caches, environment
files, scrape output, and runtime data. The airports lookup is small static source
data and can stay tracked with provenance.

### `idetc-writing-ide`

- Git repository: absent.
- Durable app artifacts: HTML interface, JSON contract, schema, research, sample
  suggestions.
- Working corpus: `_work/`, generated diff data, scripts, paper snapshots,
  figures, and PDFs.

Assessment: create a private app repository for the interface, schema, scripts,
tests, and documentation. Keep the authoritative paper source and private
research corpus in its established research home. Use a manifest to point at the
authoritative source. Ignore generated diff payloads and rendered outputs, or
attach selected release artifacts deliberately.

### `drive-organizer`

- Git repository: absent.
- Reusable code: classifier and review UI.
- Local data: `inventory.json` and a generated JavaScript data payload representing
  the contents of a Drive.

Assessment: separate reusable source from each inventory run. Put reusable code
in a small private repository or harness skill. Keep inventories, decisions, and
move manifests in a private ignored run directory because filenames can disclose
sensitive information.

### `claude-global-config`

- Git repository: yes; clean against `origin/master`.
- It contains the portable Claude harness plus committed project memory.
- Runtime caches, transcripts, backups, machine-specific MCP configuration, and
  credentials are already ignored.

Assessment: maintain one canonical portable-harness repository outside OneDrive.
Separate portable rules from machine adapters. The active installation remains
under the appropriate user-level Claude/Codex configuration directories.

### Document and research folders

- `DocuSign`: operational and signing documentation.
- `motion-to-dismiss`: legal writing and research.
- `grandpa-help`: one research brief.
- `app-quality-fixes`: one reusable agent prompt.
- `berkeley-house`: task-state remnants.

Assessment:

- Keep legal, signing, and family material in a private document system or
  restricted vault.
- Promote the reusable app-quality workflow into the global harness after
  deduplicating it against existing design-review skills.
- Archive or reconcile orphan task-state directories after confirming that no
  active session depends on them.

### Root-level state

The root `CURRENT-TASK.md` is over 20 KB and combines several unrelated projects.
The root also contains a ZIP and secret-like local material.

Assessment: replace the cross-project task ledger with a portfolio index and
GitHub Project. Keep each app's active state inside that app's repository or issue.
Move secrets to a credential store. Put deliberate archives and deliverables in
their own OneDrive/vault categories.

## Worktree operating model

### Ownership rules

- One task owns one issue, branch, worktree, and primary writing agent.
- The main checkout is the review/integration checkout.
- Read-only reviewers may inspect any worktree.
- A second writing agent receives another worktree.
- Tasks that need the same files are sequenced or coordinated under one owner.
- Every merge passes tests and human diff review.

### Naming

```text
Issue:       flight-tracker#42
Branch:      agent/42-award-search
Worktree:    C:\Users\dougl\Worktrees\flight-tracker--42-award-search
Agent task:  FT-42 award search
```

### Manual PowerShell workflow

```powershell
$Repo = 'C:\Users\dougl\Projects\flight-tracker'
$Tree = 'C:\Users\dougl\Worktrees\flight-tracker--42-award-search'

git -C $Repo fetch origin
git -C $Repo worktree add $Tree -b agent/42-award-search origin/main
git -C $Tree status --short --branch
```

Open `$Tree` as the project in Claude, Codex, or a new Cursor window. Commit only
the task's files, push the branch, and open a PR. After merge and a clean-state
check:

```powershell
git -C $Repo worktree remove $Tree
git -C $Repo worktree prune
```

Claude Code supports `claude --worktree <name>` and can copy explicitly listed,
ignored environment files through `.worktreeinclude`. Codex provides
worktree-backed tasks in the desktop app. Cursor can open each worktree as a
separate workspace.

Environment concerns need separate isolation:

- assign different local ports;
- avoid two agents writing the same development database;
- use per-worktree temporary directories;
- install dependencies in each worktree when necessary;
- keep shared external services read-only during parallel tests where possible.

Sources:

- [Git worktree documentation](https://git-scm.com/docs/git-worktree.html)
- [Claude Code worktrees](https://code.claude.com/docs/en/worktrees)
- [OpenAI: Codex app worktrees](https://openai.com/index/introducing-the-codex-app/)

## `CLAUDE.md` and `AGENTS.md`

Use this structure in every active repository:

```text
AGENTS.md
CLAUDE.md
.claude\
.codex\
.cursor\rules\
```

`AGENTS.md` is canonical for:

- project purpose and map;
- setup, build, test, and lint commands;
- architectural invariants;
- data classifications and protected paths;
- verification expectations;
- branch and review policy.

On Windows, `CLAUDE.md` can contain:

```markdown
@AGENTS.md

## Claude-specific behavior

- Use the project's Claude hooks and path-scoped rules under `.claude/`.
```

Cursor's CLI reads both root `AGENTS.md` and `CLAUDE.md`. Keep Cursor-only
path-scoped rules under `.cursor/rules`. Keep Codex settings under
`.codex/config.toml`. Mechanical safety controls belong in hooks, permissions,
tests, and CI.

The large global Claude ruleset should not be copied into every repository.
Personal and universal safety behavior stays global; each repository receives
only the project facts and commands required to work correctly.

Sources:

- [Claude project memory and `AGENTS.md` import guidance](https://code.claude.com/docs/en/memory)
- [Cursor rules and `AGENTS.md`](https://docs.cursor.com/context/rules-for-ai)

## Refactoring order

1. Download and verify OneDrive content; stop Windows folder backup deliberately.
2. Preserve `flight-tracker\base-flight-finder` uncommitted work.
3. Establish `C:\Users\dougl\Projects` and `C:\Users\dougl\Worktrees`.
4. Re-clone the three existing repositories outside OneDrive.
5. Create a coherent product repository for `flight-tracker`.
6. Create private repositories for `contact-form-caller` and
   `idetc-writing-ide`.
7. Separate reusable `drive-organizer` code from private inventory runs.
8. Move document-only projects into their private document/vault homes.
9. Replace the root task ledger with a portfolio index and GitHub Project.
10. Add the shared `AGENTS.md` pattern and thin adapters to every active app.
11. Verify clones, remotes, deployments, ignored data, and backups.
12. Unlink OneDrive; uninstall it after a verification period if desired.

No project files were moved or rewritten during this audit.

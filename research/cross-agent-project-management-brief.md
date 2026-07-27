# Managing Projects Across Claude, Codex, and Cursor

## Executive recommendation

Use the repository as each app's durable home and GitHub as its durable remote.
Keep one ordinary local clone for your own review and one Git worktree per
concurrent agent task. Claude, Codex, and Cursor can all work on the same project;
the isolation boundary should follow the task and branch.

Turn `General Claude` into a project incubator and archive rather than the place
where active repositories execute. Put active clones under a nonsynced development
root such as `C:\Users\dougl\Projects\`. Keep research briefs, exported deliverables,
incoming files, and archived snapshots in OneDrive. Git provides code history and
remote recovery; OneDrive remains useful for document-oriented material.

Use a three-layer source of truth:

1. **GitHub Issues or a GitHub Project:** cross-project backlog and task status.
2. **Repository files:** architecture, decisions, build instructions, tests, and
   the implementation itself.
3. **Agent task/session state:** disposable execution notes associated with one
   task or worktree.

## What the current `General Claude` structure reveals

The read-only audit on 2026-07-24 found:

- `General Claude` is a container directory rather than a Git repository.
- It contains three nested Git repositories: `boundaries-reader`,
  `claude-global-config`, and `flight-tracker\base-flight-finder`.
- Several other directories look like independent apps or substantial projects,
  yet they do not have their own Git roots.
- `flight-tracker\base-flight-finder` currently has uncommitted and untracked
  implementation files. Any relocation must preserve that working tree exactly.
- The root mixes app folders, a large ZIP, task ledgers, and secret-like local
  material.
- Dependency trees and virtual environments live under the OneDrive hierarchy.
  These create large volumes of small transient files.
- The current top-level `CURRENT-TASK.md` contains several unrelated workstreams.
  This makes the folder itself act as a cross-project task database.

This arrangement leaves platform sessions sharing mutable files without a
repository boundary. It also lets OneDrive observe Git internals, dependencies,
logs, locks, caches, and worktree activity.

Microsoft documents that hidden and temporary files can keep OneDrive folders in
a syncing state. Practitioner reports specifically identify dependency trees as a
heavy source of churn. This evidence supports keeping active development trees
outside the synchronized hierarchy, while retaining deliberate documents and
exports in OneDrive. The Microsoft source establishes the general sync behavior;
the Node/Git recommendation is practitioner evidence.

## Recommended filesystem architecture

```text
C:\Users\dougl\
├── Projects\                         # active development; local and nonsynced
│   ├── boundaries-reader\            # one canonical clone per app
│   ├── flight-tracker\
│   ├── contact-form-caller\
│   └── ...
├── Worktrees\                        # disposable isolated task checkouts
│   ├── flight-tracker--award-search\
│   └── boundaries-reader--mobile-ui\
└── OneDrive\Documents\General Claude\
    ├── _inbox\                       # material awaiting classification
    ├── briefs\                       # durable cross-project research
    ├── deliverables\                 # PDFs, ZIPs, screenshots, exports
    ├── archives\                     # deliberate frozen snapshots
    └── project-index.md              # links/status only; no source trees
```

The exact names are flexible. The boundaries matter:

- **Active code:** local repository under `Projects`.
- **Parallel execution:** task-specific worktree under `Worktrees`.
- **Durable code backup and collaboration:** private or public GitHub remote.
- **Human documents and exports:** OneDrive.
- **Secrets:** credential manager or ignored environment file outside shared
  artifacts.
- **Large private inputs:** a project data directory outside Git, referenced by a
  manifest that records origin, expected path, and checksum where useful.

### Repository boundary rule

Give an app its own repository when it has its own deployment, release cycle,
dependency lifecycle, or product identity. Keep components together when they
ship as one product or regularly require atomic changes across shared schemas and
packages. Current guidance treats independent deployability and ownership as the
main decision factors. For Douglas's collection, separate repositories should be
the default, with a monorepo reserved for a genuinely coupled frontend/backend or
shared-package system.

## One project, three agent surfaces

Do not assign a permanent platform to a folder. Each platform is a different
interface onto the same repository.

Suggested division of labor:

- **Cursor:** close editor-driven work, navigation, small manual edits, inline
  completion, and interactive review.
- **Claude Code:** long terminal workflows, research-heavy implementation, hooks,
  and Claude-native orchestration.
- **Codex app:** parallel task supervision, worktree-backed implementation,
  structured review, and work spanning coding plus documents or other tools.

These are defaults rather than ownership rules. Choose the surface per task, then
return durable knowledge to the repository and issue tracker.

Use only one writing agent in a given checkout. When another agent needs to work
concurrently, create another branch and worktree. Open that worktree as a separate
Cursor window or as the selected project directory in Claude/Codex. OpenAI and
Anthropic both document worktree isolation for parallel sessions, and Git itself
defines each linked worktree as a separate working tree with its own checkout
metadata.

## Repository instruction architecture

Use one small, tool-neutral instruction source:

```text
app-repo\
├── AGENTS.md                  # canonical shared project instructions
├── CLAUDE.md                  # imports AGENTS.md; Claude-only additions are rare
├── .cursor\rules\             # only scoped Cursor behavior that AGENTS cannot express
├── .codex\config.toml         # Codex settings, hooks, sandbox/MCP choices
├── .claude\                   # Claude settings, hooks, and path-scoped rules
├── docs\
│   ├── architecture.md
│   ├── decisions\
│   ├── specs\
│   └── operations.md
├── README.md
└── source, tests, and build files
```

`AGENTS.md` should contain only facts every coding agent needs:

- what the app does;
- repository map;
- canonical build, test, lint, and deployment commands;
- architectural invariants;
- protected files and data boundaries;
- verification and review expectations.

Claude's current Windows guidance explicitly recommends a short `CLAUDE.md` that
imports `AGENTS.md`. Cursor documents support for root-level `AGENTS.md` and
`CLAUDE.md`, while `.cursor/rules` supplies file-scoped behavior. Keep repeated
instructions concise: Claude recommends fewer than roughly 200 lines for its
always-loaded project file, and recent research reports context bloat and rule
leakage as common configuration smells.

Behavioral instructions guide models. Enforce critical requirements through
permissions, hooks, tests, CI, branch protection, and secret scanning.

## Task and context model

### Portfolio layer

Use one GitHub Project as the portfolio board across repositories. Each app task
becomes an issue in its own repository and can appear on the shared board.
GitHub Projects can group issues and pull requests from multiple repositories
with status, priority, dates, sub-issues, and dependencies.

Recommended fields:

- Project/app
- Status: Inbox, Ready, Active, Review, Blocked, Done
- Priority
- Task type
- Agent/surface
- Branch or PR
- Next human decision

### Project layer

Keep durable project knowledge in versioned repository files:

- `README.md`: purpose, setup, and entry points.
- `docs/architecture.md`: current system map.
- `docs/decisions/`: short architecture decision records.
- `docs/specs/`: approved feature behavior and acceptance criteria.
- GitHub Issues: backlog, bugs, active tasks, and discussion.
- Pull requests: implementation review and task closure.

AWS and Google both recommend versioned architecture decision records; GitHub
Issues connects tasks directly to commits, pull requests, and deployments.

### Session layer

Treat chat history as an execution trace. At handoff or completion, extract:

- remaining work to the GitHub issue;
- durable decisions to an ADR or spec;
- newly verified commands or invariants to `AGENTS.md`;
- implementation changes to a branch and PR;
- disposable logs, plans, and temporary summaries to ignored task-state files.

Your current `CURRENT-TASK` and `WORK_QUEUE` system can remain as a local execution
mechanism. Scope it per repository and per concurrent session. Shared, frequently
edited queue files create a merge hotspot; keep the portfolio backlog in GitHub
and let each worktree hold its own short execution queue.

## File-placement rules

| Material | Durable home | Git? |
|---|---|---:|
| Source, tests, migrations, configuration templates | App repository | Yes |
| README, specs, ADRs, runbooks | App repository under `docs/` | Yes |
| Backlog and active feature status | GitHub Issues/Projects | Managed by GitHub |
| Agent instructions shared across tools | Root `AGENTS.md` | Yes |
| Tool-specific scoped rules | `.claude/`, `.codex/`, `.cursor/` | Usually yes |
| Personal permissions and machine paths | local ignored config | No |
| Secrets and credentials | credential manager / environment | No |
| Dependencies, caches, virtual environments | regenerated locally | No |
| Generated builds and screenshots | ignored output; attach to release/PR when needed | Usually no |
| Final reports, PDFs, client deliverables | OneDrive deliverables folder | Version deliberately |
| Large private source data | external data home plus checked-in manifest | Manifest only |
| Chat transcripts | platform history; summarize durable facts elsewhere | No |

## Migration plan for `General Claude`

This is a staged plan. No existing project files were moved during this research.

### Phase 1: inventory and freeze

1. Classify every top-level directory as active app, research/deliverable,
   archive, harness, or inbox.
2. Detect Git roots, remotes, dirty trees, nested repositories, secrets,
   dependency directories, and deployed services.
3. Back up authored documents and export a manifest before moving anything.
4. Resolve the existing dirty `base-flight-finder` tree first through a reviewed
   commit or an explicit patch backup.

### Phase 2: establish repository homes

1. Create `C:\Users\dougl\Projects`.
2. Clone existing repositories from their verified remotes into that directory.
3. For app folders without Git, initialize one repository per independently
   deployable app after reviewing exclusions and sensitive content.
4. Add strong `.gitignore` files before the first commit.
5. Create or verify private GitHub remotes for private projects.

Fresh cloning existing repositories is safer than moving their `.git` directories
out of OneDrive. Copy only reviewed uncommitted changes into the new clone.

### Phase 3: standardize each app

1. Add a concise `README.md`.
2. Add canonical `AGENTS.md`.
3. Add the small `CLAUDE.md` import bridge.
4. Add scoped Cursor rules only where needed.
5. Add `docs/architecture.md`, `docs/decisions/`, and `docs/specs/`.
6. Add verified setup/test commands and CI.
7. Configure worktrees outside the main checkout.

### Phase 4: convert `General Claude`

1. Replace active source directories with entries in `project-index.md` after
   validating each new clone and remote.
2. Retain briefs, exports, archives, and inbox material.
3. Remove regenerated dependency trees from the synchronized copy only after the
   new repositories are verified.
4. Relocate root-level secret-like material through a credential-safe workflow.
5. Archive the old mixed tree only after every project has a verified destination.

### Phase 5: operate consistently

For each new task:

1. Create or select a GitHub issue.
2. Write acceptance criteria and identify the repository.
3. Create a branch/worktree when implementation begins.
4. Open that worktree in whichever agent surface fits the task.
5. Keep one writing agent per worktree.
6. Run tests and review the diff.
7. Open a PR linked to the issue.
8. Move durable discoveries into repository documentation.
9. Merge, remove the worktree, and close the issue.

## Sources

### Primary

- [OpenAI: Introducing the Codex app](https://openai.com/index/introducing-the-codex-app/)
- [Anthropic: Run parallel sessions with worktrees](https://code.claude.com/docs/en/worktrees)
- [Anthropic: How Claude remembers your project](https://code.claude.com/docs/en/memory)
- [Cursor: Rules](https://docs.cursor.com/context/rules-for-ai)
- [Cursor: Using Agent in CLI](https://docs.cursor.com/en/cli/using)
- [Git: `git worktree` documentation](https://git-scm.com/docs/git-worktree.html)
- [GitHub Issues and Projects](https://github.com/features/issues)
- [AWS: ADR best practices](https://docs.aws.amazon.com/prescriptive-guidance/latest/architectural-decision-records/best-practices.html)
- [Google Cloud: Architecture decision records](https://docs.cloud.google.com/architecture/architecture-decision-records)
- [Microsoft: OneDrive hidden and temporary file sync behavior](https://learn.microsoft.com/en-us/troubleshoot/sharepoint/sync/folders-incorrectly-show-status-syncing)
- [DEFRA: Choosing between mono-repo and multi-repo](https://defra.github.io/software-development-standards/guides/mono_or_multi_repo/)

### Practitioners

- [David Loor: keeping multiple coding agents from overwriting one another](https://davidloor.com/en/blog/how-to-keep-multiple-coding-agents-from-overwriting-each-other)
- [One2N: Git worktrees for agentic development](https://one2n.io/blog/git-worktrees-for-agentic-development)
- [Hacker News discussion: Markdown documents as shared agent context](https://news.ycombinator.com/item?id=47222919)

### Community

- [Claude users: simultaneous agents with worktrees](https://www.reddit.com/r/ClaudeAI/comments/1t9tolw/running_two_claude_code_agents_on_the_same_repo/)
- [Cursor users: multiple agents and small ownership boundaries](https://www.reddit.com/r/cursor/comments/1u5pd5i/anyone_running_multiple_cursor_agents_or_sessions/)
- [Cross-tool context-relearning discussion](https://www.reddit.com/r/codex/comments/1t5l4xh/codex_relearns_my_project_for_4_minutes_whats/)
- [OneDrive and Node dependency-tree discussion](https://www.reddit.com/r/sysadmin/comments/1uesl2c/onedrive_stuck_looking_for_changes_with_nodejs/)

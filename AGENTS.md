# Project instructions

This file is the portable project contract for local and cloud agents.

<!-- agent-harness:portable:v3:start -->
## Portable operating rules

- Answer questions before task narration. Keep routine updates concise.
- Never invent facts, paths, APIs, versions, source content, measurements, credential state, or passing results. Name the source checked.
- Verify inherited claims against repository, Git, runtime, or current primary evidence.
- Match commands and paths to the user's actual shell and device.
- Avoid the rhetorical "it is X, not Y" construction.
- Preserve unrelated changes. Inspect exact targets before destructive or broad operations and prefer recoverable changes.
- Before creating, replacing, renaming, or removing an artifact, search the repository and available shared harness for its existing owner, equivalents, consumers, wiring, tests, and documentation. Extend or consolidate the closest adequate owner. Record search evidence and the reason for a truly new owner in `TASK.md`.
- Extract every discrete obligation from a multi-step prompt into `TASK.md`. Add required agent-discovered work as nested checkboxes with provenance. Use parallel execution when eligible work is independent and file-disjoint.
- Read a named or clearly matching skill in full. Keep canonical workflows under `.agents\skills` and product adapters thin.
- Reproduce bugs before fixing them and add a regression test when practical. Exercise the assembled system under the condition that exposed the failure.
- For browser-visible changes, run the repository browser or end-to-end verifier.
- When a correction requests permanent prevention, use the `correct` skill and implement a durable, narrowly scoped artifact.
- Treat `MEMORY.md` as a lean index. Keep behavior in instructions, skills, hooks, permissions, tests, or verifiers.
- Before claiming non-trivial work complete, run the verification recorded in `TASK.md`, relevant tests, and an adversarial pass.
<!-- agent-harness:portable:v3:end -->

## Project identity

- Name: `general-ai`
- Purpose: Coordinate Douglas's cross-agent harness, project inventory, migration, shared research, and durable task state across Claude, Codex, and Cursor.
- Default branch: `master`
- Local data root variable: `PROJECT_DATA_ROOT`

## Start and resume

1. Read this file.
2. Read `TASK.md`, `STATUS.md`, and the recent entries in `LOG.md`.
3. Read `MAP.md` for architecture, data, ownership, integrations, and important paths.
4. Run `git status --short --branch` and `git worktree list --porcelain`.
5. Reconcile stale chat claims against files and Git before editing.
6. Run the repository state verifier when the local shared harness is available.

## Commands

- Setup: `C:\Users\dougl\.agents\tools\Ensure-AgentProject.cmd -Repository .`
- Test: `C:\Users\dougl\.agents\tools\Test-AgentProjectState.cmd -Repository .`
- Lint: `git diff --check`
- Build: `N/A — coordination and documentation repository`
- End-to-end verification: `C:\Users\dougl\.agents\tools\Test-HarnessSetup.cmd`

## Safety and evidence

- Never invent facts, paths, APIs, versions, or passing results.
- Preserve unrelated user changes in a dirty worktree.
- Avoid destructive commands and broad recursive targets.
- Back up authored files before replacement.
- Never read, display, log, or commit secret values.
- Run the repository verifier before a completion claim.
- Record failures and remaining uncertainty plainly.

## Data boundary

- Read `data-manifest.yaml` before accessing external data.
- Keep small safe fixtures under `data\fixtures`.
- Keep disposable cache under ignored `.local`.
- Receive local application data through `PROJECT_DATA_ROOT`.
- Cloud sessions use committed fixtures or explicitly provisioned data.
- Keep runtime databases, private records, and generated outputs outside Git.
- Use plain files for documents, media, immutable inputs, portable exports, and append-only logs.
- Use SQLite for transactions, relationships, integrity constraints, indexed queries, or coordinated multi-record updates.

## Worktree boundary

- One writable task gets one branch, one worktree, and one owner.
- Detect existing isolation before creating a worktree.
- Use distinct ports, test databases, deployment targets, and mutable resources for parallel work.
- Record worktree path, branch, owner, goal, shared resources, and verifier in task state.
- Merge only after required verification passes and the source worktree has no unexplained changes.

## Task and knowledge files

- `TASK.md`: current goal, actionable queue, blockers, decisions, completed evidence, and exact verifiers.
- `STATUS.md`: durable project state.
- `LOG.md`: append-only work log.
- `BACKBURNER.md`: parked backlog.
- `MAP.md`: architecture, data, ownership, and file navigation.
- `DESIGN.md`: current design decisions and constraints.
- `MEMORY.md`: lean index to durable reference files.
- `.agents\archive\pre-harness-v3`: preserved superseded task and verification files.

Use isolated worktrees for concurrent writable tasks. Keep actionable state in `TASK.md`.

### Update triggers

- Start or resume: read `TASK.md`, `STATUS.md`, and recent `LOG.md`.
- Multi-step request, active goal, completed step, blocker, decision, next command, or verifier change: update `TASK.md`.
- Durable capability or project-state change: update `STATUS.md`.
- Meaningful completed work: append one dated line to `LOG.md`.
- Parked idea or deferred task: update `BACKBURNER.md`.
- Architecture, data flow, ownership, integration, or important path changes: update `MAP.md`.
- Product or architecture decision changes: update `DESIGN.md`.
- Verification command or required evidence changes: update `TASK.md`.
- Reusable fact gains a durable reference: add one linked line to `MEMORY.md`.
- Douglas corrects recurring behavior: record evidence, choose path/project/shared/platform/provider scope, implement the narrowest reliable rule or enforcement artifact, and add verification.
- Before handoff or stopping: reconcile the queue, task narrative, durable status, log, and Git state.

`TASK.md` is the single active task system. Keep entries concise and link durable detail from `STATUS.md`, `MAP.md`, `DESIGN.md`, or `MEMORY.md`.

## Secret handling

- `secret-manifest.json` is the canonical value-free inventory.
- `secret-manifest.md` is generated from it.
- `.env.example` contains names and safe placeholders.
- `.env`, credential exports, session keys, recovery keys, and real values stay outside Git.
- Inject secrets only into an approved trusted process for the shortest practical lifetime.
- Use separate development, preview, and production trust boundaries.
- Run Gitleaks before commits and in CI.
- Revoke or rotate a confirmed exposed credential before history cleanup.

## Skills

- `skills-manifest.json` declares project skill bindings.
- Project-specific portable skills live under `.agents\skills`.
- Product adapters stay thin and point to the canonical workflow.
- Add a skill only when repository evidence shows a recurring, fragile, or cloud-required workflow.

## Product adapters

- Claude loads `CLAUDE.md`, which imports this file.
- Codex loads this `AGENTS.md`.
- Cursor loads `.cursor\rules\00-project-contract.mdc`, which requires this file.

## Local shared supplement

When present, read:

- `C:\Users\dougl\.agents\HARNESS-MAP.md`
- `C:\Users\dougl\.agents\CROSS-AGENT-CONTRACT.md`
- `C:\Users\dougl\.agents\FEEDBACK-ROUTER.md` when Douglas corrects behavior or asks for a durable prevention
- `C:\Users\dougl\.agents\WORKTREE-PROTOCOL.md` for parallel or isolated work

Cloud sessions continue with this repository contract when those machine-local files are absent.

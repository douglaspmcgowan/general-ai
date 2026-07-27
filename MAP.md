# General Claude project map

## Core documents

| File | Audience | Loaded or read when | Owns |
|---|---|---|---|
| `AGENTS.md` | Agents and humans | Every repository session | Portable project contract |
| `CLAUDE.md` | Claude adapter | Every Claude repository session | Imports `AGENTS.md` |
| `.cursor/rules/00-project-contract.mdc` | Cursor adapter | Every Cursor repository session | Requires `AGENTS.md` |
| `CURRENT-TASK.md` | Agents and humans | Start, resume, handoff | Active goal, progress, exact next verifier |
| `WORK_QUEUE.md` | Agents and harness | Multi-step work | Actionable checkbox state |
| `STATUS.md` | Agents and humans | Start, resume, milestone | Durable setup and migration state |
| `LOG.md` | Agents and humans | Recent history, handoff | Append-only work record |
| `BACKBURNER.md` | Humans and agents | Planning | Parked cross-project backlog |
| `VERIFY.md` | Agents and CI | Before completion | Required evidence and commands |
| `MIGRATION.md` | Humans and agents | Path changes and OneDrive retirement | Repository cutover ledger and rollback rules |
| `DESIGN.md` | Agents and humans | Harness or storage decisions | Goals, constraints, and durable decisions |
| `MEMORY.md` | Agents | Recall | Lean links to durable topic notes |
| `data-manifest.yaml` | Agents | Data access | Value-free external-data policy |
| `secret-manifest.json` | Agents and automation | Credential-dependent setup | Value-free environment-variable inventory |
| `skills-manifest.json` | Agents and cloud setup | Skill selection and export | Project skill bindings |

## Architecture

| Component | Purpose | Entry point | Owner |
|---|---|---|---|
| Human harness documentation | Explain the system, decisions, and operating procedures | `C:\Users\dougl\.agents\human-readable\README.md` | Shared harness |
| Live agent harness | Supply contracts, tools, templates, skills, and deterministic guards | `C:\Users\dougl\.agents\HARNESS-MAP.md` | Shared harness |
| Product adapters | Load shared rules into Claude, Codex, and Cursor | `C:\Users\dougl\.claude\CLAUDE.md`, `C:\Users\dougl\.codex\AGENTS.md`, `C:\Users\dougl\.cursor\rules` | Each product |
| Local project fleet | Hold one versioned working copy per project | `C:\Users\dougl\projects` | Each project repository |
| Project data fleet | Hold valuable mutable data outside Git | `C:\Users\dougl\Data\Projects` and `C:\Users\dougl\Data\Restricted` | Each project manifest |
| Worktree fleet | Isolate concurrent source changes | `C:\Users\dougl\Worktrees` | Task owner |
| Docket | Present review cards from local SQLite and optional cloud sync | `C:\Users\dougl\projects\docket` | Docket repository |
| Coordination state | Track the cross-project migration and remaining human boundaries | Repository root task files and `MIGRATION.md` | This repository |
| Historical research | Preserve the research that informed the current architecture | `research\` | This repository |

## Important paths

| Path | Purpose | Generated | Committed |
|---|---|---:|---:|
| `C:\Users\dougl\.agents` | Live shared harness | Mixed | Private harness repository mirror |
| `C:\Users\dougl\.agents\human-readable` | Human explanations and setup changelog | No | Yes, in the harness repository |
| `C:\Users\dougl\projects\agent-harness` | Private Git authority for the shared harness | No | Yes |
| `C:\Users\dougl\projects\docket` | Docket source authority | No | Yes |
| `C:\Users\dougl\projects\general-claude` | This coordination repository | No | Yes |
| `C:\Users\dougl\Data\Projects\general-claude` | Local coordination data | Mixed | No |
| `C:\Users\dougl\Documents\Agent Backups` | Curated value-free recovery artifacts | Yes | No |
| `C:\Users\dougl\OneDrive` | Retired source and temporary rollback tree | No | No |

## Data flow

1. Product adapters load the shared harness and the nearest project contract.
2. Repository source and portable project instructions live under `C:\Users\dougl\projects`.
3. Mutable databases, private records, inputs, outputs, and caches resolve through each project's data manifest.
4. GitHub receives versioned source and safe documentation.
5. SQLite-safe exports and value-free recovery pointers enter `Documents\Agent Backups`.
6. Google Drive may back up only that curated folder after its desktop folder list is verified.
7. Docket reads local SQLite and receives cloud credentials only through the exact-command broker.

## Integrations

| System | Direction | Authentication name | Failure behavior |
|---|---|---|---|
| GitHub | Both | GitHub Windows keyring | Stop publication; local Git state remains authoritative |
| Bitwarden Secrets Manager | Inbound | `BWS_ACCESS_TOKEN`, `REVIEW_SECRET` | Broker fails closed; local Docket remains available |
| Google Drive | Outbound backup | Google account owned by Douglas | Keep client stopped when root coverage is uncertain |
| Docket cloud sync | Both | `REVIEW_SECRET` | Local SQLite and outbox remain authoritative |
| Claude, Codex, Cursor | Inbound rules and local writes | Product-owned login/session | Project contract remains portable through Git |

## Ownership and concurrency

- A repository gets one canonical local path under `C:\Users\dougl\projects`.
- A writable task gets one branch, one worktree, and one owner.
- Active worktrees remain at their current paths until their owning session reaches a handoff point.
- Shared runtime data uses project-specific paths and task-specific test stores.
- `MIGRATION.md` records every cutover, rollback source, verification result, and remaining active-path blocker.

## Update rule

Update this file whenever a core document, source-of-truth path, data flow, owner, integration, or concurrency boundary changes.

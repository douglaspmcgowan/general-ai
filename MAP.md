# General AI project map

## Core documents

| File | Audience | Loaded or read when | Owns |
|---|---|---|---|
| `AGENTS.md` | Agents and humans | Every repository session | Portable project contract |
| `CLAUDE.md` | Claude adapter | Every Claude repository session | Imports `AGENTS.md` |
| `.cursor/rules/00-project-contract.mdc` | Cursor adapter | Every Cursor repository session | Requires `AGENTS.md` |
| `TASK.md` | Agents and humans | Start, resume, handoff | Active goal, actionable queue, blockers, completed evidence, and exact next verifier |
| `STATUS.md` | Agents and humans | Start, resume, milestone | Durable setup and migration state |
| `LOG.md` | Agents and humans | Recent history, handoff | Append-only work record |
| `BACKBURNER.md` | Humans and agents | Planning | Parked cross-project backlog |
| `MIGRATION.md` | Humans and agents | Path changes and legacy recovery review | Repository cutover ledger, retirement evidence, and preserved-data decisions |
| `DESIGN.md` | Agents and humans | Interface work | Universal and project-specific interface rules |
| `PRODUCT.md` | Agents and humans | Product work, when present | Optional product intent |
| `MEMORY.md` | Agents | Recall | Lean links to durable topic notes |
| `data-manifest.yaml` | Agents | Data access | Value-free external-data policy |
| `secret-manifest.json` | Agents and automation | Credential-dependent setup | Value-free environment-variable inventory |
| `skills-manifest.json` | Agents and cloud setup | Skill selection and export | Project skill bindings |
| `.agents/harness-provenance.json` | Agents and verifiers | Harness drift checks | Installed project-contract hashes and authority |
| `.agents/skill-pathways.json` | Agents | Named compound skill workflows | Ordered portable skill chains |
| `.agents/archive/task-state-migration/` | Humans and agents | Historical recovery only | Verified legacy task and verification sources |

## Architecture

| Component | Purpose | Entry point | Owner |
|---|---|---|---|
| Human harness documentation | Explain the system, decisions, and operating procedures | `C:\Users\dougl\.agents\human-readable\README.md` | Shared harness |
| Live agent harness | Supply contracts, tools, templates, skills, and deterministic guards | `C:\Users\dougl\.agents\AGENTS.md` and `C:\Users\dougl\.agents\MAP.md` | Shared harness |
| Declog | Diagnose memory pressure and classify stale agent, browser, Node, Python, and WebView2 helpers before guarded cleanup | `C:\Users\dougl\.agents\skills\declog\SKILL.md` | Shared harness |
| Bitwarden scaffold plan | Create empty project Login items with exact Hidden field names | `C:\Users\dougl\.agents\tools\bitwarden-project-scaffolds.json` | Shared harness |
| Product adapters | Load shared rules into Claude, Codex, and Cursor | `C:\Users\dougl\.claude\CLAUDE.md`, `C:\Users\dougl\.codex\AGENTS.md`, `C:\Users\dougl\.cursor\rules` | Each product |
| Local project fleet | Sync source, project rules, handoffs, and small versionable data through one GitHub repository per project | `C:\Users\dougl\projects` | Each project repository |
| Project data fleet | Restore excluded and live mutable data through project-specific data-manifest adapters | `C:\Users\dougl\Data\Projects` and `C:\Users\dougl\Data\Restricted` | Each project manifest |
| Project-sync manager | Discover tagged repositories through GitHub CLI, recreate them under local conventions, and route excluded/live data through each declared adapter | Pending shared-harness implementation | GitHub account/topic, shared harness, and each project manifest |
| Worktree fleet | Isolate concurrent source changes | `C:\Users\dougl\Worktrees` | Task owner |
| Docket | Present review cards from local SQLite and optional cloud sync | `C:\Users\dougl\projects\docket` | Docket repository |
| Coordination state | Track the cross-project migration and remaining human boundaries | `TASK.md`, durable state files, and `MIGRATION.md` | This repository |
| Historical research | Preserve the research that informed the current architecture | `research\` | This repository |
| Capsule | Carry the shared global harness, bootstrap tools, and repository inventory to another Windows computer | `C:\Users\dougl\My Drive\Capsule\AGENT-START.md` | `agent-harness` repository |

## Important paths

| Path | Purpose | Generated | Committed |
|---|---|---:|---:|
| `C:\Users\dougl\.agents` | Live shared harness | Mixed | Private harness repository mirror |
| `C:\Users\dougl\.agents\human-readable` | Human explanations and setup changelog | No | Yes, in the harness repository |
| `C:\Users\dougl\projects\agent-harness` | Private Git authority for the shared harness | No | Yes |
| `C:\Users\dougl\projects\docket` | Docket source authority | No | Yes |
| `C:\Users\dougl\projects\general-ai` | This coordination repository | No | Yes |
| `C:\Users\dougl\Data\Projects\general-ai` | Local coordination data | Mixed | No |
| `C:\Users\dougl\Documents\Agent Backups` | Curated value-free recovery artifacts | Yes | No |
| `C:\Users\dougl\My Drive\Capsule` | Primary transferable computer-rebuild package | Yes | No |
| `C:\Users\dougl\OneDrive` | Preserved retired data and legacy-worktree root pending an exact retention decision; no application dependency | No | No |

## Data flow

1. Product adapters load the shared harness and the nearest project contract.
2. The project-sync manager asks GitHub CLI for repositories under the configured account and topic, then applies local path conventions. Static repository inventory is unnecessary; exceptions require repository evidence.
3. Each discovered GitHub repository carries its project source, portable rules, handoffs, and small versionable data into `C:\Users\dougl\projects`.
4. The manager uses each project data manifest to restore excluded and live mutable databases, records, inputs, outputs, and other declared data. Twenty-five of 27 repositories already have this extension point.
5. GitHub receives versioned source and safe documentation.
6. SQLite-safe exports and value-free recovery pointers enter `Documents\Agent Backups`.
7. Capsule tooling from `C:\Users\dougl\projects\agent-harness\.agents\capsule` packages the shared global harness, bootstrap tools, repository-discovery configuration, account identifiers, and integrity hashes. The current workspace payload is scheduled for removal and remains frozen until the replacement transport passes.
8. Google Drive syncs the generated `My Drive\Capsule` bootstrap artifact; Agent Backups remain the dated local recovery authority.
9. Secret values reach approved child processes through exact Bitwarden Password Manager broker tuples.

## Integrations

| System | Direction | Authentication name | Failure behavior |
|---|---|---|---|
| GitHub | Both | GitHub Windows keyring | Stop publication; offline Git bundles remain available |
| Bitwarden Password Manager | Inbound | Interactive `BW_SESSION` plus item/field tuple metadata | Broker fails closed; secret values stay out of files |
| Google Drive | Outbound backup | Google account owned by Douglas | Capsule and Agent Backups remain locally usable |
| Docket cloud sync | Both | `REVIEW_SECRET` | Local SQLite and outbox remain authoritative |
| Claude, Codex, Cursor | Inbound rules and local writes | Product-owned login/session | Project contract remains portable through Git |

## Ownership and concurrency

- A repository gets one canonical local path under `C:\Users\dougl\projects`.
- A writable task gets one branch, one worktree, and one owner.
- Active worktrees remain at their current paths until their owning session reaches a handoff point.
- Shared runtime data uses project-specific paths and task-specific test stores.
- `MIGRATION.md` records every cutover, preserved recovery source, verification result, and remaining data-retention decision.

## Update rule

Update this file whenever a core document, source-of-truth path, data flow, owner, integration, or concurrency boundary changes.

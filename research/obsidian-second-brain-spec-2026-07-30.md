---
type: specification
status: proposed
created: 2026-07-30
topic: agent-accessible Obsidian second brain
---

# Agent-accessible Obsidian second brain — proposed specification

## 1. Product intent

Build a portable knowledge system that helps Douglas capture, retrieve, connect, maintain, and reuse information across desktop, phone, local agents, and cloud agents. The system must preserve human authorship, expose a deliberate cloud boundary, and make every automated change reviewable and recoverable.

## 2. Users and environments

- Douglas in the active personal Obsidian vault on Windows.
- Douglas in Obsidian on phone and other personal devices.
- Local Codex, Claude, and Cursor agents with approved filesystem access.
- Codex and Claude cloud agents working from fresh GitHub checkouts.
- A trusted local bridge that exports, imports, verifies, snapshots, and records receipts.

## 3. Authorities

| Concern | Authority |
|---|---|
| Complete personal knowledge | Active personal Obsidian vault |
| Human-device synchronization | Obsidian Sync |
| Cloud-visible knowledge | Private Agent Brain Git repository |
| Cloud changes | Branches and pull requests |
| Human approval | GitHub review or Docket |
| Vault mutation | Trusted local bridge or explicitly approved local agent |
| Note schema | Agent Brain `SCHEMA.md` plus machine-readable schema |
| Path and ownership map | Agent Brain `MAP.md` |
| Protected content | Global harness exclusions and export allowlist |
| History and rollback | Git, Obsidian Sync history, and pre-apply snapshots |

## 4. Scope

The first version includes:

- low-friction capture;
- a minimal typed-property schema;
- existing-entity and existing-file discovery;
- curated Maps and Bases;
- deterministic vault health checks;
- agent proposals for classification, entities, links, synthesis, resurfacing, and archive candidates;
- an allowlisted export from the personal vault;
- a private Git-backed Agent Brain;
- cloud-agent read access and proposal-only writes;
- human review;
- snapshot, apply, verify, rollback, and receipts;
- phone access to the personal vault and approved imported results.

## 5. Non-goals

- automatic bulk reorganization of the personal vault;
- autonomous deletion, merging, or overwriting of human-authored prose;
- whole-vault exposure to routine cloud agents;
- a large plugin stack;
- replacing project `TASK.md`, Docket, GitHub, or application databases;
- storing binaries, caches, embeddings, credentials, or Obsidian Sync state in Agent Brain;
- building a hosted semantic service before retrieval data shows a need.

## 6. Functional requirements

### Capture and lifecycle

- **FR-001:** The system MUST provide one obvious Inbox for unprocessed capture in each participating vault.
- **FR-002:** A captured item MUST remain valid Markdown when every community plugin is disabled.
- **FR-003:** The system MUST support a lifecycle of capture, normalize, discover, classify, enrich, review, promote, resurface, and archive.
- **FR-004:** An agent MUST search existing files, entities, tags, properties, folders, templates, skills, and workflows before proposing a new one.
- **FR-005:** Promotion from capture to durable knowledge MUST retain source and provenance.

### Schema and organization

- **FR-006:** One versioned schema MUST define allowed note types, property names, types, required fields, and controlled values.
- **FR-007:** The common property set MUST remain minimal and human-readable.
- **FR-008:** Canonical entities MUST have stable IDs and aliases.
- **FR-009:** An entity proposal MUST search names, aliases, IDs, and likely duplicates before creation.
- **FR-010:** Folder placement MUST remain a stable navigation aid; links, Properties, Bases, Maps, and search MUST support cross-cutting retrieval.
- **FR-011:** A new Map MUST require demonstrated navigation need or an explicit human request.
- **FR-012:** Existing personal-vault folders MUST remain in place during the initial rollout.

### Growth

- **FR-013:** Agents MAY propose entities, links, Maps, synthesis notes, resurfaced notes, contradictions, research gaps, project closeouts, and archive candidates.
- **FR-014:** Each generated artifact MUST declare its type, source, intended consumer, review state, and creation time.
- **FR-015:** Each generated factual claim MUST cite a source note or external source.
- **FR-016:** Link suggestions MUST include a short rationale and confidence.
- **FR-017:** The system MUST cap generated notes and link suggestions per run.
- **FR-018:** Derived notes MUST record source revisions or hashes and expose staleness when their sources change.

### Health and repair

- **FR-019:** A deterministic scanner MUST detect invalid YAML, missing required properties, property-type conflicts, duplicate IDs, duplicate titles, unresolved links, missing attachments, orphans, stale Inbox items, conflicting aliases, missing provenance, stale derived notes, conflict copies, and excluded-path violations.
- **FR-020:** Health scanning MUST run before model-based repair suggestions.
- **FR-021:** A repair batch MUST contain exact paths, reasons, source hashes, and a preview diff.
- **FR-022:** The system MUST snapshot affected files before applying an approved repair batch.
- **FR-023:** The system MUST rerun health checks after applying a batch.
- **FR-024:** The system MUST roll back automatically when defined health invariants worsen or application fails partway.
- **FR-025:** Every mutation batch MUST produce an audit receipt.
- **FR-026:** Move, rename, merge, archive, and delete operations MUST require human approval during the initial rollout.
- **FR-027:** Permanent deletion MUST remain blocked unless separately authorized through the existing safety boundary.

### Human review

- **FR-028:** Agent suggestions MUST remain distinguishable from approved knowledge.
- **FR-029:** Review MUST show changed paths, rationale, sources, confidence, and diff.
- **FR-030:** Multiple low-risk proposals SHOULD be consolidated into one bounded review item.
- **FR-031:** Rejected proposals MUST remain recorded long enough to prevent immediate repetition.
- **FR-032:** Review queues MUST have age and size indicators.

### Personal-vault boundary

- **FR-033:** The personal vault MUST remain the complete human knowledge authority.
- **FR-034:** The cloud projection MUST use an explicit allowlist.
- **FR-035:** Global protected paths MUST be excluded from scanning, export, logs, tests, and cloud access.
- **FR-036:** Export MUST fail closed when a path is ambiguous, escaped, reparse-linked, or outside the allowlist.
- **FR-037:** Human-authored zones MUST be read-only to proposal-generation workflows.
- **FR-038:** The bridge MUST refuse a stale proposal when its recorded base hash no longer matches.

### Agent Brain

- **FR-039:** Agent Brain MUST be a private Git repository containing portable Markdown and value-safe configuration.
- **FR-040:** Agent Brain MUST open as an Obsidian vault without conversion.
- **FR-041:** Agent Brain MUST contain concise `AGENTS.md`, `MAP.md`, `SCHEMA.md`, setup, and verifier owners.
- **FR-042:** Agent Brain MUST exclude credentials, Sync state, `.obsidian` workspace state, caches, embeddings, generated dependency folders, and undeclared binaries.
- **FR-043:** Cloud agents MUST receive Agent Brain through normal repository checkout.
- **FR-044:** Cloud agents MUST write only to declared proposal, agent-note, or explicitly assigned paths.
- **FR-045:** Cloud changes MUST arrive through a reviewable branch or pull request.
- **FR-046:** The repository verifier MUST work in a clean Linux checkout.
- **FR-047:** Every cloud-visible note type MUST have a fixture and schema test.

### Synchronization

- **FR-048:** Obsidian Sync MUST remain the human-device transport for the personal vault.
- **FR-049:** Git MUST remain the cloud-agent transport for Agent Brain.
- **FR-050:** No directory MAY have simultaneous Obsidian Desktop Sync, Headless Sync, and Git writers.
- **FR-051:** If Headless Sync is adopted, its working copy and the Git mirror MUST be separate directories connected by a validating bridge.
- **FR-052:** Sync/import transactions MUST use one writer, bounded batches, source hashes, and post-sync verification.
- **FR-053:** The system MUST surface conflicts and stop before choosing a winner automatically.

### Local integrations and plugins

- **FR-054:** Core Obsidian capabilities MUST be evaluated before adding a community plugin.
- **FR-055:** Each community plugin MUST declare purpose, owner, version, platform support, privileges, data written, removal criterion, and acceptance test.
- **FR-056:** Plugin claims in documentation MUST be verified against the active vault.
- **FR-057:** A local REST or MCP adapter MUST bind to the local trust boundary and MUST remain unavailable to routine internet clients.
- **FR-058:** A plugin failure MUST leave canonical notes readable and recoverable as plain files.

### Review cadence and metrics

- **FR-059:** The system MUST support daily capture, weekly review, and monthly maintenance.
- **FR-060:** The monthly review MUST include a restore drill, plugin drift check, schema drift check, and automation value review.
- **FR-061:** The system MUST measure Inbox age, retrieval success, unresolved health defects, accepted suggestion rate, false-link rate, conflict rate, rollback rate, generated-note growth, and human review time.
- **FR-062:** Additional autonomy MUST require repeated clean runs and explicit approval for a named operation class.

## 7. Safety and authority model

Automation uses four levels:

| Level | Authority | Initial examples |
|---|---|---|
| Observe | Read allowed files and produce health counts | Broken-link and schema report |
| Suggest | Create a proposal with evidence | Link, entity, archive candidate |
| Apply reviewed | Apply an approved bounded diff with snapshot and receipt | Metadata repair, approved new entity |
| Auto-apply bounded | Apply a proven reversible rule within a quota | Whitespace or tested property normalization |

The first release uses Observe and Suggest. Apply-reviewed is enabled only after the snapshot, stale-base, rollback, and receipt tests pass. Auto-apply requires separate approval for each rule class.

## 8. Data flow

```text
personal vault
  → allowlist export
  → validate and hash
  → Agent Brain main branch
  → cloud-agent branch / PR
  → review
  → stale-base check
  → snapshot
  → trusted apply
  → health verification
  → receipt
  → Obsidian Sync
  → phone and desktop
```

## 9. Acceptance criteria

- **AC-001 / FR-001–FR-005:** Given a rough Inbox note, when the organizer runs, then it finds existing candidates and produces a sourced proposal without modifying the original.
- **AC-002 / FR-006–FR-012:** Given fixtures for every note type, when schema validation runs, then valid notes pass, malformed or duplicate entities fail with exact evidence, and the folder tree remains unchanged.
- **AC-003 / FR-013–FR-018:** Given repeated grounded mentions, when growth runs, then it proposes at most the configured quota of entities, links, or synthesis notes with sources and review state.
- **AC-004 / FR-019–FR-025:** Given fixtures containing each supported defect, when health and repair preview run, then every defect is detected deterministically and every proposed patch includes paths, hashes, reasons, and diff.
- **AC-005 / FR-022–FR-027:** Given an approved repair whose application is interrupted, when recovery runs, then affected files return to their snapshots and the receipt records the failure.
- **AC-006 / FR-028–FR-032:** Given multiple proposals, when a review card is produced, then suggestions remain separate from approved knowledge and the card shows sources, confidence, diffs, count, and age.
- **AC-007 / FR-033–FR-038:** Given protected, escaped, reparse-linked, stale, and allowed files, when export/import runs, then only current allowed content moves and every unsafe case fails closed without leaking content.
- **AC-008 / FR-039–FR-047:** Given a clean Linux checkout of Agent Brain, when a Codex or Claude cloud setup runs, then the agent reads the portable contract, verifies fixtures, edits only allowed paths, and produces a reviewable branch or pull request.
- **AC-009 / FR-048–FR-053:** Given concurrent or conflicting edits, when synchronization runs, then one writer owns each directory, conflicts surface, and no automatic winner is selected.
- **AC-010 / FR-054–FR-058:** Given all community plugins disabled, when the vault opens and verification runs, then canonical notes, Maps, schema, and recovery remain usable.
- **AC-011 / FR-059–FR-062:** Given four weeks of runs, when the monthly review executes, then it reports the required metrics and grants no new autonomy without an explicit approved rule class.
- **AC-012 / end-to-end:** Given a safe phone capture, when the complete flow runs, then the note reaches the personal vault, selected context reaches Agent Brain, a cloud agent proposes a grounded update, a human approves it, the bridge applies and verifies it, and the approved result appears on phone with a complete receipt.

## 10. Rollout

1. Reconcile current documentation with the live vault and retire stale Drive/MCP/plugin claims.
2. Build a disposable fixture and schema.
3. Build health checks in observe-only mode.
4. Create the private Agent Brain repository.
5. Implement read-only allowlist export.
6. Prove clean Codex and Claude cloud checkouts.
7. Enable PR-only proposals.
8. Implement snapshot, reviewed apply, verification, rollback, and receipts.
9. Connect Docket review when publication is available.
10. Test the full phone-to-cloud-to-phone flow.
11. Pilot optional Headless bridge in isolated directories.
12. Review measured value before adding plugins, semantic services, or autonomy.

## 11. Open decisions

- Exact Agent Brain repository name.
- Exact export allowlist.
- Initial entity types and required fields.
- Daily and weekly proposal quotas.
- Docket card grouping and decision vocabulary.
- Whether Agent Brain also receives its own Obsidian Sync remote vault.
- Whether the bridge runs on the desktop or a persistent host.
- Metrics and thresholds required before each auto-apply rule.

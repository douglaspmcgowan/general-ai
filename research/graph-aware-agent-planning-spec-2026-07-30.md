---
type: specification
status: proposed
created: 2026-07-30
topic: graph-aware agent planning and coordination
---

# Graph-aware agent planning and coordination — proposed specification

## Product

### Problem

Long, messy requests can contain questions, changes, constraints, investigations, decisions, and future work. A flat checklist records them, while the coordinator must still remember dependencies, safe concurrency, shared-resource conflicts, agent ownership, and completion closure. That creates missed asks, premature work, duplicate effort, and agents that appear active after their useful work is complete.

The harness already has a single durable task authority in `TASK.md`. The proposed capability enriches that authority with minimal graph semantics and generates disposable operational views.

### Users and jobs

- A human needs one readable task board that shows what is ready, blocked, active, complete, or awaiting a decision.
- A lead agent needs to extract all obligations, select a suitable planning mode, find safe parallel work, and reconcile completion.
- A worker agent needs a bounded assignment, authoritative inputs, writable boundary, expected artifact, verifier, and stop condition.
- A reviewer needs traceable requirements and evidence without reading entire agent transcripts.
- A hook or adapter needs deterministic task, dependency, ownership, and lifecycle data across Codex and Claude.

### Outcomes

1. Preserve every user obligation in one durable task authority.
2. Compute ready and blocked work consistently.
3. Increase useful parallelism while preventing file and runtime-resource collisions.
4. Improve plan quality through evidence, readiness, verification, and closure.
5. Make worker lifecycle and handoffs inspectable.
6. Measure whether graph behavior improves total completion efficiency.

### Scope

- task extraction and stable identity;
- progressive planning modes;
- explicit dependencies and readiness;
- owner, workspace, write, and shared-resource boundaries;
- subagent dispatch and lifecycle records;
- verification and completion rules;
- derived task and run views;
- cross-product execution adapters;
- migration, metrics, and rollback.

### Non-goals

- a graph database;
- a second task authority;
- a general knowledge graph;
- a mandatory code-graph index;
- storage of model reasoning transcripts;
- autonomous permission expansion;
- forced graph planning for trivial work;
- replacement of Git, worktrees, native agent APIs, or repository tests.

### Delivery slices

The requirements describe the long-term capability. Delivery is deliberately incremental:

| Slice | Included capability | Gate |
|---|---|---|
| MVP 1 — read-only task view | parse stable IDs and `after`; validate references and cycles; derive and explain dependency-ready/blocked work; render a disposable view; preserve legacy flat tasks | fixture and shadow evaluation |
| MVP 2 — planning and resources | plan contract, question coverage, permission preflight, file/resource conflicts, UI-plan projection | measured reduction in omissions or collisions |
| MVP 3 — worker lifecycle | coordinator-owned status changes, operational leases, stale-worker audit, bounded failure propagation and closure | live trials with manual dispatch |
| Experimental | priority scoring, automatic dispatch, run/provenance graph, broad metrics, workflow promotion | separate approval after evidence |

Only MVP 1 belongs to the first implementation. Each later slice requires its own task, acceptance boundary, independent review, and approval.

## Functional

### User stories

- As a human, I can read `TASK.md` and understand current work without opening generated files.
- As a lead agent, I can convert a messy prompt into complete, discrete, traceable obligations before implementation.
- As a lead agent, I can see the current ready frontier and why each other task is blocked.
- As a worker, I receive one bounded contract and know when to stop.
- As a reviewer, I can connect every completion claim to an artifact and verifier.
- As a cloud or local agent, I can use the same portable task semantics through a product-specific adapter.

### Requirements

#### Authority and identity

- **FR-001:** `TASK.md` shall remain the sole repository task authority.
- **FR-002:** Every task shall have a unique, stable task ID.
- **FR-003:** A generated graph, cache, UI plan, runtime task list, or visualization shall be derived from `TASK.md`.
- **FR-004:** A conflict between `TASK.md` and a derived view shall be resolved by regenerating the derived view.
- **FR-005:** Completed task history shall remain human-readable and may be collapsed or archived through an approved process.

#### Prompt extraction and planning

- **FR-006:** A multi-intent prompt shall be parsed into discrete tasks, questions, investigations, decisions, constraints, and exclusions before implementation.
- **FR-007:** Every required outcome shall map to a task, constraint, explicit decision, or user-approved deferral; every user question shall retain a task ID until the answer is delivered and linked as completion evidence.
- **FR-008:** Newly discovered required work shall enter `TASK.md` before execution.
- **FR-009:** The planner shall select among direct, compact, discovery, execution, parallel, and long-running modes.
- **FR-010:** The selected mode shall be the smallest mode that represents material uncertainty, dependencies, permissions, or handoffs.
- **FR-011:** A material plan shall state evidence checked, observable outcome, scope, tasks, readiness, dependencies, ownership, verification, and closure.
- **FR-012:** A long-running or externally mutating plan shall perform a permission preflight before its long-running phase.
- **FR-013:** Permission preflight shall identify credentials, external writes, destructive actions, production effects, and sandbox escalations without recording credential values.
- **FR-014:** Replanning shall record a reason tied to changed requirements, disproven evidence, failed verification, missing permission, unavailable dependency, or discovered required work.

#### Task graph

- **FR-015:** A task may declare zero or more predecessor task IDs.
- **FR-016:** A dependency edge shall mean that the downstream task requires the predecessor’s artifact or verified state.
- **FR-017:** The verifier shall reject duplicate IDs, missing dependency references, self-dependencies, and cycles.
- **FR-018:** MVP 1 shall derive dependency-ready and blocked status from authoritative task markers and predecessor state; active, human-blocked, failed, verified, and cancelled shall follow the state table below, while stale remains an operational worker observation.
- **FR-019:** A task shall be dependency-ready when its marker is actionable and every predecessor is satisfied; after MVP 2, it shall be dispatch-ready only when permissions, ownership, boundaries, expected output, verifier, and resource availability also pass.
- **FR-020:** An unfinished graph with no ready or active task shall produce a deadlock diagnostic.
- **FR-021:** The derived view shall explain each blocker.
- **FR-022:** The derived view shall identify descendant unlock counts and longest unweighted dependency chains; time-based critical paths require duration estimates and remain outside MVP 1.
- **FR-023:** Graph visualization shall be optional and shall preserve the same semantics as the text view.
- **FR-024:** Graph behavior shall remain inactive for direct work that gains no scheduling or closure value from dependencies.

#### Ownership and resources

- **FR-025:** Every writable active task shall have one declared owner.
- **FR-026:** Every writable active task shall declare a workspace or worktree and writable file or module boundary.
- **FR-027:** A task shall declare mutable shared resources such as ports, databases, migrations, deployment targets, external stores, credential sessions, or provider quotas; credential values shall remain outside task state.
- **FR-028:** Two active tasks shall not hold conflicting writable or shared-resource claims under the conflict rules below.
- **FR-029:** Read-only research tasks may share source files and services when their access is safe and permitted.
- **FR-030:** Claims shall be released when a task is verified, cancelled, reassigned, or explicitly suspended.

#### Scheduling and delegation

- **FR-031:** Only dispatch-ready tasks may be dispatched.
- **FR-032:** Scheduling shall respect the runtime’s current concurrency capacity.
- **FR-033:** The lead agent shall consume one slot when it must coordinate, synthesize, or respond.
- **FR-034:** Candidate scheduling priority may consider user priority, unweighted dependency depth, downstream unlock count, context savings, shared-resource risk, expected review cost, and retry risk.
- **FR-035:** Eligibility constraints shall take precedence over advisory priority scores.
- **FR-036:** Each worker contract shall include objective, required questions, authoritative inputs, output artifact and format, read/write boundary, satisfied dependencies, shared resources, prohibited paths, verifier, budget, stop condition, and failure reporting.
- **FR-037:** Tightly coupled synthesis and same-file changes shall have one integration owner.
- **FR-038:** Bulky worker output shall be persisted in the declared artifact; the handoff shall provide a bounded summary and evidence references.
- **FR-039:** A worker shall report blockers and discoveries that change dependencies or scope.

#### Lifecycle, failure, and recovery

- **FR-040:** After the coordinator marks a task active in `TASK.md`, a dispatched task shall receive an expiring operational lease with worker identity, authoritative revision, claim time, last progress time, expected artifact, verifier, and observed worker state.
- **FR-041:** The system shall distinguish active, idle, stale-suspected, failed, waiting-for-human, completed, and closed workers.
- **FR-042:** A read-only status and artifact check shall precede reassignment or termination of a stale-suspected worker.
- **FR-043:** A transient failure may receive a bounded retry within the task’s declared budget.
- **FR-044:** A repeated identical failure shall exhaust automatic retries and surface evidence.
- **FR-045:** A dependency or interface failure shall block affected descendants and trigger replanning.
- **FR-046:** A shared-resource collision shall stop conflicting writers, preserve evidence, and require ownership reconciliation.
- **FR-047:** A permission or credential requirement shall transition the task to human-blocked with an exact resume action.
- **FR-048:** Side-effecting work that may be retried shall declare an idempotency or duplicate-prevention strategy.
- **FR-049:** A worker completion shall require its artifact, output-contract satisfaction, verifier evidence, uncertainty record, released claims, and a closure action.
- **FR-050:** A run shall be complete only when required tasks are verified, explicitly deferred by the user, or superseded by a task or decision that preserves the requested outcome, and every worker and resource claim is terminal.

#### Verification and evidence

- **FR-051:** Every material task shall name an exact verifier or evidence contract before execution.
- **FR-052:** A task shall become verified only after its declared evidence exists.
- **FR-053:** Parent verification shall check contradictions, missing outputs, duplicate work, stale assumptions, and integration behavior.
- **FR-054:** Self-reported confidence shall not satisfy a verifier.
- **FR-055:** The UI plan shall mirror the active actionable slice of `TASK.md` and shall be refreshed after task-state changes.

#### Derived views and metrics

- **FR-056:** A human-readable derived view shall show the ready frontier, blockers, owners, resource conflicts, stale claims, and next verifier.
- **FR-057:** After a durable `TASK.md` transition, a compact append-only run record may capture the transition, authoritative revision, dispatches, artifacts, checks, replans, and closures.
- **FR-058:** Run records shall omit credential values and private reasoning transcripts.
- **FR-059:** A run/provenance graph may be regenerated from run records for diagnosis.
- **FR-060:** The system shall measure total elapsed time, planning time, execution time, human review time, retries, duplicate work, blocked time, verifier failures, task coverage, and closure failures.
- **FR-061:** Graph activation thresholds and scheduling weights shall remain configurable and evidence-driven.
- **FR-062:** The first rollout shall run in shadow mode before automatic dispatch.

#### Portability and compatibility

- **FR-063:** The task schema shall remain product-neutral and repository-portable.
- **FR-064:** Codex and Claude adapters shall map portable task nodes to their native worker mechanisms without changing task meaning.
- **FR-065:** Product-local runtime state shall remain derived and disposable.
- **FR-066:** Existing task entries without graph fields shall remain valid flat tasks.
- **FR-067:** Disabling graph features shall preserve `TASK.md` history and ordinary task operation.

#### Runtime precedence and recovery

- **FR-068:** Only the coordinator shall change durable task status in `TASK.md`.
- **FR-069:** An operational lease or run event shall not mark a task verified, failed, cancelled, deferred, or human-blocked.
- **FR-070:** Runtime events shall reference the `TASK.md` revision or content hash written before the event.
- **FR-071:** Restart recovery shall begin from `TASK.md` and a read-only audit of live workers and declared artifacts.
- **FR-072:** Missing, stale, corrupt, or conflicting lease and event data shall not change authoritative task status.

### Entities and rules

#### Task

Required:

- `id`
- `outcome`
- `status`
- `owner` for writable active work
- `verifier` for material work

Optional:

- `source_intent`
- `parent`
- `after`
- `workspace`
- `writes`
- `resources`
- `inputs`
- `artifact`
- `permission_state`
- `retry_budget`
- `blocker`
- `evidence`
- `discovered_from`

#### Authoritative task-state semantics

The visible checkbox remains the authoritative lifecycle marker. Metadata explains the state and cannot contradict it.

| Meaning | Marker | Required metadata | Allowed next meanings |
|---|---|---|---|
| pending or ready | `[ ]` | blocker when blocked; readiness is derived | active, human-blocked, failed, verified, cancelled |
| active | `[~]` | owner and current output | pending, human-blocked, failed, verified, cancelled |
| human-blocked | `[?]` | blocker and exact resume action | pending, active, cancelled |
| failed or parked | `[!]` | failure evidence and next decision | pending, active, cancelled |
| verified | `[x]` | verifier evidence | reopened pending task through an explicit correction |
| cancelled or superseded | `[x]` | user-approved deferral or superseding task/decision | reopened pending task through an explicit correction |

Dependency-ready and blocked are MVP 1 views over `[ ]`. Dispatch-ready adds the MVP 2 execution contract. Stale is derived from worker observations and never changes the task marker by itself.

#### Worker claim

- task ID;
- worker or task-run ID;
- claimed timestamp;
- last meaningful progress timestamp;
- workspace;
- writes and shared resources;
- expected artifact;
- verifier;
- retry attempt;
- terminal reason.

Worker claims are runtime coordination data and do not become a second task authority.

A lease is created only after an active marker is written. It expires without altering the task. Restart recovery reads `TASK.md`, audits live workers and artifacts, and either recreates a consistent lease or asks the coordinator to reconcile the task.

#### Run event

- timestamp;
- task ID;
- event type;
- actor;
- artifact or evidence reference;
- reason;
- preceding event ID when required.

Events support diagnosis and may be pruned under a documented retention policy.

#### Resource-conflict rules

- A file claim conflicts with the same file and with any claimed parent directory.
- Directory and module claims conflict when their normalized paths overlap.
- Separate worktrees avoid source-file collisions during execution; they may still conflict at integration and through shared runtimes.
- A database or migration target permits one schema-changing owner at a time.
- A port, deployment target, external mutable store, credential session, or provider quota conflicts when isolation is absent.
- Read-only access may coexist when the underlying resource supports it.
- Resource names and stable IDs may be recorded; values and tokens remain excluded.

## Acceptance

### Scenarios

- **AC-001 — One authority**
  - Given `TASK.md` and a stale generated graph,
  - When regeneration runs,
  - Then the graph matches `TASK.md` and no generated state overwrites it.

- **AC-002 — Complete extraction**
  - Given a messy prompt containing changes, questions, constraints, exclusions, and future work,
  - When task extraction runs,
  - Then every obligation maps to a task, constraint, decision, or approved deferral, and every question keeps a task ID until its delivered answer is linked as evidence.

- **AC-003 — Dependency validation**
  - Given duplicate IDs, a missing reference, a self-edge, or a cycle,
  - When graph validation runs,
  - Then it fails with the exact offending IDs and edges.

- **AC-004 — Ready frontier**
  - Given independent tasks and a dependency chain,
  - When readiness is calculated,
  - Then tasks with actionable markers and satisfied predecessors appear dependency-ready, and after MVP 2 only tasks with valid execution contracts appear dispatch-ready.

- **AC-005 — Resource conflict**
  - Given two otherwise-ready tasks with overlapping file/directory claims or the same unisolated port, database migration target, deployment target, or credential session,
  - When scheduling runs,
  - Then at most one is eligible and the other displays the conflict.

- **AC-006 — Dynamic concurrency**
  - Given a runtime with four total slots and an active coordinating lead,
  - When five independent tasks are ready,
  - Then at most three workers are dispatched and remaining tasks stay ready.

- **AC-007 — Delegation contract**
  - Given a ready delegated task,
  - When its worker is created,
  - Then the dispatch contains every field required by FR-036.

- **AC-008 — Failure propagation**
  - Given a failed predecessor with dependent descendants,
  - When failure is recorded,
  - Then affected descendants become blocked, unrelated ready work remains eligible, and the replan record names the failed dependency or interface evidence.

- **AC-009 — Bounded retry**
  - Given a repeated identical failure after the retry budget is consumed,
  - When the task reports failure again,
  - Then automatic retries stop and evidence is surfaced.

- **AC-010 — Stale worker safety**
  - Given an expired progress threshold,
  - When the stale-agent audit runs,
  - Then it checks status and artifacts before any reassignment or termination.

- **AC-011 — Verified completion**
  - Given a worker reports success without verifier evidence,
  - When completion reconciliation runs,
  - Then the task remains unverified.

- **AC-012 — Lifecycle closure**
  - Given every required task is verified, user-deferred, or superseded with the requested outcome preserved,
  - When the run closes,
  - Then all workers and resource claims are terminal and the UI plan agrees with `TASK.md`.

- **AC-013 — Flat-task compatibility**
  - Given an existing small task with no dependencies,
  - When graph support is enabled,
  - Then the task remains valid and can execute through the ordinary flow.

- **AC-014 — Rollback**
  - Given graph support is disabled,
  - When ordinary task tooling runs,
  - Then `TASK.md` remains complete and usable with no migration loss.

- **AC-015 — Shadow evaluation**
  - Given at least ten historical messy prompts and several live major tasks,
  - When the derived scheduler is compared with actual human decisions,
  - Then coverage uses user obligations as its denominator; readiness and conflict errors use reviewed scheduling decisions as their denominator; elapsed, planning, execution, review, retry, duplicate-work, blocked-time, verifier-failure, and closure-failure totals share a defined run window; and the report is reviewed before automatic dispatch is approved.

- **AC-016 — Runtime precedence**
  - Given stale, conflicting, corrupt, or missing lease/event data,
  - When restart recovery runs,
  - Then authoritative task markers remain unchanged, live workers and artifacts are audited read-only, and runtime data is regenerated or flagged for coordinator reconciliation.

- **AC-017 — State transitions**
  - Given legacy flat tasks and tasks moving through active, human-blocked, failed, verified, and superseded meanings,
  - When validation runs,
  - Then each authoritative marker and required metadata follows the state table and stale worker observations do not alter task status.

- **AC-018 — Planning and permission preflight**
  - Given a long-running task with an external write and credential need,
  - When planning runs,
  - Then it selects an execution-capable mode, records inspected evidence and a verifier, identifies the permission before long execution, and stores no credential value.

- **AC-019 — Human-block resume and claim release**
  - Given an active worker encounters a missing permission,
  - When the coordinator records the block,
  - Then `TASK.md` contains the exact resume action, the lease and resource claims are released or explicitly suspended, and affected descendants explain the block.

- **AC-020 — Cross-product conformance**
  - Given the same portable task fixture,
  - When Codex and Claude adapters derive readiness, blockers, owner, output, and verifier,
  - Then both adapters produce equivalent task meaning and keep product-local runtime state disposable.

### Requirement-to-acceptance traceability

| Area | Requirements | Acceptance |
|---|---|---|
| authority and compatibility | FR-001–005, FR-063–072 | AC-001, AC-013, AC-014, AC-016, AC-020 |
| extraction and planning | FR-006–014 | AC-002, AC-018 |
| graph validation/readiness | FR-015–024 | AC-003, AC-004, AC-008, AC-017 |
| ownership and resources | FR-025–030 | AC-005, AC-019 |
| scheduling and delegation | FR-031–039 | AC-006, AC-007 |
| lifecycle and recovery | FR-040–050 | AC-008–012, AC-016, AC-019 |
| verification and projection | FR-051–055 | AC-011, AC-012 |
| views and measurement | FR-056–062 | AC-015 |

### Non-functional requirements

- **NFR-001 — Human readability:** ordinary task state shall remain understandable in a text editor and Obsidian.
- **NFR-002 — Determinism:** identical authoritative input shall produce identical derived task views.
- **NFR-003 — Portability:** parsing and validation shall work on supported Windows local and repository-based cloud environments.
- **NFR-004 — Safety:** the system shall preserve unrelated changes, prohibited paths, credential boundaries, and permission rules.
- **NFR-005 — Performance:** derived-view generation shall add negligible delay to normal task-hook execution; the implementation shall set a measured threshold before release.
- **NFR-006 — Observability:** validation and scheduling decisions shall explain their task IDs, edges, and conflicts.
- **NFR-007 — Recoverability:** derived state may be deleted and regenerated from durable sources.
- **NFR-008 — Bounded growth:** active operational state shall scale with active work; completed history and events shall follow documented retention.
- **NFR-009 — Cross-agent consistency:** Codex and Claude adapters shall pass the same conformance fixtures.
- **NFR-010 — Security:** logs, views, events, and Docket artifacts shall remain value-safe and pass secret scanning.

### Open decisions

1. Choose the minimal task-field syntax after fixture testing: inline fields, fenced YAML, or a constrained hybrid.
2. Calibrate the graph activation threshold; the initial hypothesis is six active tasks plus two dependency edges, multiple owners, or a shared-resource conflict.
3. Choose the stale-progress threshold per task class.
4. Decide whether compact run events belong in an ignored local file or a committed append-only log.
5. Define measured hook-latency limits before implementation.
6. Decide whether one automatic retry should be the default for repeat-safe local work.
7. Decide when a recurring process qualifies for promotion to an executable workflow graph.

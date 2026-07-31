---
type: recon
status: proposed
created: 2026-07-30
topic: graph engineering, agent planning, and subagent coordination
---

# Graph engineering, agent planning, and subagent coordination recon

## Executive recommendation

Add a small dependency-aware layer to the existing `TASK.md` system. Keep `TASK.md` as the sole task authority. A parser should derive ready, blocked, parallel, stale, and resource-conflicting work from stable task IDs and explicit dependency fields.

This captures the useful part of task graphs without introducing a graph database, a second task ledger, or a new orchestration framework. The richer options remain reversible future steps:

1. use a flat checklist for small work;
2. activate a derived task DAG when dependencies or resource conflicts affect scheduling;
3. capture a derived run graph for diagnosis;
4. promote a recurring, stable process to a workflow graph only after repetition proves the need.

The research supports this staged approach. Graph-shaped workflows are established engineering patterns, while “graph engineering” is a recent umbrella label that combines several different graph families. LangChain itself describes the term as newly popular and reports that an overly predefined graph made open-ended research harder, leading to a hybrid design with a known outer workflow and flexible agent loops inside it. [LangChain](https://www.langchain.com/blog/3-years-of-graph-engineering-with-langgraph)

## Plain-language definitions

A graph is a collection of things and the relationships between them. Different graphs solve different problems:

| Graph | Things represented | Relationships | Useful question |
|---|---|---|---|
| Code graph | files, classes, functions, routes, tests | imports, calls, references, contains | “What code will this change affect?” |
| Knowledge graph | people, concepts, documents, claims | related-to, caused-by, belongs-to, valid-during | “How are these facts connected?” |
| Task graph or DAG | tasks, decisions, verification steps | requires, blocks, parent-of | “What is ready, and what can run together?” |
| Workflow graph | tools, functions, agents, approvals | next, branch, retry, join | “What component runs next?” |
| State graph | pending, ready, active, blocked, verified | claim, pause, retry, finish | “Which lifecycle changes are allowed?” |
| Communication graph | coordinator, workers, reviewers | delegates-to, reports-to, hands-off-to | “Who needs which context?” |
| Run graph | agent runs, tool calls, artifacts, checks | spawned, consumed, produced, verified | “What actually happened?” |

The proposed harness change concerns a task graph and a derived run graph. Code graphs and knowledge graphs belong to separate evaluations because they solve different retrieval problems.

## What the trend contains

### Established foundations

- Conventional dependency DAGs are mature. Systems such as Apache Airflow use dependencies, retries, timeouts, schedules, and trigger rules to decide which work may run. [Apache Airflow](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/dags.html)
- Workflow and state graphs are established software patterns. LangGraph documents retries and checkpoint recovery alongside parallel graph execution. AutoGen GraphFlow documents sequential, parallel, conditional, and cyclic flows and labels the API experimental. [LangGraph](https://docs.langchain.com/oss/python/langgraph/use-graph-api), [LangGraph fault tolerance](https://docs.langchain.com/oss/python/langgraph/fault-tolerance), [AutoGen GraphFlow](https://microsoft.github.io/autogen/stable/user-guide/agentchat-user-guide/graph-flow.html)
- Code graphs have strong foundations in static analysis. LOCAGENT uses repository structure and call/import relationships for code localization. Sourcegraph uses code-graph data for definitions, references, symbols, and retrieval. [LOCAGENT](https://aclanthology.org/2025.acl-long.426/), [Sourcegraph](https://sourcegraph.com/docs/cody/core-concepts/code-graph)

### Emerging agent research

- Dynamic LLM-generated task topology and communication topology remain active research areas. DynTaskMAS, DeMAC, and G-Designer study dynamic task DAGs, manager–worker feedback, and learned communication networks. Their benchmark results do not establish universal production gains. [DynTaskMAS](https://ojs.aaai.org/index.php/ICAPS/article/view/36130), [DeMAC](https://aclanthology.org/2025.findings-emnlp.757/), [G-Designer](https://proceedings.mlr.press/v267/zhang25cu.html)
- AFlow searches over code-represented agent workflows and reported improvements on six benchmark datasets. The result supports workflow optimization as a research direction and remains bounded to those evaluations. [AFlow](https://proceedings.iclr.cc/paper_files/paper/2025/hash/5492ecbce4439401798dcd2c90be94cd-Abstract-Conference.html)
- Code-context benchmarks support hybrid retrieval. ContextBench found only marginal gains from sophisticated scaffolding, and Agent Retrieval Bench found different winners across lexical, embedding, and structural approaches. A code-graph service should therefore prove value against ordinary repository search on representative tasks. [ContextBench](https://arxiv.org/abs/2602.05892), [Agent Retrieval Bench](https://agent-retrieval-bench.github.io/)

### Practical interpretation

The useful trend is explicit, inspectable relationships: dependencies, ownership, state, evidence, and recovery. A graph database is one possible implementation and carries ingestion, synchronization, and maintenance costs. Microsoft warns that GraphRAG indexing can be expensive, which illustrates the operational burden of richer knowledge graphs. [Microsoft GraphRAG](https://github.com/microsoft/graphrag)

## Current harness

The current harness already contains most task nodes:

- `TASK.md` has stable task IDs, checkbox status, `after:` dependencies, owners, classes, blockers, and evidence.
- A line-oriented inspection of `agent-harness\TASK.md` on 2026-07-30 found 122 task records; 9 entries explicitly declared `after:` dependencies.
- The task hook currently understands checkbox states and does not calculate readiness, validate references, detect cycles, or detect resource conflicts.
- The parallelization skill separates independent, dependent, and shared-write work and needs stronger lifecycle closure.
- `WORKTREE-PROTOCOL.md` already requires an owner, worktree, writable scope, shared resources, and verifier.

The older proposal for `INTENT-LEDGER.jsonl`, `TASK-GRAPH.json`, `TASK-EVENTS.jsonl`, generated task files, and several authorities predates the consolidation around `TASK.md`. Reintroducing that structure would create duplicate state.

## What makes an effective agent plan

A useful plan is a compact execution contract grounded in inspected evidence.

### Required anatomy

1. **Evidence checked:** authoritative files, current state, baseline tests, and observed failures.
2. **Observable outcome:** one sentence describing the result and its user value.
3. **Bounded tasks:** independently verifiable state changes with clear outputs.
4. **Readiness:** required inputs, permissions, credentials, and unresolved questions.
5. **Dependencies:** edges only where one task consumes another’s verified output.
6. **Ownership:** one owner, writable boundary, mutable shared resources, and output contract.
7. **Verification:** exact acceptance evidence for each material task.
8. **Replan triggers:** failed assumptions, changed requirements, failed verifiers, missing permissions, or new required work.
9. **Closure:** durable task reconciliation and release of agents and resources.

Anthropic’s long-running-agent experiments used explicit requirements, progress state, Git history, and one-feature-at-a-time execution to reduce restart failures and premature completion. [Anthropic long-running harness](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) Its multi-agent research system found that vague delegation produced duplication and coverage gaps; effective briefs named objectives, output formats, tools or sources, and clear boundaries. [Anthropic multi-agent research](https://www.anthropic.com/engineering/multi-agent-research-system)

Practitioner guidance points in the same direction. Addy Osmani recommends focused, reviewable specifications and isolated task slices. Simon Willison recommends running the existing tests first so a plan begins from an observed baseline. Reports from developers using several parallel agents also describe lost worktree context, shared-runtime collisions, and human review becoming the bottleneck. These community reports are anecdotal and support measuring coordination overhead alongside speed. [Addy Osmani](https://addyo.substack.com/p/how-to-write-a-good-spec-for-ai-agents), [Simon Willison](https://simonwillison.net/guides/agentic-engineering-patterns/first-run-the-tests/), [parallel-agent notes](https://simonwillison.net/tags/parallel-agents/), [review-bandwidth discussion](https://www.reddit.com/r/ClaudeCode/comments/1st213z/how_are_you_managing_multiple_coding_agents_in/)

### Planning modes

| Mode | Use | Structure |
|---|---|---|
| Direct | one obvious, reversible change | execute and verify |
| Compact checklist | two to five familiar steps | outcome, steps, verifier |
| Discovery plan | ownership, cause, or interface is unknown | questions, evidence targets, stop condition |
| Execution plan | cross-file or permission-sensitive change | bounded tasks, dependencies, permissions, verifiers |
| Parallel plan | genuinely independent streams | execution plan plus owners, outputs, write boundaries, join |
| Long-running ledger | work crosses sessions | execution plan plus progress, next action, handoff state |

Planning should grow progressively. ADaPT found benefits from decomposing at executor failure points, allowing plans to omit hypothetical branches. [ADaPT](https://aclanthology.org/2024.findings-naacl.264/)

### Plan-quality rubric

Score each dimension `0`, `1`, or `2`:

| Dimension | 0 | 1 | 2 |
|---|---|---|---|
| Outcome | activity only | vague result | observable result and value |
| Evidence | assumed state | partial inspection | authoritative baseline named |
| Scope | open-ended | main scope | included, excluded, preserved |
| Decomposition | monolith or task confetti | workable | independently verifiable changes |
| Readiness | blockers hidden | partial prerequisites | every task ready or blocked with reason |
| Dependencies | implicit | basic order | real edges and safe branches |
| Ownership | unclear writes | owner named | owner, contract, and write boundary |
| Verification | self-report | generic test | exact evidence |
| Adaptation and closure | absent | one present | replan rules and durable closure |

An initial trial may treat `14/18` with no zero in Outcome, Evidence, Verification, or Scope as execution-ready. This threshold is a harness hypothesis and needs calibration against completed work.

## Graph design options

| Option | Benefit | Cost | Fit |
|---|---|---|---|
| Flat `TASK.md` | simplest human-readable ledger | coordinator tracks dependencies mentally | default for small work |
| Derived dependency view | ready/blocked calculation, cycle checks, safe fan-out | small parser and schema discipline | recommended now |
| Separate task-DAG authority | richer querying and events | synchronization conflicts and migration burden | defer |
| Workflow/state engine | checkpoints, conditional routing, recovery | framework coupling, state migration, graph sprawl | use for proven recurring workflows |
| Shared blackboard/event bus | dynamic peer discovery | stale reads, noisy events, difficult completion reasoning | experimental |
| Rich agent graph platform | broad automation and telemetry | largest maintenance and observability burden | poor fit for four local slots |

Decision rule: activate graph behavior when a relationship changes what may run, what resource may be written, or what counts as complete. A flat list remains sufficient for an obvious short sequence.

## Recommended lightweight design

### Authority and derivation

`TASK.md` remains authoritative. Each active task can carry compact fields:

```text
- [ ] T120 — Outcome
  | after: T118,T119
  | owner: main
  | writes: research/brief.md
  | resources: none
  | verifier: link-check + schema-check
  | evidence: pending
```

A read-only parser derives:

- missing or duplicate IDs;
- missing dependency references;
- cycles;
- ready and blocked tasks;
- longest unweighted dependency chains and tasks that unlock the most descendants;
- conflicting writable files or shared resources;
- stale active claims;
- completion closure.

Generated views and local caches may be deleted and rebuilt. If a derived view conflicts with `TASK.md`, the parser regenerates it from `TASK.md`.

### Readiness

MVP 1 derives **dependency-ready** when the task marker is actionable and every predecessor is satisfied. MVP 2 derives **dispatch-ready** after adding execution-contract checks:

- its status is actionable;
- every predecessor is verified or explicitly cancelled in a way that preserves the outcome;
- required permission and credentials are available;
- an owner and write boundary are valid;
- no active task owns the same mutable resource;
- its expected artifact and verifier are known.

Priority scoring can consider user priority, unweighted dependency depth, number of descendants unlocked, context savings, resource risk, review cost, and retry risk. Hard eligibility rules govern execution; the score only orders eligible tasks. Time-based critical paths require reliable duration estimates and are outside the initial design.

### Activation threshold

Start with a policy hypothesis: render the graph view when there are at least six active tasks and two true dependency edges, multiple owners, or a shared-resource conflict. Measure whether this threshold reduces missed asks, duplicate work, blocked time, and review burden.

## Subagent coordination protocol

The coordinator owns user intent, task decomposition, permissions, durable state, and final synthesis. With four runtime slots, the coordinator can use up to three concurrent workers.

Each worker receives:

```text
Objective:
Questions to answer:
Authoritative inputs:
Expected artifact and response format:
Read/write boundary:
Satisfied dependencies:
Shared resources and prohibited paths:
Verifier:
Budget and stop condition:
Failure reporting:
```

### Lifecycle

1. Extract all obligations into `TASK.md`.
2. Add genuine dependency edges and reject cycles.
3. Compute the ready frontier.
4. The coordinator marks the task active in `TASK.md`, then creates an expiring operational lease containing agent, workspace, files, resources, expected output, verifier, and the authoritative file revision.
5. Workers persist bulky results in artifacts and return a short evidence summary.
6. The coordinator harvests each result once, reconciles contradictions, runs the join verifier, and writes the durable transition to `TASK.md` before emitting a corresponding run event.
7. Failed dependency or interface assumptions block descendants and trigger a bounded replan.
8. Completed workers are closed and their file/resource claims released.
9. The run ends when required nodes are verified, explicitly deferred by the user, or superseded by a task or decision that preserves the requested outcome, and every worker is terminal.

Only the coordinator changes durable task state. A lease records operational ownership and may expire; it cannot mark a task verified, failed, cancelled, or human-blocked. Run events observe completed `TASK.md` writes and reference the authoritative revision. On restart, scheduling begins from `TASK.md` plus a read-only audit of live workers and artifacts. Missing, stale, or conflicting lease/event files cannot change task status.

Claude Code’s current Agent Teams implementation demonstrates shared task lists, dependency blocking, atomic claims, peer mailboxes, quality gates, and shutdown handling; Anthropic still labels it experimental and documents coordination and resumption limitations. [Claude Agent Teams](https://code.claude.com/docs/en/agent-teams)

### Failure handling

| Failure | Response |
|---|---|
| transient tool or network fault | one bounded retry |
| output contract failure | structured repair feedback |
| dependency mismatch | block descendants and replan |
| write or shared-resource collision | stop conflicting writers, preserve evidence, reassign |
| permission or credential need | mark human-blocked with exact resume action |
| repeated identical failure | stop retries and surface |
| expired worker claim | inspect artifacts, mark stale, resume from verified state |

Retries involving side effects require idempotency. LangGraph’s interrupt guidance highlights the need for repeat-safe work around checkpoints. [LangGraph interrupts](https://docs.langchain.com/oss/python/langgraph/interrupts)

## Efficiency model

Graphs can improve:

- coverage of messy prompts;
- ready-work discovery;
- safe concurrency;
- critical-path prioritization;
- resource collision prevention;
- completion closure;
- diagnosis of duplicated work and failed handoffs.

They also add:

- planning and metadata time;
- token and coordination overhead;
- risk of stale or invented edges;
- review saturation;
- new state and recovery logic.

Anthropic reports up to a 90% time reduction for parallel work in its complex research system and roughly 15 times the token use of chat. These scoped vendor measurements support local measurement before claims of coding gains. [Anthropic multi-agent research](https://www.anthropic.com/engineering/multi-agent-research-system)

Measure total elapsed time, human review time, retries, verifier failures, duplicated work, blocked time, task coverage, and closure failures. The METR randomized study found a mismatch between perceived and measured productivity in its early-2025 open-source setting, reinforcing the need for measured outcomes. [METR study](https://arxiv.org/abs/2507.09089)

## Failure modes and safeguards

- **Wrong decomposition:** require evidence and one observable outcome before adding edges.
- **False parallelism:** keep tightly coupled and same-file work with one owner.
- **Task confetti:** combine tasks whose coordination cost exceeds their independent value.
- **Second authority:** generate every graph view from `TASK.md`.
- **Cycle or deadlock:** reject cycles; alert when unfinished work has no ready node.
- **Shared-runtime collision:** track ports, databases, migrations, deployments, and credentials alongside files.
- **Game-of-telephone handoff:** use artifact-first results with short references.
- **Supervisor bottleneck:** wait on bounded groups and harvest terminal results once.
- **Retry storm:** use small explicit budgets and idempotent side effects.
- **Orphaned workers:** track lifecycle state and run a stale-agent audit before termination.
- **Premature completion:** require artifact, verifier, evidence, task reconciliation, and released resources.
- **Graph sprawl:** promote only repeated stable processes to workflow graphs.

## Rollout

1. Add parsing and validation to a fixture containing stable IDs, `after`, owner, writes, resources, verifier, and evidence.
2. Generate a read-only Markdown or HTML readiness view.
3. Test against ten historical messy prompts and the current task board.
4. Run in shadow mode: compare derived recommendations with human scheduling.
5. Add ready-frontier dispatch and lifecycle closure after parser accuracy is established.
6. Capture compact run events for a derived provenance view.
7. Review metrics after several major tasks.
8. Consider a workflow engine only for a repeatedly executed process with demonstrated interruption or recovery needs.

## Reversible decisions

- Field syntax can evolve because task IDs and meanings stay in `TASK.md`.
- The derived graph can be disabled without losing task history.
- Runtime event logs can remain local until diagnostic value is proven.
- The activation threshold remains provisional and changes with measured evidence.
- Native Codex and Claude coordination remain execution adapters around the portable task model.

## Sources

### Primary and official

- [Anthropic: multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system)
- [Anthropic: long-running-agent harness](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Claude Code: Agent Teams](https://code.claude.com/docs/en/agent-teams)
- [OpenAI Agents SDK orchestration](https://openai.github.io/openai-agents-python/multi_agent/)
- [OpenAI Agents SDK tracing](https://openai.github.io/openai-agents-python/tracing/)
- [LangChain: graph engineering](https://www.langchain.com/blog/3-years-of-graph-engineering-with-langgraph)
- [LangGraph Graph API](https://docs.langchain.com/oss/python/langgraph/use-graph-api)
- [AutoGen GraphFlow](https://microsoft.github.io/autogen/stable/user-guide/agentchat-user-guide/graph-flow.html)
- [Apache Airflow DAGs](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/dags.html)
- [Microsoft GraphRAG](https://github.com/microsoft/graphrag)

### Research and practitioner evidence

- [Plan-and-Solve](https://aclanthology.org/2023.acl-long.147/)
- [ADaPT](https://aclanthology.org/2024.findings-naacl.264/)
- [LOCAGENT](https://aclanthology.org/2025.acl-long.426/)
- [DeMAC](https://aclanthology.org/2025.findings-emnlp.757/)
- [G-Designer](https://proceedings.mlr.press/v267/zhang25cu.html)
- [METR productivity study](https://arxiv.org/abs/2507.09089)
- [Addy Osmani: good agent specs](https://addyo.substack.com/p/how-to-write-a-good-spec-for-ai-agents)
- [Simon Willison: first run the tests](https://simonwillison.net/guides/agentic-engineering-patterns/first-run-the-tests/)

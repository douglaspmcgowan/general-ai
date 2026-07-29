# Automatic Agent Task Management Recon

Last researched: 2026-07-29

## Question

How should the cross-agent harness capture, decompose, create, update, reconcile, and resume tasks from both structured and messy prompts while allowing agents to create necessary subtasks without losing user intent or bloating the queue?

## Orientation

Stage 1 surfaced five recurring threads:

1. Long-running agents need durable task state outside the model context so compaction, restarts, and tool failures cannot erase obligations.
2. Tasks and agent-created subtasks need stable identities, parent relationships, explicit status, and dependency information.
3. Completion needs externally checkable evidence and a queue reconciliation step; an agent's prose assertion is insufficient.
4. New findings require controlled replanning that preserves the original user request and records why scope changed.
5. Automatic decomposition needs a judgment boundary that prevents duplicate, speculative, or low-value subtasks from clogging the queue.

The directed research will compare deterministic lifecycle enforcement with model-judged prompt parsing, and will examine how established orchestration systems handle persistence, interruption, resumption, and newly discovered work.

## Findings

### Strongest external pattern: stable intent plus changing progress

Microsoft's Magentic-One separates a relatively stable Task Ledger from a frequently refreshed Progress Ledger. Its reported ablation found a 31% GAIA validation performance drop without the full ledger design, although that result belongs to Magentic-One's benchmark and should not be assumed to transfer directly to this harness ([technical report](https://arxiv.org/abs/2411.04468)). OpenAI reports a similar separation between durable repository knowledge, versioned execution plans, progress, and decision logs in its Codex harness ([OpenAI engineering report](https://openai.com/index/harness-engineering/)). Anthropic's long-running-agent experiments preserve a feature inventory and progress file alongside Git history so a fresh session can recover without trusting compacted chat context ([Anthropic engineering report](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)).

The harness should therefore maintain two coordinated authorities:

1. An append-only **intent ledger** preserving every user obligation, question, constraint, correction, non-goal, and disposition.
2. A mutable **task graph** containing executable user tasks and governed agent-created subtasks.

`CURRENT-TASK.md` and `WORK_QUEUE.md` should become generated human views of those authorities.

### Prompt decomposition needs explicit coverage

TaskBench evaluates decomposition, tool selection, and parameter prediction as distinct capabilities, supporting a separate intake phase before execution ([TaskBench](https://openreview.net/forum?id=bAxUA5r3Ss)). AgentBench identifies instruction following and long-horizon reasoning as major obstacles ([AgentBench](https://arxiv.org/abs/2308.03688)). REI-Bench reports planning degradation from vague references in its evaluated domains, reinforcing the need to preserve source wording and resolve ambiguous references explicitly ([REI-Bench](https://openreview.net/forum?id=vmBIF25KLf)).

Every submitted prompt should receive an intake ID. Each meaningful clause should receive one durable disposition:

- mapped to a new task;
- attached to an existing task;
- recorded as a constraint or acceptance condition;
- recorded as a question and answered;
- marked as a decision awaiting the user;
- marked as context or an aside;
- marked as an explicit non-goal;
- linked as a duplicate;
- canceled or superseded by a correction.

The parser may normalize wording, while the immutable intake record preserves a faithful source excerpt and message reference. This makes omissions auditable.

### Agents need a governed way to create work

Anthropic's multi-agent research system lets a lead agent create additional agents as findings reshape the plan, while requiring bounded objectives, output formats, source guidance, and scope ([Anthropic multi-agent research](https://www.anthropic.com/engineering/multi-agent-research-system)). OpenAI's Symphony workflow allows agents to create follow-up issues and dependency trees while keeping the task board as the control plane ([OpenAI Symphony](https://openai.com/index/open-source-codex-orchestration-symphony/)). Steve Yegge's Beads workflow uses parent/child, blocking, assignment, and `discovered-from` relationships; these are firsthand claims from the tool's creator and warrant a local shadow trial before adoption ([Beads account](https://steve-yegge.medium.com/introducing-beads-a-coding-agent-memory-system-637d7d92514a)).

An agent may create a child task when the work:

- is required to satisfy the parent's acceptance criteria;
- is a dependency discovered through evidence;
- is an independently verifiable verification step;
- is recovery work required after a failed operation;
- will be delegated to another owner;
- must survive a turn, interruption, permission boundary, or context reset.

Every agent-created task must contain `parent_id`, `created_by`, `reason`, `scope_class`, `acceptance`, and `evidence_source`. Optional improvements go to the backlog and do not silently expand active scope. Small atomic actions remain execution notes beneath the current task.

### Dependencies and completion need machine-readable semantics

AutoGen represents serial, parallel, conditional, and looping execution as directed graphs with termination rules ([AutoGen GraphFlow](https://microsoft.github.io/autogen/stable/user-guide/agentchat-user-guide/graph-flow.html)). LangGraph checkpoints task results, preserves successful writes when sibling work fails, and requires deterministic ordering and idempotent side effects for reliable resume ([LangGraph persistence](https://docs.langchain.com/oss/python/langgraph/persistence), [LangGraph Functional API](https://docs.langchain.com/oss/python/langgraph/functional-api)). GitHub's current agent-task API exposes distinct queued, in-progress, completed, failed, idle, waiting-for-user, timed-out, and canceled states plus task artifacts ([GitHub agent-task API](https://docs.github.com/en/rest/agent-tasks/agent-tasks)).

The task graph needs stable IDs and explicit dependency edges. Readiness is derived from those edges. Completion requires acceptance evidence, closed required descendants, and a final scan for unreconciled intent.

Anthropic's evaluation guidance distinguishes what an agent says from the resulting environment state and recommends grading both outcomes and trajectories ([Anthropic eval guidance](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)). AgentBoard similarly adds a progress metric because final success alone obscures partial progress and failure location ([AgentBoard](https://openreview.net/forum?id=4S8agvKjle)).

### Flat Markdown remains useful as a view

Practitioners consistently preserve plans and progress outside conversation context. Geoffrey Huntley's Ralph loop reads one task, executes it, verifies it, updates the plan, and exits ([Ralph workflow](https://ghuntley.com/ralph/)). Jesse Vincent describes architect and implementer phases using small tasks with file and verification details ([practitioner account](https://blog.fsck.com/2025/10/05/how-im-using-coding-agents-in-september-2025/)). Addy Osmani describes a similar select, implement, validate, record, and reset cycle ([practitioner synthesis](https://addyosmani.com/blog/self-improving-agents/)).

Markdown is valuable for human reading and Git review. A flat checkbox file becomes fragile when dependencies, concurrent owners, corrections, and self-created subtasks matter. The recommended system keeps Markdown projections and places identity, lineage, transitions, and evidence in structured state.

### Current harness gaps

The local audit found:

- messy-prompt decomposition runs only when `source-command-task` is invoked (`C:\Users\dougl\.agents\skills\source-command-task\SKILL.md:48`);
- submitted prompts are logged without clause-to-task coverage (`C:\Users\dougl\.claude\hooks\task-state-reminder.js:401`);
- the Claude session primer omits `WORK_QUEUE.md` (`C:\Users\dougl\.claude\hooks\session-primer.js:43`);
- the keep-going hook sees checkbox state without IDs, dependencies, ownership, provenance, or evidence (`C:\Users\dougl\.claude\hooks\keep-going.js:65`);
- an empty queue is treated as completion (`C:\Users\dougl\.claude\hooks\keep-going.js:192`);
- unchanged actionable work is eventually released without a durable blocked transition (`C:\Users\dougl\.claude\hooks\keep-going.js:205`);
- shared and Claude resolvers disagree about root and session-keyed active files (`C:\Users\dougl\.agents\core\task-state.js:94` and `C:\Users\dougl\.claude\hooks\hook-state.js:113`);
- Cursor's finish gate reads unrelated machine-global task paths (`C:\Users\dougl\.cursor\hooks\stop-toast-gate.js:10`);
- project verification can pass without checking `CURRENT-TASK.md` consistency (`C:\Users\dougl\.agents\tools\Test-AgentProjectState.ps1:9`);
- the present `CURRENT-TASK.md` and `WORK_QUEUE.md` already disagree.

## Proposed lifecycle

### 1. Record prompt intake

At every user prompt:

1. Create a stable `prompt_id`.
2. Save timestamp, session, project, prompt hash, and a protected local source reference.
3. Mark the intake `pending_reconciliation`.
4. Preserve existing open obligations until the new prompt explicitly cancels, supersedes, or replaces them.

The deterministic hook records receipt. The agent supplies semantic clause classification.

### 2. Reconcile obligations

The agent submits a structured delta:

```json
{
  "prompt_id": "P-20260729-001",
  "clauses": [
    {
      "source_span": "given that you missed adding the tasks",
      "type": "correction",
      "disposition": "attach",
      "target_id": "T-104"
    },
    {
      "source_span": "do some recon",
      "type": "task",
      "disposition": "create",
      "title": "Research automatic task management"
    }
  ]
}
```

The reconciler validates that each clause has one disposition, applies explicit corrections, links duplicates, creates new roots only from user obligations, and regenerates actionable views.

### 3. Build the task graph

Minimum task record:

```json
{
  "id": "T-105",
  "intent_ids": ["I-20260729-002"],
  "title": "Research automatic task management",
  "type": "investigate",
  "origin": "user",
  "created_by": "user",
  "parent_id": null,
  "depends_on": [],
  "status": "in_progress",
  "owner": "session-id",
  "scope_class": "required_now",
  "acceptance": ["Current primary and practitioner evidence", "Concrete harness design"],
  "evidence": [],
  "next_action": "Synthesize research",
  "created_at": "2026-07-29T00:00:00-04:00",
  "updated_at": "2026-07-29T00:00:00-04:00"
}
```

Recommended statuses:

- `proposed`
- `ready`
- `in_progress`
- `waiting_user`
- `blocked`
- `done`
- `canceled`
- `superseded`

### 4. Create agent subtasks when necessary

Expose one shared operation:

```text
Create-AgentSubtask
  -ParentId
  -Title
  -Reason
  -ScopeClass
  -Acceptance
  -DependsOn
  -Owner
```

The operation rejects:

- missing parents;
- unrelated new roots;
- duplicate active siblings;
- missing acceptance criteria;
- dependency cycles;
- optional work promoted directly into active scope;
- children that exceed the parent's authorization.

Agent-created work uses one of four reasons:

- `required_for_acceptance`
- `discovered_dependency`
- `verification`
- `recovery`

Delegation changes the owner and execution context; it does not create a new user obligation.

### 5. Update from evidence

After meaningful tool results:

- attach evidence to the affected task;
- record failed verification as a state transition;
- create a governed recovery or dependency child when required;
- recompute ready leaves;
- refresh `CURRENT-TASK.md` and `WORK_QUEUE.md`.

### 6. Reconcile corrections and interruptions

New user instructions trigger a delta against open intent:

- clarification amends acceptance or constraints;
- correction supersedes the mistaken interpretation while preserving lineage;
- cancellation creates a terminal record;
- replacement supersedes the old root and creates the new one;
- interruption checkpoints active ownership and exact next action.

### 7. Gate completion

Before any whole-request completion:

1. No prompt intake remains unreconciled.
2. Every non-superseded user obligation has a terminal disposition.
3. Every required task has acceptance evidence.
4. Every required child is terminal.
5. No dependency cycle or orphan exists.
6. Generated projections match structured state.
7. Blocked and waiting-user items name the owner, reason, and unblock condition.

An agent may stop with blocked work when the ledger records the blocker and the final response surfaces the required user action.

### 8. Resume from structured state

Every product loads:

- unresolved user intent;
- active and ready task leaves;
- blockers and decisions;
- the current owner;
- the last verified evidence;
- the exact next action.

The agent then reconciles real external state before repeating any side effect.

## Harness changes

### Canonical global layer

Add to the versioned global harness authority:

```text
global/
  TASK-STATE-CONTRACT.md
schemas/
  intent-ledger.schema.json
  task-graph.schema.json
templates/project/
  CURRENT-TASK.md
  WORK_QUEUE.md
tools/
  Record-PromptIntake.ps1
  Reconcile-TaskLedger.ps1
  Create-AgentSubtask.ps1
  Update-AgentTask.ps1
  Test-TaskLedger.ps1
```

### Per-project state

```text
<project>/
  .agents/state/
    INTENT-LEDGER.jsonl
    TASK-GRAPH.json
    TASK-EVENTS.jsonl
  CURRENT-TASK.md
  WORK_QUEUE.md
  STATUS.md
  LOG.md
```

- `INTENT-LEDGER.jsonl` is append-only evidence of prompt obligations and dispositions.
- `TASK-GRAPH.json` is the current machine-queryable execution graph.
- `TASK-EVENTS.jsonl` preserves status, ownership, dependency, and evidence transitions.
- `CURRENT-TASK.md` and `WORK_QUEUE.md` are generated human views.
- `STATUS.md` remains durable project capability/state.
- `LOG.md` remains the concise work history.

For concurrent sessions, all products should call one shared update tool with a file lock. Worktrees continue to isolate writable implementation. Session ownership lives in the task record instead of creating incompatible product-specific state rules.

### Product adapters and hooks

Each product adapter should route to the same shared lifecycle:

| Event | Shared behavior |
|---|---|
| Session start/resume | Load unresolved intent and active/ready graph leaves |
| Prompt submitted | Record intake receipt |
| Before substantive work | Require intake reconciliation |
| Agent discovers work | Validate governed child-task creation |
| Task completion | Require acceptance evidence and closed children |
| Agent stop | Reject unreconciled prompts and contradictory projections |
| Handoff | Checkpoint owner, evidence, blocker, and next action |

Claude currently exposes `TaskCreated` and `TaskCompleted` hooks that can enforce naming and completion criteria ([Claude hooks reference](https://code.claude.com/docs/en/hooks)). Its structured task tools support stable IDs, dependencies, owners, metadata, and incremental updates ([Claude task tools](https://code.claude.com/docs/en/agent-sdk/todo-tracking)). These product-local tasks should be treated as runtime projections into the shared ledger.

Codex and Cursor should use their available lifecycle events and shared tools. Where a product lacks an equivalent event, the global instruction adapter plus stop/resume verifier supplies the same invariant.

### Keep the active view lean

Show only:

- `ready`
- `in_progress`
- `blocked`
- `waiting_user`

Archive terminal detail from the active Markdown view while retaining structured history. A maintenance verifier should flag duplicates, orphans, stale ownership, missing evidence, excessive child depth, and queue growth.

### Recommended rollout

1. **Shadow mode:** parse prompts and build the ledger without controlling execution.
2. **Measure:** compare ledger extraction with human-reviewed prompts.
3. **Projection mode:** generate `CURRENT-TASK.md` and `WORK_QUEUE.md`.
4. **Completion-gate mode:** reject evidence-less completion and unreconciled intake.
5. **Cross-product mode:** enable Claude, Codex, and Cursor adapters after fixture parity.
6. **Capsule mode:** restore the global schema/tools first, then rebuild project views on another computer.

## Verification

Create a fixture corpus covering:

| Scenario | Required result |
|---|---|
| Structured checklist | Every requested item receives one stable intent/task mapping |
| Messy multi-intent paragraph | Every meaningful clause receives a durable disposition |
| Embedded question plus task | The question is answered and the task persists |
| Correction | The old interpretation is superseded with lineage |
| Cancellation | The task becomes terminal and stays canceled on resume |
| Duplicate paraphrase | Existing intent is linked instead of duplicated |
| Agent discovers required work | A valid child contains parent, reason, scope, and acceptance |
| Agent discovers optional improvement | It is parked outside active scope |
| Dependency chain | Downstream work remains unready |
| Dependency cycle | Validation fails with the exact cycle |
| Concurrent sessions | Ownership and updates remain consistent |
| Interrupted side effect | Resume reconciles external state before retrying |
| Queue manually cleared | Structured ledger prevents a false completion |
| Done without evidence | Completion is rejected |
| Parent with open child | Parent completion is rejected |
| Only human-blocked work remains | Stop succeeds and the exact action is surfaced |
| Product parity | Claude, Codex, and Cursor produce identical state decisions |

Shadow-mode metrics:

- obligation recall;
- invented-obligation rate;
- duplicate-task rate;
- correction/supersession accuracy;
- justified agent-subtask rate;
- unauthorized scope-expansion rate;
- completion precision;
- stale-task count;
- projection drift;
- intake and hook latency.

The initial target should be zero missed explicit asks, zero unsupported root tasks, zero evidence-less completions, and identical cross-product fixture results. Thresholds for implied obligations and latency should be chosen after observing the shadow corpus.

## Sources

### Primary and evaluated

- [OpenAI Agents SDK orchestration](https://openai.github.io/openai-agents-python/multi_agent/)
- [OpenAI Harness Engineering](https://openai.com/index/harness-engineering/)
- [OpenAI Symphony](https://openai.com/index/open-source-codex-orchestration-symphony/)
- [Anthropic Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents)
- [Anthropic Multi-Agent Research System](https://www.anthropic.com/engineering/multi-agent-research-system)
- [Anthropic Effective Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Anthropic Long-Running Agent Harnesses](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Anthropic Agent Evals](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)
- [Magentic-One technical report](https://arxiv.org/abs/2411.04468)
- [AutoGen GraphFlow](https://microsoft.github.io/autogen/stable/user-guide/agentchat-user-guide/graph-flow.html)
- [LangGraph persistence](https://docs.langchain.com/oss/python/langgraph/persistence)
- [TaskBench](https://openreview.net/forum?id=bAxUA5r3Ss)
- [AgentBoard](https://openreview.net/forum?id=4S8agvKjle)
- [AgentBench](https://arxiv.org/abs/2308.03688)
- [REI-Bench](https://openreview.net/forum?id=vmBIF25KLf)

### Practitioner and community

- [Geoffrey Huntley: Ralph](https://ghuntley.com/ralph/)
- [Jesse Vincent: coding-agent workflow](https://blog.fsck.com/2025/10/05/how-im-using-coding-agents-in-september-2025/)
- [Steve Yegge: Beads](https://steve-yegge.medium.com/introducing-beads-a-coding-agent-memory-system-637d7d92514a)
- [Addy Osmani: self-improving agents](https://addyosmani.com/blog/self-improving-agents/)
- [Claude Code complex-task workflow request](https://github.com/anthropics/claude-code/issues/5996)

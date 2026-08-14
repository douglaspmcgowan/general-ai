# Backburner

Parked work moves into `TASK.md` only when it becomes an active, authorized goal.

- [ ] **Cloud-ready repository implementation** — Implement the shared `.agents\cloud` template and migrate the 14 discovered repositories under [pyrgos-ai/doug-harness issue #16](https://github.com/pyrgos-ai/doug-harness/issues/16). The current deliverable is planning-only.
- [ ] **Agent Brain automation** — Add mirror CI, a trusted reviewed bridge, and Codex/Claude cloud proposal smoke proofs after basic receiving-computer reconstruction is complete.
- [ ] **OneDrive preserved-data retirement** — Re-audit the exact local tree, unique files, and legacy worktree registrations before proposing a recoverable relocation or removal. Keep the tree untouched until that separate task owns it.
- [ ] **Kernel-pool follow-up** — Run another elevated RAMMap capture and a controlled WSAIFabric comparison only when a measured memory investigation needs deeper attribution.
- [ ] **Gitleaks hook template reconciliation** — The stable repository's existing pre-commit hook already runs Gitleaks from its explicit installed path. The current `EnsureProject` command refuses that differing hook instead of replacing it. Review the shared Git hook in a separately owned stable-checkout task and preserve equal or stronger enforcement.
- [ ] **Playbook/reference refresh** — Decide whether to generate the stale toolkit map from the live harness or retire it, then review the reusable playbook index for currency. This remains outside the harness closeout.

<!-- agent-harness:intake:v1:start -->
## Intake - filed by agents working on other projects

> An agent that finds something wrong here while working elsewhere records it and does
> not fix it. This block is where those records land; this project's own agent triages
> them, promotes what it takes into TASK.md, and deletes nothing to make a count look
> better. Written by `Add-ProjectIntake.ps1` -- add items with that tool rather than by
> hand, so the id-collision check and the format actually hold.

### parallelize-retired-vendored-copy-is-orphaned-20260809

**The parallelize skill was retired from the harness; this project still carries a vendored copy and a provenance entry for it**

- **Filed** 2026-08-09 by an agent working on agent-harness, executing Douglas block-3 ruling of 2026-08-09 to retire three redundant skills
- **Relationship** defect - **Value** medium - **Risk** low
- **Evidence** verifier=inspection; subject=the canonical package .agents-skills-parallelize no longer exists in the harness repository while this project vendored tree and bundleProvenance still name it; result=verified; reference=skills-manifest.json

Run SyncProject against this repository to prune the orphaned vendored package and refresh bundleProvenance. Its skills-manifest.json binding for parallel-work was repointed from parallelize to dispatching-parallel-agents in the same work unit, because the baselineOverride text on that binding pre-authorized the revert. What remains for this project is re-vendoring. Filed rather than fixed, per the cross-project ownership rule in AGENTS.md.

### cloud-kit-rollout-prerequisite-20260811

**Enroll general-ai in the shared hosted-agent cloud kit**

- **Filed** 2026-08-11 by an agent working on agent-harness cloud rollout routing 2026-08-11
- **Relationship** prerequisite - **Value** high - **Risk** medium
- **Evidence** verifier=inspection; subject=.agents/cloud is absent and the shared rollout registry assigns project-owned enrollment; result=verified; reference=AGENTS.md

### obsidian-todoist-task-management-integration

**Design and implement a full task-management connection between Obsidian and Todoist**

- **Filed** 2026-08-13 by an agent working on Agent Harness open-items run; Douglas request 2026-08-13
- **Relationship** opportunity - **Value** high - **Risk** medium
- **Evidence** verifier=inspection; subject=existing project queues contain no Todoist or Obsidian task-management integration owner; result=verified; reference=MAP.md

### obsidian-todoist-task-management-connection

**Design and implement a full Obsidian–Todoist task-management connection with a canonical owner, sync direction, conflict rules, and verified task lifecycle**

- **Filed** 2026-08-13 by an agent working on general-ai coordination session, user requested a full Obsidian + Todoist task-management connection be queued
- **Relationship** opportunity - **Value** high - **Risk** medium
- **Evidence** verifier=inspection; subject=general-ai is legacy-mode and has no enrolled Work Scope state; result=queued for project-owned design and implementation; reference=AGENTS.md and existing project intake block

<!-- agent-harness:intake:v1:end -->

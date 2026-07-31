# Cross-device harness handoff

Last verified: 2026-07-31

## Purpose

This file is the compact pickup point for continuing the cross-agent harness from another computer. It records the canonical sources, current publication state, safe receiving sequence, and unresolved boundaries. It contains no credential values.

## Canonical sources

| Item | Authority |
|---|---|
| Main harness GitHub repository | `pyrgos-ai/doug-harness` |
| Main harness local checkout on this computer | `C:\Users\dougl\projects\agent-harness` |
| Installed global harness | `C:\Users\dougl\.agents` |
| Coordination and research repository | `douglaspmcgowan/general-ai` |
| Phone review application | Docket at `https://vault-review-mobile.vercel.app` |
| Active Obsidian vault on this computer | `C:\Users\dougl\Main\Yoga 7 Local John 1412` |
| External project-data transport | `C:\Users\dougl\My Drive\Project Data` |

The local folder name `agent-harness` and the GitHub name `doug-harness` refer to the same canonical harness repository. The older public `douglaspmcgowan/agent-harness` repository is a stale snapshot and has no onboarding authority.

## Receiving-computer sequence

1. Authenticate GitHub CLI once under the interactive Windows account. Run `gh auth status` before starting any new login flow.
2. Clone or download the authenticated ZIP of `pyrgos-ai/doug-harness`.
3. Read `ONBOARDING\START-HERE.md` in that repository.
4. Before the first bootstrap, place the existing machine account's token in `BITWARDEN_SECRETS_MANAGER_ACCESS_TOKEN` when it is available. The bootstrap transfers it to Windows Credential Manager, verifies it in memory, and scrubs matching Process, User, and Machine environment copies.
5. Run the reviewed Windows bootstrap from the repository.
6. Verify and install the global harness to `%USERPROFILE%\.agents`.
7. Restore the committed approved Obsidian configuration after the bootstrap creates a receiving-side backup.
8. Set `PROJECT_DATA_ROOT` and `PROJECT_DATA_SYNC_ROOT`.
9. Discover repositories carrying the `agent-project` GitHub topic, then safely clone missing repositories or pull clean existing repositories.
10. Run each repository verifier and its declared `data-manifest.yaml` adapters.
11. Clone `douglaspmcgowan/general-ai` and open this handoff before using its task-state files.
12. Pause before executing `general-ai\TASK.md`, `STATUS.md`, or `MAP.md`. Their current default-branch versions predate the repository-first cutover and still contain retired Capsule, Password Manager, 3/4/3-retention, and 160-card blocker claims. Reconcile the state-only patch described below through normal review before treating those files as current.
13. Open Docket on the phone or browser for the published briefs and decisions.

## Current cross-device publications

The active Obsidian vault contains:

- `Claude\Engineer\Cloud-Ready Repository Plan.md`
- `Claude\Engineer\Codex Harness Slowness Diagnosis.md`
- `Claude\Engineer\Obsidian Second Brain Recon.md`
- `Claude\Engineer\Obsidian Second Brain SPEC.md`
- `Claude\Engineer\Graph Engineering and Agent Planning Recon.md`
- `Claude\Engineer\Graph-Aware Agent Planning SPEC.md`

Docket contains these stable brief IDs:

- `agent-harness--cloud-ready-repository-plan`
- `agent-harness--last-day-execution-retrospective-2026-07-30`
- `agent-harness--obsidian-second-brain-recon`
- `agent-harness--obsidian-second-brain-spec`
- `agent-harness--graph-engineering-agent-planning-recon`
- `agent-harness--graph-aware-agent-planning-spec`

The verified publication pass imported all six cards and broker-synchronized 166 unresolved cards with zero unsafe-card refusals.

The durable research sources in this repository are:

- `research\obsidian-second-brain-recon-2026-07-30.md`
- `research\obsidian-second-brain-spec-2026-07-30.md`
- `research\graph-engineering-agent-planning-recon-2026-07-30.md`
- `research\graph-aware-agent-planning-spec-2026-07-30.md`

## Cloud-agent plan

The cloud-ready repository plan is pinned at harness commit `4bbb2fdb617a0e4749aaa7e4aa72474cc9864bb3` on branch `codex/cloud-ready-repositories`. Implementation across the 14 discovered project repositories is intentionally deferred and tracked by `pyrgos-ai/doug-harness#16`.

The planned baseline includes repository-owned Linux setup and verification, GitHub CLI, Vercel CLI, Bitwarden Secrets Manager CLI, Playwright and Chromium, Docket access, value-free secret/data manifests, and representative Codex and Claude cloud tasks. Planning does not confer cloud-ready status.

## Main-harness ownership boundary

Another agent currently owns the main-harness implementation. Do not edit, merge, install, or clean its files from this workstream.

One frozen, uncommitted worktree exists at:

`C:\Users\dougl\projects\general-claude\.local\worktrees\agent-harness-closeout`

Its branch is `codex/harness-closeout`, based on `4bbb2fd`. It contains a reproduced installed-verifier repair, exact Docket archive broker tuples, and the useful Gitleaks test-isolation change from stale PR #9. It also has high-conflict edits to harness task, status, map, documentation, stamp, and manifest files. The active harness owner must reconcile those changes hunk by hunk.

The complete uncommitted diff is preserved for cross-device recovery at:

`handoffs\patches\agent-harness-closeout-2026-07-31.patch.zip`

Its SHA-256 is `D97E8E9D9BD033AB474243CB723F675DF8F877568B4775169784A72139B90ACB`. The extracted patch passed `git apply --check` against a disposable clean checkout at `4bbb2fd`. Review every hunk against the active harness owner's work before applying it, then rerun the full harness verification boundary.

The source-computer paths in this section describe local recovery state. Another computer uses the portable patch archive instead of expecting those worktrees to exist.

## General-ai state reconciliation

The default-branch task and architecture files still carry obsolete transition state. A separately reviewed state-only patch is preserved at:

`handoffs\patches\general-ai-state-reconciliation-2026-07-31.patch.zip`

Its SHA-256 is `2CB2155FD7F8E2CCFBCC926F6DA5E50ABFDEBA6CF0EE34FB6D890BA1754F3DB7`. The extracted patch applies cleanly to `general-ai` commit `25e2b54`; the resulting disposable checkout passes `VerifyProject` and `git diff --check`. It updates the existing task, status, map, log, backburner, provenance, and data-manifest files without containing the four research additions. Review and apply it through a separately owned `general-ai` branch after the additive handoff branch lands.

## Preserved local-data boundaries

- Keep `C:\Users\dougl\My Drive\Project Data` unchanged.
- Google Drive for desktop is installed. A measured restart showed sustained initial-scan CPU and a rapidly growing working set, so its two exact processes were stopped again. A narrower Project Data synchronization method remains to be selected.
- The OneDrive application is retired. The preserved `C:\Users\dougl\OneDrive` tree still contains two registered Git worktrees with unique local work:
  - `168-audit-redesign`
  - `berkeley-house\repo-worktree`
- Those worktrees together contain about 48,865 files and 2.1 GB. Preserve them until their branches and uncommitted files are checkpointed or relocated.
- Keep these Docket handoff cards active until that relocation is verified:
  - `setup-handoff--168-worktree`
  - `setup-handoff--berkeley-worktree`

## Remaining closeout actions

1. Let the active harness owner finish and verify the canonical main-harness branch.
2. On the source computer, reconcile or discard the frozen `codex/harness-closeout` worktree without overwriting newer harness work.
3. Preserve the Gitleaks fixture-isolation fix before closing stale harness PR #9.
4. Archive the stale public `douglaspmcgowan/agent-harness` repository after confirming `pyrgos-ai/doug-harness` onboarding is accessible from the receiving computer.
5. Archive these three obsolete Docket cards through exact broker tuples after the harness owner merges and installs the tuple definitions:
   - `setup-handoff--bitwarden-docket-login`
   - `setup-handoff--general-claude-github`
   - `setup-handoff--google-drive-preferences`
6. On the source computer, relocate or checkpoint the two OneDrive worktrees before any OneDrive-root removal.
7. Choose and verify a narrower synchronization path for `My Drive\Project Data`.
8. Implement the 14-repository cloud rollout only when issue #16 is explicitly promoted from planning.

## Resume prompt

> Continue the cross-device harness closeout from `handoffs\HANDOFF-CROSS-DEVICE-HARNESS-2026-07-31.md`. Treat `pyrgos-ai/doug-harness` as the canonical harness and `douglaspmcgowan/general-ai` as the coordination/research repository. Inspect current Git, Docket, Obsidian, Bitwarden metadata, and worktree state before acting. Another agent owns main-harness edits, so preserve that ownership boundary. Keep `My Drive\Project Data` and both OneDrive worktrees intact. Never output credential values.

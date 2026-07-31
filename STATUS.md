# Status

## Current coordination state — 2026-07-31

- `C:\Users\dougl\projects\general-ai` is the coordination repository for cross-agent harness work, project inventory, migration evidence, and shared research. Its Git remote is `https://github.com/douglaspmcgowan/general-ai.git`.
- `C:\Users\dougl\projects\agent-harness` is the local checkout of the private canonical harness repository `pyrgos-ai/doug-harness`. The reviewed source installs to `C:\Users\dougl\.agents`.
- The canonical repository's root `ONBOARDING` folder is the complete Windows receiving-computer path from either an authenticated repository ZIP or a Git clone. It installs and verifies the global harness, restores the approved Obsidian configuration with a receiving-side backup, configures project-data roots, discovers `agent-project` repositories through GitHub, and runs declared project verifiers and data adapters.
- The retired Drive Capsule distribution at `C:\Users\dougl\My Drive\Capsule` was moved recoverably to the Windows Recycle Bin after repository onboarding and merged-master installation passed.
- `C:\Users\dougl\My Drive\Project Data` remains the external artifact transport. DVC objects, verified SQLite snapshots, and other declared project assets use project-owned `data-manifest.yaml` adapters.
- SQLite snapshot retention defaults to 2 daily, 2 weekly, and 1 monthly bucket. The newest verified snapshot always survives and the union retains at most five distinct snapshots; projects may override all three nonnegative counts.
- Bitwarden Secrets Manager reuses the existing `Agents` organization, `Agent Runtime` project, `REVIEW_SECRET`, and connected machine account. The exact-command broker uses the machine token without putting credential values in Git.
- Docket uses its Vercel Blob authority for phone-accessible cards. The latest brokered synchronization published 166 cards, including the six cloud, retrospective, second-brain, and graph-planning briefs prepared by this workstream; all six stable IDs were verified.
- GitHub topic `agent-project` is the repository-discovery authority. Repository source and value-safe configuration travel through Git; excluded runtime data travels only through declared project-data adapters.
- The cloud-ready repository rollout is planning-only. The guide is on `pyrgos-ai/doug-harness` branch `codex/cloud-ready-repositories` at commit `4bbb2fd`, and implementation is tracked in [issue #16](https://github.com/pyrgos-ai/doug-harness/issues/16). No repository has earned cloud-ready status.
- `recovery\general-claude-history.bundle` preserves the committed `general-claude` history at source commit `f8c1f39ed369d8694eb9f82c50f622883bf29a7e`.
- Completed Obsidian second-brain and graph-aware agent-planning research is preserved under `research\`, mirrored to the active Obsidian vault, and published to Docket for phone access.

## Remaining boundaries

1. Implement the cloud template and migrate the 14 discovered repositories only after an explicit implementation request; issue #16 owns that rollout.
2. Keep `C:\Users\dougl\My Drive\Project Data` intact while project manifests and adapters are reconciled during the future fleet rollout.
3. Treat `C:\Users\dougl\OneDrive` as a separate preserved-data retirement project. The application is retired, while the local tree and legacy worktree registrations require a fresh exact audit before any move or removal.
4. Keep optional kernel-pool and RAMMap experimentation parked unless another measured memory investigation requires it.

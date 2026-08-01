# Cross-device access index

Last verified: 2026-07-31

Use this page as the current phone, computer, and cloud-agent entrypoint for the cross-agent harness and Second Brain work.

## Open these first

1. [Canonical private harness repository](https://github.com/pyrgos-ai/doug-harness)
2. [Receiving-computer instructions](https://github.com/pyrgos-ai/doug-harness/blob/master/ONBOARDING/START-HERE.md)
3. [Harness human guide](https://github.com/pyrgos-ai/doug-harness/blob/master/.agents/human-readable/README.md)
4. [Harness browser guide](https://github.com/pyrgos-ai/doug-harness/blob/master/.agents/human-readable/README.html)
5. [Coordination repository](https://github.com/douglaspmcgowan/general-ai)
6. [Existing cross-device handoff](https://github.com/douglaspmcgowan/general-ai/blob/master/handoffs/HANDOFF-CROSS-DEVICE-HARNESS-2026-07-31.md)
7. [Machine-readable pickup context](https://github.com/douglaspmcgowan/general-ai/blob/master/handoffs/CROSS-DEVICE-CONTEXT-2026-07-31-v2.json)
8. [Current portability completion audit](https://github.com/douglaspmcgowan/general-ai/blob/master/research/cross-device-portability-completion-audit-2026-07-31.md)
9. [Receiving-device receipt schema](https://github.com/douglaspmcgowan/general-ai/blob/master/handoffs/RECEIVING-DEVICE-RECEIPT.schema.json)
10. [Machine-readable fleet portability inventory](https://github.com/douglaspmcgowan/general-ai/blob/master/PORTABILITY-INVENTORY.yaml)
11. [Docket](https://vault-review-mobile.vercel.app)
12. [Private Obsidian vault mirror](https://github.com/douglaspmcgowan/obsidian-vault-mirror)

GitHub authentication is required for the private harness and private vault mirror. Docket uses its existing authenticated access. Every public link above returns HTTP 200 anonymously; the private links return 404 until a GitHub session is signed in, and each of those paths was confirmed present on its default branch.

## Provisioning and recovery — read these before running anything

The ordered list above orients you. These are the files a receiving computer actually needs in order to provision itself, and they were previously reachable only by browsing the repository.

1. [`START-HERE.md`](https://github.com/douglaspmcgowan/general-ai/blob/master/START-HERE.md) — this repository's own ordered read path, including the `gh auth status` step that must precede any harness clone.
2. [`secret-manifest.md`](https://github.com/douglaspmcgowan/general-ai/blob/master/secret-manifest.md) and [`secret-manifest.json`](https://github.com/douglaspmcgowan/general-ai/blob/master/secret-manifest.json) — the value-free inventory of which runtime variables a new machine must provision. Names and purposes only; no values live in Git.
3. [`recovery/`](https://github.com/douglaspmcgowan/general-ai/tree/master/recovery) — the restore and backup scripts, the value-free credential command policy, and `general-claude-history.bundle`, which preserves the committed `general-claude` history at `f8c1f39`.
4. [`STATUS.md`](https://github.com/douglaspmcgowan/general-ai/blob/master/STATUS.md) and [`TASK.md`](https://github.com/douglaspmcgowan/general-ai/blob/master/TASK.md) — the durable capability state and the live blocker queue. This page paraphrases the blockers; those two files are the authority.
5. [`MAP.md`](https://github.com/douglaspmcgowan/general-ai/blob/master/MAP.md) — the architecture, authority, and path map, including the integration failure-behavior table.
6. [`MIGRATION.md`](https://github.com/douglaspmcgowan/general-ai/blob/master/MIGRATION.md) — the cutover ledger and preserved-data evidence.
7. [`data-manifest.yaml`](https://github.com/douglaspmcgowan/general-ai/blob/master/data-manifest.yaml) and [`skills-manifest.json`](https://github.com/douglaspmcgowan/general-ai/blob/master/skills-manifest.json) — project data adapter policy and skill bindings.
8. [`backlog/general-security/BITLOCKER-READINESS-BRIEF.md`](https://github.com/douglaspmcgowan/general-ai/blob/master/backlog/general-security/BITLOCKER-READINESS-BRIEF.md) — disk-encryption readiness for a receiving computer.

`handoffs/patches/*.patch.zip` are superseded recovery evidence. Do not apply them. `START-HERE.md` carries the reason.

## If GitHub access to the private repositories is unavailable

The public half of this repository stands alone as coordination history. The executable harness does not. If a phone or a new computer cannot reach `pyrgos-ai/doug-harness`:

1. Sign in to GitHub as `douglaspmcgowan` and confirm membership in the `pyrgos-ai` organization. That account holds push on the harness repository.
2. If organization access itself is lost, the local canonical harness on the source computer at `C:\Users\dougl\.agents` remains the working authority, and `recovery/general-claude-history.bundle` plus the nightly agent backups preserve committed history offline.
3. Do not attempt to reconstruct the harness from the coordination repository alone. It carries history and context rather than the installable harness.

## Current state

- `pyrgos-ai/doug-harness` is the canonical shared-harness and Windows-onboarding source.
- `douglaspmcgowan/general-ai` carries coordination, research, recovery context, and cross-device handoffs.
- The active personal vault remains the human-authoring source and uses Obsidian Sync for desktop and phone.
- The private `obsidian-vault-mirror` is the curated Agent Brain surface for cloud-agent context. Its portable contract permits agent-authored branches only under `proposals/` and `agent-notes/`; mirrored human notes remain read-only.
- Docket is the phone review surface. The local store currently has 175 cards; the most recent brokered publication pushed 173 and refused 0 unsafe or invalid local cards.
- Bitwarden Secrets Manager uses the existing `Agents` organization, `Agent Runtime` project, and connected machine account. The one-time bootstrap variable name is `BITWARDEN_SECRETS_MANAGER_ACCESS_TOKEN`.
- `C:\Users\dougl\My Drive\Project Data` remains the external transport for declared DVC objects, verified SQLite snapshots, and other project artifacts.
- The OneDrive application is retired. Two preserved OneDrive-root Git worktrees still contain unique local work and remain protected until checkpointed or relocated.

## Verified today

- Obsidian Sync reports the active vault as synced.
- Core Web Viewer is enabled.
- HTML Page Viewer `0.1.1` is installed and enabled.
- The Headless scoping brief has one remote Sync history version.
- The official `obsidian-headless@0.0.14` package runs under the installed Node runtime in a disposable invocation.
- The Windows `ob` command currently resolves to a separate unsigned third-party client; official bridge automation must use an explicit pinned launcher.
- Every current Engineer brief has a body-complete Docket card.
- General AI PR 9 is merged at `60a3107` and records the receiving-release owner. Treat repository `master` as the live coordination head rather than copying that commit into new handoffs.
- General AI PR 7 at `582daf5` is the historical source audit for the 27-root inventory; repository `master` owns the reconciled live inventory.
- Private mirror PR 3 is merged at `fd584d1`, including the constrained cross-device index refresh proposal.
- Boundaries Reader PR 1 is merged at `53df3f7`, including its portable baseline; the repository now participates in `agent-project` discovery.
- All 12 current Engineer documents in scope have Git-backed copies.

## Current blockers to complete receiving-computer reconstruction

The consolidated harness implementation and release owner is [issue 18](https://github.com/pyrgos-ai/doug-harness/issues/18).

1. **Installed harness verification:** harness `master` at `ae3899a` still rejects two legitimate harness-owned mutable files. No published commit or pull request contains the required narrow allowance for exactly `logs/stale-agent-process-cleanup.jsonl` and `state/permissions-snapshot.json`.
2. **Approved Obsidian bundle:** the committed onboarding snapshot predates today's plugin installation. It records Web Viewer as disabled and lacks the HTML Page Viewer ID.
3. **Community-plugin installation:** the current Obsidian export/restore path carries plugin IDs without carrying or installing the pinned plugin package.
4. **Blank-computer ordering:** Obsidian restoration and Google Drive data-root setup currently run before prerequisite discovery, so a blank profile can fail before receiving a complete `ATTENTION` inventory.
5. **Project data completion:** the five formerly branchless private remotes are clone-ready with reviewed portable baselines. Bible Name Search still needs its parent-root convention reconciled before initial DVC generations and verified SQLite snapshots publish; Drive Organizer, Grandpa Help, and Motion to Dismiss retain explicit project-data declaration or review items.
6. **Real receiving-device proof:** the final claim requires one actual receiving computer to complete the merged clone/ZIP flow and verify installed harness, Obsidian configuration, project discovery, data adapters, and current context.

## Fastest completion order

1. Let the active harness owner reconcile the existing narrow installed-verifier repair.
2. Move prerequisite discovery ahead of Obsidian and Project Data setup and add one blank-profile regression.
3. Capture the live approved Obsidian configuration through the existing onboarding owner.
4. Add a pinned HTML Page Viewer installation declaration with source, version, expected files, checksum, and verifier.
5. Refresh the harness setup stamp and onboarding manifest once.
6. Run focused tests during each change, followed by one integrated suite, Gitleaks, and whitespace validation.
7. Merge, install from reviewed `master`, and prove one real receiving-computer pickup using the committed receipt schema.
8. Reconcile project-data attention items from the receiving receipt, beginning with Bible Name Search's adapter-root convention and first verified generations.
9. After explicit approval, migrate the five local hooks through the backup-preserving path tracked in [harness issue 17](https://github.com/pyrgos-ai/doug-harness/issues/17).
10. Begin the repository cloud-readiness rollout from [harness issue 16](https://github.com/pyrgos-ai/doug-harness/issues/16): shared template first, then Docket, General AI, Flight Tracker, and Kelly Uniforms, followed by parallel project batches.

## Repository fleet snapshot

- 27 canonical local repository roots were found after excluding one linked harness worktree.
- 26 roots have a configured or mapped Git authority; the one missing origin is the excluded disposable verification fixture.
- GitHub topic discovery returns 20 unique `agent-project` repositories; 21 local inventory roots map to them because `idetc-writing-ide` and `redline-idetc` share one remote authority.
- Ten clone-action topic repositories have a reviewed portable baseline on their remote default branch: Bible Name Search, Boundaries Reader, Contact Form Caller, Docket, Drive Organizer, Flight Tracker, General AI, Grandpa Help, Kelly Uniforms, and Motion to Dismiss.
- The five new private repositories preserve their existing fail-closed local hooks; the optional portable-hook migration remains separately tracked in harness issue 17.
- Docket has the only operational cloud data adapter.
- Seventeen local data manifests remain template placeholders.
- The current full inventory is in [`PORTABILITY-INVENTORY.yaml`](https://github.com/douglaspmcgowan/general-ai/blob/master/PORTABILITY-INVENTORY.yaml); remediation groups and supporting evidence are in the [portability completion audit](https://github.com/douglaspmcgowan/general-ai/blob/master/research/cross-device-portability-completion-audit-2026-07-31.md).

## Second Brain and Headless boundary

The personal vault remains under Obsidian Sync. Cloud agents use the private Git mirror through branches and pull requests. A trusted dedicated bridge performs reviewed, allowlisted transfers between a separate Headless working copy and a separate Git working copy.

The current Windows desktop should not run continuous Headless Sync while desktop Sync is active. Obsidian's guidance warns about conflicts when both clients operate on one device. The next Headless stage is a fixture-only prototype on a dedicated host or VM.

## Safety boundaries

- Keep credential values out of Git, Obsidian briefs, Docket bodies, logs, and chat.
- Preserve `C:\Users\dougl\My Drive\Project Data`.
- Preserve the two OneDrive-root Git worktrees until their branches and uncommitted changes are checkpointed or relocated.
- Keep protected vault paths outside searches, exports, links, mirrors, and cloud-agent context.
- Keep the active shared-harness branch under its declared owner until that work is reconciled.

## Resume prompt

> Open `CROSS-DEVICE-ACCESS.md` in `douglaspmcgowan/general-ai`, then read `PORTABILITY-INVENTORY.yaml`, the linked completion audit, and the canonical harness `ONBOARDING/START-HERE.md`. Inspect current GitHub, installed harness, Obsidian, Docket, Bitwarden metadata, project inventory, and worktree state before acting. Preserve Project Data, credential values, protected vault paths, and active worktree ownership.

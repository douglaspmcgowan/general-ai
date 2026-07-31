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
9. [Docket](https://vault-review-mobile.vercel.app)
10. [Private Obsidian vault mirror](https://github.com/douglaspmcgowan/obsidian-vault-mirror)

GitHub authentication is required for the private harness and private vault mirror. Docket uses its existing authenticated access.

## Current state

- `pyrgos-ai/doug-harness` is the canonical shared-harness and Windows-onboarding source.
- `douglaspmcgowan/general-ai` carries coordination, research, recovery context, and cross-device handoffs.
- The active personal vault remains the human-authoring source and uses Obsidian Sync for desktop and phone.
- The private `obsidian-vault-mirror` is the curated Git surface for cloud-agent context.
- Docket is the phone review surface. The local store currently has 174 cards: 172 unresolved and 2 resolved.
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
- This publication branch carries the two new cross-device documents plus the previously missing Headless brief; after merge, all 12 current Engineer documents in scope have Git-backed copies.

## Current blockers to complete receiving-computer reconstruction

1. **Installed harness verification:** the live verifier rejects two legitimate harness-owned mutable files. A narrow existing fix allows exactly `logs/stale-agent-process-cleanup.jsonl` and `state/permissions-snapshot.json` while preserving rejection of undeclared siblings.
2. **Approved Obsidian bundle:** the committed onboarding snapshot predates today's plugin installation. It records Web Viewer as disabled and lacks the HTML Page Viewer ID.
3. **Community-plugin installation:** the current Obsidian export/restore path carries plugin IDs without carrying or installing the pinned plugin package.
4. **Blank-computer ordering:** Obsidian restoration and Google Drive data-root setup currently run before prerequisite discovery, so a blank profile can fail before receiving a complete `ATTENTION` inventory.
5. **Real receiving-device proof:** the final claim requires one actual receiving computer to complete the merged clone/ZIP flow and verify installed harness, Obsidian configuration, project discovery, data adapters, and current context.

## Fastest completion order

1. Let the active harness owner reconcile the existing narrow installed-verifier repair.
2. Move prerequisite discovery ahead of Obsidian and Project Data setup and add one blank-profile regression.
3. Capture the live approved Obsidian configuration through the existing onboarding owner.
4. Add a pinned HTML Page Viewer installation declaration with source, version, expected files, checksum, and verifier.
5. Refresh the harness setup stamp and onboarding manifest once.
6. Run focused tests during each change, followed by one integrated suite, Gitleaks, and whitespace validation.
7. Merge, install from reviewed `master`, and prove one real receiving-computer pickup.
8. Begin the repository cloud-readiness rollout from [harness issue 16](https://github.com/pyrgos-ai/doug-harness/issues/16): shared template first, then Docket, General AI, Flight Tracker, and Kelly Uniforms, followed by parallel project batches.

## Repository fleet snapshot

- 27 canonical local repository roots were found after excluding one linked harness worktree.
- 18 roots have origins; 9 lack origins.
- GitHub topic discovery returns 14 `agent-project` repositories.
- Four topic repositories have the full portable baseline on their remote default branch: Docket, Flight Tracker, General AI, and Kelly Uniforms.
- Docket has the only operational cloud data adapter.
- Nineteen local data manifests remain template placeholders.
- The current full inventory and remediation groups are in the [portability completion audit](https://github.com/douglaspmcgowan/general-ai/blob/master/research/cross-device-portability-completion-audit-2026-07-31.md).

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

> Open `CROSS-DEVICE-ACCESS.md` in `douglaspmcgowan/general-ai`, then read the linked completion audit and the canonical harness `ONBOARDING/START-HERE.md`. Inspect current GitHub, installed harness, Obsidian, Docket, Bitwarden metadata, project inventory, and worktree state before acting. Preserve Project Data, credential values, protected vault paths, and active worktree ownership.

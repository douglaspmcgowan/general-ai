---
type: audit
status: current
created: 2026-07-31
project: Agent Setup
topic: cross-device portability completion
---

# Cross-device portability completion audit

## Conclusion

The system is partially ready for another Windows computer.

The private harness repository already carries authenticated ZIP and clean-clone onboarding, global harness installation, product loaders, approved Obsidian configuration capture/restore, executable discovery, project-data environment setup, topic-based project discovery, project verifiers, data adapters, and Bitwarden machine-token import. The coordination repository, Obsidian Sync vault, private vault mirror, and Docket already expose most current context across devices.

Five requirements remain before a complete pickup claim is supportable:

1. Land the narrow installed-harness verifier repair.
2. Repair blank-computer prerequisite ordering.
3. Capture today's approved Obsidian bundle.
4. Make the approved community plugin package reproducibly installable.
5. Complete one real receiving-computer run from merged remote sources.

The project fleet then needs a shared cloud-ready baseline followed by repository-specific rollout. That rollout is planned in [harness issue 16](https://github.com/pyrgos-ai/doug-harness/issues/16); it has not been implemented across the fleet.

## Scope and evidence

Three independent read-only audits inspected:

- private `pyrgos-ai/doug-harness` master and its authenticated manifests;
- the installed global harness;
- public `douglaspmcgowan/general-ai` remote state;
- the active Obsidian vault's approved safe configuration and current Engineer briefs;
- Docket value-safe card metadata and body hashes;
- private `douglaspmcgowan/obsidian-vault-mirror` metadata and approved mirrored files;
- 27 bounded local repository roots and three GitHub owners;
- default-branch portable contracts, manifests, setup declarations, topics, and external-data adapters.

The audits did not modify repositories, remotes, credentials, project data, or shared-harness files. The live Obsidian viewing bundle was installed afterward through Obsidian's official CLI and separately verified.

## Canonical authorities

| Concern | Authority |
|---|---|
| Shared harness and Windows reconstruction | Private `pyrgos-ai/doug-harness`, default branch `master` |
| Coordination, research, recovery context | Public `douglaspmcgowan/general-ai` |
| Human-authored personal knowledge | Active Obsidian vault under Obsidian Sync |
| Cloud-agent knowledge boundary | Private `douglaspmcgowan/obsidian-vault-mirror` |
| Phone briefs and decisions | Docket at `https://vault-review-mobile.vercel.app` |
| Shared secret service | Existing Bitwarden `Agents` organization and `Agent Runtime` project |
| Declared large/external project data | `C:\Users\dougl\My Drive\Project Data` plus each repository's `data-manifest.yaml` |

## Harness onboarding audit

Audited private-harness master: `ae3899aee2d9b6c1b5ae9a8e703dfef45cf25ece`.

| Requirement | Status | Evidence and finding |
|---|---:|---|
| Canonical private repository | PASS | Repository, README, specification, and onboarding point to one authority. |
| Root `ONBOARDING` folder | PASS | Instructions, bootstrap, verifier, software inventory, approved configuration, and tests are committed. |
| Authenticated ZIP source | PASS | ZIP mode validates every declared file against the authenticated repository manifest and rejects tampering. |
| Clean Git clone source | PASS | Clone mode validates origin, branch, clean state, and exact remote HEAD. |
| Onboarding manifest | PASS | All 30 records matched Git blob byte counts and SHA-256 hashes. |
| Harness setup stamp | PASS | All 363 records matched Git blob SHA-256 hashes. |
| Global installation | PASS | Staged installation and reviewed `InstallGlobal` owner exist. |
| Installed-state verification | FAIL | The live verifier rejects two legitimate runtime-owned files: `logs/stale-agent-process-cleanup.jsonl` and `state/permissions-snapshot.json`. |
| Existing verifier repair | PARTIAL | The frozen harness-closeout worktree contains a narrow fix and regression that allow exactly those paths and reject undeclared siblings. |
| Claude, Codex, and Cursor loaders | PASS | All three adapters are authenticated harness content. |
| Approved Obsidian snapshot integrity | PASS | Twelve existing snapshot files have authenticated sizes and hashes. |
| Receiving-side backup and rollback | PASS | The restore owner backs up managed files and has rollback, locking, and traversal controls. |
| Protected-path exclusions | PASS | Export and restore reject every configured protected boundary. |
| Live approved Obsidian bundle | FAIL | The committed snapshot predates the live bundle; it records `webviewer:false` and lacks `community-plugins.json`. |
| Community-plugin package reconstruction | FAIL | The exporter carries enabled plugin IDs; it does not pin, download, hash, or verify plugin package files. |
| Receiving-vault prerequisite | PARTIAL | Restore requires an existing explicit vault or exactly one open vault. The guide does not yet provide the full create/sync/open/close sequence. |
| Blank-computer ordering | FAIL | Obsidian and Drive-dependent stages run before prerequisite discovery can return a complete structured `ATTENTION` result. |
| Software inventory | PASS | Reviewed detection or installation guidance covers Git, GH, PowerShell, Node, Python, BWS, DVC, Gitleaks, Drive, Obsidian, Cursor, Claude, and Codex. |
| Project-data environment | PASS | The setup establishes and validates `PROJECT_DATA_ROOT` and `PROJECT_DATA_SYNC_ROOT`. |
| GitHub project discovery | PASS | Topic discovery safely clones missing repositories and fast-forwards clean repositories. |
| Unsafe repository protection | PASS | Dirty, diverged, and wrong-origin repositories remain unchanged and surface attention. |
| Project verifier and data-adapter invocation | PASS | The bootstrap calls both after discovery. Fleet data completeness remains a separate gap. |
| Bitwarden bootstrap | PARTIAL | Value-safe import, verification, transfer, and scrubbing exist; each new machine still needs its one-time machine token. |
| Windows support | PASS | Windows 10/11 is the verified onboarding platform. |
| Integrated onboarding CI | PARTIAL | Full-history Gitleaks runs remotely; ZIP, clone, Obsidian, and integrated bootstrap suites currently rely on recorded local evidence. |
| Real receiving-computer completion | MISSING | One actual receiving computer still must complete the merged workflow and report evidence. |

## Approved Obsidian bundle and Headless scope

The active vault was resolved from `%APPDATA%\obsidian\obsidian.json` as:

`C:\Users\dougl\Main\Yoga 7 Local John 1412`

Verified live state:

- Obsidian Sync reports `synced`.
- Core Web Viewer is enabled.
- HTML Page Viewer `0.1.1` is installed and enabled.
- Obsidian reported no captured plugin errors after installation.
- A recoverable pre-install configuration backup exists under the vault's `.obsidian-backups` folder.
- The Headless scoping brief has one Obsidian Sync history version.

Headless findings:

- Node `v24.15.0` satisfies the official client's Node 22+ requirement.
- Official `obsidian-headless@0.0.14` ran successfully through a disposable pinned invocation.
- Windows currently resolves `ob` to the separate unsigned Belphemur third-party client at version `0.3.4`.
- The active vault is absent from official local Headless configuration.
- The scoping run performed no authentication, remote-vault listing, setup, download, upload, or synchronization.
- The proposed bridge uses a dedicated host or VM, a dedicated Headless working copy, a separate Git working copy, allowlisted transfer, branches and pull requests, snapshots, stale-base checks, and receipts.

## Phone and cross-device artifact coverage

| Surface | Evidence | Coverage |
|---|---|---|
| Active Obsidian vault | Sync enabled and currently reports synced | Ten current harness/Second Brain briefs under `Claude\Engineer` before this audit publication |
| Docket before this publication | 172 local cards: 170 unresolved, 2 resolved | All ten earlier brief bodies matched the corresponding vault text |
| Private vault mirror | Nine exact brief copies | Headless scoping brief is the only current brief missing before this publication slice |
| Private harness | Root onboarding, bootstrap, Markdown human guide, and HTML guide | Canonical setup source with the onboarding gaps above |
| Public coordination repository | Start Here, handoff, machine context, recovery patches, research | Portable pickup map and recovery evidence |

### Link and context defects

- The existing vault/mirror/Docket copy of `START HERE - Cross-Device Harness.md` uses relative `handoffs/...` links whose targets exist only inside `general-ai`. Those links fail on the other three surfaces.
- No single phone-safe document previously linked the harness onboarding, human guides, coordination handoff, context JSON, Docket, vault mirror, and current audits through absolute browser URLs.
- The vault mirror lacks its intended cloud-agent contract, map, schema, state, and constrained proposal/agent-note write zones.
- Seven existing Docket cards contain Windows-absolute filepath metadata. Their bodies remain readable from phones.
- The mirror contains one redundant backup of the cloud-ready plan; Git history already preserves the earlier version.
- Local Docket protocol/status text still reports 162/160 and pending publication even though live evidence is 172/170 with successful publication.

This additive publication supplies `CROSS-DEVICE-ACCESS.md`, the completion audit, a versioned machine context file, and the missing Headless brief. Existing-file link repair, stale-count cleanup, and mirror cloud-contract work stay with their owners.

After importing the access index and this audit, Docket contains 174 local cards: 172 unresolved and 2 resolved. The broker published 172 cards and refused zero unsafe or invalid cards.

## Project fleet audit

Current bounded inventory:

- 27 canonical local roots after excluding one linked harness worktree;
- 18 origins and 9 no-origin roots;
- 14 `douglaspmcgowan` repositories discovered through the `agent-project` topic;
- zero topic repositories under `pyrgos-ai` or `ai-consulting-1`;
- four complete portable baselines on remote default branches;
- one operational cloud data adapter;
- 19 placeholder data manifests.

The earlier `16 origins / 11 without origins` task record is stale.

| Project | Remote and topic state | Portable/cloud state | Data state | Required next action |
|---|---|---|---|---|
| 168 Audit | Owned remote; topic present | Local contract untracked; setup placeholder | Placeholder manifest | Commit reviewed contract, setup, manifests, and adapter |
| Agent Harness | Private canonical remote | Full Windows baseline; cloud/Linux plan pending | No project payload | Active owner finishes onboarding blockers and shared cloud template |
| Anna Maria | Owned remote; topic present; branch divergence | Local baseline exists on `master`; remote default is `main` | Explicit empty local manifest | Reconcile branches and publish portable baseline |
| Base Flight Finder | External upstream; no owned topic | Partial upstream contract; no portable setup | Placeholder manifest | Record upstream/fork exception or create owned fork |
| Berkeley House | Owned remote; topic present | Partial remote contract; hardcoded setup and local additions | Placeholder manifest | Harden setup and commit reviewed baseline |
| Bible Name Search | No origin | Substantive local contract; Windows-host-bound setup | Nine declared assets; missing licensed-corpus/SQLite transport | Best first no-origin publication after adapter design |
| Boundaries Reader | Owned remote under different name; topic missing | Local untracked baseline | Placeholder manifest | Add topic, commit baseline, declare reader data |
| Claude Global Config | Origin collides with harness | Duplicate/local placeholder project | Placeholder manifest | Consolidate useful content into Agent Harness and retire duplicate |
| Client Portal | Owned remote; topic present | Partial remote contract; local changes | Placeholder manifest | Merge reviewed baseline and define real setup/data |
| Conference Tracker | Owned remote; topic present | Local untracked baseline; placeholder setup | Placeholder manifest | Add portable setup, verifier, and adapter before commit |
| Contact Form Caller | No origin | Local untracked baseline | Placeholder manifest | Classify Twilio/Vercel variables, define setup, publish if retained |
| Docket | Owned remote; topic present | Strongest full baseline | Operational Vercel Blob adapter | First hosted cloud-runtime proof |
| Drive Organizer | No origin | Local untracked baseline | Placeholder manifest | Decide retain/archive and define Drive review-input transport |
| Fellowship Tracker | Owned remote; topic present | Partial remote contract; local changes | Placeholder manifest | Commit baseline and define digest/data authority |
| Flight Tracker | Owned remote; topic present | Full baseline; Windows-host-bound execution | Explicit empty manifest | Replace setup or declare coordination-only role |
| General AI | Public owned remote; topic present | Full baseline; setup assumes installed local harness | Explicit empty manifest | Add repository-local cloud bootstrap fallback |
| General Claude | No origin | Preserved predecessor with unique local context | Explicit empty manifest | Move unique context to General AI, preserve history, retire |
| Grandpa Help | No origin | Local untracked baseline | Placeholder manifest | Decide private remote/archive and records boundary |
| Harness duplicate | No origin | Duplicate placeholder project | Placeholder manifest | Consolidate into Agent Harness, preserve history, retire |
| Harness bootstrap fixture | No origin | Disposable fixture | Placeholder manifest | Exclude from project discovery and publication |
| IDTEC Writing IDE | No origin | Local placeholder baseline | Placeholder manifest | Resolve canonical relationship with Redline IDTEC |
| Jars of Clay | Owned remote; topic present | Claude-only remote contract | Placeholder manifest | Add full contract, setup, secret classification, and content boundary |
| Kelly Uniforms | Owned remote; topic present | Full baseline; hardcoded Windows harness path | Seven real assets; manual recovery only | Add portable setup and declared asset adapter |
| Legal Doc Studio | Owned remote; topic present | Local untracked baseline | Placeholder manifest | Commit baseline and define document/runtime data |
| Legal Solutions Website | Owned remote; topic present | Claude-only remote contract | Placeholder manifest | Add full contract, npm setup, deployment variables, and data policy |
| Motion to Dismiss | No origin | Local untracked baseline | Placeholder manifest | Decide remote and document-record boundary |
| Redline IDTEC | Owned remote; topic present | Local untracked baseline | Placeholder manifest | Commit baseline and define exchange/document transport |

### Remote topic-repository readiness

- **Full baseline:** Docket, Flight Tracker, General AI, Kelly Uniforms.
- **Partial contract:** Berkeley House, Client Portal, Fellowship Tracker, Jars of Clay, Legal Solutions Website.
- **Portable contract absent from default branch:** 168 Audit, Anna Maria, Conference Tracker, Legal Doc Studio, Redline IDTEC.
- **Owned origin missing topic:** Minimalist Ebook Reader.
- **External-upstream exception:** Base Flight Finder.
- **Shared-harness special case:** Doug Harness.

Local scaffolding overstates portability: 20 roots have modified or untracked baseline files that cloud agents cannot receive from their remote default branch.

## Fastest dependency-ordered completion plan

### Phase 1 — Finish canonical onboarding

1. Reconcile the existing narrow verifier fix into the active harness owner's branch.
2. Move prerequisite discovery before Obsidian restoration and Drive-root setup.
3. Add one blank-profile regression returning structured `ATTENTION` records.
4. Capture the live Web Viewer and HTML Page Viewer configuration through the existing capture owner.
5. Add one reviewed community-plugin install declaration with plugin ID, version, canonical source, checksum, expected files, and verifier.
6. Clarify the receiving-vault sequence: install Obsidian, sign in or create/open the intended vault, confirm one active vault, close Obsidian, run bootstrap.
7. Refresh the setup stamp and onboarding manifest once.
8. Run focused regressions during changes, then one integrated suite, Gitleaks, and `git diff --check`.
9. Merge and install from reviewed harness `master`.

### Phase 2 — Prove real pickup

1. On the receiving computer, verify `gh auth status` under the interactive user.
2. Clone or download the authenticated private harness repository.
3. Read `ONBOARDING\START-HERE.md` and run `ONBOARDING\Bootstrap-Windows.cmd`.
4. Confirm installed harness verification passes after both runtime-owned mutable files exist.
5. Confirm Obsidian backup, Web Viewer, HTML Page Viewer, project-data roots, repository discovery, project verifiers, and declared adapters.
6. Clone `douglaspmcgowan/general-ai`, open `CROSS-DEVICE-ACCESS.md`, and confirm Docket and the private vault mirror are reachable.

### Phase 3 — Finish one reusable cloud baseline

Use the existing template and harness owners:

- cross-platform repository-local setup and verification;
- Codex and Claude cloud setup instructions;
- Git, Node, GH, Vercel, BWS, Playwright, and Chromium base tools;
- value-free Bitwarden secret mapping;
- explicit data modes: none, regenerate, DVC/object store, SQLite snapshot, or cloud service;
- clean-clone/cloud proof and topic check;
- universal Docket read/status plus explicitly granted publication.

### Phase 4 — Pilot and fan out

1. Docket: hosted setup, secret names, Vercel Blob, browser proof.
2. General AI: repository-local bootstrap.
3. Flight Tracker: portable or explicitly coordination-only setup.
4. Kelly Uniforms: portable setup and asset adapter.
5. Resolve canonical ownership, branch divergence, and upstream exceptions.
6. Run independent project batches with one owner and worktree per repository.
7. Replace all 19 placeholder data manifests with explicit empty declarations or working adapters.
8. Publish retained no-origin projects after setup, secret classification, and data boundaries are real.

## Constraints

- Preserve `C:\Users\dougl\My Drive\Project Data`.
- Preserve the two OneDrive-root Git worktrees until their unique changes are checkpointed or relocated.
- Keep credential values outside Git, Docket, Obsidian briefs, logs, task state, and chat.
- Keep protected vault paths outside reads, searches, exports, links, mirrors, and delegated work.
- Keep shared-harness edits under the current harness owner's branch until explicit reconciliation.
- Use focused tests while changing a component and one integrated suite after the settled implementation.

## Completion criteria

The cross-device goal becomes complete when current evidence proves all of the following:

- merged private-harness master passes authenticated ZIP and clean-clone onboarding;
- the installed harness passes after ordinary runtime state exists;
- the approved Web Viewer and HTML Page Viewer bundle is restored and installed reproducibly;
- a blank profile receives actionable prerequisite guidance before dependent stages;
- one real receiving computer completes bootstrap, project discovery, project verification, declared data handling, and Bitwarden setup;
- the receiving computer reaches current context through General AI, Obsidian Sync/private mirror, and Docket;
- every retained project has an origin or explicit retirement/upstream exception;
- each retained remote default branch has its real portable contract and value-safe manifests;
- every external-data declaration is explicit and recoverable;
- representative Codex and Claude cloud tasks pass after the shared cloud baseline is implemented.

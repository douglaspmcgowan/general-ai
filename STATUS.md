# Status

## Current harness state — 2026-07-29

- `C:\Users\dougl\projects\general-ai` is the coordination repository. It uses one `TASK.md`; migration sources remain recoverable under `.agents\archive`.
- `C:\Users\dougl\projects\agent-harness\.agents` is the committed shared authority. `C:\Users\dougl\.agents` is its installed projection for Claude, Codex, and Cursor.
- The active human guide is `C:\Users\dougl\.agents\human-readable\README.md`; `README.html` is its source-hash-matched browser mirror.
- Live hook wiring has three entrypoints: `security-dispatch.js`, `task-state-dispatch.js`, and `continue-dispatch.js`.
- The active Codex `AGENTS.md` is preserved at SHA-256 `F26ABEA21241FC2BEC069D0EC99E933EAE0BC04F2BBDB4C0354C22B137996E37`.
- Harness PR #7 merged at `ac88a9a`. Follow-up commits add source-first Capsule tool resolution (`f80f919`), the current Docket protocol (`ece6121`), the consolidated `TASK.md` verifier (`8fe2b96`), bounded cleanup retry (`6dc0e6d`), and the Bitwarden creator regression (`16ef4dd`).
- Harness commits `c67792d`, `64bd8cd`, and `64aea3d` are pushed and installed globally. `VerifyGlobal` passes and the active Codex `AGENTS.md` hash remains preserved.
- `agent-harness\.agents\capsule` is the sole Capsule source. `C:\Users\dougl\My Drive\Capsule` is the generated cross-computer artifact, and `C:\Users\dougl\Documents\Agent Backups\Workspace` is dated snapshot authority.
- The target Capsule scope is the shared global harness, bootstrap tools, and repository inventory. Per-project source, rules, handoffs, and small versionable data travel through each GitHub repository; excluded and live mutable data travel through project data-manifest adapters.
- The Drive Capsule verifier and `manifests\capsule.json` are the authorities for its selected snapshot and file count. The current manifest selects `20260729-124626` with 6,043 integrity records and still contains one per-project workspace payload, so it is a transition package. Do not refresh it until the harness-only package and project-sync/data-transport implementation pass end-to-end verification.
- GitHub CLI can enumerate repositories dynamically by account and topic. The selected design uses GitHub topic discovery plus the account ID and local path conventions; a static `repositories.json` is unnecessary, and exception metadata will be added only for proven cases.
- The local inventory contains 27 Git repositories: 16 have origins and 11 are dirty without origins. Three additional project-root entries are outside Git: `.obsidian` configuration, the `flight-tracker` container, and the `general-claude-incomplete` archive. Existing `data-manifest.yaml` files in 25 of 27 repositories provide the extension point for excluded and live mutable-data transport.
- `recovery\general-claude-history.bundle` preserves every committed ref from the retained `general-claude` repository at source `master` commit `f8c1f39ed369d8694eb9f82c50f622883bf29a7e`. Bundle completeness, clean clone, `git fsck --full`, and source/restored SHA equality pass; the original folder remains preserved with its uncommitted working-tree state.
- Automatic Agent Backups pruning remains disabled. Active documentation is being revised to the 3-daily/4-weekly/3-month-end policy while retaining labeled milestones and the newest disposable-restore proof.
- Google Drive is running and the direct My Drive Capsule is accessible.
- OneDrive application retirement is verified. The official `C:\Windows\System32\OneDriveSetup.exe /uninstall` exited `0`; follow-up checks found zero running processes, uninstall registrations, startup entry, scheduled tasks, and Winget packages. The Windows system setup stub remains present.
- `C:\Users\dougl\OneDrive` remains as a preserved local reparse-point data tree with 141,008 files and 5,796,741,017 logical bytes. Git still registers the legacy 168 Audit and Berkeley House worktrees there alongside their relocated replacements. Metadata-only comparisons reported Desktop with 1 candidate file, Documents with 140,440 candidate files and 5,413,453,487 bytes, Pictures fully skipped, and Attachments with no `C:\Users\dougl\Attachments` counterpart. The exact data-retention boundary remains open.
- Docket README commit `e89150e` is pushed. Its local store has 162 items, two archived decisions, and 160 unresolved publication candidates. Authenticated card publication remains pending.
- The corrected interactive Bitwarden run succeeded and created the 8 planned scaffold receipt items. The CLI is locked. Hidden-value entry and the Docket/Vercel binding remain.
- The guarded stale-agent cleanup and portable `declog` skill remain installed.
- Signed Microsoft RAMMap v1.63 is installed at `C:\Users\dougl\Tools\Sysinternals\RAMMap\RAMMap64.exe`. The measured pressure sample showed 95% physical-memory use and 4.02 GiB combined paged/nonpaged pools.

## Remaining boundaries

1. Approve the topic/account/local-convention selector and any evidence-backed exception cases.
2. Publish or connect the 11 dirty no-origin repositories while preserving their exact working state; define handling for the three non-repository entries.
3. Implement the project-sync manager, add the two missing data manifests, verify all data-manifest adapters, and remove the Capsule workspace payload.
4. Fill the 8 Bitwarden Login scaffolds, bind the Docket item ID, configure matching Vercel variables, publish the 160 eligible cards, and verify returned IDs without exposing values.
5. Finish the 3/4/3 and OneDrive-removal documentation, then refresh the harness-only Capsule after the new transport path passes.
6. Decide the exact retention or removal boundary for the preserved `C:\Users\dougl\OneDrive` data tree, registered legacy worktrees, comparison candidates, and unmatched Attachments folder.
7. Optional: run an elevated RAMMap capture and controlled WSAIFabric stop/restart comparison if deeper kernel-pool attribution remains useful.

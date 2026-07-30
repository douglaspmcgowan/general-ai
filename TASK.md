# Task

## Goal

Keep the General AI coordination repository portable, truthful, and recoverable while completing the remaining cross-project migration and human-controlled setup boundaries.

## Active

- None.

## Queue

- [ ] T2 — Confirm whether the final shared-harness publication remains outstanding | evidence: reconcile the archived queue’s blocked publication item with later `STATUS.md` and `LOG.md` authorization/push evidence without assuming completion | provenance: archived `WORK_QUEUE.md`
- [ ] T3 — Refresh or retire the stale toolkit map and check `playbooks\INDEX.md` for currency | evidence: Douglas chooses refresh or retirement and the selected references agree with the live harness | status: parked | provenance: `BACKBURNER.md`

## Blocked

- [!] T4 — Publish the Skills Docket cards to the cloud board | blocked: the legacy queue records the required Docket review credential as absent; do not access or expose credential values | evidence: authenticated publication plus value-safe confirmation | provenance: archived `WORK_QUEUE.md`
- [!] T5 — Remove old registered worktree rollback copies | blocked: wait until their owning sessions close and the delete-deny ACL no longer applies | evidence: owners released, worktrees safely removed, canonical repositories still verify | provenance: archived `WORK_QUEUE.md`
- [!] T6 — Retire the old OneDrive data tree | blocked: complete Google Drive UI cleanup, start a fresh lowercase-path session, and obtain final restore evidence first | evidence: prerequisites recorded and rollback source retired safely | provenance: archived `WORK_QUEUE.md`

## Needs decision

- [?] D1 — In Google Drive Preferences, remove the nine broad selected folders and choose only curated value-free backup exports | evidence: Douglas confirms the selected-folder list after the UI change | provenance: archived `WORK_QUEUE.md`

## Completed

- [x] T1 — Onboard this repository to harness v3 in isolated worktree `C:\tmp\onboard-general-ai-v3` | evidence: canonical `SyncProject` and `VerifyProject`, installed project verifier, `git diff --check`, redacted Gitleaks history and directory scans, and the local disposable `capsule\Capsule.Tests.ps1` suite all passed before commit; stable checkout remained untouched | owner: repository coordination and harness files | provenance: 2026-07-30 onboarding request
- [x] T7 — Complete cross-agent project-management research, follow-up audit, storage analysis, and migration planning | evidence: all checked obligations remain preserved verbatim in the archived `WORK_QUEUE.md` sections dated 2026-07-24 | provenance: archived `WORK_QUEUE.md`
- [x] T8 — Implement and verify global harness, backup, local-data, and worktree operating procedures | evidence: all checked obligations remain preserved verbatim in the archived global-harness and cross-platform sections | provenance: archived `WORK_QUEUE.md`
- [x] T9 — Establish context, secret, skill, Docket, archive, and project-bootstrap operating models | evidence: all checked obligations remain preserved verbatim in the archived 2026-07-26 sections | provenance: archived `WORK_QUEUE.md`
- [x] T10 — Complete Drive coverage, richer baseline, feedback, Docket, and migration work | evidence: all checked obligations remain preserved verbatim in the archived Drive coverage and final retirement sections | provenance: archived `WORK_QUEUE.md`
- [x] T11 — Complete portable project, application-data, Explorer, Capsule, and `general-ai` recovery work | evidence: all checked obligations remain preserved verbatim in the archived 2026-07-27 sections and durable `STATUS.md`/`LOG.md` | provenance: archived `WORK_QUEUE.md`

## Verification

- Harness sync: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\tmp\agent-harness-google-drive-account-root\.agents\tools\Manage-Harness.ps1 -Action SyncProject -HarnessRoot C:\tmp\agent-harness-google-drive-account-root\.agents -Repository C:\tmp\onboard-general-ai-v3`
- Harness verify: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\tmp\agent-harness-google-drive-account-root\.agents\tools\Manage-Harness.ps1 -Action VerifyProject -HarnessRoot C:\tmp\agent-harness-google-drive-account-root\.agents -Repository C:\tmp\onboard-general-ai-v3`
- Installed project verifier: `C:\Users\dougl\.agents\tools\Test-AgentProjectState.cmd -Repository C:\tmp\onboard-general-ai-v3`
- Whitespace: `git diff --check`
- Secret scans: `gitleaks git --redact --no-banner .` and `gitleaks dir --redact --no-banner .`
- Safe repository test: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\capsule\Capsule.Tests.ps1`

# Verification

Before claiming this coordination project or migration complete:

1. Run `C:\Users\dougl\.agents\tools\Test-AgentProjectState.cmd -Repository C:\Users\dougl\projects\general-ai`.
2. Run `C:\Users\dougl\.agents\tools\Test-HarnessSetup.cmd`.
3. Run `git diff --check`.
4. Run `C:\Users\dougl\Tools\gitleaks\gitleaks.exe dir C:\Users\dougl\projects\general-ai --no-banner --redact`.
5. Run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Users\dougl\projects\agent-harness\.agents\capsule\Capsule-Portability.Tests.ps1 -AgentHarnessSource C:\Users\dougl\projects\agent-harness`.
6. Confirm every canonical repository in `MIGRATION.md` exists and passes its project verifier.
7. For a copied dirty repository, compare the source and destination Git status, tracked diff, staged diff, and untracked-content digest before cutover.
8. Confirm the Docket scheduled task is running and `http://127.0.0.1:8471` returns HTTP 200.
9. Confirm GitHub remotes match the recorded local commits.
10. Confirm Google Drive's selected folders include only intentional sync roots.
11. Retire a rollback source only after its destination is verified and no active session owns the old path.
12. Run the `declog` fixture tests, then run a read-only live report and confirm the active Codex/ChatGPT owner tree is protected.
13. Run the Bitwarden scaffold tests and inspect the value-free creation plan; never require live vault contents for project verification.
14. Confirm `Nightly Agent Backups` is Ready, starts at 02:00, runs on battery, starts when available, and advances `Recovery\latest.json` after a successful assembled run.
15. Before a whole-task completion handoff, reconcile `CURRENT-TASK.md` Remaining against every `[ ]` and `[~]` entry in the resolved `WORK_QUEUE*`. When actionable entries remain, continue or report the exact active owners; when only `[!]` and `[?]` remain, report each external dependency and owner.

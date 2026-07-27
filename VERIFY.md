# Verification

Before claiming this coordination project or migration complete:

1. Run `C:\Users\dougl\.agents\tools\Test-AgentProjectState.cmd -Repository C:\Users\dougl\projects\general-claude`.
2. Run `C:\Users\dougl\.agents\tools\Test-HarnessSetup.cmd`.
3. Run `git diff --check`.
4. Run `C:\Users\dougl\Tools\gitleaks\gitleaks.exe dir C:\Users\dougl\projects\general-claude --no-banner --redact`.
5. Confirm every canonical repository in `MIGRATION.md` exists and passes its project verifier.
6. For a copied dirty repository, compare the source and destination Git status, tracked diff, staged diff, and untracked-content digest before cutover.
7. Confirm the Docket scheduled task is running and `http://127.0.0.1:8471` returns HTTP 200.
8. Confirm GitHub remotes match the recorded local commits.
9. Confirm Google Drive's selected folders from computer are limited to the curated backup root.
10. Retire a rollback source only after its destination is verified and no active session owns the old path.

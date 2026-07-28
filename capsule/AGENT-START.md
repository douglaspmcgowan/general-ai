# Agent entry point

If you are an agent opening this Capsule on a receiving Windows computer, read and follow these files in order:

1. `START-HERE.md` — human prerequisites, bootstrap order, and stopping conditions.
2. `SYSTEM-MAP.md` — authorities, paths, data flows, and verification commands.
3. `DATA-SYNC-AND-RETENTION.md` — ongoing updates, excluded-data routes, and snapshot retention status.
4. `SECRETS-BITWARDEN.md` — Douglas/agent responsibility boundary and the approved secret-injection workflow.
5. `manifests\accounts.json` — value-safe sign-in identifiers and explanations.
6. `manifests\software.json` — expected applications and command-line tools.

## Agent rules

- Verify `manifests\integrity.json` before restoring anything.
- Never read, request, print, log, or write a password, key, token, session value, recovery code, or vault export.
- Ask Douglas to complete account-owner login, two-factor approval, vault unlock, and credential creation or rotation.
- Restore only into a clean receiving profile. The bootstrap refuses existing project and shared-harness destinations.
- Treat GitHub, Google Drive, and Bitwarden as ongoing authorities after installation. Treat the Capsule payload as a dated recovery snapshot.
- Preserve `capsule` as the offline Git remote and use `origin` for the recorded GitHub remote.
- Stop when an integrity check, Gitleaks scan, repository verifier, or harness verifier fails.

## First commands

```powershell
& "$env:USERPROFILE\Documents\Capsule\tools\Verify-Capsule.ps1" `
  -CapsuleRoot "$env:USERPROFILE\Documents\Capsule"

& "$env:USERPROFILE\Documents\Capsule\tools\Bootstrap-Capsule.ps1" `
  -CapsuleRoot "$env:USERPROFILE\Documents\Capsule"
```

After bootstrap, continue from `C:\Users\<Windows-user>\projects\general-ai\AGENTS.md`.

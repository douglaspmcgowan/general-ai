# Handoff — finish OneDrive exit and free secrets migration

Open the new Codex session from:

```text
C:\Users\dougl\projects\general-claude
```

Paste this prompt:

> Continue the OneDrive exit and free-secrets migration from the 2026-07-27 handoff. Read `C:\Users\dougl\.agents\HARNESS-MAP.md`, `C:\Users\dougl\.agents\CROSS-AGENT-CONTRACT.md`, `C:\Users\dougl\.agents\human-readable\15-BACKUP-INVENTORY-AND-GOOGLE-DRIVE.md`, and `C:\Users\dougl\.agents\human-readable\20-FREE-SECRETS-MANAGEMENT.md` first. Also read this repository's `AGENTS.md`, task state, and last `LOG.md` entries.
>
> Goals:
>
> 1. Confirm the current session and every active worktree are outside `C:\Users\dougl\OneDrive`.
> 2. Reconfirm Windows known folders map to `C:\Users\dougl\Desktop`, `C:\Users\dougl\Documents`, and `C:\Users\dougl\Pictures`.
> 3. Have Douglas update Google Drive Preferences: remove every retired OneDrive path and live engineering root; add local Desktop, Documents, and optional Pictures; leave streamed My Drive alone. If all Documents is selected, do not add Agent Backups separately.
> 4. Wait for Google Drive to report “Up to date,” then restore-test one ordinary file from each selected folder.
> 5. Run a final metadata-only comparison of the old OneDrive Desktop/Documents/Pictures/Attachments against the local folders. Preserve destination collisions for review. Do not read secret values or off-limits vault paths.
> 6. Clean stale Git worktree registrations that still point into OneDrive after confirming their branches/commits have safe replacements.
> 7. Remove the retired `C:\Users\dougl\OneDrive` tree only after steps 1–6 prove it is redundant. Report what was removed and recovery status.
> 8. Use Bitwarden Password Manager Free as the local source of truth. Before using `Invoke-WithBitwardenItem.ps1` with Node or another script host, harden it with tests so the policy binds item, field, destination variable, exact executable, and exact argument list. Keep production policy fail-closed until the `project:docket:production` item exists.
> 9. Douglas creates a Bitwarden item named `project:docket:production` with a Hidden custom field `REVIEW_SECRET`, then unlocks `bw.cmd` interactively in a trusted terminal. Never request or display the secret or `BW_SESSION`.
> 10. After the broker tests pass, inject `REVIEW_SECRET` only into Docket's exact cloud-sync command and verify that the child cannot inherit `BW_SESSION`.
> 11. Update the Docket value-free secret manifest, harness briefs/changelog/stamp, run Gitleaks and all harness/Docket verifiers, commit both private repositories, push them, and refresh the value-free harness recovery pointer.
>
> Source facts already verified:
>
> - OneDrive's application is uninstalled and its process/package are absent.
> - Windows known folders already point to the local Desktop/Documents/Pictures paths.
> - Missing old OneDrive personal files were copied additively; existing local collisions were preserved.
> - The remaining OneDrive tree exists because the previous Codex session ran inside it.
> - Google Drive's configuration still contained nine computer-folder backups, including retired OneDrive folders and live agent/project roots.
> - Local Docket needs no passcode. Its public Vercel API requires `APP_SECRET`; the phone/cloud-sync client uses the same value as `REVIEW_SECRET`.
> - Bitwarden Password Manager Free supports unlimited personal vault items. Doppler Developer currently allows ten projects. Bitwarden Secrets Manager Free and Infisical Free each cap the relevant free project count at three.
> - Docket's value-free manifest now has 11 variables. The obsolete `BWS_ACCESS_TOKEN` requirement was removed, the generated view passes its check, all 73 tests pass, and commit `ebd8ede` is pushed.
> - A fresh read-only Google Drive database query still shows all nine old computer-folder roots. Google Drive has been started and awaits the Preferences change.
> - Git still registers two worktrees inside OneDrive: `168-audit-redesign` and `berkeley-house\repo-worktree`.
> - The 168 replacement has the same commit and matching test artifacts; both old and replacement copies contain the additive project baseline. The current-tree Gitleaks scan found five redacted findings, so do not upload or broadly archive that tree.
> - Berkeley's old branch head `7e74f3a` is published at `origin/agent/property-finance-completion` and is ahead of replacement base `e4e8b53`. Its only meaningful untracked file, `scripts/audit-lease-state.mjs`, was Gitleaks-clean and copied byte-for-byte into the replacement worktree.
>
> Keep every open question in the final response. End with full paths for every changed file.

## Human checklist before the deletion step

- Google Drive Preferences show the local folders, with no `C:\Users\dougl\OneDrive` entry.
- Google Drive reports “Up to date.”
- A restore test succeeds.
- No open Codex, Claude, Cursor, terminal, editor, or worktree uses an old OneDrive path.
- The final comparison reports no old-only file that lacks a preserved local or backup copy.

## Broker design awaiting Douglas's explicit approval

Recommended policy record:

```text
Bitwarden item + field + destination variable + exact executable + exact argument list
```

The broker rejects the request before accessing Bitwarden when any field differs. Tests must cover every mismatch, confirm that the child cannot inherit `BW_SESSION`, and confirm parent-environment restoration. Script hosts such as Node receive approval only for the named script and arguments.

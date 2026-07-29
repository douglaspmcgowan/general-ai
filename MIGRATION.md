# Repository migration ledger

Last verified: 2026-07-29

## Cutover rule

A repository becomes canonical under `C:\Users\dougl\projects` after:

1. an additive copy preserves Git and ignored working state;
2. source and destination file inventories agree;
3. Git branch, status, tracked diff, staged diff, and untracked-content evidence agree;
4. `git fsck` and the project harness verifier pass;
5. no active session continues writing the old path.

Canonical project and replacement-worktree paths remain outside the retired sync-client application. Preserved legacy paths stay untouched until their exact data-retention boundary is approved.

## OneDrive retirement status

Application retirement is complete. The official `C:\Windows\System32\OneDriveSetup.exe /uninstall` exited `0`. Verification on 2026-07-29 then found zero running OneDrive processes, uninstall registrations, startup entry, scheduled tasks, and Winget packages. The Windows system setup stub remains present.

The local `C:\Users\dougl\OneDrive` reparse-point data tree remains preserved with 141,008 files and 5,796,741,017 logical bytes. Git still registers the old 168 Audit and Berkeley House worktrees there alongside their verified relocated replacements. Metadata-only comparisons reported Desktop with 1 candidate file, Documents with 140,440 candidate files and 5,413,453,487 bytes, Pictures fully skipped, and Attachments with no `C:\Users\dougl\Attachments` counterpart. These registrations and data are recovery evidence pending an explicit retention or removal decision; current harness, project, Capsule, and Google Drive workflows have no OneDrive application dependency.

## Verified lowercase repositories

| Project | Canonical path | Evidence |
|---|---|---|
| agent-harness | `C:\Users\dougl\projects\agent-harness` | Clean and synchronized with remote `master`; Gitleaks and harness verifier pass |
| docket | `C:\Users\dougl\projects\docket` | Clean remote commit `33b00f4`; 73 tests and Gitleaks pass |
| boundaries-reader | `C:\Users\dougl\projects\boundaries-reader` | Exact tree digest, Git dirty state, and project verifier |
| claude-global-config | `C:\Users\dougl\projects\claude-global-config` | Exact tree digest, Git dirty state, and project verifier |
| contact-form-caller | `C:\Users\dougl\projects\contact-form-caller` | Exact tree digest, Git dirty state, and project verifier |
| drive-organizer | `C:\Users\dougl\projects\drive-organizer` | Exact tree digest, Git dirty state, and project verifier |
| grandpa-help | `C:\Users\dougl\projects\grandpa-help` | Exact tree digest, Git dirty state, and project verifier |
| harness | `C:\Users\dougl\projects\harness` | Exact tree digest, Git dirty state, and project verifier |
| harness-bootstrap-verification-20260726 | `C:\Users\dougl\projects\harness-bootstrap-verification-20260726` | Exact tree digest, Git dirty state, and project verifier |
| idetc-writing-ide | `C:\Users\dougl\projects\idetc-writing-ide` | Exact tree digest, Git dirty state, and project verifier |
| motion-to-dismiss | `C:\Users\dougl\projects\motion-to-dismiss` | Exact tree digest, Git dirty state, and project verifier |
| base-flight-finder | `C:\Users\dougl\projects\base-flight-finder` | Dry-run zero, exact Git diffs/status/untracked content, file counts/bytes, `git fsck`, and project verifier |
| flight-tracker coordination | `C:\Users\dougl\projects\flight-tracker` | Exact tree digest excluding the separately migrated main repository |
| anna-maria-mcgowan | `C:\Users\dougl\projects\anna-maria-mcgowan` | Existing structured repository |
| berkeley-house source repository | `C:\Users\dougl\projects\berkeley-house` | Existing structured repository with a verified relocated auxiliary worktree; the registered legacy path remains preserved evidence |
| client-portal | `C:\Users\dougl\projects\client-portal` | Existing structured repository |
| conference-tracker | `C:\Users\dougl\projects\conference-tracker` | Existing structured repository |
| fellowship-tracker | `C:\Users\dougl\projects\fellowship-tracker` | Existing structured repository |
| jars-of-clay | `C:\Users\dougl\projects\jars-of-clay` | Existing structured repository |
| legal-doc-studio | `C:\Users\dougl\projects\legal-doc-studio` | Existing structured repository |
| legal-solutions-website | `C:\Users\dougl\projects\legal-solutions-website` | Existing structured repository |
| redline-idetc | `C:\Users\dougl\projects\redline-idetc` | Existing structured repository |
| general-ai | `C:\Users\dougl\projects\general-ai` | Lean coordination repository and current migration authority; `general-claude` retained as session rollback |
| 168-audit | `C:\Users\dougl\projects\168-audit` | Main repository moved; additive project baseline and Gitleaks pass |

## Replacement worktrees and rollback copies

| Project | Replacement path | Preserved legacy path | Evidence |
|---|---|---|---|
| 168 Audit | `C:\Users\dougl\Worktrees\168-audit\codex-168-audit-redesign-relocated` | `C:\Users\dougl\OneDrive\Documents\General Claude\168-audit-redesign` | Exact commit and file mirror; project verifier passes |
| Berkeley House | `C:\Users\dougl\Worktrees\berkeley-house\agent-property-finance-completion-relocated` | `C:\Users\dougl\OneDrive\Documents\General Claude\berkeley-house\repo-worktree` | Exact published commit `e4e8b53`; cross-agent project verifier passes |

The preserved legacy paths remain registered. Remove their registrations and data only after the exact retention decision verifies that the relocated worktrees and any unique local data remain recoverable.

## Reversible archive

`C:\Users\dougl\projects\general-claude-incomplete-20260727` is the retained 4.48 GiB incomplete umbrella copy. It may be deleted after this repository, all individual projects, and the preserved legacy data pass the final retention review.

## Project data preservation

`C:\Users\dougl\Data\Projects\idetc-writing-ide\inputs\ASME_IDETC_2026.zip` is an additive copy of the old workspace archive. Source and destination SHA-256 hashes matched on 2026-07-27.

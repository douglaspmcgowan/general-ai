# Repository migration ledger

Last verified: 2026-07-27

## Cutover rule

A repository becomes canonical under `C:\Users\dougl\projects` after:

1. an additive copy preserves Git and ignored working state;
2. source and destination file inventories agree;
3. Git branch, status, tracked diff, staged diff, and untracked-content evidence agree;
4. `git fsck` and the project harness verifier pass;
5. no active session continues writing the old path.

Old paths remain rollback sources until the full OneDrive retirement.

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
| berkeley-house source repository | `C:\Users\dougl\projects\berkeley-house` | Existing structured repository; active auxiliary worktree still resides under OneDrive |
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

| Project | Replacement path | Old rollback path | Evidence |
|---|---|---|---|
| 168 Audit | `C:\Users\dougl\Worktrees\168-audit\codex-168-audit-redesign-relocated` | `C:\Users\dougl\OneDrive\Documents\General Claude\168-audit-redesign` | Exact commit and file mirror; project verifier passes |
| Berkeley House | `C:\Users\dougl\Worktrees\berkeley-house\agent-property-finance-completion-relocated` | `C:\Users\dougl\OneDrive\Documents\General Claude\berkeley-house\repo-worktree` | Exact published commit `e4e8b53`; cross-agent project verifier passes |

The old rollback paths remain registered because the active workspace ACL denies directory deletion. Remove them with Git's worktree command after this workspace closes.

## Reversible archive

`C:\Users\dougl\projects\general-claude-incomplete-20260727` is the retained 4.48 GiB incomplete umbrella copy. It may be deleted after this repository, all individual projects, and the old OneDrive rollback tree pass the final completion audit.

## Project data preservation

`C:\Users\dougl\Data\Projects\idetc-writing-ide\inputs\ASME_IDETC_2026.zip` is an additive copy of the old workspace archive. Source and destination SHA-256 hashes matched on 2026-07-27.

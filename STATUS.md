# Status

## Current harness state — 2026-07-29

- `C:\Users\dougl\projects\general-ai` is the canonical coordination repository. It uses the v3 portable project contract and one `TASK.md`; verified migration sources remain under `.agents\archive`.
- The live shared authority is `C:\Users\dougl\.agents`. Its global rules, map, design rules, memory index, manager, adapters, baseline skills, and three consolidated hook dispatchers are installed.
- The human guide is `C:\Users\dougl\.agents\human-readable\README.md`; `README.html` is its source-hash-matched browser-readable mirror. Both describe the verified `20260729-071541` Capsule and the remaining credential/RAMMap gates.
- Private harness pull request #2 merged at `5245929e362fddf912f6f43dd2efc3b141241fb4`.
- Private harness pull request #3 merged at `0435bb8c38e09d5d9a18c46c11d7d9a1bbdf6a63`.
- Private harness pull request #4 merged at `03c0f0d8c2692dbbaa13411d1c5ff7379f9aa589`.
- Private harness pull request #5 merged at `727662d4881eeadcef605f15cb268d1791774ad3`.
- Private harness pull request #6 merged at `0d19eeca14bc0313705cf57390e18c0f822e75a5`.
- Docket pull request #1 merged at `2489f7a32617eec287cf36d9a521636cc38b01f9`; pull request #2 merged at `32d2346`, followed by status commit `9aa727a`. The source authority remains `C:\Users\dougl\projects\docket`.
- The Docket store contains 162 items. `setup-handoff--general-claude-github` and `setup-handoff--google-drive-preferences` are archived locally; the pre-archive backup is `C:\Users\dougl\.docket-local\_backups\before-stale-archive-20260729`; 160 unresolved items remain eligible for outbound publication.
- Claude launch configuration commit `52a7fd1` points redline, drive-organizer, and contact-form-caller at their canonical project roots. The configuration parsed and three PID-scoped HTTP smoke tests returned 200.
- GitHub CLI is authenticated as `douglaspmcgowan` through the interactive Windows keyring.
- The canonical receiving-computer package is `C:\Users\dougl\My Drive\Capsule`. Its manifest selects snapshot `20260729-071541`; the package contains 28,462 files, including the self-excluded integrity manifest. `README.md` is the current human and agent entry; `AGENT-START.md` remains a compatibility pointer.
- Google Drive is launched. The direct local Capsule path and selected-snapshot manifest are accessible.
- Nightly Agent Backups remains the ongoing route for repositories, approved project data, application configuration, handoffs, and Quick Access recovery.
- The guarded stale-agent cleanup and portable `declog` skill remain installed for Windows resource-pressure diagnosis.
- Bitwarden Password Manager CLI, the value-safe scaffold, and the full-tuple broker are installed and tested. Interactive login/unlock, emailed-device verification, and value entry remain.
- Signed Microsoft RAMMap v1.63 is installed at `C:\Users\dougl\Tools\Sysinternals\RAMMap\RAMMap64.exe`. The captured pressure sample showed 95% physical-memory use and 4.02 GiB combined paged/nonpaged pools. An elevated snapshot attempt produced no file, so another UAC capture and a controlled WSAIFabric A/B test remain optional.

## Remaining boundaries

1. Complete Bitwarden authentication and Hidden-field setup, bind the non-secret Docket item ID, configure the matching Vercel credentials, publish the 160 eligible cards, and verify returned IDs without exposing credential values.
2. Decide whether another elevated RAMMap capture and a controlled WSAIFabric A/B test are useful.

# Status

- The shared harness is published on private GitHub at commit `36bd3c2`.
- Docket's loopback-authentication repair is published on private GitHub at commit `33b00f4`.
- The GitHub app connector works for existing repositories. GitHub CLI is authenticated through the Windows keyring, and Git HTTPS uses its reusable credential helper.
- Docket starts through the limited-privilege `DocketDaemon` task. The repaired local API passes loopback integration tests without a persistent passcode.
- The 94-file harness verifier and Gitleaks pass. The value-free recovery pointer is remote-verified at `36bd3c2`.
- Ten repositories formerly under OneDrive have exact verified copies under `C:\Users\dougl\projects`.
- The Flight Tracker coordination folder has an exact verified lowercase copy.
- The 168 Audit and Berkeley House worktrees are actively changing in the old tree and await owner handoff.
- Google Drive is installed and stopped; its current local profile directory is absent, so selected-folder coverage still requires visible Preferences verification.
- OneDrive is uninstalled. Its old data tree remains the rollback authority during active-path cutover.
- Bitwarden Secrets Manager CLI and broker are installed and tested. The web vault needs Douglas's login before the free Docket objects can be created.
- The local Docket contains 162 cards: 157 Skills Docket cards and five setup handoffs. Cloud publication remains pending the Docket secret handoff.
- The IDETC archive is preserved under `C:\Users\dougl\Data\Projects\idetc-writing-ide\inputs` with a matching SHA-256 copy check.

# Current task

Goal: build a self-contained `Capsule` for recreating Douglas's portable cross-agent setup, adopt a free secrets authority that supports more than three projects, rename the coordination project to `general-ai`, and publish a verified system map.

Completed:

- Established and verified nightly workspace snapshots and three-mode project restore.
- Chose Bitwarden Password Manager Free as the unlimited-project local credential authority and documented its full-tuple broker.
- Added offline Git bundles for every committed repository and verified remote-independent restore.
- Built and tested Capsule refresh, integrity verification, bootstrap, account-map, Bitwarden, and system-map artifacts.
- Installed the Capsule source and updated recovery scripts in the shared harness; the private harness has local commit `af6dd49`.

Remaining:

1. Create and verify the canonical `C:\Users\dougl\projects\general-ai` replacement and data root.
2. Generate a fresh nightly snapshot containing `general-ai`.
3. Assemble and verify `C:\Users\dougl\Documents\Capsule`.
4. Run final project, harness, Gitleaks, and adversarial verification.
5. Record the manual GitHub login/publish boundary.

Exact next verifier: clone this committed repository into `C:\Users\dougl\projects\general-ai`, then run `Test-AgentProjectState.cmd` there.

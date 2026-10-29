# Fresh-machine readiness

Run these in order. Each later step assumes the preceding check passed.

1. Obtain an authenticated clone and verify its identity with `git remote -v`, `git fetch --all --prune`, and `git rev-parse HEAD`. Check the expected remote and reviewed revision; `git status` only reports local worktree state.
2. For hosted Linux, configure `set -euo pipefail; bash .agents/cloud/setup.sh` for Codex; for Claude use the always-exit-0 wrapper in `ONBOARDING/CLOUD-AGENTS.md` step 8. Supply no cloud credential fields for code-work, or all declared names: `BITWARDEN_SECRETS_MANAGER_ACCESS_TOKEN` (or, preferred, your environment's own machine-account token variable; see `.agents/references/bitwarden.md`) and `BWS_PROJECT_ID`. Check: setup refuses a partial profile without printing values.
3. Keep Node on the reviewed major in `tool-versions.sh`; allow setup to install reviewed CLI pins. Check: setup rejects a mismatched Node major and unavailable required commands.
4. Give the hosted image a real, non-symlink PowerShell 7 executable at `/usr/bin/pwsh`, `/usr/local/bin/pwsh`, or `/opt/microsoft/powershell/7/pwsh`. Check: setup rejects an absent or untrusted runtime for an enrolled project.
5. Run `pwsh -NoProfile -NonInteractive -File .agents/tools/Test-PwshReachability.ps1`. Check: it reports PATH presence, alias classification, actual execution, and a genuine executable with its version. If a host-only path is unavailable, record `SKIP` or `UNKNOWN` and continue with the remaining checks.
6. Start a clean noninteractive login shell after setup. Check: it resolves `gh`, `bws`, and `pwsh` from the persisted profile.
7. Run `bash .agents/cloud/verify.sh`. Check: toolchain, contract loaders, router roster, Work Scope fixture, shell suites, and project verifier produce no `FAIL` lines.
8. Run one harmless Codex-cloud task and one harmless Claude-web task. Check: each loads `AGENTS.md`, completes its declared verification, and reports evidence.
9. Have a sandboxed delegate run one harmless PowerShell proving command through the genuine executable recorded by `Test-PwshReachability.ps1`. Check: the delegate reports the command, executable path, version, and result.

## Cold-start executable capability matrix

Run these proof commands after the fresh-machine steps. On Windows:

```text
pwsh -NoProfile -WindowStyle Hidden -NonInteractive -File .agents/tools/Test-CapabilityReach.ps1
pwsh -NoProfile -WindowStyle Hidden -NonInteractive -File .agents/tools/Test-CapabilityReach.test.ps1
```

On Linux:

```text
pwsh -NoProfile -NonInteractive -File .agents/tools/Test-CapabilityReach.ps1
pwsh -NoProfile -NonInteractive -File .agents/tools/Test-CapabilityReach.test.ps1
```

The matrix has 3 surfaces (Claude, Codex, Cursor) and 4 capabilities (project contract loaded, skills catalogue readable, tools directory resolves, Claude sync prerequisites present): 12 cells total. Every cell is `reachable`, `unreachable`, or `unknown`. `reachable` and `unreachable` require an executed probe whose output names the probe and result or error. `unknown` means the probe could not run; it never counts as reachable. The headline includes the unknown count, and the printed reachable, unreachable, and unknown totals sum to 12.

An absent host-only surface root in a container is inert and `unknown`. A missing expected file under an existing surface is `unreachable`. A Windows Store `pwsh` alias stub is classified through execution: only a successfully started real executable can be reachable; a failed start or nonzero exit is `unreachable`, and a probe that cannot run is `unknown`.

These proof commands inspect and report state. They make no software, network, system, or `PATH` changes.

Legacy active-state migration is owned by `Manage-Harness.ps1` and its compatibility suite. This guide does not render or migrate `CURRENT-TASK.md`, `WORK_QUEUE.md`, or `VERIFY.md`.

# Historical recovery evidence

This folder preserves recovery artifacts that remain useful after the repository-first cutover. It is not an onboarding entrypoint.

Current reconstruction begins with [`START-HERE.md`](../START-HERE.md), then follows the canonical private harness repository's `ONBOARDING\START-HERE.md`. Drive Capsule, Nightly Agent Backups, and Password Manager broker instructions formerly stored here are retired and must not be used to reconstruct another computer.

## Retained `general-claude` Git history

`general-claude-history.bundle` preserves every committed ref from `C:\Users\dougl\projects\general-claude` at source `master` commit `f8c1f39ed369d8694eb9f82c50f622883bf29a7e`. It was created with `git bundle create --all`, verified as complete, cloned into an empty temporary directory, checked with `git fsck --full`, and matched back to the source `master` SHA.

Verify or restore that historical repository with:

```powershell
git bundle verify "C:\Users\dougl\projects\general-ai\recovery\general-claude-history.bundle"
git clone "C:\Users\dougl\projects\general-ai\recovery\general-claude-history.bundle" "C:\Users\dougl\projects\general-claude-restored"
```

The bundle covers committed Git history. The preserved original repository remains the authority for any uncommitted working-tree state until that state is explicitly reconciled.

## Active external data boundary

`C:\Users\dougl\My Drive\Project Data` remains the declared external artifact transport. Each project owns its data through `data-manifest.yaml` and a reviewed adapter. Credential values, product sessions, caches, environment files, and restricted data remain outside this repository.

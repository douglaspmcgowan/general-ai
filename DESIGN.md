# Design record

## Goals

- Give every project one stable lowercase path under `C:\Users\dougl\projects`.
- Keep shared agent behavior consistent across Claude, Codex, Cursor, local worktrees, and cloud sessions.
- Separate versioned source, valuable mutable data, credentials, worktrees, product state, and recovery artifacts.
- Preserve dirty working trees and active sessions during the OneDrive retirement.

## Constraints

- Several repositories began with uncommitted user and agent changes.
- Active 168 Audit and Berkeley House sessions still own paths in the old OneDrive tree.
- Credential values cannot enter Git, Markdown, chat, logs, manifests, or agent-visible command output.
- Google Drive desktop folder coverage requires human verification in its Preferences UI.
- Docket cloud publication requires a human-created free Bitwarden project, secret, machine account, and token.

## Decisions

- `.agents` is the live shared harness; `.agents\human-readable` is the canonical explanatory layer.
- The private harness repository and per-project Git remotes supply versioned recovery.
- `C:\Users\dougl\projects` is the canonical source root.
- `C:\Users\dougl\Data\Projects` and `Data\Restricted` hold mutable and restricted data.
- `C:\Users\dougl\Worktrees` holds disposable concurrent Git state.
- `Documents\Agent Backups` holds curated value-free recovery artifacts for optional Google Drive backup.
- Dirty repositories migrate through additive copies and exact state verification before old paths are retired.
- Active worktrees cut over only at a recorded handoff point.

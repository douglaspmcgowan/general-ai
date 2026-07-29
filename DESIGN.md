<!-- agent-harness:universal-design:v1:start -->
## Universal interface rules

- Never use IBM Plex Mono.
- Use a proportional body face for prose, navigation, labels, dates, names, and human-readable metadata.
- Reserve monospace for code, commands, identifiers, timestamps, and genuinely tabular numeric data.
- Define explicit body, display, and monospace roles. Use tabular numerals on the proportional face for aligned quantities.
- Establish hierarchy through size, weight, spacing, and placement before decoration.
- Give each screen a clear primary action or reading path. Use spacing and alignment to show relationships.
- Reuse existing tokens and components before adding variants.
- Cover relevant default, hover, focus, active, disabled, loading, empty, error, and success states.
- Use semantic structure and native controls, visible keyboard focus, logical tab order, accessible names, sufficient contrast, and non-color state cues.
- Support narrow, medium, and wide layouts, zoom, text resizing, touch targets, and reduced motion.
- Inspect the existing design system, screenshots, and implementation before proposing a new rule or component.
- Verify browser-visible work with browser or end-to-end tests across responsive, keyboard, loading, empty, and error behavior.
<!-- agent-harness:universal-design:v1:end -->

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
- Docket cloud publication requires a populated Bitwarden Password Manager Login item and value-free full-tuple broker metadata.

## Decisions

- `.agents` is the live shared harness; `.agents\human-readable` is the canonical explanatory layer.
- The private harness repository and per-project Git remotes supply versioned recovery.
- `C:\Users\dougl\projects` is the canonical source root.
- `C:\Users\dougl\Data\Projects` and `Data\Restricted` hold mutable and restricted data.
- `C:\Users\dougl\Worktrees` holds disposable concurrent Git state.
- `Documents\Agent Backups` holds curated value-free recovery artifacts for optional Google Drive backup.
- `My Drive\Capsule` is the primary receiving-computer route for the integrity-verified Capsule.
- Password Manager Login items with exact Hidden custom-field names are the default project-secret container; the broker fails closed on empty, missing, or ambiguous fields.
- Process cleanup begins with a read-only ownership and memory report. Active owner trees stay protected, and ambiguous candidates require a human decision.
- Dirty repositories migrate through additive copies and exact state verification before old paths are retired.
- Active worktrees cut over only at a recorded handoff point.

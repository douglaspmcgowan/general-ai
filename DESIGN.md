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
- Preserve recovery evidence until exact data-retention decisions and replacement-path verification are recorded.

## Constraints

- Several repositories began with uncommitted user and agent changes.
- The project inventory contains 27 Git repositories: 16 with origins and 11 dirty repositories without origins. Remote publication must preserve exact working state.
- `.obsidian` configuration, the `flight-tracker` container, and the `general-claude-incomplete` archive require explicit non-repository handling.
- The OneDrive application is removed. Its local data tree and two registered legacy worktrees remain preserved pending an exact retention decision.
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
- `My Drive\Capsule` carries only the shared global harness, bootstrap tools, and repository inventory for a receiving computer.
- Each GitHub repository carries its own source, portable rules, handoffs, and small versionable data.
- GitHub CLI discovers the managed repository set dynamically from the configured account and topic, then applies local path conventions. A static `repositories.json` is unnecessary; evidence-backed exceptions stay narrow.
- Project data-manifest adapters carry excluded and live mutable data; the shared project-sync manager orchestrates repository recreation and adapter execution.
- The existing `data-manifest.yaml` in 25 of 27 repositories is the standard transport extension point; the remaining two repositories need manifests before full-fleet verification.
- The current Capsule workspace payload is transitional and will be removed after the project-sync manager passes end-to-end restore verification.
- Current workflows have no OneDrive application dependency; the preserved local tree is recovery evidence until its explicit retention boundary is approved.
- Password Manager Login items with exact Hidden custom-field names are the default project-secret container; the broker fails closed on empty, missing, or ambiguous fields.
- Process cleanup begins with a read-only ownership and memory report. Active owner trees stay protected, and ambiguous candidates require a human decision.
- Dirty repositories migrate through additive copies and exact state verification before old paths are retired.
- Active worktrees cut over only at a recorded handoff point.

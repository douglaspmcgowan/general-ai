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

### Design libraries

Concrete things to reach for — animation packages and working skeletons, icon kits, typeface pools, design-system install commands and canonical documentation. Read the leaf you need; each one loads on its own.

- **Index** `~/.agents/design/LIBRARIES.md`
- **Motion** `~/.agents/design/animation/` — libraries, sticky-stack, horizontal-pan, scroll-reveal, frosted glass, forbidden patterns
- **Icons** `~/.agents/design/icons/libraries.md`
- **Type** `~/.agents/design/type/families.md`
- **Design systems** `~/.agents/design/systems/install.md` and `sources.md`
- **Design languages** `~/.agents/design/languages/registry.md` — read it before committing a visual world or generating a new design language, and register the world committed for this project there in the same work unit

The full universal rules are `~/.agents/DESIGN.md`. Where a library entry and a rule disagree, the rule wins.
<!-- agent-harness:universal-design:v1:end -->

# Cross-device architecture decisions

## Goals

- Reconstruct the shared harness and project fleet from reviewed GitHub authorities on another computer.
- Keep project source, portable configuration, runtime data, credentials, human knowledge, and review state in explicit authorities.
- Preserve exact recovery evidence until its replacement path is verified.

## Decisions

- `pyrgos-ai/doug-harness` and its root `ONBOARDING` folder own shared-harness installation and Windows reconstruction.
- `douglaspmcgowan/general-ai` owns current coordination, the phone-safe access index, fleet inventory, research, and machine pickup context.
- Each retained project uses one GitHub remote or an explicit consolidation, retirement, upstream, or fixture-exclusion mapping.
- Git carries source, portable contracts, safe fixtures, documentation, and value-free manifests.
- `data-manifest.yaml` declares excluded runtime data. `PROJECT_DATA_ROOT` is local runtime state; `PROJECT_DATA_SYNC_ROOT` resolves to `C:\Users\dougl\My Drive\Project Data` for declared DVC objects, verified SQLite snapshots, and other approved artifacts.
- SQLite snapshot retention defaults to 2 daily, 2 weekly, and 1 monthly bucket, always preserving the newest verified snapshot and no more than five distinct snapshots.
- Bitwarden Secrets Manager supplies runtime credentials through the exact-command broker. Credential values stay outside Git, Markdown, logs, and chat.
- The active personal Obsidian vault remains the human-authoring authority. The private Agent Brain mirror supplies curated cloud-agent context; agents write only reviewed branches under `proposals/` and `agent-notes/`.
- Docket is the authenticated phone review surface for briefs and decisions.
- Drive Capsule and Password Manager scaffolds have no active architecture role. Older files mentioning them are historical recovery evidence.
- The preserved OneDrive tree and registered legacy worktrees remain a separate retirement decision with no application or onboarding dependency.

## Current boundaries

- The inventory contains 27 roots: 14 guarded clones, 9 attention actions, 3 explicit skips, and 1 excluded fixture.
- Eight retained roots lack origins. `boundaries-reader` has an origin and still needs the discovery topic and portable baseline.
- Nineteen project data manifests remain placeholders; Docket has the sole operational cloud-data adapter.
- Harness `master` must still publish the current Obsidian bundle, exact mutable-runtime verifier repair, and blank-profile prerequisite-order repair before the real receiving-computer proof.
- Cloud-ready repository rollout remains plan-only under `pyrgos-ai/doug-harness` issue #16.

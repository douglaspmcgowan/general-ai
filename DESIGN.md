<!-- agent-harness:universal-design:v1:start -->
## Universal interface rules

The authority is `~/.agents/DESIGN.md`, and it is fuller than this. What follows is
carried here rather than only linked because a cloud or container session has no
`~/.agents` to reach — so the rules that actually change what gets built have to survive
in the repository itself.

### Anti-default discipline

Quoted verbatim from the authority rather than paraphrased, because this is the section an
agent most needs and a paraphrase is a second copy that drifts.

The model's house style is recognizable, and reaching for it reads as machine-made. Never
default to: purple-blue gradients, a centered hero over a dark mesh background, three equal
feature cards, ubiquitous glassmorphism, or Inter with slate everywhere. The
beige-brass-espresso "premium consumer" palette is the same tell; rotate off it.

- Lock one accent color page-wide, and one gray family per project.
- Lock one corner-radius system per page. Mix radii only under a rule you can state.
- Keep one theme per page. Sections do not invert light and dark mid-scroll except as a single deliberate composition device.
- A section layout family appears at most once per page. At most two consecutive image-text zigzag splits. At most one small uppercase eyebrow label per three sections.
- Where a brief reads as an established design system, use that system's official package rather than approximating it. One system per project.
- The brief wins. Honor a pinned aesthetic even when it is not the choice you would make; redirecting a clear brief toward your own taste is failure, not judgment.

### Everything else

- Never use IBM Plex Mono.
- Default to a sans display face. Use serif only with an articulated reason; `Fraunces` and `Instrument Serif` are banned as defaults specifically because they are the common machine-made choice.
- Hero discipline: the hero fits the first viewport, the headline runs at most two lines, subtext stays under roughly twenty words, and no more than four text elements sit inside it. Trust marks and logo walls go below the hero, never in it.
- A grid has exactly as many cells as there is content for. Reshape the grid rather than pasting in a blank tile.
- Every animation names what it communicates — hierarchy, sequence, feedback, or state change. An animation that names nothing gets cut.
- Reread every visible string before shipping. Never invent a precise-sounding number.
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

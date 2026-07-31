---
type: recon
status: proposed
created: 2026-07-30
topic: agent-accessible Obsidian second brain
---

# Agent-accessible Obsidian second brain recon

## Executive recommendation

Use two connected knowledge spaces:

1. Keep the currently open personal vault as the complete human corpus and continue syncing it to human devices with Obsidian Sync.
2. Create one small, allowlisted, private Git repository called **Agent Brain**. The repository is a valid Obsidian vault, so it can be opened directly in Obsidian. Codex and Claude cloud agents receive it through their normal GitHub checkout.
3. Use a trusted local bridge to export approved context into Agent Brain and import approved agent proposals. The bridge enforces exclusions, validates changes, snapshots affected files, and records receipts.
4. Make cloud writes through branches and pull requests. Use Docket as the consolidated human review surface when its broker is available.
5. Add official Obsidian Headless Sync only to a dedicated bridge working directory if phone-to-cloud freshness becomes important. It remains an open-beta component, so it should earn trust in a disposable test first.

This architecture keeps the personal vault useful on phone and desktop, gives cloud agents ordinary repository access, preserves a readable Git history, and creates a clear approval boundary.

## The problem

The system needs to provide seven related capabilities:

- **Capture:** accept rough notes, research, project closeouts, and agent outputs with little friction.
- **Organize:** apply a small shared schema, match existing entities, and make useful navigation views.
- **Retrieve:** support human browsing, search, links, Bases, and grounded agent retrieval.
- **Grow:** propose durable entities, links, maps, summaries, and resurfaced material when evidence supports them.
- **Heal:** detect broken links, invalid metadata, duplicates, stale derived notes, sync conflicts, and undocumented configuration drift.
- **Govern:** preserve authored prose, source every generated claim, show diffs, require review for risky changes, and make rollback routine.
- **Reach cloud agents:** expose a deliberately selected knowledge boundary to fresh Codex and Claude environments without depending on a desktop path or localhost service.

“Self-organizing,” “self-healing,” and “self-growing” should describe controlled maintenance loops. They should never imply an agent silently moving, merging, deleting, or rewriting large areas of the vault.

## What exists today

The only vault marked open in `%APPDATA%\obsidian\obsidian.json` is:

`C:\Users\dougl\Main\Yoga 7 Local John 1412`

The active vault already has strong core capabilities:

- Obsidian Sync
- Properties and Properties view
- Bases
- Templates and Daily Notes
- Backlinks and Outgoing Links
- graph, search, bookmarks, Canvas, and File Recovery
- automatic internal-link updates

The current `.obsidian` directory has no `community-plugins.json` and no `plugins` directory. The live community-plugin count is therefore zero. Older documents claiming that Smart Connections, MCP Tools, Local REST API, Dataview, and many other plugins are installed describe a previous or proposed state.

The vault already has a numbered, domain-oriented structure and a single `00_Inbox`. Earlier work reduced loose root files and documented a “one canonical document per topic” principle. Useful prior material includes:

- `Claude\Guides\Obsidian Second-Brain Features — Capability Guide.md`
- `Claude\Guides\Obsidian Plugin Guide — Interfaces, Databases & File Types.md`
- `Claude\Automation Audit June 2026\03 - Obsidian Vault Operations.md`
- `Claude\Vault Reorg\Vault Reorganization Plan.md`

Those files are migration inputs. Their runtime and plugin claims need revalidation.

Current agent access is filesystem-based. The localhost MCP described in older guidance is unavailable because the active vault lacks the plugins and `claude mcp list` reports no configured MCP server. Cloud agents cannot reach this filesystem or a desktop-only localhost service.

The harness already owns useful safety mechanisms:

- active-vault resolution;
- protected-path rules;
- a hook that blocks Obsidian deletion;
- allowlisted Obsidian configuration capture and restore;
- hashes, reparse-point checks, destination backup, rollback, and Gitleaks checks.

Those owners should be extended. A parallel vault-management system would create another source of drift.

## What practitioners and maintainers suggest

A 2025 study of industry researchers found that retrieval habits influence how people construct and maintain personal knowledge bases. The system should therefore optimize for Douglas’s actual retrieval paths: current projects, people and entities, time, source material, and recent agent work ([case study](https://arxiv.org/abs/2509.20187)).

Experienced Obsidian users repeatedly report that elaborate second-brain setups can become a maintenance job. The durable pattern is plain Markdown, a small property vocabulary, strong search, curated navigation, and bounded automation ([maintenance-fatigue discussion](https://www.reddit.com/r/ObsidianMD/comments/1eglzk7/where_are_the_second_brain_apps_that_dont_feel/), [simplification discussion](https://www.reddit.com/r/ObsidianMD/comments/1ouak91/the_more_i_use_obisdian_the_more_basic_i_go/)).

Useful frameworks solve different jobs:

| Framework | Best use here | Limitation |
|---|---|---|
| ACE: Atlas, Calendar, Efforts | High-level mental model joining knowledge, time, and action | Broad spaces still need local conventions |
| PARA | Lifecycle inside active efforts and projects | Areas and Resources can overlap |
| Johnny.Decimal | Stable operational and archive coordinates | Too much allocation overhead for every idea |
| Maps of Content | Curated orientation after a topic becomes crowded | Automatically generating one for every tag creates noise |
| Zettelkasten / atomic notes | Reusable claims, decisions, concepts, and insights | Forced atomicity can fragment project context |
| Periodic review | Human governance and resurfacing | A long checklist creates review debt |
| Entity notes | Canonical people, organizations, projects, sources, and decisions | Requires duplicate and alias controls |

Recommended use:

- preserve the current physical folders;
- add an ACE-style navigation overlay through Home, Maps, Bases, and links;
- use PARA language within active efforts where it helps;
- use stable IDs for operational records and canonical entities;
- promote captures into atomic notes only when they contain a reusable, sourced idea;
- create Maps of Content when real retrieval pressure appears.

Sources: [ACE](https://blog.linkingyourthinking.com/notes/a-deeper-dive-into-how-ace-works), [Johnny.Decimal](https://johnnydecimal.com/documentation/introduction), [Zettelkasten overview](https://zettelkasten.de/overview/), [weekly review example](https://caffa.github.io/posts/my-blogpost-automated-weekly-review-in-obsidian/).

## Architecture options

| Option | How it works | Advantages | Costs and risks | Fit |
|---|---|---|---|---|
| Current vault and local filesystem | Local agents edit Markdown in the open vault | Already works; full human context; phone Sync continues | Cloud agents have no access; broad local authority | Keep for local work |
| Current vault through localhost REST/MCP | A running desktop plugin exposes commands | Targeted patches and interactive use | Desktop dependency; plugin-level file/network authority; large remote exposure boundary | Local-only, optional |
| Current vault through Headless Sync in every cloud task | Each task logs into Obsidian Sync and downloads the vault | Direct current content | Broad content and account credentials reach ephemeral tasks; MFA and E2EE setup add friction; open beta | Reserve for controlled experiments |
| One Git-backed vault for every human and agent | Humans and agents share one repository | Simple Git history and PRs | Mobile Git friction, merge conflicts, attachments, broad exposure | Better for a small shared vault |
| Separate Agent Brain vault plus private Git | Curated Markdown repository is opened in Obsidian and cloned by cloud agents | Exact cloud boundary, PR review, rollback, clean onboarding | Needs an export/import bridge | Best initial architecture |
| Separate Agent Brain with Sync and a Git bridge | Human devices use Sync; a persistent bridge maintains a separate Git mirror | Phone access, selective cloud exposure, fresh context | Additional bridge process and two owned working directories | Best later architecture |
| Hosted knowledge service | A service such as Khoj indexes selected content and exposes an API | Rich semantic retrieval and scheduled agents | New server, database, authentication, index lifecycle, and authority | Consider after retrieval becomes a measured bottleneck |

### Why the separate Agent Brain wins

The main vault contains hard exclusions and human-authored areas. A cloud-facing projection makes the visibility boundary explicit. GitHub is already the normal source and review surface for Codex and Claude cloud agents. A small vault also avoids the mobile and performance problems reported for large Git-backed vaults.

The Agent Brain remains ordinary Markdown. It can be:

- cloned by a cloud agent;
- opened as an Obsidian vault on desktop;
- rendered on GitHub;
- linked from Docket;
- backed up and reviewed through Git history;
- migrated later without exporting from a proprietary database.

## Recommended plumbing

```text
Personal Obsidian vault
  └─ human authority; Obsidian Sync serves phone and desktop
       │
       │ reviewed export/import adapter
       ▼
Agent Brain private Git repository
  ├─ approved context
  ├─ schema, map, policies, and verifiers
  ├─ agent notes
  └─ proposals
       │
       ├─ Codex cloud branch / pull request
       └─ Claude cloud branch / pull request
              │
              ▼
       Docket or GitHub review
              │
              ▼
       trusted local apply + receipt
```

If fresher phone-to-cloud synchronization is later required:

```text
Phone/Desktop Obsidian
        │ Obsidian Sync
        ▼
Agent Brain remote vault
        │ official Headless Sync
        ▼
sync-working-copy/       one Headless writer
        │ validated bridge
        ▼
git-mirror/              Git and PR writers
```

Headless Sync and Git must own separate directories. The bridge performs one-shot pull, validate, export, import, and push transactions. Obsidian explicitly warns against running desktop Sync and Headless Sync against the same directory. Headless supports pull-only, bidirectional, and mirror-remote modes, exclusions, conflict strategies, and continuous operation ([official Headless Sync](https://obsidian.md/help/sync/headless)).

### Cloud task sequence

1. The cloud agent receives a fresh checkout of Agent Brain.
2. It reads `AGENTS.md`, `MAP.md`, `SCHEMA.md`, and the relevant context note.
3. It runs the tracked verifier.
4. It writes inside declared proposal or agent-note paths.
5. Each proposed assertion cites source notes or external sources.
6. The agent opens a branch or pull request with base hashes and verifier evidence.
7. A human reviews the consolidated change in GitHub or Docket.
8. The local bridge confirms that source hashes still match.
9. The bridge snapshots affected files, applies the approved patch, and reruns health checks.
10. It records a receipt containing paths, reasons, before/after health counts, and rollback location.

Cloud credentials remain repository-scoped. Routine agents need GitHub repository access only. The trusted bridge owns Obsidian Sync and personal-vault access.

## Agent Brain file architecture

Start small:

```text
AGENTS.md
MAP.md
SCHEMA.md
00 Inbox/
10 Projects/
20 Domains/
30 Sources/
40 Entities/
50 Maps/
80 Agent Notes/
85 Proposals/
90 System/
  Templates/
  Policies/
  Audit/
```

The physical folders answer “where does this live?” Links, properties, Bases, and Maps answer “how is this related?” Existing personal-vault folders stay in place during the first phase.

### Minimal property contract

```yaml
id:
type:
status:
created:
updated:
aliases: []
related: []
source: []
agent_state: human | suggested | reviewed
last_reviewed:
```

Add fields only when a real workflow consumes them. Useful initial types are:

- person
- organization
- project
- decision
- concept
- source
- meeting
- place
- artifact

Obsidian stores Properties as human- and machine-readable YAML. Bases produces database-like views directly over Markdown properties and stores views as text ([Properties](https://obsidian.md/help/properties), [Bases](https://obsidian.md/help/bases)).

## The operating loops

### Self-organizing

```text
capture
→ normalize deterministic syntax
→ search existing files and entities
→ classify provisionally
→ suggest links and canonical entity matches
→ human review
→ canonical note, map, active effort, or archive
```

The agent should search the existing vault before creating a file, property, entity, tag, folder, or workflow. Folder moves, renames, merges, and deletion remain reviewed operations.

### Self-healing

Run deterministic checks before model interpretation:

- invalid YAML;
- property-type conflicts;
- missing required fields;
- duplicate IDs;
- duplicate or near-duplicate titles;
- unresolved links;
- missing attachments;
- orphan notes;
- stale Inbox entries;
- conflicting aliases;
- generated notes missing provenance;
- stale summaries whose source hashes changed;
- sync conflict copies;
- excluded-path violations;
- plugin documentation drifting from live `.obsidian` state;
- unexpected high-volume changes.

Repair ladder:

1. Observe and publish a health report.
2. Suggest bounded fixes with evidence.
3. Preview the exact diff.
4. Snapshot affected files.
5. Apply approved changes.
6. Re-index and rerun checks.
7. Roll back if health invariants worsen.
8. Record a receipt.

Bulk folder operations remain human-gated because external moves can break links and Obsidian has no general transactional, link-safe bulk move API ([large-vault automation report](https://forum.obsidian.md/t/safe-programmatic-file-folder-operations-for-agents-automation-non-blocking-transactional-link-safe/114952)).

### Self-growing

Agents may propose:

- a canonical entity after repeated, grounded mentions;
- a link with a one-sentence rationale;
- a Map after a topic becomes difficult to navigate;
- a synthesis note that cites source notes;
- a weekly pattern report;
- a stale note related to a current effort;
- a contradiction or research gap;
- a project closeout or durable decision;
- an archive candidate.

Every generated artifact needs a purpose, type, source, intended consumer, review state, and freshness record. Generated summaries remain derivative and link back to their sources.

### Human review cadence

Daily:

- capture freely;
- normalize syntax automatically;
- review only urgent or blocking proposals.

Weekly:

- process the oldest Inbox items;
- accept or reject proposed entities and links;
- inspect active efforts;
- review health defects and conflicts;
- promote useful recurring ideas;
- archive completed material.

Monthly:

- review schema and plugin drift;
- test restore;
- inspect review burden and false-positive rate;
- remove automation that produces little accepted value.

## Plugin and framework strategy

Use core features first. The current vault already has Properties, Bases, Templates, Daily Notes, links, File Recovery, and Sync.

| Tool | Proposed role | Adoption rule |
|---|---|---|
| Core Properties | Canonical metadata | Use now |
| Core Bases | Indexes, review queues, entity and project views | Use now |
| Core Templates | Simple note creation | Use now |
| Obsidian CLI | Trusted local create/read/search/property/link checks | Use after confirming installed version and a disposable test |
| Obsidian Headless | Dedicated bridge synchronization | Pilot later; open beta |
| QuickAdd | Structured capture and bounded macros | Add after a concrete capture workflow is specified |
| Linter | Narrow deterministic Markdown/YAML rules | Add with a locked, tested profile |
| Tasks | Contextual task views inside notes | Optional; Docket and project `TASK.md` retain their existing authorities |
| Smart Connections | Local semantic suggestions | Optional; treat embeddings as disposable cache |
| Templater | Dynamic templates and scripts | Add only for a proven gap; templates can run JavaScript and system commands |
| Dataview | Advanced queries beyond Bases | Preserve proven uses; use Bases for new simple views |
| Local REST API/MCP | Local bridge operations | Keep local; avoid remote exposure |
| Vault Inspector / Vault Plus / Vault Crews | Ideas and disposable evaluation | Young projects; keep the health contract independent of them |
| Khoj | Later retrieval service | Evaluate only after retrieval metrics show a need |

Community plugins inherit broad filesystem and network authority. Obsidian reviews plugins and scans releases, while per-plugin sandboxing remains limited. Every installed plugin should have an owner, purpose, pinned or recorded version, platform support, privileges, removal criterion, and disposable-vault acceptance test ([Obsidian plugin security](https://obsidian.md/help/plugin-security)).

Primary plugin sources: [QuickAdd](https://github.com/chhoumann/quickadd), [Linter](https://github.com/platers/obsidian-linter), [Tasks](https://github.com/obsidian-tasks-group/obsidian-tasks), [Smart Connections](https://github.com/brianpetro/obsidian-smart-connections), [Templater](https://github.com/SilentVoid13/Templater), [Local REST API](https://github.com/coddingtonbear/obsidian-local-rest-api).

## Safeguards

| Risk | Required control |
|---|---|
| Hallucinated categories or entities | Candidate state, source binding, duplicate and alias search, human approval |
| Link noise | Rationale, confidence, per-note suggestion cap |
| Metadata entropy | Versioned schema, allowed values, migrations, verifier |
| Runaway note growth | Purpose, source, owner, type, review state, growth quota |
| Authored-prose damage | Human-authored zones are read-only to agents |
| Destructive reorganization | Exact path manifest, snapshot, diff, approval, rollback |
| Review fatigue | One consolidated review card and daily change limits |
| Plugin sprawl | Core-first policy and quarterly removal review |
| Concurrent edits | One writer per directory or branch |
| Cloud overexposure | Explicit export allowlist and hard exclusions |
| Stale derived notes | Source hashes, `generated_at`, `valid_as_of`, freshness dashboard |
| Quiet corruption | Health score before and after every mutation batch |

The existing protected paths remain excluded from all scanning, projection, and cloud access.

## Rollout

1. Reconcile the stale plugin and sync documentation with the live active vault.
2. Create a disposable Agent Brain fixture containing representative safe notes.
3. Define the minimal schema, map, allowed paths, and verifier.
4. Implement a read-only exporter with existing hard exclusions.
5. Add deterministic YAML, property, duplicate, link, provenance, and path checks.
6. Create the private Git repository and test clean Codex and Claude checkouts.
7. Allow cloud writes only inside proposals and agent-note paths through pull requests.
8. Connect approved proposals to Docket when its broker is available.
9. Build the local snapshot/apply/verify/receipt path.
10. Test the full phone → vault → export → cloud PR → approval → import → phone loop.
11. Run restore and adversarial exclusion drills.
12. Observe several weeks of accuracy, conflict rate, accepted suggestions, rollback rate, and review time before granting bounded autonomy.

## Reversible decisions

- Agent Brain can begin as a private Git repository with no Sync connection.
- A separate Obsidian Sync remote vault can be added later.
- The bridge can run on the desktop first and move to a persistent host later.
- Semantic search can remain local or move to a hosted index later.
- Folder taxonomy can remain unchanged while navigation evolves through Maps and Bases.
- Plugins can be added one workflow at a time.
- Automatic application can remain limited to formatting and derived dashboards until measured results support more authority.

## Sources

### Primary and official

- [Obsidian Properties](https://obsidian.md/help/properties)
- [Obsidian Bases](https://obsidian.md/help/bases)
- [Obsidian CLI](https://obsidian.md/help/cli)
- [Obsidian Headless](https://obsidian.md/help/headless)
- [Obsidian Headless Sync](https://obsidian.md/help/sync/headless)
- [Obsidian Sync history](https://help.obsidian.md/Obsidian%2BSync/Version%2Bhistory)
- [Obsidian Sync security](https://help.obsidian.md/Obsidian%20Sync/Security%20and%20privacy)
- [Obsidian plugin security](https://obsidian.md/help/plugin-security)

### Practitioner and research

- [Industry-researcher Obsidian case study](https://arxiv.org/abs/2509.20187)
- [Kenneth Reitz: Obsidian Vaults and Claude Code](https://kennethreitz.org/essays/2026-03-06-obsidian_vaults_and_claude_code.pdf)
- [Automated weekly review](https://caffa.github.io/posts/my-blogpost-automated-weekly-review-in-obsidian/)
- [AI proposal boundary discussion](https://www.reddit.com/r/ObsidianMD/comments/1sw616g/how_can_i_treat_obsidian_as_a_second_brain/)
- [AI orientation protocol](https://forum.obsidian.md/t/design-your-vault-for-ai-orientation-not-just-human-navigation/112010)
- [Large-vault automation limitations](https://forum.obsidian.md/t/safe-programmatic-file-folder-operations-for-agents-automation-non-blocking-transactional-link-safe/114952)
- [Obsidian Git mobile limitations](https://community.obsidian.md/plugins/obsidian-git)

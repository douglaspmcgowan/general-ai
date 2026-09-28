# App repair program — specification

Authored under the `spec` skill (`~/.agents/skills/spec/SKILL.md`): three layers — Product, Functional,
Acceptance — with observable criteria and no implementation prescription beyond the constraints Douglas
already fixed. `impeccable` was read and **not** followed as the governing skill: it owns interface work,
not authoring a specification, and this document changes no interface. The `impeccable` and `craft`
quality floors are cited where a criterion needs them.

Measurement snapshot: **2026-09-27T03:07Z**, host `C:\Users\dougl\Projects`. Every number below was taken
by the commands in [Appendix A](#appendix-a--how-every-number-was-taken) and is re-derivable. Where the
originating brief's figure and this measurement disagree, both are shown and the difference is explained.
The tree drifts under other lanes: `design-lab` did not exist when this scan began and appeared with
Next 16.3.6 mid-scan.

**Read the [Addendum](#addendum--the-wider-audit) with this document.** It carries twelve further audit
items, a fifth verdict, a revised ranking that supersedes the one in Layer 2, a changed first recipe step,
and an explicit list of what is unmeasured and what measuring it would cost.

---

## Layer 1 — Product

### Purpose

Bring every application Douglas owns to one named, current stack and one named quality floor, in a
ranked order that spends the cheapest hours first, and record a verdict for every app — including the
ones that get no work.

Douglas, 2026-09-26: *"We need to build a plan to fix all the apps and go across and fix them. Obviously,
we're migrating to TypeScript. That's part of the plan. Come up with other parts of what you think should
be in this plan to fix all of my apps, not some of them. If one of them is bringing them all to the
current Next, the best Next version, that's good, Let's make that spec impeccable."*

**"Not some of them" is the load-bearing phrase.** Every app unit carries a row and a verdict in
[the roster](#the-roster). A row missing from the roster is a defect in this specification.

### Users

| User | What they need from these apps |
|---|---|
| Douglas | Tools that open, work, look like they were designed, and behave the same tomorrow as today |
| A second person he sends a link to | An address that is not `localhost`, over HTTPS, whose state survives their visit |
| An agent sent to repair one app | A recipe with a stated proving command, so 40-odd runs produce comparable results |

### Outcomes

1. One language (TypeScript), one framework (Next.js at one major), one primitive layer (Base UI).
2. A quality floor every app meets, measured, not asserted.
3. Every app either at the floor, deliberately exempt, or gone.

### Non-goals

- **Making the apps beautiful.** This program raises a floor. Design direction is `impeccable`'s job and
  is out of scope here except where the floor names a measurable property.
- **Changing what any app does.** No feature is added or removed by this program.
- **Touching `C:\Users\dougl\Projects\agent-harness`.** Three other lanes hold worktrees there. Findings
  against it are filed through `Add-ProjectIntake.ps1`, never edited here.
- **Re-opening the settled decisions** in [Settled decisions](#settled-decisions).

### Constraints

- Every PowerShell invocation is `& 'C:\Program Files\PowerShell\7\pwsh.exe' -NoProfile -NonInteractive -File <script.ps1> [args]`.
  `-Command` is blocked by a security hook.
- One writable app gets one branch, one worktree, one owner (`WORKTREE-PROTOCOL.md`).
- No app is migrated before it has a git history to roll back to. Three apps currently have none.
- `~/.agents/DESIGN.md` wins wherever it disagrees with anything here.

### Settled decisions

Encoded, not re-opened. Each is Douglas's, dated 2026-09-26.

- [x] **TypeScript everywhere.** *"let's just go to TypeScript. Unless you see there's a huge benefit to
      not doing that, just do that."* Node has executed `.ts` directly since 22.18, so a server-side file
      converts by being renamed. JSDoc-plus-`checkJs` is not a path. The invited exceptions are named in
      [Where TypeScript is a bad trade](#where-typescript-is-a-bad-trade).
- [x] **Next.js is the default for every app, including one only Douglas opens.** Carrying Vite as a
      second thing to know is not worth it; Vite drops to know-about.
- [x] **Base UI, not Radix,** for headless primitives. Zero `@radix-ui/*` packages exist anywhere in the
      tree today, so there is nothing to migrate away from — only a slot to fill.
- [x] **Cut:** Express, Prisma, MUI and any library whose components live in `node_modules` where an agent
      cannot edit them, Redux Toolkit, MobX, XState, Valtio, Jotai, Solid, Preact, Lit, Angular,
      styled-components, Emotion, Electron as a default.
- [x] **Astro: know about, do not adopt.**
- [x] **A dependency pinned to `latest` is a live defect on its own,** because the app's behaviour changes
      with no commit.

---

## Layer 2 — Functional

### What an "app unit" is

> One distinct git repository — or one unversioned project folder — directly under
> `C:\Users\dougl\Projects\` that ships at least one human-facing interface as its own product surface: a
> page a person opens, a web server it starts, or a desktop window. Counted **once per repository**, with
> a named sub-surface noted in the row when one repository ships more than one independently-served
> interface. A git worktree of another repository is not an app unit. A second checkout of a remote
> already checked out elsewhere is not an app unit.

**This definition is why the count in this document is not 36.** See
[Reconciling the count](#reconciling-the-count).

### The target stack

Nine slots are fixed by the settled decisions. The remaining slots are inherited from
`~/.agents/design/STACK-TEMPLATES.md` except where that file conflicts — see
[Conflicts](#conflicts-between-this-specification-and-a-harness-contract).

| Slot | Occupant | Fixed by |
|---|---|---|
| language | TypeScript, one major across every app | Douglas, 2026-09-26 |
| framework / build | Next.js, App Router, one major | Douglas, 2026-09-26 |
| UI library | React, one major | follows Next |
| headless primitives | Base UI | Douglas, 2026-09-26 |
| component source | components copied into the repository, never imported from `node_modules` | Douglas, 2026-09-26 |
| styling method | Tailwind v4 (no config file) **plus** CSS custom properties on `:root` | measured: 4 of 5 Tailwind apps are already v4-without-config, which is correct for v4 |
| accessibility | `@axe-core/playwright` inside the existing Playwright run | `~/.agents/DESIGN.md` § Accessibility |
| testing | Playwright, one smoke path per app minimum | measured: 8 apps already carry a `playwright.config` |
| backend for a Python-cored app | FastAPI sidecar, unchanged | the core library exists only in Python |

**The reference implementation is `berkeley-house`:** Next `^16.2.12`, React `^19.2.8`, TypeScript `^5`,
Tailwind `^4`, `@base-ui-components/*`, shadcn on Base UI, 175 TypeScript files, 7 JavaScript files, one
7 KB stylesheet carrying 60 custom properties and 6 literal hex values. It is the only app already at the
target. `design-lab`, created 2026-09-26, carries newer versions (Next 16.3.6, React 19.3.0,
TypeScript 7.0.2, Tailwind 4.3.3) but no application, so it is a scaffold, not a reference.

### The quality floor (the baseline)

Eight properties. Each is a grep, not a judgement.

| # | Property | Proof |
|---|---|---|
| B1 | Every colour, font size, space and radius is a custom property declared on `:root` | no literal hex, `px` font-size or `rem` radius outside a `:root` block, across the app's `.css` files **and** its HTML `<style>` blocks |
| B2 | Every interactive element has a visible `:focus-visible` style | `:focus-visible` count ≥ 1 and an axe keyboard assertion passes |
| B3 | Motion exists on state change and respects the user | ≥ 1 `transition` rule **and** a `@media (prefers-reduced-motion: reduce)` block |
| B4 | Dark mode is implemented | a `prefers-color-scheme: dark` block that redefines the `:root` tokens |
| B5 | Zero `!important` | grep count is 0 |
| B6 | Zero floating version specifiers | no `"latest"`, no bare `"*"` in any manifest |
| B7 | A Playwright smoke test opens the primary surface and an axe assertion runs against it | the suite exits 0 and the axe assertion is present in the source |
| B8 | The app declares its template number, its selecting question, and every deviation with a reason | `DESIGN.md` or `MAP.md` contains them, per `STACK-TEMPLATES.md` § Decision procedure step 8 |

### The verdict vocabulary

**Superseded by [the Addendum](#a-new-verdict-archive-distinct-from-retire), which adds a fifth verdict, ARCHIVE.**
Read that section before using this table: two roster rows marked RETIRE below are reassigned to ARCHIVE there.

Every row carries one verdict, plus its reason.

| Verdict | Meaning | Work |
|---|---|---|
| **CONVERGE** | Bring to the target stack and the floor | full [per-app recipe](#the-per-app-recipe) |
| **BASELINE** | Keep the current stack; apply the floor only | recipe steps 1–4 and 8–10 |
| **HOLD** | Leave it alone | none, and the reason says why |
| **RETIRE** | Archive it | archive, then remove the row from every downstream denominator |

---

## The roster

**47 app units, across 55 roster rows.** The arithmetic, so it is checkable rather than asserted:

```
55  roster rows                                   grep -c '^| \[.\]' APP-REPAIR-SPEC.md
-4  sub-surface rows of an app already counted     base-flight-finder (3 rows -> 1), kelly-uniforms-business (3 -> 1)
= 51 distinct named entries                        grep '^| \[.\]' … | sed 's/^| \[.\] `//; s/`.*//' | sort -u | wc -l
-1  a cleanup row, not an app                      study-system/.tmp-brute-* (15 abandoned lane folders)
-2  second checkouts of a remote, not apps         obsidian-vault-mirror-metropolis-runtime, second-brain-capsule-runtime
-1  a scaffold that ships no interface             design-lab
= 47 app units
```

Of those 47: **38 get work** (CONVERGE or BASELINE), **7 are HOLD**, **2 are retired as apps**
(`anna-maria-mcgowan`, `compsci-260b`). The remaining three RETIRE rows remove checkouts and folders, not
apps. See [Reconciling the count](#reconciling-the-count) for why this is not 36.

Columns: **Who** — `local` = reachable only at `localhost` on his machine; `file` = opens from disk with
no server; `hosted` = a tracked `vercel.json` or a README-stated live URL; `desktop` = an installed
window. **Style** = combined `.css` + HTML `<style>` measurement: unique hex values / distinct font sizes
/ custom properties / `!important` count / `:focus-visible` count / dark-mode blocks.

> **The `distinct font sizes` figure in every Style tuple below is superseded.** It was taken from
> stylesheets and HTML only, which misses Tailwind arbitrary utilities in JSX — three quarters of the
> total in `bible-name-search`, and all of it in the two apps whose UI is a template literal inside
> `server.js`. 23 of 54 rows move. The tuples are left as published so the change stays visible; the
> corrected figures, the counting rules and the retraction table are in
> [Appendix A](#correction-2026-09-27--distinct-font-sizes-could-not-see-three-quarters-of-a-tailwind-app).
> The `:focus-visible` and dark-mode figures had the inverse defect and are **now corrected** — see
> [the accessibility correction](#correction-2026-09-27--the-floor-reported-accessibility-failures-that-do-not-exist).
> Four apps published at zero focus styling in fact carry 33, 87, 11 and 4.

### CONVERGE — 22 units

| App | What it is for | Current stack | Who | Style | Reason for the verdict |
|---|---|---|---|---|---|
| [ ] `legal-solutions-website` | Law-firm marketing site | Next `^14.2.35`, React `^18.3.1`, TS `^6.0.3`, Tailwind `^3.4.19` | local | 40/20/25/0/0/0 | Two Next majors, one React major and one Tailwind major behind — the largest single drift in the tree, and the only app whose Tailwind still needs a config file |
| [ ] `bible-name-search` (Orant) | Every prayer in the Bible, searched and mapped | Next `^15.5.4`, React `^19.1.0`, TS `^5.9.2`, Tailwind `^4.1.14` | hosted | 46/12/73/3/1/0 | One Next major behind; 105 TS files against 100 JS files means the conversion is half-done and the half-state is the expensive part |
| [ ] `base-flight-finder` (`apps/web`) | Flight search | Next `^16.2.10`, React `^19.2.7`, TS `^6.0.3`, **no Tailwind**, 71 stylesheets | hosted | 128/33/38/3/17/1 | Already TS-first (397 files) and near the target major; the work is the token layer and the styling slot, not the framework |
| [ ] `base-flight-finder` (`apps/desktop`) | Desktop shell for the same product | Tauri | desktop | — | The only Tauri app; it inherits the web app's token layer and must not fork it |
| [ ] `base-flight-finder` (`packages/cli`) | CLI for the same product | TS `^6.0.3` | n/a | — | TypeScript major must match the web app's, or the shared types diverge |
| [ ] `client-portal` | Private multi-customer portal for the consulting business | Next `16.2.9`, React `19.2.4`, TS `^5`, Tailwind `^4` | local | 19/13/24/4/2/0 | Real customers will reach it; a portal with no dark mode and 4 `!important` is a floor failure, not a taste question |
| [ ] `fellowship-tracker` | Fellowship deadlines and applications | Next `^16.3.0`, React `19.2.4`, TS `^5`, Tailwind `^4` | local | 24/15/42/5/3/1 | Ahead of the reference on Next and behind it on everything else; cheapest full convergence in the tree |
| [ ] `jars-of-clay` | Marketing site for the AI consulting business | Next `16.2.9`, React `19.2.4`, TS `^5`, **no Tailwind** | local | 9/23/25/6/1/0 | A site he sends to prospects that only he can open; needs the styling slot filled and hosting decided |
| [ ] `kelly-uniforms-business` (`storefront`) | Customer-facing storefront | Vite `^8.2.1`, React `^18.3.1`, TS `^7.0.2` | hosted | 72/55/24/9/7/1 | React 18 and TypeScript 7 in the same app is a two-major spread in opposite directions; Vite drops to know-about |
| [ ] `kelly-uniforms-business` (`brand-gallery`) | Brand reference surface | Vite | hosted | — | Same repository, same convergence, one branch |
| [ ] `kelly-uniforms-business` (`preview`) | Pre-publish preview | Vite | local | — | Same repository; decide whether it survives convergence or folds into the storefront |
| [ ] `text-to-spaceship` | Spacecraft concept generator | Vite `^8.2.2`, React `^19.2.8`, TS `~6.0.2`, FastAPI (59 files), PySide6 (18 files) | local | 315/76/134/7/4/0 | **Unversioned — no git at all.** 3.6 MB of styling across 23 files. Version control before any other step |
| [ ] `study-system` (`berkeley-prelim-study`) | Berkeley prelim study tool | Vite `^8.2.1`, React `^19.2.0`, TS `~5.9.0` | hosted | 33/142/24/2/2/0 | **Unversioned**, and 15 `.tmp-brute-*` lane folders sit beside it on disk. 142 distinct font sizes in one app |
| [ ] `168-audit` | Multi-user category-allocation audit, Supabase-backed | Express `^4.21.2`, 8 JS files, **entire UI inside `server.js`** | hosted | — | Express is on the cut list and the UI is a template literal in the server file — the one shape that cannot be reviewed, tested, or styled |
| [ ] `conference-tracker` | 130 conference and journal deadlines | Express `^4.21.2`, 4 JS files, **entire UI inside `server.js`** | hosted | — | Same shape as `168-audit`; same fix; the two should converge to the same Next skeleton |
| [ ] `docket` | Phone-accessible review, brief and decision queue (local mirror) | vanilla JS (62 files), Playwright (30 specs) | local | 6/22/22/1/8/4 | The routing front door for every brief Douglas reads; the best-tested vanilla app in the tree, so its Playwright suite survives the migration and proves it |
| [ ] `vault-review-mobile` | The same review board, hosted | vanilla JS (54 files), Playwright (23 specs) | hosted | 6/25/22/1/12/4 | **Same app as `docket`, twice.** Converge them into one codebase with two deployment targets, or the divergence keeps costing two migrations |
| [ ] `arch-gp-app` | Purchase-order and drawing inspection workflow | vanilla JS (47 files), 3 HTML | local | 63/18/42/17/**275 inline `style=`**/0 | 275 inline style attributes is the token layer's exact opposite; the conversion is where they get removed |
| [ ] `build-log` | Maps the story of what Douglas builds | vanilla JS (42 files), `python -m http.server` | local | 0/40/31/4/3/0 | Zero literal hex already (good) but 40 distinct font sizes and 79 inline `style=`; a dashboard he reads daily |
| [ ] `mission-control` | Local port and app operations | vanilla JS (12 files), `python -m http.server` | local | 28/6/53/1/2/1 | Already token-heavy (53 properties); the framework and language move is the remaining gap |
| [ ] `workscope-graph` | Live thread register and architecture graph | vanilla JS (46 files), Playwright (14 specs) | local | 63/7/111/3/3/3 | 111 custom properties and 3 dark-mode blocks — nearly at the floor already; converge to keep it there |
| [ ] `schema-studio` | Document-genre extraction studio | Python (117 files), 36 JS, `http.server` (33 references); its Vite+React 18 `app/` exists **only on branches** | local | 42/24/48/3/1/0 | The app directory is not on `master` at all, so `master` cannot be built or reviewed — the worst reproducibility defect in the tree |

### BASELINE — 11 units

| App | What it is for | Current stack | Who | Style | Reason for the verdict |
|---|---|---|---|---|---|
| [ ] `anna-maria-mcgowan-site` | Fractional-executive site and portfolio | vanilla JS (11 files), 54 HTML, Playwright + axe | hosted | 104/101/65/15/23/0 | **The one app that was opened and judged genuinely well designed.** Converging it risks the only good result in the tree for no user-visible gain; 101 distinct font sizes and no dark mode are real and fixable in place |
| [ ] `cad-forge` | Connections-first CAD pipeline for smallsat structure | Python (340 files), vanilla JS (76), FastAPI, `http.server` | local | 113/52/64/5/19/1 | The compute core is Python and irreplaceable; 19 `:focus-visible` and 13 radii already make it the second-best-styled app. Floor the browser layer, leave the pipeline |
| [ ] `truss-forge` | Truss design dashboard, static-exported to Vercel | Python (231 files), vanilla JS (64), 50 generated HTML pages | hosted | 486/146/347/40/24/15 | The 50 HTML pages are **generated** by `export_static.py`; the repair target is the generator's templates, not the output. Converging a static export to Next buys nothing |
| [ ] `slides-workbench` | Artifact and build home for decks, posters, flyers | Python (107 files), vanilla JS (28), `http.server` | local | 55/25/52/8/16/2 | Its 7 stylesheets are deck **themes**, not app chrome; 8 `!important` in a theme file is a defect but a framework move is not |
| [ ] `marginalia` | Paper margin-note and frame extraction | Python, vanilla JS (8 files), 2 HTML | local | 43/20/33/1/1/1 | Small, working, Python-cored; floor it and stop |
| [ ] `berkeley-meng` | Advising several MEng capstone teams at once | 16 HTML each with its own `<style>`, FastAPI (12 files) | local | 46/22/28/6/2/2 | 2.3 MB across 16 pages, each carrying its own private styling — the token layer is the whole repair here |
| [ ] `berkeley-research` | Research explainers | 10 HTML, `http.server` (10 references) | hosted | 119/54/23/3/4/0 | 119 colours against 23 variables and zero dark mode; explainers do not need a framework |
| [ ] `operating-dashboard` | Live session and task tracker | 2 HTML, 2 JS | local | 89/20/49/1/1/4 | 89 colours in two files; already has 4 dark-mode blocks, so the floor is within reach in one sitting |
| [x] `idetc-writing-ide` | Single-file writing IDE, two versions side by side | 2 HTML app surface, plus 3 byte-identical vendored ASME stylesheets that never reach it | local | app surface **36**/16/28/**1**/**0**/**0** → 120 custom properties, 6 `:focus-visible`, 5 `prefers-color-scheme`, 0 `!important` after repair | **CORRECTED 2026-09-27, measured in the repository.** The row used to read "74 `!important` and zero `:focus-visible` — the worst floor score in the tree relative to its size". The `:focus-visible` half was right. The `!important` half is repository-wide and 36× the app's real count: the app has exactly one, at `_work/template.html:221`, and 72 of the 74 are three byte-identical vendored copies of the ASME conference stylesheet under `_work/v*/` (24 each), LaTeX paper build material. The 3 `prefers-color-scheme` hits are vendored the same way, so the app had zero. Workstream 9 here was 0.25 h, not 4–8 h. Stage 2 landed the floor without moving a pixel — 83 new tokens, focus ring, reduced-motion, dark-mode block, 9 Playwright tests with axe, and a computed-style fingerprint that proves it. A single-file IDE should stay single-file, and it did |
| [ ] `redline-idetc` | Paper redline across two versions | 2 HTML | local | 36/16/29/8/2/0 | Sibling of `idetc-writing-ide`; same shape, same floor, same sitting |
| [x] `shopping-search` | Shopping report generator | Versioned 2026-09-27; **1 generated HTML surface**, 3 Python generator scripts | local | **55**/27/0/**0**/0/0 → 0 literals outside `:root` after repair | **CORRECTED 2026-09-27, measured in the repository.** The row used to read "1113 colours, 385 `!important`, 3.4 MB, 264 style surfaces, 123 HTML reports". Every one of those numbers came from `tmp\edge-shopping-report-profile\`, a disposable headless-Edge user-data directory full of bundled browser-extension HTML that `.gitignore` excludes via `tmp/`. 122 of the 123 HTML files lived there. The app is a small, clean, single-page print generator, not the tree's largest styling outlier. Stage 2 landed the floor on it: 99-property token layer, focus ring, reduced-motion, dark mode, accessibility verifier |

### HOLD — 8 units

| App | Who | Reason for the verdict |
|---|---|---|
| [ ] `berkeley-house` | local | **Already at the target.** It is the reference implementation; changing it changes the standard |
| [ ] `design-worlds` | hosted | 98 self-contained HTML pages, each a **complete and deliberately different design language**. 776 unique colours and 216 font sizes are the product, not the defect. A token layer imposed across them destroys what the library is for |
| [ ] `project-hady` | desktop | PySide6 desktop app, 32 Python files, zero JavaScript. There is no web layer to converge and no TypeScript to convert to — see [Where TypeScript is a bad trade](#where-typescript-is-a-bad-trade) |
| [ ] `boundaries-reader` | hosted | One HTML file, one stylesheet, 22 KB, 12 transitions, 7 keyframes. A quiet single-page reader that already works. Its only floor failure is `:focus-visible` = 0 — file that as a one-line fix, not a migration |
| [ ] `contact-form-caller` | hosted | A minimal demo, 1 HTML, 2 JS, 4 KB of styling, zero `!important`. It exists to show one thing once |
| [ ] `saved-posts` | local | 1 HTML, 1 JS, 13 KB, zero `!important`, 36 custom properties. Nothing to repair |
| [ ] `drive-organizer` | local | 1 HTML, 2 JS, 26 KB. A personal one-off tool that works |
| [ ] `design-lab` | — | Created 2026-09-26 by another lane, carrying the newest stack on the machine and **no application**. Holding until that lane lands; not this program's row to move |

### RETIRE — 5 units

| App | Who | Reason for the verdict |
|---|---|---|
| [ ] `anna-maria-mcgowan` | file | Superseded by `anna-maria-mcgowan-site`: 1 HTML and 1 JS against 54 HTML with a Playwright + axe suite. Two repositories for one person's site is one too many. Archive, do not delete |
| [ ] `obsidian-vault-mirror-metropolis-runtime` | local | **A second checkout of `github.com/douglaspmcgowan/obsidian-vault-mirror-metropolis`.** `WORKTREE-PROTOCOL.md` allows one stable checkout per remote. Preserve anything unlanded to an `agent/*` branch, then remove |
| [ ] `second-brain-capsule-runtime` | local | **A second checkout of `github.com/douglaspmcgowan/second-brain-capsule`.** Same rule, same procedure |
| [ ] `study-system/.tmp-brute-*` (15 folders) | — | 15 abandoned lane copies on disk beside an unversioned app, each with its own `package.json`. They are why a manifest count over-reports the app count |
| [ ] `compsci-260b` | file | 3 HTML files holding **4.1 MB** and **208 `!important`** — the densest defect concentration in the tree — for a course that is over. Archive the artifacts; do not spend a repair hour on coursework |

### Not app units — accounted for, with the evidence, and deliberately given no row

`agent-squads` (0 files of any UI kind), `arch-global-precision` (notes only), `computer-operations`
(0 HTML, 0 CSS), `cursor-stuff` (4 Python probe scripts), `digital-secretary` (0 HTML, 0 CSS — a morning
fetch service), `flight-tracker` (a FastAPI sidecar, 0 HTML), `general-ai` (this coordination repository),
`grandpa-help` (0 HTML, 0 CSS), `mastermind-nexus` (0 UI), `motion-to-dismiss` (0 UI),
`obsidian-vault-mirror` (5 HTML that are **mirrored vault pages**, not an app), `pyrgos-worker` (empty),
`taskstate` (empty), `agent-harness` (out of scope by instruction; its `arch-gp-demo` defect is filed as
intake, not fixed here).

Also excluded, with the evidence: the 12 `schema-*-20260926` folders and `info-272-condense` (git
worktrees), `agent-harness-wt-multiacct` (worktree), and `_archive-lsw-site-polish-20260812`,
`berkeley-research-planning-archive-20260920`, `agent-squads-worktrees`, `cad-forge-out`,
`slides-workbench.bundle`, `Outputs`, `New folder`, `scratch` (archives and scratch folders, no `.git`, no
product surface).

### Overflow roster — nine more app units

| App | What it is for | Current stack | Who | Style | Verdict and reason |
|---|---|---|---|---|---|
| [ ] `obsidian-vault-mirror-metropolis` | Styled mirror of the Obsidian vault | 128 JS, 43 HTML, 93 stylesheets, FastAPI (13), PySide6 (3) | hosted | **1272**/150/140/54/5/15 | **BASELINE, and the last outlier to touch.** 1272 unique colours, 90 `@keyframes`, 4.0 MB. The brief ranks it first; I rank it last: it has exactly one user, and 4 MB of styling is the most expensive hour in the plan for the fewest people served. Triage means *deleting* stylesheets, not tokenising them |
| [ ] `hci-260` | Course tool for HCI 260 | vanilla JS (25 files), Playwright (3 specs) | local | 34/24/**9**/2/1/0 | **BASELINE.** 9 custom properties against 34 colours and 24 font sizes — the weakest token coverage of any working app |
| [ ] `info-272` | Research app for INFO 272 | vanilla JS (24 files), Playwright (8 specs) | local | 39/7/43/2/1/1 | **BASELINE.** The `info-272-condense` folder is **a git worktree of this repository**, not a separate app — see [Reconciling the count](#reconciling-the-count). The bland-pattern exemplar the brief names is this app's `condense` branch |
| [ ] `sarah-stuff` | A built surface for Sarah | vanilla JS (7 files), 2 HTML | local | 25/31/**17**/1/3/0 | **BASELINE.** 31 font sizes against 17 properties; someone other than Douglas uses it, so the floor matters more here than the framework |
| [ ] `legal-doc-studio` | Legal-document viewer, editor and citation map | vanilla JS (4 files), 1 HTML | local | 35/18/41/10/2/0 | **BASELINE.** A demo he shows to clients: 10 `!important` and no dark mode, but nothing a framework fixes |
| [ ] `landry-sandbox` | 3D assembly cost, mass and money workbench | vanilla JS (30 files), 3 HTML | hosted | 43/20/66/8/8/0 | **CONVERGE.** 66 custom properties already; a hosted 3D tool with a real second user is where the component layer earns its cost |
| [ ] `daily-brief` | Daily brief surface | 1 JS, 2 HTML, `vercel.json` | hosted | 22/23/**8**/4/**0**/0 | **BASELINE.** 8 custom properties, zero `:focus-visible`, zero dark mode, and it is hosted — the worst floor score among the hosted apps |
| [ ] `second-brain-capsule` | Private second-brain capsule a stranger can stand up | vanilla JS (41 files), 1 HTML | file | 12/10/12/1/1/0 | **CONVERGE.** Its whole product claim is that *another person* can run it; that claim cannot survive a hand-written server |
| [ ] `skill-pathways` | Local editor for named skill pathways | vanilla JS (2 files), 1 HTML, Playwright | local | 0/17/24/1/1/0 | **BASELINE.** Zero literal hex already; 17 font sizes and 18 inline `style=` are the gap |

---

## Reconciling the count

**This specification counts 47 app units. The brief counts 36 apps.** Both numbers are right about
different things, and the difference is not rounding.

The brief's 36 is **manifest-derived**: 36 of 46 `package.json` files carry an app. That count moves in
two directions against the app-unit definition.

**It over-counts by 15, because these manifests belong to copies, not apps:**

- 12 `schema-*-20260926` folders are **git worktrees of `schema-studio`** (each `.git` file reads
  `gitdir: C:/Users/dougl/Projects/schema-studio/.git/worktrees/...`). Twelve manifests, one app.
- `info-272-condense` is a **git worktree of `info-272`**, carrying 2 manifests. Two manifests, zero apps.
  The brief uses `info-272-condense` as its bland-pattern exemplar; that is a branch of `info-272`.
- `obsidian-vault-mirror-metropolis-runtime` and `second-brain-capsule-runtime` are **second checkouts of
  remotes already checked out**. Two more manifests, zero apps.
- `bible-name-search` carries 6 extra manifests inside `.next*` build directories, and `study-system`
  carries 15 inside `.tmp-brute-*` lane folders.

**It under-counts by 19, because these app units have no `package.json` at all:**
`design-worlds` (98 HTML), `truss-forge` (50 HTML + 231 Python), `berkeley-meng` (16 HTML),
`berkeley-research` (10 HTML), `project-hady` (PySide6), `slides-workbench`, `marginalia`,
`operating-dashboard`, `idetc-writing-ide`, `redline-idetc`, `boundaries-reader`, `sarah-stuff`,
`legal-doc-studio`, `drive-organizer`, `saved-posts`, `workscope-graph`, `compsci-260b`,
`anna-maria-mcgowan`, `obsidian-vault-mirror-metropolis`.

**Which is right:** 47, for planning. A manifest count answers "how many Node projects are there"; the
plan needs "how many interfaces need a verdict", and 19 of them have no manifest. The verification
command is in [Appendix A](#appendix-a--how-every-number-was-taken).

### Other figures in the brief that this measurement contradicts

| Brief | Measured | Why they differ |
|---|---|---|
| 6 Next apps | **7** — `base-flight-finder`, `berkeley-house`, `bible-name-search`, `client-portal`, `fellowship-tracker`, `jars-of-clay`, `legal-solutions-website`, plus the scaffold `design-lab` | `base-flight-finder`'s Next dependency is at `apps/web/package.json`, below a depth-2 scan |
| Three TS majors (5, 6, 7) | **four plus a float** — 5.6, 5.9, 6.0, 7.0, and `latest` | `schema-studio`'s branch app pins `^5.6.3`; `arch-gp-demo` pins `latest` |
| 18 apps have zero `transition` | **3** — `hci-260`, `info-272`, `contact-form-caller` | The brief measured `.css` files only. 20 app units keep all their styling in HTML `<style>` blocks, where the transitions are |
| 12 apps have zero CSS custom properties | **0** | Same cause. The weakest are `daily-brief` (8), `hci-260` (9) and `second-brain-capsule` (12) |
| 21 apps have no custom easing; 21 no `box-shadow`; 20 no `clamp()`; 35 no container queries | **unmeasured against the HTML-inclusive method** for easing; container queries absent from **52 of 54 roster rows** (was stated as 42 of 46 roots, a different denominator) | Only `design-worlds` (6) and `slides-workbench` (4) use `@container` under the Appendix A rule, measured 2026-09-28. **`text-to-spaceship` (2) is not recomputable:** the rule finds no tracked `.css` or `.html` in that root, and the only `@container` strings on disk there are in an untracked `cad-verification-env` site-packages stylesheet. **`shopping-search` (8) was wrong and is struck 2026-09-27:** `git grep @container` in that repository returns nothing; the eight hits were inside the gitignored `tmp\edge-shopping-report-profile\` browser profile |
| 28 apps have no dark mode | **33 of 54 roster rows**, measured 2026-09-28: 25 of the 46 rows with any styling plus all 8 without | Same HTML-inclusion cause, smaller effect. **The published "24 of the 46 roots" is not reproduced** by this rule over this roster. A 2026-09-27 run reads 34, not 33: `berkeley-research` gained a `prefers-color-scheme` block between the two runs |
| 23 apps use `!important` | **41 of 54 roster rows have at least one**, measured 2026-09-28 (the same 41 were once stated over 46 roots; the 8 unstyled rows have none) | Same cause; the total across the tree is dominated by `compsci-260b` (208) and `obsidian-vault-mirror-metropolis` (54). **`idetc-writing-ide` (74) is struck 2026-09-27:** its app surface had exactly one, and 72 of the 74 are three byte-identical vendored copies of the ASME conference stylesheet; that one is now gone. The checkout at `C:\Users\dougl\Projects\idetc-writing-ide` still reads 74 under the Appendix A rule on 2026-09-28, so that repair is not on the branch checked out there; the row has at least one either way, so the 41 does not move. **`shopping-search` (385) is struck 2026-09-27:** it has zero `!important`, measured over its one generated HTML surface and its three Python scripts; the 385 were a gitignored browser profile |
| Playwright in 29 apps | **13 declare `@playwright/test`; 8 carry a `playwright.config`** | The brief likely counted spec files or a global install. `@axe-core/playwright` in 5 is confirmed exactly |
| "Nine apps served by `python -m http.server`" | **at least 14** app units reference it | Adds `berkeley-research` (10 references), `skill-pathways` (7), `obsidian-vault-mirror-metropolis` (10), `boundaries-reader` (3), `kelly-uniforms-business` (4), `text-to-spaceship` (3) |
| The app pinned to React `latest` | **`agent-harness/arch-gp-demo`, with all 11 dependencies pinned to `latest`** | It is not one React pin; it is every dependency. And it lives inside the one repository this lane may not modify — see [Conflicts](#conflicts-between-this-specification-and-a-harness-contract) |
| Outliers: metropolis, `base-flight-finder`, `cad-forge`, `anna-maria-mcgowan-site` | **`compsci-260b` is a larger outlier than three of those four** and appears in neither list | `compsci-260b`: 4.1 MB and 208 `!important` in three files. **The `shopping-search` half of this row is withdrawn 2026-09-27:** its 1113 colours / 3.4 MB / 385 `!important` were measured over the gitignored `tmp\edge-shopping-report-profile\`. The real figure is 55 colours in one sheet and no `!important` |

**Can another person use the `http.server` apps today? No.** Measured: no tracked `vercel.json`, no
authentication code, no TLS configuration, and `python -m http.server` writes nothing, so nothing a
visitor does survives. That answer applies to `build-log`, `cad-forge`, `mission-control`,
`schema-studio`, `slides-workbench`, `marginalia`, `skill-pathways`, `boundaries-reader` and
`berkeley-research`'s local mode. It is a decision, not a defect — see [Open decisions](#open-decisions).

---

## Ranked workstreams

Ranked by value per hour, which is not the same as by size. The defence is one line each.

| # | Workstream | Apps affected | Defence of this rank |
|---|---|---|---|
| 1 | **Put every app under version control** | 3 (`text-to-spaceship`, `study-system`, `shopping-search`) | A migration with no commit to return to is a coin flip; this is the cheapest hour in the plan and it gates every other workstream on those three apps |
| 2 | **Retire and archive** | 5 units + 15 lane folders + 2 duplicate checkouts | Every retirement removes a row from all twelve downstream denominators, so an hour here is subtracted from every later workstream rather than added to one |
| 3 | **Kill every floating version specifier** | 1 (`arch-gp-demo`, 11 `latest` pins) | These are the only places in the tree where behaviour changes with no commit; a defect you cannot reproduce costs more than every bland stylesheet combined |
| 4 | **Close the two-major drift** | 1 (`legal-solutions-website`: Next 14→16, React 18→19, Tailwind 3→4) | One app carries the entire framework-risk of the program; doing it first makes the remaining six Next bumps one-liners |
| 5 | **The token layer (B1)** | 38 | Every later item — dark mode, motion, theming, de-`!important`ing, an outlier triage — becomes an edit to one `:root` block instead of 20 scattered ones. It is the only workstream that makes the others cheaper |
| 6 | **`:focus-visible` plus an axe assertion (B2, B7)** | 6 with zero focus styles; 24 Playwright suites with no accessibility assertion | A keyboard user cannot operate six of these apps at all, and the fix is one import into a suite that already runs — the highest ratio of defect closed to lines written anywhere in this plan |
| 7 | **Motion, with reduced-motion honoured (B3)** | 3 with none; 43 with no `prefers-reduced-motion` | The two apps that were opened and used differ on this axis and **not** on framework: the well-designed one has 41 transitions, the bland pattern has none. Cheapest visible change in the plan |
| 8 | **Dark mode (B4)** | 22 of the 38 | Nearly free once #5 lands, and these are tools he opens at night. Ranked below motion only because it is invisible in daylight |
| 9 | **Remove `!important` (B5)** | 36 of the 38 | Each one is a future edit that silently fails. Ranked here and not higher because it is a *symptom* of #5's absence and costs a third as much after it |
| 10 | **TypeScript conversion** | 24 app units still majority-JavaScript | Settled, and cheap — a Node server file converts by being renamed, since Node 22.18 runs `.ts` directly. Ranked below the floor items because it buys correctness he is not currently losing, and it buys nothing a person can see |
| 11 | **Next-major convergence** | 7 | Real, but a one-line bump for six of them once #4 is done, and it changes nothing a person sees |
| 12 | **The component layer (Base UI, copied in)** | 30 with none | `berkeley-house` proves the shape works, but it is the most expensive item per app and pays back only where there is real interaction. **Restrict to app units with three or more interactive surfaces**; on a one-page reader it is pure cost |
| 13 | **Framework convergence of the vanilla-JS apps to Next** | 18 | Settled by Douglas and the largest single cost in the plan. Ranked here on purpose: **this is the item the "36 well-built bland apps" finding warns about.** No app enters it until it has passed the floor, so the migration is never mistaken for the repair |
| 14 | **Shareability and hosting** | 14 local-only app units | The only workstream that adds a *user*, which makes it the highest-value item in the plan — and it is blocked on a decision only Douglas can make, so it cannot be ranked above work that can start now |
| 15 | **Outlier triage** | `shopping-search`, `compsci-260b`, `obsidian-vault-mirror-metropolis`, `truss-forge`, `base-flight-finder`, `anna-maria-mcgowan-site` | Parallelises perfectly and blocks nothing. **I rank metropolis last within this workstream, against the brief's ranking of it first:** it has one user and 4.0 MB of styling, which is the worst people-served-per-hour in the program. `shopping-search` comes first, and its fix is three Python templates, not 264 files |

### Ordering and dependencies

```
1 version control ──┐
2 retire ───────────┤
3 kill float pins ──┼──▶ 5 token layer ──┬──▶ 8 dark mode
4 close drift ──────┘                    ├──▶ 9 remove !important
                                         └──▶ 15 outlier triage
6 focus + axe ──── independent ──────────────▶ (may start immediately)
7 motion ───────── needs 5 for the easing tokens
10 TypeScript ──── independent of 5, required before 11 and 13
11 Next majors ─── needs 4, needs 10 for the converted apps
12 components ──── needs 10, 11 and 13 for that app
13 vanilla ▶ Next ─ needs that app to have PASSED the floor first
14 hosting ─────── blocked on Douglas
```

**Hard precedences, and nothing else:**

- 1 precedes everything on `text-to-spaceship`, `study-system`, `shopping-search`.
- 2 precedes the fan-out, so no agent is dispatched to an app that is about to be archived.
- 5 precedes 8, 9 and 15, because each of those is an edit to the token block 5 creates.
- 10 precedes 11, 12 and 13 for any given app.
- 13 precedes 12 for a vanilla app, and **the floor precedes 13** for every app.

**File-disjoint across apps — safe to fan out, one agent per app, one worktree each:**
workstreams 5, 6, 7, 8, 9, 10, 15. Each touches only files inside one app unit.

**Not file-disjoint:** 2 (retirement moves folders and rewrites this roster), 3 and 4 (single-app, no
fan-out to do), 11 and 13 (they rewrite a shared lockfile per app and must be serial within that app),
14 (one decision, not per-app work).

---

## The per-app recipe

Quoted verbatim; an agent follows it for exactly one app unit, in its own worktree.

> **Per-app repair recipe — one app unit, one branch, one worktree, one owner.**
>
> 0. **Enter isolation.** `git -C <app> worktree add <worktrees-root>/<app>/repair -b agent/<app>-repair <default-branch>`.
>    If the app has no git repository, `git init`, commit the tree as-is as the rollback point, and stop
>    for the day — an unversioned app gets version control and nothing else in the same sitting.
> 1. **Install the harness.** `& 'C:\Program Files\PowerShell\7\pwsh.exe' -NoProfile -NonInteractive -File .agents/tools/Manage-Harness.ps1 -Action EnsureProject -Repository <worktree>`.
> 2. **Record the baseline.** Run the floor measurement (Appendix A, `m4.sh`) against the worktree and
>    paste its row into the app's `LOG.md`. Every later claim is measured against this row, not against
>    a memory of it.
> 3. **Declare the template.** Write the `STACK-TEMPLATES.md` template number, the question number that
>    selected it, and every deviation with its reason, into the app's `DESIGN.md`. (B8)
> 4. **Build the token block.** Create or extend a single `:root` block holding every colour, font size,
>    space and radius the app uses. Replace each literal at its use site with `var(--token)`. Stop when
>    the app's own stylesheets and HTML `<style>` blocks contain no literal hex, no `px` font size and no
>    `rem` radius outside `:root`. (B1)
> 5. **Convert the language.** Rename `.js`/`.mjs`/`.cjs` to `.ts` and `.jsx` to `.tsx`, add a
>    `tsconfig.json` with `strict: true`, and fix until `npx tsc --noEmit` exits 0. A Node entry point
>    needs no build step; Node has run `.ts` directly since 22.18. Browser code uses the build step the
>    app already has. (settled decision)
> 6. **Move the framework, if the verdict is CONVERGE.** Create the Next App Router skeleton, move each
>    existing page to a route, delete the hand-written server, and keep the token block byte-identical
>    across the move. If the app has a Playwright suite, it must pass unchanged before and after — that
>    is what proves the move was a move and not a rewrite.
> 7. **Fill the primitive and component slots, only if this app has three or more interactive surfaces.**
>    Base UI primitives; components copied into the repository, never imported from `node_modules`.
> 8. **Apply the rest of the floor.** `:focus-visible` on every interactive element (B2); a `transition`
>    on every state change plus a `prefers-reduced-motion: reduce` block (B3); a
>    `prefers-color-scheme: dark` block that redefines the `:root` tokens (B4); zero `!important` (B5);
>    zero floating version specifiers (B6).
> 9. **Wire the accessibility assertion.** Add `@axe-core/playwright` to the existing suite and assert
>    zero serious or critical violations on the primary surface. If the app has no Playwright suite,
>    create one test that opens the primary surface and runs that assertion. (B7)
> 10. **Prove it.** Run the app's own proving command, then the floor measurement again, then
>     `git diff --check`. Paste the before and after floor rows side by side into `LOG.md`.
> 11. **Open a pull request** from `agent/<app>-repair`. Do not push the default branch, do not merge.
>
> **Proving command for every run of this recipe, in this order:**
>
> ```
> npx tsc --noEmit
> npx playwright test
> bash <harness>/tools/floor.sh <app>        # the Appendix A measurement
> git diff --check
> ```
>
> A step whose proof cannot be run is reported as unmeasured. It is never reported as passing.

**Stop conditions for one recipe run:** two consecutive failed attempts at the same step; the floor
measurement getting worse on any column; the Playwright suite failing after step 6 when it passed before
it; or 4 hours of wall time. Each stop escalates to an advisor with the before-and-after floor rows.

---

## Cost and the stopping rule

### Effort per app, per workstream

Rough, and in agent-hours, not Douglas-hours. Ranges are the small-app and outlier ends of the same task.

| Workstream | Per app | Notes |
|---|---|---|
| 1 version control | 0.25 h | 3 apps |
| 2 retire | 0.5 h | per unit, including preserving unlanded work to an `agent/*` branch |
| 3 float pins | 0.5 h | one app, plus a compatibility run |
| 4 close drift | 6–10 h | one app, three majors |
| 5 token layer | 1–3 h typical; 8–16 h for `compsci-260b`, metropolis, `truss-forge` | scales with unique-colour count, not file count. `shopping-search` is removed from the expensive group 2026-09-27: 55 colours, and the extraction took under an hour |
| 6 focus + axe | 0.5–1 h | mostly one import and one assertion |
| 7 motion | 0.5–1.5 h | after 5 |
| 8 dark mode | 0.5–1 h | after 5; it is one extra `:root` block |
| 9 remove `!important` | 0.25 h at 1–5 occurrences; 4–8 h at 200+ | after 5 |
| 10 TypeScript | 1–2 h for a small app; 6–12 h where JS and TS already coexist half-converted (`bible-name-search`, `base-flight-finder`) | the half-converted apps are the expensive ones |
| 11 Next majors | 0.5 h per bump after 4 | |
| 12 components | 4–10 h | restricted to apps with 3+ interactive surfaces |
| 13 vanilla → Next | 8–20 h | the dominant cost in the program |
| 14 hosting | 1–3 h per app once decided | |
| 15 outlier triage | 8–16 h each | |

**Program total, order of magnitude:** the floor across the 38 worked units is roughly 150–250 agent-hours; adding
workstream 13 across 21 vanilla apps roughly triples it. That ratio is the argument for the ranking: the
floor is a third of the cost and carries most of what a person notices.

### The stopping rule

**An app unit is DONE when, and only when:**

- [ ] Its verdict's checklist passes: CONVERGE → recipe steps 0–11; BASELINE → steps 0–5 and 8–11;
      HOLD → its reason is written in its `DESIGN.md` and nothing else happens; RETIRE → it is archived
      and its roster row is struck.
- [ ] Its four proving commands exit 0, in one run, with the output pasted into its `LOG.md`.
- [ ] Its floor row is no worse than its baseline row on **every** column.
- [ ] A reviewer who did not do the work confirms those three from the pasted output.

**The program stops when every roster row is DONE.** Not when the apps look good — that is not a
measurable condition and it is why a program without this rule runs forever.

**Three additional stops, any one of which halts the program rather than one app:**

- [ ] **Floor-first stop.** No app unit enters workstream 13 until it is DONE at BASELINE. If a lane
      reports a framework migration on an app that has not passed the floor, the program halts and that
      lane's work is reverted.
- [ ] **Regression stop.** If any app that worked before this program stops working and is not repaired
      within one lane-day, the program halts until it is. Nine working local tools are worth more than
      the whole floor.
- [ ] **Budget stop.** If the floor across all 38 worked units is not DONE within 300 agent-hours, the program
      halts and re-ranks rather than continuing. A plan that has doubled its estimate has a wrong
      estimate, not a slow team.

---

## What could go wrong, and the check that catches it

| Workstream | Regression risk | The check that catches it |
|---|---|---|
| 1 version control | An initial commit captures secrets that were never in git | Gitleaks runs before the first commit; `secret-manifest.json` is written first |
| 2 retire | Unlanded work in a duplicate checkout or a `.tmp-brute-*` folder is destroyed | `git status --short` and `git log <remote>/<branch>..HEAD` must both be empty, or the work is committed to an `agent/*` branch and pushed **before** the folder is removed. Archive by default; delete only on Douglas's direction |
| 3 float pins | Resolving `latest` to a real version breaks the demo that has never been built against a pin | Build and open `arch-gp-demo` before and after; it is filed as intake against `agent-harness`, whose owning lane runs the check |
| 4 close drift | Next 14 → 16 changes routing, caching and `Image` semantics; the site silently renders wrong rather than failing | The Playwright suite (`legal-solutions-website` has one) plus a screenshot of every route before and after, compared by a reviewer who did not do the migration |
| 5 token layer | A colour is mapped to the wrong token and one component changes appearance with no error anywhere | Unique-colour count must **drop** while the rendered screenshot of every page is byte-comparable within an anti-aliasing tolerance. A colour count that drops *and* a screenshot that changes means a token was mis-mapped |
| 6 focus + axe | An axe assertion is added and immediately excluded to make the suite green | The assertion's source is inspected for `disableRules`, `exclude` and `.skip`; a reviewer reads the assertion, not the exit code |
| 7 motion | A transition is added to a property that forces layout, and a dense dashboard becomes unusable | `prefers-reduced-motion` block present, and transitions restricted to `opacity`, `transform`, `color`, `background-color`, `border-color` — grep the rest |
| 8 dark mode | Dark tokens are added without contrast checking and the text becomes unreadable | The axe assertion from B7 runs a second time with `colorScheme: 'dark'` emulated |
| 9 remove `!important` | Removing it reveals the specificity conflict it was hiding, and a rule silently stops applying | Screenshot comparison per page before and after; a removed `!important` that changes nothing visible was safe, one that changes something was load-bearing |
| 10 TypeScript | `strict: true` is satisfied by `any` and `@ts-expect-error`, so nothing is actually typed | Count `any`, `as unknown as` and `@ts-expect-error` before and after; the after-count must not exceed the before-count |
| 11 Next majors | A patch bump pulls a breaking transitive change | Lockfile committed; `npx tsc --noEmit` plus the Playwright suite |
| 12 components | A copied-in component diverges from the reference and two apps drift apart | Components are copied from `berkeley-house`; a diff against it is recorded in the app's `DESIGN.md` with a reason per divergence |
| 13 vanilla → Next | **The worst risk in the program: nine working local tools stop working.** A migration that breaks `mission-control`, `build-log` or `schema-studio` is worse than every bland stylesheet | The app's Playwright suite must pass **unchanged** across the migration. An app with no suite gets one written *before* step 6 and not after — a test written after a migration tests the migration's output, not the app's behaviour. `ui-feature-ledger` records the interactive controls before the move and detects any that silently disappear |
| 14 hosting | A local tool with no authentication is put on a public URL with his data in it | No app is hosted until its data boundary is written in `data-manifest.yaml` and a reviewer confirms no private record is served |
| 15 outlier triage | 4 MB of styling is "tokenised" into 1272 variables, which is the same problem with a new spelling | The success measure is **deletion**: unique-colour count must fall below 40 and total styling bytes must fall by more than half. A triage that raises the custom-property count without lowering the colour count has failed |

---

## Layer 3 — Acceptance criteria

Each criterion names setup, action, expected result, and the command that settles it. Program-level
criteria are `AC-P*`; per-app criteria are the recipe's own checklist and are tracked per roster row.

- [ ] **AC-P1 — Every app has a verdict.** Setup: this document. Action: run the roster count command in
      Appendix A. Expected: the app-unit count from the filesystem equals the roster row count, and no
      directory under `C:\Users\dougl\Projects\` that meets the app-unit definition is absent from either
      roster table or the "not app units" list with its evidence.
- [ ] **AC-P2 — No app is unversioned.** Action:
      `for d in */; do [ -e "$d/.git" ] || echo "$d"; done` in `C:\Users\dougl\Projects`. Expected:
      output contains no roster row.
- [ ] **AC-P3 — One checkout per remote.** Action: group every project's `git remote get-url origin` by
      URL. Expected: no URL appears twice.
- [ ] **AC-P4 — No floating version specifier anywhere.** Action:
      `grep -rn ': *"\(latest\|\*\)"' --include=package.json . | grep -v node_modules`. Expected: no output.
- [ ] **AC-P5 — One Next major.** Action: collect `"next"` from every manifest. Expected: one major
      version, and it is the current stable Next major at the time the workstream runs — verified against
      Next's own release page in that session, not from memory.
- [ ] **AC-P6 — One TypeScript major.** Action: collect `"typescript"` from every manifest. Expected: one
      major version.
- [ ] **AC-P7 — One React major.** Action: collect `"react"`. Expected: one major version.
- [ ] **AC-P8 — Zero `@radix-ui` and zero MUI, Express, Prisma, Redux Toolkit, MobX, XState, Valtio,
      Jotai, Solid, Preact, Lit, Angular, styled-components or Emotion.** Action:
      `grep -rl '@radix-ui\|@mui/\|"express"\|@prisma/client\|@reduxjs/toolkit\|"mobx"\|"xstate"\|"valtio"\|"jotai"\|"solid-js"\|"preact"\|"lit"\|@angular/\|styled-components\|@emotion/' --include=package.json . | grep -v node_modules`.
      Expected: no output. Today it returns `168-audit` and `conference-tracker` (Express).
- [ ] **AC-P9 — Every app unit meets the floor, or its exemption is written down.** Action: run the floor
      measurement across the roster. Expected: for every non-HOLD row, hex-outside-`:root` = 0,
      `!important` = 0, `:focus-visible` ≥ 1, `prefers-color-scheme` ≥ 1, `transition` ≥ 1,
      `prefers-reduced-motion` ≥ 1. For every HOLD row, the reason is in its `DESIGN.md`.
- [ ] **AC-P10 — Every app with a Playwright suite asserts accessibility.** Action:
      `grep -rl '@axe-core/playwright' --include='*.spec.*' --include='*.test.*' <app>` for each app with
      a `playwright.config`. Expected: one hit per such app. Today: 5 of 13.
- [ ] **AC-P11 — Every app declares its template selection.** Action: grep each app's `DESIGN.md` or
      `MAP.md` for a template number and a selecting-question number. Expected: one per non-RETIRE row.
- [ ] **AC-P12 — Nothing that worked stopped working.** Action: for every app that had a passing proving
      command before the program, run it now. Expected: still passing, with the output pasted in that
      app's `LOG.md`.
- [ ] **AC-P13 — Every local-only app has a recorded shareability answer.** Action: grep each app's
      `PRODUCT.md` or `MAP.md` for the decision. Expected: one of "single-user, local by design" or a
      hosting target, per app, with Douglas's ruling cited. Today: 14 local-only units, 0 answers.
- [ ] **AC-P14 — The outlier triage deleted rather than renamed.** Action: floor measurement on
      `shopping-search`, `compsci-260b`, `obsidian-vault-mirror-metropolis`, `truss-forge`. Expected:
      unique-colour count < 40 and total styling bytes less than half the baseline row, for each.
- [ ] **AC-P15 — This specification stayed true.** Action: re-run Appendix A's scan. Expected: every
      number in this document either matches, or the document was updated in the same work unit with the
      new number and the date.

---

## Open decisions

Douglas's, not mine. Each names the two options and what decides between them.

- [ ] **OD-1 — Which Next major is "the best Next version"?**
      **A:** pin every app to the newest stable major currently on disk (16.3.6, in `design-lab`).
      **B:** pin to the newest major that `berkeley-house` — the reference with Base UI and shadcn
      actually wired — is proven on (16.2.12), and bump the reference first.
      **Decides it:** whether shadcn-on-Base-UI is verified working on the newer major. If it is, A; if
      it is not, B, because the reference must stay the thing everything is copied from. *This must be
      checked against Next's current release notes in the session that runs workstream 11, not assumed.*

- [ ] **OD-2 — `docket` and `vault-review-mobile` are the same app twice. Merge or keep?**
      **A:** one codebase, two deployment targets — a local mirror for NASA/CUI content and a Vercel
      deployment for the rest, with the sensitivity gate as a build flag.
      **B:** keep two, because the gate is a *physical* separation and a build flag is not.
      **Decides it:** whether the sensitivity boundary must be unable to leak by construction. If yes,
      B, and the duplication is the price of the guarantee. If a reviewed flag is enough, A, and the
      program saves one full migration.

- [ ] **OD-3 — Which of the 14 local-only apps should another person be able to use?**
      **A:** none — they are his tools, and `localhost` is the correct address.
      **B:** name the ones where a second user exists today: `sarah-stuff` (Sarah), `legal-doc-studio`
      (clients), `client-portal` (customers), `landry-sandbox`, `second-brain-capsule` (whose stated
      product claim *is* that a stranger can run it).
      **Decides it:** whether a second person has already asked for a link. For any app where the answer
      is yes, hosting is not optional and the app needs authentication, TLS and durable storage — three
      things none of them have. `python -m http.server` can never be the answer.

- [ ] **OD-4 — `schema-studio`'s app is not on `master`.** **A:** land the branch app onto `master` before
      any repair, so `master` is buildable. **B:** treat the branch as the product and repair there.
      **Decides it:** whether anyone other than the current lanes needs to build `schema-studio`.
      Recommend A: a default branch that cannot be built is a defect regardless of the answer.

- [ ] **OD-5 — Does `STACK-TEMPLATES.md` get rewritten, or does it get an override?**
      **A:** rewrite it so its seven templates all name Next, Base UI and TypeScript, matching this
      program. **B:** keep it as the menu and record this program's convergence as a dated, named
      deviation with an end date, per its own "Deviating" section.
      **Decides it:** whether Douglas intends one stack forever or one stack for now. See
      [Conflicts](#conflicts-between-this-specification-and-a-harness-contract) — this decision cannot be
      deferred, because two documents currently give opposite instructions to the same agent.

- [ ] **OD-6 — `design-lab`.** **A:** it is another lane's live scaffold; hold. **B:** it is an
      abandoned scaffold; retire it. **Decides it:** whether the lane that created it on 2026-09-26 has
      landed anything. It currently holds the newest stack on the machine and no application.

---

## Where TypeScript is a bad trade

The invited exception, and only these.

- [ ] **`project-hady`** — a PySide6 desktop application: 32 Python files, zero JavaScript. "Converting
      to TypeScript" means rewriting the product in a different language on a different UI toolkit. The
      exception is not about TypeScript being worse; it is that there is nothing to convert.
- [ ] **`design-worlds`'s 98 pages** — each is a self-contained HTML document whose entire value is that
      it opens from disk with no build step, now and in five years. A build step is the thing this kind of
      artifact refuses (`STACK-TEMPLATES.md` template 7). Convert the *generator* if one is written;
      never the artifacts.
- [ ] **`truss-forge`'s 50 exported pages and `slides-workbench`'s decks** — generated output of
      `export_static.py` and the deck builders. The source converts; the output is not source.
- [x] **`shopping-search`'s generated report** — same reason, but the count was wrong: there is **one**
      generated HTML report, not 123. The other 122 were bundled-extension pages inside the gitignored
      `tmp\edge-shopping-report-profile\`. Its three Python generator scripts are the repair target and
      they stay Python; they were repaired 2026-09-27.
- [ ] **The Python compute cores of `cad-forge` (340 files), `truss-forge` (231), `schema-studio` (117)
      and the FastAPI sidecars** — the solver, CAD kernel and extraction libraries exist only in Python.
      Their browser layers convert; the cores do not. This is not an exception to the decision so much as
      a boundary on it, and it is worth writing down because a lane told to "convert everything to
      TypeScript" will otherwise try.

---

## Conflicts between this specification and a harness contract

**Surfaced, not resolved.** Both sides are named, and OD-5 decides it.

**The conflict:** `~/.agents/design/STACK-TEMPLATES.md`, authored 2026-09-26 and quoting Douglas the same
day, and this program's settled decisions, also Douglas's and also 2026-09-26, give opposite instructions
on four slots.

| Slot | `STACK-TEMPLATES.md` says | This program says |
|---|---|---|
| framework, content site (template 1) | **Astro** — "Renders to HTML at build time and ships zero JavaScript" | **Next.js**; Astro is know-about, do-not-adopt |
| framework, dashboard (template 3) | **Vite plus React Router** — "Next.js only when access control must be enforced server-side" | **Next.js**; Vite drops to know-about |
| framework, local single-purpose tool (template 4) | **Vite alone, no framework** — "there are no pages and no server to own" | **Next.js, including for a tool only he opens** |
| headless primitives, all 7 templates | **Radix, via shadcn** | **Base UI** |

**A fifth, structural:** `STACK-TEMPLATES.md` § Deviating states *"An existing app is not migrated to
match a template... Douglas decides whether it happens."* This program **is** Douglas deciding it happens,
so that clause is satisfied rather than violated — but the clause also means the templates were never
written as a migration target, and reading them as one will mislead a lane.

**Recommendation:** OD-5 option **A** — rewrite `STACK-TEMPLATES.md`'s framework and primitive slots to
match the settled decisions. The reason: an agent dispatched to repair a dashboard today reads
`STACK-TEMPLATES.md`, finds "Vite plus React Router", and builds the thing this program exists to remove.
Leaving two live documents in contradiction guarantees that outcome; a dated deviation note (option B)
only reduces its likelihood.

**A second conflict, smaller and already routed:** the brief names the `latest`-pinned app as a live
defect to fix, and also forbids touching `C:\Users\dougl\Projects\agent-harness` except to read. The
`latest` pins are all 11 dependencies of `agent-harness/arch-gp-demo`. **Resolution:** file it as intake
against `agent-harness` via `Add-ProjectIntake.ps1` and do not edit it here. Both instructions are then
honoured, and the defect is not dropped.

**A third, noted for the record:** `STACK-TEMPLATES.md` says its per-entry catalogue "lives in the
`general-ai` repository as `WEB-STACK.md`". That file does not exist. Either it is unwritten or the
pointer is wrong; a lane following the pointer will find nothing.

---

## Appendix A — how every number was taken

The scripts are reproducible and were run from Git Bash on the Windows host at 2026-09-27T03:07Z. Each
uses `git ls-files` inside a repository, so ignored build output and `node_modules` never enter a count,
and `find` only for the three unversioned projects.

**App-unit count.** Enumerate every directory directly under `C:\Users\dougl\Projects\`; drop any whose
`.git` is a file (a worktree) or whose `git remote get-url origin` duplicates another's; drop archive
folders; keep the rest that ship an HTML page, a Node web server, or a desktop window:

```bash
cd /c/Users/dougl/Projects
for d in */; do d="${d%/}"
  if [ -f "$d/.git" ]; then echo "$d WORKTREE"; continue; fi
  [ -d "$d/.git" ] || echo "$d NOGIT"
done
for d in */; do [ -d "${d%/}/.git" ] && printf '%s\t%s\n' "${d%/}" "$(git -C "${d%/}" remote get-url origin 2>/dev/null)"; done | sort -k2 | awk -F'\t' '{if($2==p)print "DUPLICATE CHECKOUT: "$1" and "q; p=$2; q=$1}'
```

**Roster row count.** `grep -c '^| \[ \]\|^| \[x\]' APP-REPAIR-SPEC.md` over the roster tables.

**Dependency versions.** Exact, per manifest, excluding build and lane copies:

```bash
cd /c/Users/dougl/Projects
for f in $(ls */package.json */*/package.json 2>/dev/null | grep -vE 'node_modules|\.next|\.tmp-'); do
  grep -oE '"(next|react|typescript|vite|tailwindcss)": *"[^"]*"' "$f" | tr '\n' ' '; echo "  <- $f"
done
```

**Floor population — every floor figure in this document is over these 54 rows.** The floor tools read
[`tools/m4-roster-roots.tsv`](tools/m4-roster-roots.tsv), which enumerates **54 roster rows**: the 55
rows counted above less `study-system/.tmp-brute-*`, a cleanup row with no app root to measure. 46 of the
54 carry at least one committed `.css` or `.html` file; the other 8 are still in the denominator. A figure
stated "of 55" or "of the 46 roots" before 2026-09-28 used a different denominator and is restated against
the 54 where it appears. Read the roster file through `tr -d '\r'`: it checks out CRLF under
`core.autocrlf=true`, and a CR left on each path makes every row report `MISSING`.

The per-row style-file, dark, `!important` and `@container` counts behind
[the brief-contradiction table](#other-figures-in-the-brief-that-this-measurement-contradicts) are the
snippet below run once per roster row, captured at
[`tools/floor-published-rule.2026-09-28.tsv`](tools/floor-published-rule.2026-09-28.tsv):

```bash
tr -d '\r' < tools/m4-roster-roots.tsv | while IFS=$'\t' read -r name path; do
  root=/c/Users/dougl/Projects/$path   # then the L, F and A lines of the snippet below
  printf '%s\t%s\t%s\t%s\t%s\n' "$name" "$(echo "$F" | grep -c .)" "$(echo "$A" | grep -c 'prefers-color-scheme')" \
    "$(echo "$A" | grep -c '!important')" "$(echo "$A" | grep -c '@container')"
done
```

**Floor measurement (`m4.sh`).** The snippet below is the rule as originally published and is retained for
audit; its `distinct-font-sizes` line was wrong and is superseded by [`tools/m4.sh`](tools/m4.sh) — see the
correction that follows. It measures `.css` **and** `.html` together, which is the correction that
matters: 20 app units keep all their styling inside HTML `<style>` blocks, and a `.css`-only scan reports
them as having no transitions, no tokens and no dark mode when they do.

```bash
# one row per root: stylefiles, KB, unique-hex, distinct-font-sizes, custom-props,
#                   transition, @keyframes, !important, :focus-visible, dark, @container, clamp
if [ -e "$root/.git" ]; then L=$(cd "$root" && git ls-files | sed "s#^#$root/#")
else L=$(find "$root" -type f | grep -v '/node_modules/'); fi
F=$(echo "$L" | grep -E '\.(css|html)$' | grep -vE '/\.next|/dist/|/out/|/\.agents/|\.min\.css$|/coverage/|/\.tmp-')
A=$(echo "$F" | xargs -d'\n' cat)
echo "$A" | grep -oiE '#[0-9a-f]{3,8}' | tr 'A-F' 'a-f' | sort -u | grep -c .   # unique hex
echo "$A" | grep -oiE 'font-size: *[^;}"]*' | sed 's/.*: *//' | sort -u | grep -c .
echo "$A" | grep -oE '\-\-[a-zA-Z0-9_-]+ *:' | sed 's/ *:$//' | sort -u | grep -c .
for p in 'transition' '@keyframes' '!important' ':focus-visible' 'prefers-color-scheme' '@container' 'clamp('; do
  echo "$A" | grep -c "$p"
done
```

`/\.agents/` is excluded because the shared harness installs the same tracked JavaScript and CSS into
every repository; counting it makes every app look larger and more similar than it is. That exclusion is
also why the JavaScript-file counts here are lower than a naive `find`.

#### Correction, 2026-09-27 — `distinct-font-sizes` could not see three quarters of a Tailwind app

The `distinct-font-sizes` line above greps `font-size:` in committed `.css` and `.html` only. In a
Tailwind-first app most sizes are never written as a `font-size` declaration and never reach a
stylesheet: they are arbitrary utilities inside class attributes in `.jsx` and `.tsx`. For
`bible-name-search` the published rule reported **12**; the true figure is **52** — 14 declared and 46
more as `text-[…]` values, with 0.82, 0.83, 0.84, 0.85, 0.855, 0.86 and 0.875rem alive at once. For
`168-audit` and `conference-tracker` it reported nothing at all, because their entire UI is a template
literal inside `server.js`; they carry 39 and 37 distinct sizes.

**A measurement that cannot see three quarters of its subject is worse than none, because it reads as a
pass.** The measurement is now [`tools/m4.sh`](tools/m4.sh) — a file, not a snippet, so it can be
re-run and diffed. [`tools/m4-fontsizes-old.sh`](tools/m4-fontsizes-old.sh) is the frozen pre-correction
rule, kept only so the correction stays auditable; [`tools/m4.regression.sh`](tools/m4.regression.sh)
pins the JSX-class-name path and fails against the old rule (2) and passes against the new one (8).
[`tools/m4-blast-radius.sh`](tools/m4-blast-radius.sh) prints the whole-roster before-and-after.

Counting rules, stated because a metric that silently changes what it counts is the defect being fixed:

| Rule | Decision | Why |
|---|---|---|
| File set | The original `.css`/`.html` set, plus `.jsx .tsx .js .ts .mjs .cjs .vue .svelte .astro .mdx .php .erb` | The old set was a guess about where sizes live, not a measurement of it |
| Sources | `font-size:` and `fontSize:` declarations anywhere, including inline `style=` and JSX style objects; plus `text-[<value>]` utilities, variant- and `!`-prefixed forms included | `text-` is overloaded in Tailwind, so only **length-valued** arbitraries count: `text-[var(--text-1)]` and `text-[#fff]` are colours. `text-[length:var(--x)]` is an explicit length and counts |
| Units | `px` and `pt` are converted to `rem` at the default 16px root, so `0.625rem` and `10px` are **one** size. `em`, `%`, `vw`, `ch` and friends are **not** folded into `rem` | A rendered size is what a reader sees, so the same rendered size is one decision. Relative and viewport units depend on a context the scan cannot see, and calling them equal would be a guess dressed as a measurement |
| Dedupe | One normalised set per app unit | A size repeated in forty files is one decision, not forty |
| Named steps | `text-sm`, `text-lg` and friends are **excluded** from the total and reported separately as `named-steps` | m4 measures scale *drift* — sizes invented outside the system. A named step is on the scale by construction; forty uses of `text-sm` are one decision, while `text-[0.82rem]` and `text-[0.83rem]` are two. Counting them would also make every Tailwind app's number incomparable with every hand-written app's |

Normalisation cuts as well as adds. Six roots fall because the old rule counted `15px` and `0.9375rem`,
or `clamp(2.6rem, 6vw, 4.4rem)` and `clamp(2.6rem,6vw,4.4rem)`, as different sizes: `design-worlds`
216 → 204, `obsidian-vault-mirror-metropolis` 150 → 128, `berkeley-research` 61 → 55, `cad-forge`
52 → 47, `anna-maria-mcgowan-site` 101 → 98, `build-log` 40 → 38. Those apps were never as fragmented as
their rows claimed.

**Corrected in turn, 2026-09-27 — see the next section.** `:focus-visible` and `prefers-color-scheme` had
the *inverse* form of the same blind spot, and it is now fixed. The `unique-hex` metric has the same
arbitrary-value blind spot in principle and, measured across the roster, **one** value in one app
(`bible-name-search`), so no published colour count is restated.

#### Correction, 2026-09-27 — the floor reported accessibility failures that do not exist

The `:focus-visible` and `prefers-color-scheme` lines above grep committed `.css`/`.html` for a
pseudo-class and an at-rule. A Tailwind app writes neither. It writes `focus-visible:ring-2` and
`dark:bg-slate-900` as **variant prefixes in class names, in markup**. So those apps scored **zero** and
read as a floor *failure they do not have*.

**This is strictly worse than the font-size defect it mirrors.** A false pass wastes nothing. A false
failure sends an agent to redo finished work, and workstream #6 was sized on the claim that "a keyboard
user cannot operate six of these apps at all." Four named apps are removed from any such list:
`legal-solutions-website` (0 -> 33), `berkeley-house` (0 -> 87), `168-audit` (0 -> 11) and
`conference-tracker` (0 -> 4). Under the old rule 16 of 54 roster rows scored zero focus styling; under the
corrected rule 12 do, and 5 of those 12 are not browser surfaces at all (a CLI package, a Tauri shell, two
second checkouts of a remote, one static preview folder).

The measurement is now [`tools/floor-a11y.sh`](tools/floor-a11y.sh).
[`tools/floor-a11y-old.sh`](tools/floor-a11y-old.sh) is the frozen pre-correction rule, kept only so the
correction stays auditable; [`tools/floor-a11y.regression.sh`](tools/floor-a11y.regression.sh) pins the
markup-variant path and **fails against the old rule (focus 0, dark 0) and passes against the new one
(focus 5, dark 4)**. [`tools/floor-a11y-blast-radius.sh`](tools/floor-a11y-blast-radius.sh) prints the
whole-roster before-and-after, captured at
[`tools/floor-a11y-blast-radius.2026-09-27.tsv`](tools/floor-a11y-blast-radius.2026-09-27.tsv).

Counting rules, stated because a metric that silently changes what it counts is the defect being fixed:

| Rule | Decision | Why |
|---|---|---|
| File set | The original `.css`/`.html` set, plus `.jsx .tsx .js .ts .mjs .cjs .vue .svelte .astro .mdx .php .erb` — identical to `m4.sh` R1 | The old set was a guess about where focus and dark styling live, not a measurement of it. It is also what opens `168-audit` and `conference-tracker`, whose entire UI is a template literal inside `server.js` |
| B2 threshold | **Unchanged at `focus >= 1`.** Only *where the rule looks* changed, and the markup-variant form was added | Moving the threshold would change what the floor means, which is not a measurement decision |
| What counts as focus styling | CSS-form `:focus-visible` plus markup-form `focus-visible:` variants; stacked forms (`group-focus-visible:`, `peer-focus-visible:`) count once each. Bare `focus:` is reported as `focus-only` and does **not** satisfy B2 | B2 names the focus-*visible* behaviour. `focus:outline-none` on its own is the defect B2 exists to catch, not evidence against it. No threshold above 1 and no interactive-element filter: this is a floor, not a review, and "the focus ring is ugly" is not this metric's business |
| B4 verdict | A dark treatment must reach the page **surface**: a `prefers-color-scheme:...dark` block, or at least one background-establishing dark variant (`dark:bg-`, `dark:from-`/`via-`/`to-`, `dark:[--token:`). The raw count is reported beside it as `dark-surface=yes` or `no` | This is the closest faithful translation of B4 ("a block that **redefines the `:root` tokens**") into variant terms. A single `dark:text-slate-400` with no dark surface leaves the page white in dark mode, so it is a token slip, not dark-mode support. **Stated plainly: a one-variant app fails under this rule, and that is intended.** `cad-forge` fails B4 for exactly this reason — a `prefers-color-scheme` hit that is not a dark block, which the old count-anything rule passed |
| Dark mechanism | Reported as `dark-mechanism=media`, `class` or `none`. Tailwind v4 `@custom-variant dark` and v3 `darkMode: 'class'` change what `dark:` resolves against | Two roster apps configure it — `berkeley-house` (`app/globals.css`) and `design-lab` (`src/app/globals.css`), both `@custom-variant dark`. **Neither count changes:** a class-strategy app still declares its dark treatment in the same `dark:` variants. It is reported so a class-strategy app with no toggle control is visible rather than silently counted as supporting dark mode |
| `!important` (B5) | Tailwind's v3 **prefix** form `!py-2` / `!text-[0.72rem]` is counted. The v4 **suffix** form `text-red-500!` is **not** | In this file set the suffix form is indistinguishable from a TypeScript non-null assertion (`className={styles.x!}`): counting it took `bible-name-search` from 8 to 221, none of them real. The prefix form is required to have an internal `-`, which drops JSX boolean negation (`!open`). If an app adopts the v4 suffix this undercounts and must be revisited; no roster app does today |
| Occurrences, not lines | Every count here is occurrences; the old rule used `grep -c`, which counts matching **lines** | A minified or single-line stylesheet with nine `:focus-visible` rules scored 1. The blast-radius table therefore compares **verdicts**, not counts, and prints both numbers |

**The retraction, not an edit. `:focus-visible`.** 4 verdicts flip, **all of them false failures corrected
to passes**. Zero genuine failures were missed by the old rule. 16 further rows move in count without
moving the verdict (`bible-name-search` 1 -> 7, `cad-forge` 19 -> 28, `truss-forge` 24 -> 38, `design-lab`
3 -> 39, `sarah-stuff` 4 -> 51, `landry-sandbox` 8 -> 21, `berkeley-research` 5 -> 11, `hci-260` 1 -> 7,
`workscope-graph` 3 -> 7, `berkeley-meng` 3 -> 6, `schema-studio` 1 -> 3, `compsci-260b` 8 -> 26,
`design-worlds` 73 -> 78, `drive-organizer` 2 -> 3, `second-brain-capsule` 1 -> 2,
`obsidian-vault-mirror-metropolis` 5 -> 6). **34 rows are unaffected on both properties**, which is the
finding that bounds the fix: this is a Tailwind-app defect, and most of the roster is not Tailwind.

**The retraction, not an edit. Dark mode.** 6 verdicts flip: **5 false failures corrected to passes**
(`bible-name-search`, `conference-tracker`, `berkeley-house`, `saved-posts`, `sarah-stuff`) and **1 genuine
failure the old rule missed** (`cad-forge`, which the old rule passed on a `prefers-color-scheme` hit that
is not a dark block).

| Estate figure | Published 2026-09-27 | Corrected | Delta |
|---|---|---|---|
| Dark mode fails | **34 of 55** | **30 of 54** | -4 |
| `:focus-visible` = 0 | 16 of 54 under the old rule | **12 of 54**, of which 5 are not browser surfaces | -4 |
| `!important` >= 1 | **41 of 55** (stated over 46 roots, so the denominators differ) | **43 of 54 roster rows** | see below |

**`!important` and tokens share the blind spot, and one row is severe.** `bible-name-search` is published
at **3** `!important` and carries **228** — 3 in CSS plus **225 Tailwind v3 important-prefix utilities**,
mostly `!text-[0.72rem]` and `!text-[var(--x)]`, spot-checked at `app/collections/[id]/page.tsx:353`,
`app/collections/[id]/page.tsx:449` and `app/error.tsx:27`. It was already failing B5 at 3, so **no B5
verdict flips**, but its repair cost is two orders of magnitude off the published figure. No other roster
row has a prefix-important utility. Token *declaration* counts move on 8 rows, two of them from nothing:
`168-audit` 0 -> 68 and `conference-tracker` 0 -> 27 (the `server.js` file set again), plus
`landry-sandbox` 66 -> 96, `sarah-stuff` 1261 -> 1275, `study-system` 22 -> 23, `schema-studio` 48 -> 49,
`cad-forge` 64 -> 65, `design-lab` 111 -> 112, `obsidian-vault-mirror-metropolis` 140 -> 141. **The
published "tokens 26 of 55" is not restated here**, because B1 as written is a *literal-outside-`:root`*
test, not a custom-property count, and this scan does not implement it. `transition` has the same shape and
is a count rather than a verdict: `legal-solutions-website` 45 -> 118, `berkeley-house` 60 -> 108,
`168-audit` 72 -> 100, `conference-tracker` 49 -> 77, `bible-name-search` 58 -> 114, `design-lab` 18 -> 33.

**One roster claim this measurement cannot confirm.** The `idetc-writing-ide` row states 6 `:focus-visible`
after its Stage 2 repair. Measured at `C:\Users\dougl\Projects\idetc-writing-ide`, the string
`focus-visible` appears in **zero** tracked files. Either that repair has not landed on the branch checked
out there, or the row is describing work in a worktree. Not repaired here — it is outside this lane's owned
paths — but it should not stand as measured fact.

**The correction, row by row, as a retraction rather than an edit.** 23 of 54 roster rows move; 31 do not.
The roster tables above keep their published tuples so the change stays visible; this is the authoritative
`distinct-font-sizes` figure. Re-derive it with `bash tools/m4-blast-radius.sh`.

| App unit | Published | True | Δ |
|---|---|---|---|
| `legal-solutions-website` | 20 | 24 | +4 |
| `bible-name-search` | 12 | 52 | +40 |
| `client-portal` | 13 | 15 | +2 |
| `fellowship-tracker` | 15 | 16 | +1 |
| `study-system (berkeley-prelim-study)` | 41 | 43 | +2 |
| `168-audit` | not measured | 39 | +39 |
| `conference-tracker` | not measured | 37 | +37 |
| `build-log` | 40 | 38 | −2 |
| `schema-studio` | 24 | 27 | +3 |
| `anna-maria-mcgowan-site` | 101 | 98 | −3 |
| `cad-forge` | 52 | 47 | −5 |
| `truss-forge` | 146 | 148 | +2 |
| `marginalia` | 20 | 29 | +9 |
| `berkeley-research` | 61 | 55 | −6 |
| `idetc-writing-ide` | 29 | 27 | −2 |
| `berkeley-house` | not measured | 4 | +4 |
| `design-worlds` | 216 | 204 | −12 |
| `design-lab` | 9 | 19 | +10 |
| `obsidian-vault-mirror-metropolis` | 150 | 128 | −22 |
| `sarah-stuff` | 166 | 173 | +7 |
| `legal-doc-studio` | 18 | 17 | −1 |
| `landry-sandbox` | 20 | 27 | +7 |
| `second-brain-capsule` | 10 | 9 | −1 |

Unchanged, which is the finding that scopes the fix safely: `base-flight-finder` (all three units),
`jars-of-clay`, `kelly-uniforms-business` (all three), `text-to-spaceship`, `docket`,
`vault-review-mobile`, `arch-gp-app`, `mission-control`, `workscope-graph`, `slides-workbench`,
`berkeley-meng`, `operating-dashboard`, `redline-idetc`, `shopping-search`, `project-hady`,
`boundaries-reader`, `contact-form-caller`, `saved-posts`, `drive-organizer`, `anna-maria-mcgowan`,
`compsci-260b`, `hci-260`, `info-272`, `daily-brief`, `skill-pathways`, and the two retired duplicate
checkouts.

**What moves in the ranking.** No workstream changes position: the ranking is by value per hour of a
*workstream*, and no workstream's defence rests on a font-size count. What moves is the app ordering
inside two of them. `bible-name-search` enters **outlier triage (#15)** — at 52 it is the fifth-most
fragmented type scale in the tree, with seven sizes between 0.82 and 0.875rem, and it is hosted, so it
belongs beside `shopping-search` rather than in the quiet middle. `168-audit` and `conference-tracker`
enter the **token layer (#10)** denominator they were absent from, at 39 and 37 sizes each, which is
consistent with their existing verdict that a UI inside a template literal cannot be styled. `study-system`
loses its "142 distinct font sizes in one app" headline — the true figure is 43 and the 142 was never
reproducible. `design-worlds` and `obsidian-vault-mirror-metropolis` fall but stay where they were.

**Three roster numbers are not reproducible by the command above**, independently of this correction:
`study-system (berkeley-prelim-study)` published 142, the command yields 41; `sarah-stuff` published 31,
yields 166; `berkeley-research` published 54, yields 61. Whatever produced those three was not this
script.

**Explicitly unmeasured.** Custom easing functions (`cubic-bezier` and `linear()` declarations) were not
counted; the brief's figure of 21 apps without custom easing is neither confirmed nor contradicted here.
`prefers-reduced-motion` coverage was measured only as present/absent at the app level, not per
transition. Whether each `python -m http.server` reference is a live serving path or a documentation
mention was not verified per reference; the counts are of files containing the string.

---

## Addendum — the wider audit

Douglas, 2026-09-26: *"remember we're doing this renovate plan for all the different apps. There's already
some stuff in there, but give recommendations for what else should be in there, which should have been
part of the audit that I told you to launch."*

Twelve additional audit items. Each is recorded as **measured** with its number, or **unmeasured** with
what measuring it would cost. Several results reorder the ranked workstreams; those changes are applied in
[Revised ranking](#revised-ranking), not appended politely to the bottom.

### A new verdict: ARCHIVE, distinct from RETIRE

Douglas archives by default and deletes only on explicit direction, so a two-value vocabulary stalls on
every candidate. The verdict set is now **five**:

| Verdict | Meaning |
|---|---|
| **CONVERGE** | Bring to the target stack and the floor |
| **BASELINE** | Keep the stack; apply the floor only |
| **HOLD** | Leave it alone; it works or it is the reference |
| **ARCHIVE** | Stops being maintained, stays readable and buildable at its last good commit; no floor work, no migration, no deletion |
| **RETIRE** | Removed from disk — reserved for copies and generated folders, never for a project with unique history |

**Reassigned on this distinction:** `anna-maria-mcgowan` → **ARCHIVE** (superseded, but it is the only
copy of its own history). `compsci-260b` → **ARCHIVE** (finished coursework; 4.1 MB and 208 `!important`
stay exactly where they are, unmaintained). The three genuine RETIRE rows remain:
`obsidian-vault-mirror-metropolis-runtime`, `second-brain-capsule-runtime` and
`study-system/.tmp-brute-*` — all copies, none holding unique history.

### Item-by-item

**1 — Does it still build and start? UNMEASURED.**
Not run. `npm install && npm run build` across the 20 distinct app manifests needs network, roughly
1.5–4 GB of `node_modules` per Next app, and 3–10 minutes each: **2–4 agent-hours and 20–40 GB of disk**,
before counting failures to diagnose. Douglas is right that it changes verdicts, so it is now
**workstream 0** and **step 0 of the per-app recipe** — the first thing done to any app, so every later
failure is attributable. An app that does not build today gets ARCHIVE or a rebuild decision, never
CONVERGE.

**2 — Secrets and advisories. PARTLY MEASURED; the risk is lower than assumed.**

- **Zero tracked dotenv files across all 64 project roots.** Command: `git ls-files` per repository,
  filtered to a dotenv path, excluding `*.example`, `*.sample` and `*.template`. Empty output.
- **`.gitleaks.toml` present in 35 roots**, with a gitleaks GitHub Actions workflow in the scanned
  repositories, so the scan is already wired rather than needing adding.
- **`npm audit`: UNMEASURED.** It requires the installs from item 1; it comes free once workstream 0 runs.
- **Hardcoded keys: UNMEASURED by pattern here**, deliberately. The instruction is to report counts and
  severities only and never a secret's surrounding line; a grep that finds one puts it in this transcript.
  The correct tool is gitleaks per repository, whose report is written to a file and read by Douglas.

This item was nominated to outrank everything aesthetic. **On the evidence it does not, because there is
currently nothing to fix:** no committed dotenv file exists and the scanner is already installed. It stays
ahead of the floor in the ranking only as workstream 0's second half, where the installs make `npm audit`
free.

**3 — Dependency rot as a number. PARTLY MEASURED.**
Current versions are frozen exactly in [Reconciling the count](#reconciling-the-count) and the roster.
**Majors-behind is unmeasured**, because it requires the current published major of each package from the
npm registry, which needs network in the session that runs it. Cost: minutes, not hours — one
`npm outdated` per app after workstream 0's install. What is measurable now is the **spread**, which is
the actionable number. Next spans majors 14–16; React 18–19; TypeScript 5.6–7.0; Tailwind 3–4; Vite 6–8.
**Exactly one app is behind on three slots at once — `legal-solutions-website` (Next 14, React 18,
Tailwind 3)** — and it is the only rebuild-versus-migrate candidate on rot grounds. No app is three majors
behind on everything, so no app's verdict changes to ARCHIVE from rot alone.

**4 — Every unpinned dependency. MEASURED. The answer is one manifest.**
`grep -rl ': *"\(latest\|\*\|next\)"' --include=package.json` over the tree, excluding `node_modules`,
`.next*` and `.tmp-*`, returns **exactly one file: `agent-harness/arch-gp-demo/package.json`, where all 11
dependencies are `"latest"`.** No other app carries a floating specifier. This narrows workstream 3 from a
sweep to a single fix, and that fix is filed as intake against `agent-harness`.

**5 — Runtime versions. MEASURED, and the spread is the defect.**
Node floors in use: `>=18` (`daily-brief`), `>=20` (`landry-sandbox`), `>=22` (`base-flight-finder`,
`docket`, `vault-review-mobile`), `22.x` (`berkeley-house`), `>=24` (`arch-gp-app`), `>=24 <25`
(`obsidian-vault-mirror-metropolis`). **Only 3 roots carry a `.nvmrc`** — `berkeley-house`, `docket`,
`vault-review-mobile` — all pinning 22. **12 roots declare any runtime at all; the other 35 declare none.**
Python: `3.12` (`skill-pathways`), `3.12.8` (metropolis), `3.13` (`schema-studio`), `>=3.13,<3.14`
(`project-hady`). **Nothing pinned here is end-of-life**, because Node 18 appears as a *floor* rather than
a pin and so permits a current runtime — but `daily-brief`'s declared floor is a dead release and should be
raised. New workstream: one Node major and one Python minor, declared in `.nvmrc` and `.python-version` in
every app.

**6 — Last touched, and whether it was finished. MEASURED, and the freshness signal is unusable.**
`git log -1 --format=%cs` per repository: **the oldest last-commit date in the entire tree is 2026-08-15,
and 28 roots share 2026-08-17** — a mass harness install flattened the history. **No app is stale by date,
and date cannot identify an abandoned app here.** The usable half of this item is the README: **23 roots
have no `README.md` at all**, including the app units ~~`idetc-writing-ide`~~ (struck 2026-09-27: stage 1 of its repair wrote one, with a real start command), `kelly-uniforms-business`,
`legal-solutions-website`, `slides-workbench`, `saved-posts`, `drive-organizer`, `berkeley-research`,
`compsci-260b`, `shopping-search`, `study-system` and `text-to-spaceship`. An app with no README and no
stated start command cannot be handed to an agent, which makes this a prerequisite, not a nicety.

**7 — Duplication across apps. MEASURED, and it does not justify a shared package.**
MD5 of every tracked application source file (`.js`, `.mjs`, `.cjs`, `.ts`, `.tsx`, `.css`) across every
repository, excluding `node_modules`, `.min.js` and `.agents/` — the shared harness vendors byte-identical
skill packages into every repository, and counting those produced a false 282-group result on the first
run. **Of 2,222 tracked application source files, exactly one content hash appears in three or more app
roots, and it is `postcss.config.mjs`.** Byte-level duplication across these apps is effectively zero, so
**a shared component or utility package is not justified by this evidence and is not added to the plan.**

*Honest limit:* near-duplicate code — same logic, different formatting or names — is **unmeasured**. It
needs a similarity tool such as `jscpd` across 2,222 files: roughly 1–2 agent-hours plus triage.
Recommended as a cheap follow-up, not as a workstream.

```bash
# corrected duplication measurement
for d in <app roots>; do (cd "$d" && git ls-files | grep -E '\.(js|mjs|cjs|ts|tsx|css)$' \
  | while read -r f; do printf '%s  %s\n' "$(md5sum "$f"|cut -d' ' -f1)" "$d/$f"; done); done \
  | grep -v '\.agents/' | grep -viE 'node_modules|/vendor/|\.min\.js' \
  | awk '{h=$1; sub(/^[^ ]+  /,""); split($0,a,"/"); print h"\t"a[1]}' | sort -u \
  | awk -F'\t' '{c[$1]++} END{for(k in c) if(c[k]>=3) n++; print n+0}'
```

**8 — What data each app owns, and where. PARTLY MEASURED.**
Tracked database files: **`text-to-spaceship` 1, `project-hady` 1; every other app tracks none.**
**Corrected 2026-09-27: `shopping-search` tracks zero**, not 27 — `git ls-files` finds no `.db` or
`.sqlite` in it, and none exists on disk outside the gitignored browser profile. **35 roots carry a `data-manifest.yaml`**, which is where
the answer is supposed to live. **UNMEASURED:** the untracked, gitignored runtime data each app writes —
`.local` caches, generated JSON, SQLite files outside git — which is exactly the data a migration can
destroy. Measuring it means reading 35 `data-manifest.yaml` files and reconciling each against its
`.gitignore` and its on-disk state: **2–3 agent-hours.** Until that is done, **no app may enter
workstream 13 (framework convergence)**, because the regression the brief most fears is losing a SQLite
file nobody listed. This is now a hard precedence.

**9 — Accessibility measured, not assumed. UNMEASURED, and this is the most valuable unmeasured item.**
The existing figures — `@axe-core/playwright` in 5 apps, `@playwright/test` in 13, `:focus-visible` absent
from 6 — are **package and grep counts, not defect counts.** A real violation count needs each app running
and axe driven against its primary surface: it depends on workstream 0, then roughly **0.25 agent-hours
per app, 10–12 hours across the 38 worked units**. Douglas is right that this number is what makes the
accessibility workstream rankable. **Until it exists, workstream 6's rank is argued from a defect class —
six apps a keyboard user cannot operate — rather than from a count**, and this specification says so
rather than inventing the count.

**10 — One performance number per app. Metric defined; runtime value UNMEASURED.**
The metric is **total bytes of CSS and JavaScript the primary surface ships, uncompressed**, because it
applies uniformly to a Next app, a vanilla page and a Python-served static file, and it is measurable
without a browser. The styling half is already measured in every roster row and in Appendix A's scan: it
ranges from **4 KB (`contact-form-caller`) to 4.1 MB (`compsci-260b`)**, a factor of a thousand. The
JavaScript half and any runtime metric — LCP, INP, a Lighthouse score — are **unmeasured** and need
workstream 0 plus a browser run: roughly **0.25 agent-hours per app**. Recorded as a floor-item candidate,
not yet a floor item, because a threshold set without the distribution is a guess.

**11 — A front door. Not a measurement; it is the highest-value deliverable in the plan.**
There is no index of these apps. Measured: **47 app units, 0 pages listing them.** One page — every app,
what it does, whether it currently runs, and a link — makes the other 46 discoverable, including to
Douglas. It is promoted to **workstream 1**, above the floor and above every migration, for three reasons:
it is the only deliverable whose value does not depend on any other workstream finishing; its "whether it
currently runs" column is workstream 0's output, so the two share one measurement; and it is the artifact
that makes this program's progress visible without reading this document. **Its own verdict: build it
new**, in the target stack, as the reference application's first real consumer. Whether it extends
`mission-control` instead is OD-7.

**12 — Which apps should be shareable but are not. Widened; the answer is a decision.**
Measured: **14 app units are reachable only at `localhost`**, and the nine `python -m http.server` ones
additionally have no authentication, no TLS and no durable storage. Widened past those nine as instructed,
the apps where **a second person demonstrably exists today** are `sarah-stuff` (Sarah), `client-portal`
(customers, per its own `PRODUCT.md`), `legal-doc-studio` (clients, per its own README),
`anna-maria-mcgowan-site` (Anna Maria), `jars-of-clay` (prospects, per its own README) and
`second-brain-capsule` (whose entire product claim is that a stranger can stand it up). **That list, not
current hosting, decides whether hosting work is in scope per app** — which is OD-3, now widened from nine
apps to all 47.

### Revised ranking

Four items enter and two move, on the evidence above. Everything below position 10 keeps its earlier rank
and defence, shifted down.

| # | Workstream | Change | Defence |
|---|---|---|---|
| 0 | **Prove every app builds and starts** | **new, and first** | You cannot plan a migration for an app you have not proven works, and its output feeds items 2, 3, 9, 10 and 11 at no extra cost. An app that fails here gets ARCHIVE, which removes it from every later denominator |
| 1 | **The front door** | **new, promoted from item 11** | The only deliverable whose value does not wait on another workstream, and the one that makes 46 apps discoverable to their own owner |
| 2 | **Version control for the 3 unversioned apps** | was 1 | Unchanged reasoning; second now because 0 and 1 are cheaper and inform more |
| 3 | **README with a start command for the 23 roots that have none** | **new** | An app an agent cannot start is an app no lane can repair; the cheapest possible unblock, and workstream 0's prerequisite in practice |
| 4 | **Archive and retire** | was 2 | Unchanged, now with the five-verdict vocabulary |
| 5 | **One Node major and one Python minor, declared per app** | **new** | Four Node floors, one of them dead (`daily-brief`, `>=18`); 35 of 47 declare no runtime at all, so "works on my machine" is currently the only specification |
| 6 | **`npm audit` across every app, and gitleaks executed per repository** | was part of item 2 | Free once 0 has installed; **demoted from the nomination's "outranks everything" position because the measurement found nothing to fix** — zero tracked dotenv files and the scanner already wired in 35 roots |
| 7 | **Kill the one floating manifest** (`arch-gp-demo`) | was 3 | Narrowed from a sweep to one file by measurement; filed as intake against `agent-harness` |
| 8 | **Close the two-major drift** (`legal-solutions-website`) | was 4 | Unchanged, and now confirmed as the only app behind on three slots |
| 9 | **Inventory every app's runtime data before any migration** | **new, and a hard gate** | The regression that actually costs him something is a lost SQLite file; 3 apps track database files and the untracked runtime data is unmeasured |
| 10 | **The token layer (B1)** | was 5 | Unchanged defence; still the item that makes every later item cheaper |
| 11+ | focus+axe, motion, dark mode, `!important`, TypeScript, Next majors, components, vanilla→Next, hosting, outlier triage | shifted down by ten | Unchanged defences |

**Dropped on the evidence:** a shared component or utility package. Item 7's corrected measurement found
one duplicated file across 2,222, so the workstream has no evidence behind it. Near-duplicate measurement
is recommended as a 1–2 hour follow-up that could reinstate it.

### Recipe change

Step 0 of [the per-app recipe](#the-per-app-recipe) is replaced by:

> **0. Prove it works before touching it.** In the app's own checkout, run its install, its build and its
> start command, open its primary surface, and paste the result into `LOG.md` as `BEFORE`. If it does not
> build or start, **stop**: record the failure, propose ARCHIVE or a rebuild, and escalate. Do not repair
> an app whose working state was never established — every later failure then becomes unattributable,
> which is the exact cost this step buys off. Only then enter isolation:
> `git -C <app> worktree add <worktrees-root>/<app>/repair -b agent/<app>-repair <default-branch>`. If the
> app has no git repository, `git init` and commit the tree as-is as the rollback point first.

### New acceptance criteria

- [ ] **AC-P16 — Every app is proven to build and start, or is ARCHIVE.** Action: read each app's `LOG.md`
      `BEFORE` block. Expected: one per non-ARCHIVE row, with pasted output.
- [ ] **AC-P17 — A front door exists and is accurate.** Action: open it. Expected: every roster row
      appears with its purpose, its current run status and a working link, and the count on the page
      equals the roster count.
- [ ] **AC-P18 — Every app declares its runtime.** Action: check for `.nvmrc` and, where Python is used,
      `.python-version`. Expected: one per non-ARCHIVE row, all naming the same major.
- [ ] **AC-P19 — Every app has a README naming its start command.** Action: grep each README for the
      command. Expected: one per non-ARCHIVE row. Today: 23 roots have no README at all.
- [ ] **AC-P20 — Every app's runtime data is inventoried before it is migrated.** Action: read each
      `data-manifest.yaml` and confirm every path it names exists and is either tracked or listed as
      external. Expected: complete for every app before it enters framework convergence.
- [ ] **AC-P21 — `npm audit` reports zero critical advisories, or each is recorded with a reason.**
      Action: `npm audit --audit-level=critical` per app after install. Expected: clean, or an entry in
      that app's `LOG.md`. Report counts and severities only.
- [ ] **AC-P22 — Accessibility is counted, not assumed.** Action: axe against every app that starts.
      Expected: a violation count per app recorded in its `LOG.md`, and the accessibility workstream's
      rank re-argued from those counts.

### New open decision

- [ ] **OD-7 — Where does the front door live?**
      **A:** extend `mission-control`, which already owns port and app operations for this machine and
      already carries 53 custom properties and a dark-mode block.
      **B:** build app 48, in the target stack, as the reference application's first real consumer.
      **Decides it:** whether the front door must be reachable from a phone. If yes, B, because
      `mission-control` is a local Windows operations surface and hosting it would mean hosting the
      operations tool. If it is a desktop surface only, A, and the program adds no new app.
      **Recommendation: B**, because item 12's list of real second users means at least six of these apps
      will be hosted, and a front door that cannot reach them is a front door to nothing.

### What I did not get to

Named precisely, as instructed. Each is unmeasured, never estimated.

| Item | Why not | Cost to finish |
|---|---|---|
| 1 build-and-start across 20 manifests | Needs network installs and 20–40 GB of disk, past this lane's 80-minute ceiling | 2–4 agent-hours |
| 2 `npm audit`, and gitleaks *executed* per repository | Depends on item 1's installs; gitleaks was confirmed *installed*, not *run* | 1 agent-hour after item 1 |
| 3 majors-behind per package | Needs the npm registry | 0.5 agent-hours after item 1 |
| 8 untracked runtime data per app | Needs 35 `data-manifest.yaml` files reconciled against `.gitignore` and disk | 2–3 agent-hours |
| 9 axe violation counts | Needs every app running | 10–12 agent-hours across 38 units |
| 10 runtime performance value | Needs every app running in a browser; the static byte metric is already measured | 8–10 agent-hours |
| 7 near-duplicate code | Needs a similarity tool across 2,222 files; the exact-duplicate measurement is complete and returned one group | 1–2 agent-hours |
| Custom easing coverage | Noted as unmeasured in Appendix A before this addendum | 0.25 agent-hours |

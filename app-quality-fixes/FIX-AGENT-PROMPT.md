# FIX-AGENT PROMPT — App-quality pass for Doug's design apps

> **What this is.** A reusable Claude Code sub-agent brief ("the framework"). Instantiate it once per
> target app (fill the `{{…}}` slots from the table at the bottom) and dispatch all instances in
> parallel via the Agent tool. Each agent reads the full app-design research corpus + runs the
> **impeccable** anti-slop detector, audits ONE app against it, applies fixes on an isolated branch,
> verifies, and reports. **No merges, no deploys** — Doug reviews and merges.
>
> Round 1 = the existing corpus + the impeccable skill + the motion/interaction specs (all below).
> All of it is rolled in; no slot is left empty.

---

## ROLE

You are an **app-quality fix agent**. You improve ONE existing app so it stops reading as
"vibe-coded" / AI-generated and instead reads as deliberately designed — while fixing obvious
correctness, responsive, and accessibility defects you encounter. Precise, verify, stay in scope.

## STEP 0 — READ THE RESEARCH CORPUS FIRST (do not skip)

This is the rubric you are applying. Read in this order:

1. **Anti-vibe-codisms (highest authority — Doug flagged these personally):**
   `C:\Users\dougl\.claude\projects\C--Users-dougl-OneDrive-Documents-General-Claude\memory\feedback_ai_isms.md`
   (Condensed inline under THE STANDARD below — read the file too for full rationale & sources.)
2. **Motion / interaction defaults (the new research):**
   `C:\Users\dougl\.claude\projects\C--Users-dougl-OneDrive-Documents-General-Claude\memory\reference_motion_interaction_defaults.md`
   (Concrete numbers reproduced under POLISH SPECS below.)
3. **The impeccable skill — your primary tool (see STEP 0.5).** Skill dir:
   `C:\Users\dougl\.claude\skills\impeccable\` — read `SKILL.md` + the relevant `reference\*.md` playbooks.
4. **App-aesthetics field guide** (`app-aesthetics-guide`): `G:\My Drive\UC Berkeley\Research\Claude Research Folder\app-aesthetics-guide\`
   — 10 sections on the tells of vibe-coded *apps*. Read its index + the sections matching your target's archetype.
5. **Web-design field guide** (`web-design-guide`): `G:\My Drive\UC Berkeley\Research\Claude Research Folder\web-design-guide\`.

> If a Drive path is slow/missing, fall back to the same-named GitHub repo under `douglaspmcgowan/…`.

## STEP 0.5 — USE THE IMPECCABLE SKILL (it does the heavy lifting)

`impeccable` (pbakaus/impeccable) is built for product/app UI — exactly your target's category. It ships
real reference playbooks AND a static + browser anti-slop **detector** that flags side-stripe borders,
gradient text, glassmorphism, eyebrow-on-every-section, AI-purple, etc.

- **Run the detector** over the target and let its findings seed your audit. Read
  `C:\Users\dougl\.claude\skills\impeccable\SKILL.md` for the exact CLI/flags, then run it — e.g.
  `node "C:\Users\dougl\.claude\skills\impeccable\scripts\detect.mjs" <file-or-glob-or-url>`
  (entry also at `scripts\detector\cli\main.mjs`; `npx impeccable` may work if wired). If you can serve the
  app, point the detector at the running URL for the browser engine; otherwise run it over the HTML/CSS files.
- **Read the playbooks** you'll act on: `reference\audit.md`, `reference\polish.md`, `reference\harden.md`,
  `reference\animate.md`, `reference\interaction-design.md`, plus `layout.md` / `colorize.md` / `typeset.md`
  as relevant. (You may also invoke the skill via the Skill tool — `impeccable` with sub-command `audit`
  then `polish`/`harden` — if it's available in your context; if not, the files above are the source.)
- **Scope note:** `design-taste` is the sibling skill for *landing pages/portfolios* only — use it ONLY if a
  target is a marketing page, not for app/tool/dashboard UI.

## THE STANDARD — condensed anti-vibe-codisms

**Core principle:** the tell is the *unintentional default*, not the technique. Any one of these is fine
inside a deliberate, coherent design language; it's an AI-ism when it's the reflexive default with no
rationale. When unsure, do the opposite of the LLM default. **Do NOT "fix" choices that are already
deliberate and coherent.**

- **Subtitles/marks:** no one-sentence descriptive subtitle under a title/hero/card heading; no
  accent-highlight `<span class="mark">` on a few words; no serif-italic on one accent word.
- **Color/effects:** no purple/indigo→blue "VibeCode" gradients; no gradient-pill CTAs, oversized colored
  glows, colored box-shadows, or glassmorphism as decoration. Dark mode must be near-neutral (R≈G≈B:
  `#0d0d0d`/`#141414`/`#1a1a1a`), NOT blue/navy-tinted; faint warm cast OK, cool cast is a tell.
- **Type:** don't default to Inter/Geist/Space Grotesk/Instrument Serif/DM Sans/Plus Jakarta/Syne/Fraunces —
  pick a deliberate display+body pairing. **Monospace ONLY** for code, IDs/hashes/refs, `<kbd>`, file
  paths/shell, and literal tokens — never on labels, nav, buttons, headings, badges, stats, or body.
- **Layout/components:** not everything centered; avoid card-nesting + uniform 16px-radius identical-padding
  cards; avoid 3-across identical icon-top feature cards; avoid filler "1·2·3" steps and stat banners.
- **Icons:** **never emoji as icons/bullets** — inline SVG only. No `border-left: 3px solid var(--accent)`
  strip on every list item/card — use tints/row hierarchy.
- **Copy:** no vague aspirational headlines / generic superlative+hedging padding. Concrete, founder-voice.
- **Imagery:** real screenshots/photos, not stock "diverse team at laptop" or plastic AI illustration.
- **Motion:** no purposeless uniform fade-ins; motion signals state/directs attention; every interactive
  element gets hover + `:focus-visible`; honor `prefers-reduced-motion`.

## POLISH SPECS — concrete numbers (from the motion/interaction research)

- **Icon buttons (Cursor/Linear/Raycast):** icon-only at rest (transparent bg, muted glyph), faint chrome
  on hover — dark UIs `rgba(255,255,255,.06)` hover / `.10` active. Lock every toolbar control to ONE box
  on a baseline (e.g. 28px box, 16px glyph, 6px radius). Press = `transform: scale(.96)`. Icon-only buttons
  MUST have `title`/`aria-label`. Gate hover with `@media (hover:hover)`.
- **Motion:** enter/appear → `ease-out` `cubic-bezier(.16,1,.3,1)`; moving on-screen → `ease-in-out`; hover
  bg → plain `ease`. Durations: feedback 80–150ms; state change (menu/tooltip/toggle) 200–300ms; layout
  300–500ms; >400ms feedback feels laggy; <200ms feels instant; exit ≈75% of enter. Animate ONLY
  `transform`/`opacity` (never width/height/top/left). No bounce/elastic.
- **Numbers:** `font-variant-numeric: tabular-nums` on the sans font — never a mono font.
- **Corner radius:** nested rule `inner = max(0, outer − padding)`. buttons/inputs 6–8px, cards/panels
  8–12px, app shell/modal 10–14px. One scale.
- **States:** every interactive element needs default/hover/focus/active/disabled (+loading/error/success on
  inputs). Hover ≠ focus. Focus ring via `:focus-visible` + `box-shadow` (respects radius), e.g.
  `box-shadow:0 0 0 2px var(--bg),0 0 0 3px var(--accent)`. Always ship
  `@media (prefers-reduced-motion: reduce)` killing transitions/transforms.

## STEP 1 — AUDIT (before changing anything)

1. Detect the stack (single-file HTML / vanilla JS / Vite+React / Next.js …) via `package.json`,
   `index.html`, entry files. Note where styling lives.
2. Run the impeccable detector + walk the UI. Produce an **issue list**: each item =
   `{rule violated, file:line, current → proposed, severity}`. Separate **design/anti-vibe** from
   **correctness/responsive/a11y**.
3. Rank by impact. Skip anything already deliberate and coherent.

## STEP 2 — FIX

- Apply ranked fixes; smallest change that removes the tell. Keep the app's intent and content — you are
  **de-slopping + hardening, not redesigning from scratch** and not rewriting copy wholesale.
- Also fix obvious correctness defects you hit: broken mobile/responsive layout (`100vh`→`100dvh`, overflow
  clipping), missing hover/focus states, console errors, broken links, missing alt/labels/contrast.
- **Read before Write** on every file (Doug edits files outside sessions — never blind-overwrite).

## STEP 3 — VERIFY (no "it should work")

- If it runs: start the dev server (or open the HTML), then preview MCP — `preview_start`, `preview_resize`
  to **375px** and a desktop width, `preview_console_logs` (must be clean), `preview_snapshot`, and
  `preview_screenshot` before/after on changed screens. Re-run the impeccable detector to confirm flags cleared.
- If it genuinely can't run, trace changed paths by hand and label **UNVERIFIED** with the reason.

## CONSTRAINTS (follow exactly)

1. Work on a NEW branch **`fix/app-quality-pass`**. **Never commit to `main`, never push to `main`, never
   merge, never trigger a production deploy.** You MAY commit to your branch and push *the branch only*; then
   stop. Open a **draft PR** if the repo has a remote.
2. **Verify the repo before any commit:** run `git remote -v` and confirm origin is the EXPECTED
   `douglaspmcgowan/{{REPO}}`. (Critical for dfm-kg-agent-v2: if remote shows `dfm-kg-agent` v1, STOP — you're
   in the wrong git root.)
3. **Scope:** ONLY `{{PROJECT_NAME}}` at `{{LOCAL_PATH}}`. No other repos/branches/CI/infra; no dep bumps
   beyond what a fix needs; no feature work.
4. **Secrets:** never read, print, log, or commit `.env*`, API keys, tokens, or `node_modules`. Name an env
   var if needed; never reveal its value.
5. Match surrounding code idiom, comment density, naming. Comment only non-obvious WHY.

## OUTPUT CONTRACT (final message = structured data, not chat)

```
## {{PROJECT_NAME}} — app-quality pass
1. Stack & where styling lives: …
2. impeccable detector findings (raw): …
3. Audit — design/anti-vibe issues (rule · file:line · before→after · severity): …
4. Audit — correctness/responsive/a11y issues: …
5. Fixes applied (file · change summary): …
6. Verification: commands + observations (console clean? mobile+desktop render? detector re-run?) OR UNVERIFIED — <reason>
7. Branch + git status (committed? branch pushed? draft PR url?): …
8. Before/after screenshots: <paths>
9. Left unfixed / needs Doug (one line each): …
```

---

## INSTANTIATION TABLE — the 6 targets (one agent each)

| {{PROJECT_NAME}} | {{REPO}} | {{LOCAL_PATH}} (clone if absent) | Stack notes |
|---|---|---|---|
| DPM Agent Kit | `dpm-agent-kit` (public) | `C:\Users\dougl\dpm-agent-kit` → else `gh repo clone douglaspmcgowan/dpm-agent-kit` | Scrubbed agentic-coding setup + **interactive HTML explorables** (the UI surface to audit). |
| Conference Tracker | `conference-tracker` (public) | `C:\Users\dougl\Projects\conference-tracker` | Deadline/location tracker; calendar + cards + table + map views. |
| DFM KG Agent v2 | `dfm-kg-agent-v2` (private) | `G:\My Drive\UC Berkeley\Research\dfm_scraping\dfm-kg-agent-v2` | Vite + React frontend (Modal+FastAPI backend — **frontend only** in scope). Confirm `git remote -v` = v2! |
| DFM Graph Explorer | `dfm-graph-explorer` (public) | `G:\My Drive\UC Berkeley\Research\Claude Research Folder\dfm-graph-explorer` | d3 force-graph explorer SPA (canvas+SVG, large single index.html). |
| Fellowship Tracker | `fellowship-tracker` (private) | `C:\Users\dougl\Projects\fellowship-tracker` | Fellowship application tracker (tracker archetype). |
| AI Engineering Design DB | `ai-engineering-design-db` (public) | `G:\My Drive\UC Berkeley\Research\Claude Research Folder\ai-engineering-design-db` | JSONL of 831 projects + interactive KG explorer (8,795 edges) — audit the explorer UI. |

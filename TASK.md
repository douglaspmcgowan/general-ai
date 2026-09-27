# Task

## Active goal

Give Douglas a working understanding of the web/app stack, a canonical reference for it, and a design pipeline in the harness that makes every app he builds look considered rather than generic.

## Queue

### Stack education and reference

- [x] Explain what is in the corpus for UI/IX/web design — design libraries, component registries, agent design skills, reference sources. Answered in chat 2026-09-25.
- [x] Explain the absences (Rive, Spline, Webflow, Astro, Storybook, Radix, MUI, Chakra, Bootstrap, accessibility, design research, IA) and whether each belongs in his stack. Answered in chat 2026-09-25.
- [x] Explain the stack levels and how the categories differ — language vs library vs framework vs platform vs design language. Answered in chat 2026-09-25.
- [x] Correct two mislabels Douglas caught: Lovable is a builder not hosting; Mobbin feeds the design language rather than being a dead-end tool. Answered in chat 2026-09-25.
- [x] Write the canonical catalogue of every language, library, framework, platform and system, with a slot and a verdict per entry. `WEB-STACK.md`, 2026-09-25.
- [x] Explain React plainly — what it is and what it is not — with no analogy and no worked example. Answered in chat 2026-09-25 and carried into the artifact.
- [x] For every layer, list the alternatives present in his current setup and/or in the Instagram corpus, and compare them. Answered 2026-09-25; the "your apps" column landed with the 2026-09-25 scan.
- [x] Build a visual artifact explaining each part of the stack. v1 published 2026-09-25.

### Dispatched work

- [x] Inventory what Douglas is actually using. Read-only scout returned 2026-09-25: 36 app-bearing manifests; 21 of 36 no UI library; 30 of 36 no component layer; 34 of 36 no animation; Playwright in 29; axe in 5; `DESIGN.md` in 31 repos; zero `@radix-ui/*`; `berkeley-house` on Next 16 + React 19 + Tailwind v4 + shadcn on `@base-ui/react`.
- [x] Correct the earlier claim that Radix arrives with shadcn in his tree. Corrected in chat 2026-09-25 and in the artifact's Corrections section.
- [x] Write the codex handoff prompt. `.agents/fleet-briefs/stack-audit-20260925.md`, 2026-09-25.

### Stack explainer v2 — Douglas, 2026-09-26

Douglas: "instead of outputing all the answers to all of these in chat, output the answers to the different stack stuff just thru a better version of the artifact, and then answer questions about my apps in chat". Stack taxonomy goes in the artifact; app-specific and process questions are answered in chat.

- [x] Rebuild the artifact against `DESIGN.md` and `impeccable`, carrying every expansion below. Douglas, 2026-09-26: "webstack strata still looks bad. please inspect it yourself and keep working on it until it's good. and it has all the information we've discussed in this chat." **Published v2 2026-09-26** to https://claude.ai/artifact/CkvMsycKfxKXupGYK8GYK7 — 18 sections, 16 strata, source `.local/preview/strata.html`. Verified in-browser at 1280 and at 375: 0 console errors, 0 mojibake, no horizontal overflow, charset UTF-8.
  - [x] Alternatives to React, with tradeoffs and the honest case for and against. Stratum 05, nine alternatives with a Trade line each plus a ranked migration path for the 21 vanilla apps.
  - [x] Whole-app state managers — definition, examples, server-state vs client-state split. Own section, nine tools with size and a "wrong tool when" column.
  - [x] TypeScript: the argument against, the argument for, and a decision rule. Own section, six against including the TS 7 compiler-API split that partly forces his 5.9/6/7 spread.
  - [x] Frameworks in detail, plus rendering models. Stratum 11 plus a standalone CSR/SSR/SSG/ISR/islands section.
  - [x] Styling in detail, including what actually makes an interface look good. Stratum 06 plus the ten ranked determinants, each carrying his own measured number.
  - [x] Headless primitives defined from scratch. Own section enumerating the ~30 behaviours one dropdown requires.
  - [x] Component sources, including the registry model's honest downside. Stratum 08 plus five named downsides and a mitigation.
  - [x] Motion in detail. Own section: twelve moves ranked by effect per effort, nine of them free.
  - [x] 3D and canvas — DOM vs SVG vs Canvas vs WebGL vs WebGPU. Own section plus the absolute accessibility cost and a legitimate-vs-showpiece split.
  - [x] Every remaining category. Folded into the strata rather than given separate sections.
  - [x] Compatibility view with the mechanism of each conflict. Own section, 13 rows.
  - [x] Testing narrowed to Playwright only. Douglas, 2026-09-26: "for testing, let's judt do playwright." Stratum 15 now holds Playwright and `@axe-core/playwright` only.
  - [x] Expand the second stack. Own section covering the 9 `http.server` apps, 3 FastAPI sidecars and PySide6.
- [x] Do the app audit myself rather than dispatching it. Douglas, 2026-09-26: "no, don't run it. do that audit yourself." Two CSS-measurement passes over 46 manifests plus in-browser inspection of two contrasting apps. Result in the artifact: 18/35 zero transitions, 21/35 no shadows, 20/35 no `clamp()`, 35/35 no container queries, 23/35 use `!important`. **`anna-maria-mcgowan-site` is genuinely well designed and `info-272-condense` is the bland pattern — both vanilla JS, which proves the stack is not the cause.**
- [x] Add stack review to the `review` and `design-review` skills, and build a stack-template library with a selection procedure. Landed on `agent/stack-review-capability` in `agent-harness`, commit `30d8734d6`: `.agents/design/STACK-TEMPLATES.md` (7 templates × 22 slots + an 8-question procedure) and `.agents/skills/solo-review/stack-review.md`. **Unlanded — needs Douglas to merge.**
- [x] Do builders (v0, Lovable, Bolt) do anything Claude Code cannot? Answered in chat 2026-09-26: only browser-based prompt-to-UI with a live preview and no repo.
- [x] With PRODUCT.md and SPEC.md present, does DESIGN.md still make sense? Answered in chat 2026-09-26: yes.
- [x] Give a link to v0 and say what it retrieves from and how we would pick our own retrieval set. Answered in chat 2026-09-26: https://v0.app; pinned to Next.js + React + Tailwind + shadcn on Radix + lucide plus Vercel's own docs, which is why its output is consistent and uniform. Our retrieval set is whatever the selected stack template names, and nothing else.
- [ ] Locate the codex stack-audit results. Douglas, 2026-09-26: "can you bring in the results of the agent i dispatched on codex? idk if it was on this computer or the toher." Superseded in substance by the audit done in-session, but the dispatched run has still not been found. <!-- agent: session -->

### Harness design capability — Douglas, 2026-09-26

Douglas: "basically i want to make the way things are designed in this harness in general better. let's figure that out" and "we should ahve esarch design some up with a design, produt intent and spec file. and have those reviewed and iteted on."

- [x] Review the existing design language and design skills and report how/if they need updating. Delivered 2026-09-26. Four defects found, all unfixed and listed under Blockers below.
- [x] Produce the design-pipeline proposal merging the existing design setup with the stack work. `C:\Users\dougl\Projects\agent-harness\DESIGN-PIPELINE-PROPOSAL.md` on `agent/design-pipeline-proposal`, commit `e8adc32f5`. Eight stages, three gates, six ranked gaps. **Unlanded — needs Douglas to read and rule.**
- [x] Build the v0-equivalent as a `craft` sub-command that resolves its retrieval set from the selected stack template and generates against the project's own tokens. Douglas, 2026-09-26: "ok send an agent to build the vo thing and let's make that part of craft." Landed on `agent/craft-generate` in `agent-harness`, commit `7d80272b0`, branched off `agent/stack-review-capability`: new `.agents/skills/craft/generate.md` (203 lines) plus routing rows in `craft/SKILL.md` and `design/LIBRARIES.md`, `INDEX.md` regenerated by its generator. Six refusal conditions; a literal hex, px or arbitrary spacing value in generated output is defined as a defect. Three-variant pass with an explicit must-differ vs must-not-differ split. Verifiers green before and after the edits. **Unlanded.**

### Carried over, still open

- [ ] Install a working local runtime for the downloaded Voxtral Small 24B Q4_K_M weights. The codex lane returned `outcome: succeeded / exit-zero-clean` and produced nothing. Re-run on agy. Brief: `brief-voxtral-runtime.md`.
- [ ] Audit this workstation's disk usage. All three scan jobs were killed when the prior session ended; no directory sizes obtained. Propose cleanup, delete nothing.

## Blockers

- Four harness design defects found 2026-09-26, none fixed, each needing Douglas's ruling on scope:
  1. `~/.agents/DESIGN.md` line 22 states "no design hook exists on any surface" (verified 2026-08-08). **This is now false** — `impeccable` 4.0.4 ships a post-edit design detector hook and the detector modules exist. The stale sentence actively instructs agents to skip mechanical enforcement.
  2. The impeccable detector already validates shipped `.tsx/.jsx/.html/.vue/.svelte/.astro/.css` against the `DESIGN.md` palette, radius scale, typography and contrast — and **nothing enables or runs it**. The gap is wiring, not a missing verifier.
  3. ~~`INDEX.md` names no design skill at all.~~ **Withdrawn 2026-09-26 — the claim was false.** `INDEX.md` § Canonical skills lists `craft` (line 1068), `design-review` (1072), `impeccable` (1092), `brandkit` (1055) and `hue`. The smaller true fact: the generator does not enumerate skill *sub-files*, so `craft/generate.md` and `solo-review/stack-review.md` are reachable through their SKILL.md and `design/LIBRARIES.md` but carry no INDEX row. Not a defect.
  4. `spec` SKILL.md and `impeccable` `init.md` claim the same content ("purpose, users, jobs, outcomes, non-goals, constraints") for `SPEC.md` and `PRODUCT.md` respectively. Two owners, one decision.
- `ssh systematicchaos` returns "Permission denied (publickey)" and inspecting `.ssh/` was permission-denied. syschaos work is blocked on Douglas.
- `agent-harness` local clone is 28 commits behind `origin/master`, so `Manage-Harness.ps1 -Action InstallGlobal` would overwrite the installed tree with stale content. Pull before any global install.
- **`C:\Users\dougl\Projects\agent-harness` is one shared checkout carrying ~35 worktrees, and two lanes collided in it this session.** One lane's reflog shows `checkout: moving from agent/craft-generate to agent/design-pipeline-proposal` then `reset: moving to master` while that lane was mid-edit, silently replacing its working tree; its first two edits landed on master content. It recovered by moving to its own worktree and redoing the work. Every future harness lane must be given a dedicated worktree, not the shared checkout.
- Two further harness defects found and not fixed: `design/LIBRARIES.md` carries the "Design language: GSAP Editorial AIDA" block twice, byte-identical (~25 duplicated lines every design session pays for); and `craft/SKILL.md` routes to `gallery`, which has no owner under `.agents/skills/` and exists only as a machine-local Claude skill, so a Codex or Cursor session following that row reaches nothing.

## Waiting on Douglas

- owner: Douglas — merge harness PR #1885 (fleet router operator override) and #1880 (auto-mode owner capture).
- owner: Douglas — merge corpus PR douglaspmcgowan/general-ai#17 into `master`; no agent may push or merge `master`.
- owner: Douglas — rule on `agent/stack-review-capability` (`30d8734d6`), `agent/design-pipeline-proposal` (`e8adc32f5`) and `agent/craft-generate` (`7d80272b0`), all unlanded in `agent-harness`. They stack in that order.
- owner: Douglas \u2014 delete the leftover untracked `C:\Users\dougl\Projects\agent-harness\.agents\skills\craft\generate.md` in the shared checkout. Byte-identical to the committed file; the lane's `rm` was refused by the bulk-delete security hook and then by the auto-mode classifier.
- owner: Douglas — decide whether `.agents/harness-defects/*.md` and `.agents/work/tmp/hook-plan-task*.md` are meant to be tracked. They are untracked, yet master's committed `INDEX.md` indexes them, so `Build-HarnessIndex.ps1 -Verify` reports stale in any clean checkout. Either track them, or make the generator exclude `work/tmp/`. The stack-review lane also flags one row it would push back on: it wrote Radix as the primitive throughout the templates, while the tree has zero Radix and `berkeley-house` already runs Base UI.
- owner: Douglas — decide whether to land the two stack changes recommended earlier: Astro as the content-site default, and axe-core wired into the browser verifier.
- owner: Douglas — authorize `linear` and `notion` in claude.ai connector settings. `google-workspace`, `microsoft-todo`, `obsidian` and `todoist` failed to connect this session.

## Completed evidence

- Corpus republished: 221 posts, 1,060 slides read, 247 audio tracks transcribed, 203 entity notes, zero-gap coverage table. Commit `25ec9c5`.
- `WEB-STACK.md` written 2026-09-25: 26 sections, every entry carrying a slot and a verdict.
- Stack explainer v2 published 2026-09-26 to https://claude.ai/artifact/CkvMsycKfxKXupGYK8GYK7. In-browser verification at 1280×900 and 375×812: 18 sections, 16 strata, 18 index links, 0 console errors, 0 mojibake, 0 horizontally overflowing elements, `document.characterSet` = UTF-8.

## Next verifier

`git diff --check`, then the repository verifier:
`& 'C:\Program Files\PowerShell\7\pwsh.exe' -NoProfile -NonInteractive -File "$env:USERPROFILE\.agents\tools\Manage-Harness.ps1" -Action VerifyProject -Repository .`

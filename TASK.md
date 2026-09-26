# Task

## Active goal

Give Douglas a working understanding of the web/app stack, a canonical reference for it, and a dispatched audit that tells him what to change in his own apps to stop them looking bland.

## Queue

### Stack education and reference

- [x] Explain what is in the corpus for UI/IX/web design — design libraries, component registries, agent design skills, reference sources. Answered in chat 2026-09-25.
- [x] Explain the absences (Rive, Spline, Webflow, Astro, Storybook, Radix, MUI, Chakra, Bootstrap, accessibility, design research, IA) and whether each belongs in his stack. Answered in chat 2026-09-25.
- [x] Explain the stack levels and how the categories differ — language vs library vs framework vs platform vs design language. Answered in chat 2026-09-25.
- [x] Correct two mislabels Douglas caught: Lovable is a builder not hosting; Mobbin feeds the design language rather than being a dead-end tool. Answered in chat 2026-09-25.
- [x] Write the canonical catalogue of every language, library, framework, platform and system, with a slot and a verdict per entry. `WEB-STACK.md`, 2026-09-25.
- [x] Explain React plainly — what it is and what it is not — with no analogy and no worked example. Douglas, 2026-09-25: "STOP EXPLAINING REACT BY SOME ANALOGY/EXAMPLE. EXPLAIN WHAT IT IS, IN PLAIN TERMS, NOT THROUGH SOME JARGON OR ANALOSY. WHAT IT IS AND WHAT IT DOESNT." Answered in chat 2026-09-25: definition, the five-step mechanism, the three terms, and a ten-item "what it is not" list where each entry names another slot in the stack.
- [x] For every layer, list the alternatives present in his current setup and/or in the Instagram corpus, and compare them. Douglas, 2026-09-25: "what are all fo the different verisons of this thing that is in either or both of those and then compare them for me." Answered in chat 2026-09-25: 16 layers, each with its alternatives, corpus presence and a pick. The "your apps" column is still pending the repo scan.
- [x] Build a visual artifact explaining each part of the stack, what it does, and how the parts work together. Douglas, 2026-09-25: "make a visual artifact that visually explains each part of this design stack and what it does and how it works together." Published 2026-09-25: https://claude.ai/artifact/CkvMsycKfxKXupGYK8GYK7 — 16 strata in five zones, per-stratum alternatives, slot-occupancy rules and four wiring diagrams. Source: `scratchpad/web-stack-strata.html`.

### Dispatched work

- [x] Inventory what Douglas is actually using: every app under `Projects`, its language, UI library, framework, styling, component libraries, animation, testing, and whether it has a `DESIGN.md`. Read-only scout lane returned 2026-09-25: 36 app-bearing `package.json` files; 21 of 36 have no UI framework; 30 of 36 have no component layer; 34 of 36 have no animation library; Playwright in 29; `@axe-core/playwright` in 5; `DESIGN.md` in 31 repos; zero `@radix-ui/*` tree-wide; `berkeley-house` already runs Next 16 + React 19 + Tailwind v4 + shadcn on `@base-ui/react`. Reported in chat, and folded into the audit brief as a start-from section.
- [x] Correct the earlier claim that Radix arrives with shadcn in his tree. It does not: there is zero `@radix-ui/*` anywhere, and `berkeley-house` uses `@base-ui/react`. Corrected in chat 2026-09-25.
- [ ] Rebuild the visual stack explainer against `DESIGN.md` and the `impeccable` skill. Douglas, 2026-09-25: "also your design looks awful. use the skills and rules in the harness." Version 1 at https://claude.ai/artifact/CkvMsycKfxKXupGYK8GYK7 was built without loading `impeccable` and without working from `DESIGN.md`; that was the error. Gated on his confirmation that this is the next thing to do.
- [x] Write the codex handoff prompt: audit every app touched or used in the last month, report the current stack, and recommend the best setup front and back — including a full stack overhaul where warranted — so the apps stop looking bland. Douglas, 2026-09-25: "i see lots of cool demos of components, motions, animations, other nice website features, and my apps still look bland." Written to `.agents/fleet-briefs/stack-audit-20260925.md` and reproduced verbatim in chat 2026-09-25. Five steps, six proving requirements, a 3-hour ceiling, and a gated Stage 2 for implementation.

### Carried over, still open

- [ ] Install a working local runtime for the downloaded Voxtral Small 24B Q4_K_M weights. The codex lane returned `outcome: succeeded / exit-zero-clean` and produced nothing — no `models\asr\runtime\`, no `transcribe.ps1`, no `README.md`. Re-run on agy. Brief: `brief-voxtral-runtime.md`.
- [ ] Audit this workstation's disk usage and explain what is filling C:. All three scan jobs were killed when the prior session ended; no directory sizes obtained. C: has moved from 53 GB free to 100 GB free (90%) on its own. Propose cleanup, delete nothing.

## Blockers

- None blocking. Two items above need re-dispatch rather than a decision.

## Waiting on Douglas

- owner: Douglas — merge harness PR #1885 (fleet router operator override) and #1880 (auto-mode owner capture).
- owner: Douglas — merge corpus PR douglaspmcgowan/general-ai#17 into `master`; no agent may push or merge `master`.
- owner: Douglas — decide whether to land the two stack changes recommended earlier: Astro as the content-site default in the libraries reference, and axe-core wired into the browser verifier with a `DESIGN.md` rule behind it. One dispatch once he says go.
- owner: Douglas — authorize `linear` and `notion` in claude.ai connector settings. `google-workspace`, `microsoft-todo`, `obsidian` and `todoist` failed to connect this session; blocked on: those endpoints, not on a decision.

## Completed evidence

- Corpus republished: 221 posts, 1,060 slides read, 247 audio tracks transcribed, 203 entity notes, zero-gap coverage table. Commit `25ec9c5`.
- `WEB-STACK.md` written 2026-09-25: 26 sections, every entry carrying a slot and a verdict, plus the recommended default stack and the slot-occupancy conflict rules.

## Next verifier

`git diff --check`, then the repository verifier:
`& 'C:\Program Files\PowerShell\7\pwsh.exe' -NoProfile -NonInteractive -File "$env:USERPROFILE\.agents\tools\Manage-Harness.ps1" -Action VerifyProject -Repository .`

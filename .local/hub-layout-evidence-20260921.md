# Hub-and-ring canvas evidence — 2026-09-21

## Verification

- python .local/build_social_entities.py — exit 0; generated 10 detail canvases and 6 top-canvas edges.
- python .local/check_social_rendering.py C:\Users\dougl\Projects\general-ai\.local\social-catalog-20260919\publication-dryrun — CANVASES=11 NODES=307 GROUPS=55 EDGES=43 ENTITIES=161 OUTSIDE_LINKS=21 VIOLATIONS=0.
- python -m unittest test_check_social_rendering test_publish_social_corpus from .local — 28 tests, all pass.

## Ubiquitous entities

Computed at five or more categories and listed once in the overview legend: Anthropic, ChatGPT, Claude, Claude Fable, Grok, OpenAI.

## Per-canvas table

| Canvas | Box | Nodes | Groups | Edges | Crossings |
| --- | ---: | ---: | ---: | ---: | ---: |
| Saved AI Posts.canvas | 2520x1585 | 13 | 0 | 6 | 0 |
| Agents and coding.canvas | 3180x2180 | 50 | 7 | 9 | 0 |
| AI news.canvas | 3103x2180 | 27 | 5 | 2 | 0 |
| Business.canvas | 3180x2180 | 26 | 6 | 0 | 0 |
| CAD and 3D.canvas | 3066x2180 | 23 | 5 | 0 | 0 |
| Design tools.canvas | 3180x2180 | 47 | 7 | 16 | 8 |
| Hardware.canvas | 3180x1810 | 21 | 5 | 2 | 0 |
| Research.canvas | 3180x2180 | 31 | 7 | 2 | 0 |
| Security.canvas | 3105x1810 | 36 | 4 | 4 | 0 |
| Unsorted.canvas | 1990x2180 | 13 | 4 | 0 | 0 |
| Workflows and productivity.canvas | 3180x1810 | 20 | 5 | 2 | 0 |

## PNG inspection

The overview reads as a centre category with a radial ring, with the legend and two index files separated in the top strip.
Detail canvases show a central shared-core group, hub cards facing their cluster memberships, and cluster groups distributed around the core.
The rendered preview shows no cards or groups touching; the only visible long lines are intentional edge labels, and the top canvas has no crossings.

Preview PNG: .local/preview3.png

## Not done

- The supplied brief-sc17-spatial-canvas.md and canvas_preview.py were not present on disk, so .local/canvas_preview.py was used for the required local preview.
- Git commit, push, and PR were not performed because the fleet brief explicitly forbids touching Git in this linked worktree.

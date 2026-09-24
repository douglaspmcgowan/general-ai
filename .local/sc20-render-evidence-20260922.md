# SC20 render lane evidence (2026-09-22)

## Files changed

- `.local/build_social_publication.py` — derives the confirmed count from membership data, validates exact judgement coverage, reports rejected/not-applicable counts, and renders the 2026-09-22 index date.
- `.local/build_social_entities.py` — merges the proposed Jev/local-decision card line and derives corpus/readings gates from the input data.
- `.local/test_build_social_publication.py` — regression test proving a missing confirmed-member judgement is refused.
- `S/publication-dryrun/**` — regenerated publication, entity, comparison, canvas, and manifest outputs.
- `S/classification/card-lines-v1.json` — regenerated with 39 hand-written cluster lines.
- Adjacent `*.pre-sc20b` backups were created for the two source scripts, all 399 pre-existing publication files, and the prior card-lines file.

## Verification

- `build_social_publication.py --dest S/publication-dryrun` — exit 0; `confirmed_members=206`, `judgement_records=206`, `source_notes=206`, `rejected=405`, `not_applicable=68`.
- `build_social_entities.py` — exit 0; `entity_notes=171`, `multi_pointer_entities=48`, `clusters=39`, `comparison_notes=11`, `detail_canvas_count=10`.
- `check_social_rendering.py S/publication-dryrun` — exit 0; `CANVASES=11 NODES=326 GROUPS=56 EDGES=43 ENTITIES=171 OUTSIDE_LINKS=21 VIOLATIONS=0`.
- `python -m unittest test_check_social_rendering test_publish_social_corpus test_build_social_publication` — exit 0; `Ran 29 tests`, `OK`.
- No existing test pinned `192`, `161`, or `38`; the new builder-gate test is the only test addition required.
- Regression test red/green: the new test first failed because the coverage helper did not exist; after implementation it passes and reports the missing judgement in the gate error.

## Coverage counts

- New shortcode notes: `SHORTCODES_EXPECTED 14`, `SHORTCODE_NOTES 14`, `SHORTCODES_MISSING []`.
- Entity notes for all entities named by the 14 new posts: `POST_ENTITY_NAMES 17`, `POST_ENTITY_NOTES 17`, `POST_ENTITY_NOTES_MISSING []`.
- New canonical entities versus the pre-SC20 snapshot: 10 (`Arrow 2`, `Astra for Law`, `Cursor`, `esp32`, `Laya`, `Shopify`, `TikTok Shop`, `uConsole`, `VITURE Pro 2`, `Wave`). Existing entities with new pointers, including Jev and GPT-6 Astra, also have notes.

## Cluster line audit

- Proposed line merged verbatim: `agents-and-coding/Jev and local decision models` → `Compare fixed-option cloud decisions with local inference, then verify the benchmark conditions.`
- `CARD_CLUSTERS 39`; `MISSING_CLUSTER_LINES []` across every `classification/comparisons/*.json` topic file.

## Canvas preview

- `canvas_preview.py` rendered `.local/sc20b-preview.html` and `.local/sc20b-preview.png`; the focused Agents/coding preview was also rendered to `.local/sc20b-agents-preview.png` and visually inspected.
- The focused PNG contains the `Jev and local decision models` group and its hand-written line; group boxes remain spatially separated in the preview.
- Direct top-canvas gate check: `TOP_CANVAS_CROSSINGS 0`, limit `3`, gate `True`; the full rendering gate also reports zero violations.

## Not done

- No vault write or interactive browser use occurred; headless Edge was used only for the required local PNG render. The brief explicitly forbids Git changes, so no commit, push, or PR was opened in this lane.
- The required fleet-status write was attempted but the status directory denied access; the prescribed hook-misfire filing was also attempted and reported its state directory unavailable.

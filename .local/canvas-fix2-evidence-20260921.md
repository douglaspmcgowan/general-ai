# Detail canvas category-fix evidence — 2026-09-21

Category membership uses `primary_topic` from `classification/primary-topics-v2.json`; each comparison JSON's cluster `post_ids` was checked to match that assignment before rendering. An entity belongs on a detail canvas when a `source: collection` pointer targets a post whose `primary_topic` is that canvas's category.

1. `C:/Users/dougl/AppData/Local/Programs/Python/Python313/python.exe .local/build_social_entities.py` → exit `0`; summary: `entity_notes=161`, `comparison_notes=11`, `detail_canvas_count=10`, `canvas_edges=0`.
2. `C:/Users/dougl/AppData/Local/Programs/Python/Python313/python.exe .local/check_social_rendering.py C:\Users\dougl\Projects\general-ai\.local\social-catalog-20260919\publication-dryrun` → exit `0`; summary: `CANVASES=11 NODES=286 GROUPS=42 EDGES=0 ENTITIES=161 OUTSIDE_LINKS=21 VIOLATIONS=0`.
3. `C:/Users/dougl/AppData/Local/Programs/Python/Python313/python.exe -m unittest discover -s .local -p "test_*.py"` → exit `0`; summary: `Ran 16 tests in 1.515s — OK`.
4. `git diff --check` → exit `0`; summary: no whitespace errors.

| Detail canvas | Nodes | Groups | Entity cards | Distinct category entities | Tallest group |
| --- | ---: | ---: | ---: | ---: | ---: |
| Agents and coding.canvas | 81 | 6 | 74 | 74 | 910px |
| AI news.canvas | 24 | 4 | 19 | 19 | 520px |
| Business.canvas | 17 | 4 | 12 | 12 | 390px |
| CAD and 3D.canvas | 16 | 4 | 11 | 11 | 390px |
| Design tools.canvas | 52 | 6 | 45 | 45 | 650px |
| Hardware.canvas | 14 | 4 | 9 | 9 | 390px |
| Research.canvas | 21 | 5 | 15 | 15 | 390px |
| Security.canvas | 30 | 3 | 26 | 26 | 520px |
| Unsorted.canvas | 7 | 3 | 3 | 3 | 260px |
| Workflows and productivity.canvas | 12 | 3 | 8 | 8 | 390px |

The rendering gate now rejects detail-canvas entity cards whose pointing posts are outside the canvas category, and rejects any group with height/width above 4 or height above 2400px. Unit tests cover both violations.

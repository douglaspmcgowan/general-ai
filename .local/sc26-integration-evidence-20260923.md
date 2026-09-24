# SC26 integration evidence — 2026-09-23

The SC22/SC25/SC26 staging rebuild used the accepted slide and audio captures, then rendered the entity, comparison, canvas, source-note, coverage, and DM-resource layers into the rebuilt `publication-dryrun` tree. The protected geo note remained outside the generated tree and was refused by the publisher dry-run.

- Confirmed members: 221 source notes.
- Slides: 221 slide files; 1,060 images expected and 1,060 read.
- Audio: 130 post files; 247 tracks; 83 speech/mixed tracks transcribed; 68 posts marked useful commentary.
- Coverage: 221 rows, zero unexplained gaps; pinned-comment status recorded as not reachable for the seven required IDs.
- DM packet: 11 shared posts and 6 technology links; output contains zero sender, handle, thread, timestamp, or caption fields.
- Entity/comparison/canvas rebuild: 1,307 entity notes, 11 comparison notes, 10 detail canvases; all canvas overlap/outside checks clear.
- Rendering gate: `CANVASES=11 NODES=313 GROUPS=49 EDGES=56 ENTITIES=1307 OUTSIDE_LINKS=21 VIOLATIONS=0`.
- Unit tests: 33 passed (`test_build_social_publication`, `test_check_social_rendering`, `test_publish_social_corpus`).
- Publisher dry-run: 1,151 CREATE, 297 UPDATE, 122 unchanged, 1 REFUSE (the protected geo note); geo SHA-256 unchanged before/after.
- No vault write was applied.

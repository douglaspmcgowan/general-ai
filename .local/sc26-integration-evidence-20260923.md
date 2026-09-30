# SC26 integration evidence — 2026-09-23

The SC22/SC25/SC26 staging rebuild used the accepted slide and audio captures, then rendered the entity, comparison, canvas, source-note, coverage, and DM-resource layers into the rebuilt `publication-dryrun` tree. The protected geo note remained outside the generated tree and was refused by the publisher dry-run.

- Confirmed members: 221 source notes.
- Slides: 221 slide files; 1,060 images expected and 1,060 read.
- Audio: 130 post files; 247 tracks; 83 speech/mixed tracks transcribed; 68 posts marked useful commentary.
- Coverage: 221 rows, zero unexplained gaps; pinned-comment status recorded as not reachable for the seven required IDs.
- DM packet: 11 shared posts and 6 technology links; output contains zero sender, handle, thread, timestamp, or caption fields.
- Entity admission/rebuild: 171 pre-SC26 entities retained; 201 entity notes after rebuild (30 additions, each with collection pointer count): Alibaba (4), Andreessen Horowitz Academy (1), Anduril (1), Apple MLX (1), Apple Silicon (2), Blender (6), Claude Opus 5.5 (6), Coinbase (1), Delta (1), Discord (4), Evolving AI (12), Gmail (3), Google (11), Google Drive (3), GPT-6 Sol (2), Hugging Face (4), Hyperframes (7), KnockKnock (1), Meta (4), MiMo-V2.6 Flash (1), Mirage (1), Muse (2), Notion (6), Remotion (4), Replit (1), Slack (5), Tesseract (1), Three.js (9), United (1), Xiaomi (2).
- Entity filename safety: the requested bad-name scan returned `0`.
- Rendering gate: `CANVASES=11 NODES=313 GROUPS=49 EDGES=56 ENTITIES=201 OUTSIDE_LINKS=21 VIOLATIONS=0`.
- Unit tests: 35 passed (`test_build_social_publication`, `test_check_social_rendering`, `test_publish_social_corpus`).
- Publisher dry-run (rebuilt tree pin plus prior published-tree ownership pin): 45 CREATE, 363 UPDATE, 56 unchanged, 1 REFUSE (only the protected geo note); geo SHA-256 unchanged before/after.
- No vault write was applied.

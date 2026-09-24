# SC20 new-posts evidence (2026-09-22)

| shortcode | topic | cluster | entities |
|---|---|---|---|
| Ddh9Td-DbGw | business | Service offers and monetization claims | Shopify, TikTok Shop |
| Ddirp2IlGWA | agents-and-coding | Jev and local decision models | Jev |
| DdZHdUENhZw | design-tools | Generative image and motion production | Claude |
| DctOcUANi1k | agents-and-coding | Gated or underspecified recommendations | none |
| DcQRc6NsTeL | hardware | Modular desk controls and sponsored accessories | VITURE Pro 2 |
| DdjDp4eDa2G | ai-news | Roundups that compress many claims | Anthropic, Arrow 2, Astra for Law, Claude, Gemini, GPT-6 Astra, OpenAI |
| Ddh509zOSrT | agents-and-coding | Jev and local decision models | Jev, Laya |
| DdihR_AjG94 | agents-and-coding | Jev and local decision models | Jev |
| DcNS25ssG7T | workflows-and-productivity | Promoted tools and underspecified workflows | Wave |
| Dde1U7QxV99 | hardware | Physical-device and credential boundaries | esp32, uConsole |
| DdOhd6bCdSM | agents-and-coding | Builder resources and open repositories | GitHub |
| DcADKC3Ayhf | design-tools | Agent-readable design and interface generation | Claude, Cursor |
| DdHPBuLGJWA | business | Service offers and monetization claims | Claude |
| DdgngwSDNhG | unsorted | Keyword-gated offers | none |

- Posts: 192 before → 206 after.
- Entities: 161 before → 171 after.
- Clusters: 38 before → 39 after.
- New cluster: `agents-and-coding/Jev and local decision models`.
- Proposed card lines: `classification/sc20-card-lines-proposed.json` (merged later by the owning builder lane).
- Backups: 17 pre-existing changed files copied to adjacent `.pre-sc20` paths.

## Files changed
- `browser/ai-collection-captions-raw.json`
- `browser/ai-collection-membership.json`
- `classification/ai-classification.json`
- `classification/catalog-records-v3.json`
- `classification/catalog-records-v3.md`
- `classification/primary-topics-v2.json`
- `classification/entities-v1.json`
- `classification/entity-aliases-v1.json`
- `classification/entity-mentions-v1.json`
- `classification/entity-readings-v1.json`
- `classification/judgement/batch-5.json`
- `classification/sc20-card-lines-proposed.json`
- `classification/comparisons/agents-and-coding.json`
- `classification/comparisons/business.json`
- `classification/comparisons/design-tools.json`
- `classification/comparisons/hardware.json`
- `classification/comparisons/ai-news.json`
- `classification/comparisons/workflows-and-productivity.json`
- `classification/comparisons/unsorted.json`

## Not done
- Publication builder command: `python .\\build_social_publication.py --dest <staging>\\publication-sc20-scratch`; exit code `1`, refusing with `expected 192 confirmed members, found 206`. The builder lane must update its 192-member gate before a full render.
- No vault write, browser use, or Git operation was performed.

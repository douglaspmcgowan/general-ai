## 1. Unit tests
```text
$ python -m unittest test_publish_social_corpus -v
test_apply_creates_then_updates_and_backs_up (test_publish_social_corpus.PublisherTests.test_apply_creates_then_updates_and_backs_up) ... ok
test_dry_run_writes_nothing_and_prints_exclusions (test_publish_social_corpus.PublisherTests.test_dry_run_writes_nothing_and_prints_exclusions) ... ok
test_each_excluded_vault_path_refuses_without_touching_it (test_publish_social_corpus.PublisherTests.test_each_excluded_vault_path_refuses_without_touching_it) ... ok
test_geo_note_is_never_modified_and_orphans_are_kept (test_publish_social_corpus.PublisherTests.test_geo_note_is_never_modified_and_orphans_are_kept) ... ok
test_human_authored_and_locked_targets_are_refused_byte_identical (test_publish_social_corpus.PublisherTests.test_human_authored_and_locked_targets_are_refused_byte_identical) ... ok
test_pin_mismatch_refuses (test_publish_social_corpus.PublisherTests.test_pin_mismatch_refuses) ... ok
test_report_contains_actions_and_geo_hashes (test_publish_social_corpus.PublisherTests.test_report_contains_actions_and_geo_hashes) ... ok
test_script_contains_no_file_deletion_calls (test_publish_social_corpus.PublisherTests.test_script_contains_no_file_deletion_calls) ... ok
test_source_under_excluded_vault_path_refuses_before_reading (test_publish_social_corpus.PublisherTests.test_source_under_excluded_vault_path_refuses_before_reading) ... ok
test_target_outside_corpus_folder_refuses (test_publish_social_corpus.PublisherTests.test_target_outside_corpus_folder_refuses) ... ok
test_unchanged_files_keep_mtime (test_publish_social_corpus.PublisherTests.test_unchanged_files_keep_mtime) ... ok

----------------------------------------------------------------------
Ran 11 tests in 1.244s

OK
```

## 2. Seeded fake-vault dry run
```text
$ python publish_social_corpus.py --source C:\Users\dougl\Projects\general-ai\.local\social-catalog-20260919\publication-dryrun --vault-root C:\Users\dougl\AppData\Local\Temp\social-publisher-evidence-2bf247aeb74a427a9e55cd755ad25996\fake-vault
EXCLUDED_DIR=Backups/
EXCLUDED_DIR=_review/
EXCLUDED_DIR=_evidence/
EXCLUDED_FILE=run-manifest.json
EXCLUDED_FILE=CONTRACT-EVIDENCE.md
EXCLUDED_FILE=Continuation plan and progress map.md
MODE=dry-run
SOURCE=C:\Users\dougl\Projects\general-ai\.local\social-catalog-20260919\publication-dryrun
TARGET=C:\Users\dougl\AppData\Local\Temp\social-publisher-evidence-2bf247aeb74a427a9e55cd755ad25996\fake-vault\50 Knowledge\57 Corpus\Saved AI Posts
UNCHANGED 00 - Saved AI Posts Corpus Index.md
UNCHANGED DM resources.md
UNCHANGED Images/crucix-dashboard.png
UNCHANGED Needs review.md
REFUSE Notes/a-comment-gated-glossary-of-ai-builder-terms — DcNkAaQtZwv.md: target is not authored_by: agent
REFUSE Notes/a-curated-subset-of-claude-code-design-skills — DZv8-rvkZ9E.md: locked target
UNCHANGED Notes/a-date-based-reminder-about-future-relevance — Da7zM_GpD_S.md
UNCHANGED Notes/a-fable-five-operating-system-setup-offer — DaRxpoXHFIR.md
UNCHANGED Notes/a-five-advisor-council-for-hard-decisions — DbJsAW7DbiD.md
UNCHANGED Notes/a-four-prompt-opus-and-fable-comparison — DbMSwY9iOTK.md
UNCHANGED Notes/a-hype-versus-output-ranking-of-ai-tools — DbDiZ5OlHVe.md
UNCHANGED Notes/a-personal-claim-about-ai-relevance — Db6ZvnoPGUN.md
UNCHANGED Notes/a-post-that-only-asks-fact-or-hype — DbtEt6ZC1GJ.md
UNCHANGED Notes/a-skeptical-reading-of-stateless-mcp — Db_zB2xkkZt.md
UNCHANGED Notes/a-week-of-fast-moving-ai-headlines — Db23365ACi-.md
UNCHANGED Notes/agent-booking-mistake-exposes-api-authorization-gaps — Db3IJv1AJ1Q.md
UNCHANGED Notes/agent-guide-lead-magnet — DXpxFmOHONg.md
UNCHANGED Notes/agent-strategy-gated-by-a-follow — DYIRI90gs5E.md
UNCHANGED Notes/agentic-claude-model-capability-roundup — DXTngscAIPK.md
UNCHANGED Notes/agentic-os-course-destination — Da_Khm4ARLh.md
UNCHANGED Notes/ai-generated-livestream-renders-episodes-ahead-of-playback — DcoxK0nIJa0.md
UNCHANGED Notes/ai-news-recap-adds-claims-about-agents-and-media — DdD5JcjgQ8s.md
UNCHANGED Notes/animation-resource-giveaway-for-figma-users — DWoYaIxDWJD.md
UNCHANGED Notes/anonymous-ox-alpha-model-claims-and-access-links — DcTaQR3APjQ.md
UNCHANGED Notes/anthropic-s-collection-of-claude-powered-objects — Dc3f2-UoHWf.md
UNCHANGED Notes/anthropic-s-startup-guide-mention-without-a-link — DcbthMGn_bu.md
UNCHANGED Notes/architecture-file-records-decisions-agents-cannot-infer — DdR5eAPOfT6.md
UNCHANGED Notes/astra-experiments-across-games-worlds-and-figma — Dc8lPnHDjXC.md
UNCHANGED Notes/autonomous-decision-tree-pattern-teaser — DcOCgBkNNjK.md
UNCHANGED Notes/base-s-knowledge-graph-context-loading-pitch — DcbFunokXyI.md
UNCHANGED Notes/bedroom-ready-ai-application-infrastructure-stack — DVNcIoBgH9Q.md
UNCHANGED Notes/bilevel-loops-promised-as-a-fivefold-upgrade — DbjLy_tormR.md
UNCHANGED Notes/blueprint-promises-a-prompt-to-build-workflow — DdKmOKvDEIe.md
UNCHANGED Notes/bolt-forge-advertises-expanded-model-usage-limits — DdTs3PIpq3L.md
UNCHANGED Notes/building-an-mcp-host-around-multiple-servers — Dbhdx66GL3O.md
UNCHANGED Notes/cache-to-cache-communication-skips-text-between-models — DdatXCRmVwW.md
UNCHANGED Notes/case-studies-for-less-uniform-websites — DYCIEb8MLKU.md
UNCHANGED Notes/chatbot-assisted-personal-data-cleanup — DYWm6yygPWm.md
UNCHANGED Notes/checklist-for-making-vibecoded-websites-credible — DcoBxsSodtT.md
UNCHANGED Notes/claude-assisted-breach-story-claims-a-dramatic-chain — DdcK88DD-IR.md
UNCHANGED Notes/claude-built-bluetooth-finder-for-a-managed-phone — DbqRmHYjfyD.md
UNCHANGED Notes/claude-code-guide-behind-an-engagement-gate — DcRENuwpjpk.md
UNCHANGED Notes/claude-code-session-to-session-handoffs — DbxTRFJBpzd.md
UNCHANGED Notes/claude-code-workflow-for-web-design — DblU1r_HA5p.md
UNCHANGED Notes/claude-design-access-workaround-teaser — DYC1yvhsckC.md
UNCHANGED Notes/claude-loops-replacing-manual-prompting — DZXsQkKgEeQ.md
UNCHANGED Notes/claude-plugins-skills-and-mcp-starter-set — DZkt4AxCTfJ.md
UNCHANGED Notes/claude-second-brain-skill-teaser — DXxGZjsD_PH.md
UNCHANGED Notes/claude-skills-for-end-to-end-interface-design — DZtuV9Bk5GZ.md
UNCHANGED Notes/codex-and-claude-guide-teaser-requires-a-comment — DdappS3nEtK.md
UNCHANGED Notes/command-line-tools-inside-claude-code — DXjlj-GDXBJ.md
UNCHANGED Notes/comparing-sol-and-fable-on-coding-economics — DastBeBAMB_.md
UNCHANGED Notes/component-library-teaser-for-developers — DXtgNKPEjs7.md
UNCHANGED Notes/computer-vision-reads-poker-tells — Dapvu1TgMX8.md
UNCHANGED Notes/context-graph-as-the-post-swarm-product — Dc05tndxpWt.md
UNCHANGED Notes/conversational-product-building-pitch — DXh-ACgk-f0.md
UNCHANGED Notes/creative-developer-projects-show-small-experiments-shipping — DcuI3KiDuyu.md
UNCHANGED Notes/crucix-local-osint-intelligence-terminal — DbQyH2NBc7C.md
UNCHANGED Notes/day-one-claude-project-showcase — DZZ-FWADu5_.md
UNCHANGED Notes/deepseek-v4-flash-pricing-and-benchmark-pitch — Dbirg1tGZXJ.md
UNCHANGED Notes/designer-made-ui-library-for-ai-prompts — DcPgGapgaJG.md
UNCHANGED Notes/designer-made-ui-library-supplies-prompts-to-ai — DczqUuMgOk2.md
UNCHANGED Notes/designer-oriented-claude-skill-shortlist — DXg6gAVjKwF.md
UNCHANGED Notes/developer-decision-fatigue-meme — DcL1SNXIt6A.md
UNCHANGED Notes/discounted-api-proxy-underground-economy — DYhR9kvDXKz.md
UNCHANGED Notes/early-claude-fable-demos-showcase-rapid-browser-builds — DcyTLjagPxg.md
UNCHANGED Notes/early-knowledge-graph-implementation-teaser — DcHG2kPtZZG.md
UNCHANGED Notes/editable-canva-layers-from-ai-posters — DXs9baSDcG6.md
UNCHANGED Notes/editable-code-based-image-generation-with-reinforcement-learning — DceUGnuh-KA.md
UNCHANGED Notes/eight-frontier-ai-developments-from-july — DbD_eQ2EhbF.md
UNCHANGED Notes/eli5-visual-explainer-workflow-for-claude-code — DcY8rf9jUY7.md
UNCHANGED Notes/entrepreneurship-meme-without-substance — DYezDRbqEYJ.md
UNCHANGED Notes/execute-code-harness-versus-mcp-token-study — Dcd5smMHH8T.md
UNCHANGED Notes/five-browser-resources-for-practical-design-work — DcjDy50DXp4.md
UNCHANGED Notes/five-claude-skills-for-faster-building — DX1skMrlTJL.md
UNCHANGED Notes/five-psychology-lessons-framed-through-claude — DaxObZGACq6.md
UNCHANGED Notes/folder-versus-agentic-system-provocation — DbwnCJqRtXJ.md
UNCHANGED Notes/font-references-for-creative-project-work — DbLQJHKgblS.md
UNCHANGED Notes/frame-based-scroll-animation-production-pipeline — DW7lN7sj2ow.md
UNCHANGED Notes/framer-chimes-and-parallax-animation-tutorial — DcmbRpjsRB4.md
UNCHANGED Notes/frontier-planning-turns-cheap-models-into-executors — Db08WMRlZc5.md
UNCHANGED Notes/fusion-axis-combines-numpad-trackpad-and-controls — DcwhNwfsgnZ.md
UNCHANGED Notes/gbp-management-income-claim-uses-a-personal-results-disclaimer — DdXXo_Bll7v.md
UNCHANGED Notes/gemini-animated-logo-email-tactic — DXs4k6nD3V6.md
UNCHANGED Notes/genjutsu-s-performance-preserving-video-transformation — Dc1kFA-gFa_.md
UNCHANGED Notes/geospy-style-visual-geolocation-from-ordinary-photos — Dc3YS5Ush9I.md
UNCHANGED Notes/gesture-controls-for-ai-coding-agent-prototypes — DcdtNz1DgGL.md
UNCHANGED Notes/google-s-canva-challenge-teaser — Dc1h11QDhc4.md
UNCHANGED Notes/gpt-6-astra-as-a-computer-operating-agent — Dc1qHoaAeeC.md
UNCHANGED Notes/gpt-image-2-creative-showcase-claims — DXery6FkoU4.md
UNCHANGED Notes/graph-debugging-rant-without-the-diagnosis — DcTIPKyt7Am.md
UNCHANGED Notes/graph-theory-turns-rubiks-cube-states-into-a-network — Ddd9mmFDd1d.md
UNCHANGED Notes/grok-bot-as-a-team-of-specialized-agents — DcY1-eIEriY.md
UNCHANGED Notes/grok-bot-research-desk-for-trading-analysis — DcvuQQcjEPD.md
UNCHANGED Notes/grok-bot-s-shared-login-blast-radius — DcHPKO-gQLs.md
UNCHANGED Notes/hands-replace-the-mouse-in-a-gesture-interface — Db--miYgE93.md
UNCHANGED Notes/hermes-agent-turns-imessage-into-delegated-work — Dcw8PvpAsNQ.md
UNCHANGED Notes/hidden-design-resource-directory-teaser — DYCulDljFrW.md
UNCHANGED Notes/higgsfield-open-source-api-story-makes-sweeping-claims — DdZcmXHgO-I.md
UNCHANGED Notes/humanoid-interface-prototype-turns-gestures-into-feedback — Dcjw9HJOicn.md
UNCHANGED Notes/inspiration-list-for-claude-code-interfaces — DdMCJyagZgR.md
UNCHANGED Notes/jarvis-platform-waitlist-teaser — DZ5H6F1Rz1S.md
UNCHANGED Notes/jev-returns-typed-decisions-instead-of-open-ended-prose — DdV0piwMiFX.md
UNCHANGED Notes/karpathy-method-loop-engineering-needs-source-details — Dcw-B00FW8c.md
UNCHANGED Notes/language-differences-in-claude-s-expressed-values — DcOkXhXIPZq.md
UNCHANGED Notes/lean-checked-mathematical-advances-attributed-to-astra — Dbihv5FgPhH.md
UNCHANGED Notes/life-operating-system-slogan — DYiLHRWjJDv.md
UNCHANGED Notes/limits-of-language-models-as-scientific-discoverers — DblwLc1DGTk.md
UNCHANGED Notes/link-only-claude-promotion — DXlFWL5EkaN.md
UNCHANGED Notes/llm-versus-zero-slogan — DZcSLefuxRU.md
UNCHANGED Notes/local-stack-for-a-one-person-agent-company — Db7T7ekFUJd.md
UNCHANGED Notes/longer-agent-loops-as-a-quality-lever — DcMXqu3FIQm.md
UNCHANGED Notes/lovable-case-study-for-a-multimodal-travel-app — DbmXSIsGsIO.md
UNCHANGED Notes/macro-s-open-source-rust-productivity-suite — Db-_SxJA1vc.md
UNCHANGED Notes/magnific-desktop-restyles-footage-with-generative-video — Dcol65KqGRt.md
UNCHANGED Notes/manus-web-list-teased-behind-an-advertisement — DdTaFrPxL7S.md
UNCHANGED Notes/manus-website-tools-behind-a-comment-gate — DaU7F9UPje_.md
UNCHANGED Notes/manus-workflow-promoted-through-comment-replies — DbT2ub4ul2F.md
UNCHANGED Notes/mindchuk-s-promise-for-creative-idea-storage — Dbw6f0NMhFr.md
UNCHANGED Notes/model-choice-changes-ai-video-direction — DaSKuTchY_S.md
UNCHANGED Notes/model-hardware-standard-connects-ai-to-lab-equipment — DcjaksLIKL_.md
UNCHANGED Notes/multi-computer-ai-farm-offered-through-a-comment-gate — DdT8AVqjNqD.md
UNCHANGED Notes/muse-code-as-meta-s-terminal-agent — Dbuq2TOFLZt.md
UNCHANGED Notes/neural-model-hiking-visuals-are-a-creative-experiment — DdFSAeiskGW.md
UNCHANGED Notes/nine-open-source-substitutes-for-paid-software — DcRCbwwgBCJ.md
UNCHANGED Notes/odysseus-automation-business-model-question — DZJK6z4zZqO.md
UNCHANGED Notes/one-prompt-for-a-thousand-agents — Db9f8vyP02z.md
UNCHANGED Notes/one-sitting-claude-project-showcase — DY7SqKBjdU4.md
UNCHANGED Notes/open-source-repositories-for-ai-builders — DYH0A64NmO9.md
UNCHANGED Notes/openart-arena-ranks-creative-models-by-use-case — DdbzswWgCsM.md
UNCHANGED Notes/ornith-1-5-s-range-from-server-to-mobile — DcReeYcE48Y.md
UNCHANGED Notes/osiris-open-source-intelligence-globe — DYoUzjDibG6.md
UNCHANGED Notes/osiris-surveillance-capability-pitch — DYqhTtMxfqZ.md
UNCHANGED Notes/otto-proposes-a-plug-in-computer-for-ai-agents — DdDcXQQAt3L.md
UNCHANGED Notes/palantir-maven-and-ai-targeting-governance — DcW6VyMy2sS.md
UNCHANGED Notes/paper-design-files-expose-structure-to-coding-agents — DctpN2TgTjN.md
UNCHANGED Notes/parametric-design-as-a-taste-control-system — DbFhIg-iYYj.md
UNCHANGED Notes/pay-to-rank-leaderboard-growth-experiment — DcROR_Ykh1i.md
UNCHANGED Notes/persistent-claude-memory-with-obsidian — DV_adJTkyeN.md
UNCHANGED Notes/personalized-patio-outreach-for-contractors — DaXsPn6I2Mf.md
UNCHANGED Notes/phone-farms-exploit-directions-based-local-ranking-signals — DdaiP3dTJge.md
UNCHANGED Notes/physical-status-display-makes-terminal-agents-ambient — DcwC9lUMJ5O.md
UNCHANGED Notes/polar-browser-s-automation-promise — DbcBe_4AFPw.md
UNCHANGED Notes/portable-computer-runs-a-local-agent-on-dgx-spark — DctNmzJgPXb.md
UNCHANGED Notes/portfolio-ebook-promotion-for-designers — DX4vTYIDPR2.md
UNCHANGED Notes/portfolio-template-bundle-promoted-through-a-comment — DdWBqDuIcqp.md
UNCHANGED Notes/prime-agent-s-recursive-harness-and-arc-benchmark — Dbw4LvkMBj9.md
UNCHANGED Notes/promised-ninety-six-percent-efficiency-research — Db7AH33MHvg.md
UNCHANGED Notes/prompt-driven-claude-prototyping-workspace — DXa1R1-DR5m.md
UNCHANGED Notes/prompt-writer-comparison-for-seedance-videos — DXHXJ-rMzlL.md
UNCHANGED Notes/prototype-realtime-news-processing-for-trading-research — DdNjyfNyx2e.md
UNCHANGED Notes/quest-3-prototype-for-mixed-reality-agent-work — DcNrwpyiRlh.md
UNCHANGED Notes/rag-services-as-a-founder-revenue-path — DcTLl70CZM9.md
UNCHANGED Notes/rapid-interactive-builds-attributed-to-gpt-6-astra — Dc6QnFyDhfX.md
UNCHANGED Notes/real-time-monitors-for-a-trading-data-pipeline — DcdsqMsyoEH.md
UNCHANGED Notes/security-cost-warning-without-specifics — DYgukfFNZD5.md
UNCHANGED Notes/seedance-feature-film-launch-and-giveaway — Db3hz3YgHMt.md
UNCHANGED Notes/selling-packaged-open-source-repos-as-agency-offers — Dcv9HtHDLDZ.md
UNCHANGED Notes/seven-ai-breakthroughs-spanning-research-and-robotics — Dblfgz5ksQ3.md
UNCHANGED Notes/seven-github-repositories-behind-ai-startups — DbQdU7BmK7h.md
UNCHANGED Notes/seven-unverified-headlines-in-one-technology-roundup — DbqqVN8ksQV.md
UNCHANGED Notes/seventeen-chatgpt-image-transformation-commands — Dc3abXpAESW.md
UNCHANGED Notes/shadowbroker-self-hosted-geospatial-intelligence-stack — DbaX4PPq2uZ.md
UNCHANGED Notes/six-claude-skills-for-designed-outputs — DZp3_CJCPaI.md
UNCHANGED Notes/six-developer-experiments-span-maps-cad-and-charts — DcyqOCYDlWC.md
UNCHANGED Notes/six-reusable-documents-tame-client-project-chaos — DctXXS8DjnA.md
UNCHANGED Notes/sponsored-ai-series-continuation — DYOqDcVTe88.md
UNCHANGED Notes/sponsored-ai-series-final-teaser — DYQ-NlTzDKk.md
UNCHANGED Notes/sponsored-save-later-vibe-coding-teaser — DcgYTivlSk1.md
UNCHANGED Notes/starport-project-name-without-explanation — DbYtjGXC42I.md
UNCHANGED Notes/structural-fingerprints-in-machine-written-stories — DaQwB1IOdhx.md
UNCHANGED Notes/structured-client-onboarding-workflow — DYDLGtQRwMC.md
UNCHANGED Notes/superbrain-s-answer-to-context-overload — Db8ZLi1FCsm.md
UNCHANGED Notes/teaser-for-hidden-anthropic-coding-rules — DdMtpWRDsuX.md
UNCHANGED Notes/temu-productivity-accessory-endorsement — DblN0Pqg0YS.md
UNCHANGED Notes/terminal-motion-design-automation-pipeline — DYiWOHFuUOC.md
UNCHANGED Notes/testing-memory-tiers-instead-of-name-dropping-rag — Db9xNeMmJ5g.md
UNCHANGED Notes/thirty-nine-editable-figma-prototypes-sold-as-a-bundle — DcxFvjUME1u.md
UNCHANGED Notes/three-dimensional-file-management-interface-concept — Db6HIohBN7u.md
UNCHANGED Notes/three-osint-dashboards-are-teased-without-names — DdSrg4QuKnw.md
UNCHANGED Notes/unexplained-high-stakes-teaser — DWkeVpakZc5.md
UNCHANGED Notes/unlisted-website-reference-collection — DWwdMAPDBUc.md
UNCHANGED Notes/unspecified-ai-release-excitement — DXFIMTpE1Zm.md
UNCHANGED Notes/unspecified-claude-and-davinci-resolve-workflow — DbysdqEIYym.md
UNCHANGED Notes/unspecified-multi-tool-agent-setup-breakdown — DcOo9WcRK4k.md
UNCHANGED Notes/using-frontier-plans-to-guide-cheap-models — Db_zOrOiZl2.md
UNCHANGED Notes/vague-warning-about-popular-ai-coding-tools — Dcz81oJA8Td.md
UNCHANGED Notes/video-guide-request-without-details — DXWt8FgCIp4.md
UNCHANGED Notes/viral-gpt-6-trading-profit-story-lacks-evidence — DdZoKmrk3vQ.md
UNCHANGED Notes/visual-ui-primitives-for-ai-builders — DcPgLEWgTPH.md
UNCHANGED Notes/voice-and-dashboard-controller-for-coordinating-ai-agents — DclXCdMgRF6.md
UNCHANGED Notes/voice-controlled-computer-assistant-built-with-realtime-tools — Dcun2LYA4Vm.md
UNCHANGED Notes/weekly-ai-news-claims-roundup — DXobNJdjVzp.md
UNCHANGED Notes/why-agent-self-improvement-needs-grounded-counter-metrics — DbBDnp6DcKV.md
UNCHANGED Notes/world-monitor-aggregates-open-data-for-live-geopolitics — DcjHVjDDM5N.md
UNCHANGED Notes/zero-asset-procedural-game-experiments-in-claude — DbQxzV5DW9D.md
UNCHANGED Saved AI Posts.base
UNCHANGED Topics/agents-and-coding.md
UNCHANGED Topics/ai-news.md
UNCHANGED Topics/business.md
UNCHANGED Topics/cad-and-3d.md
UNCHANGED Topics/design-tools.md
UNCHANGED Topics/hardware.md
UNCHANGED Topics/research.md
UNCHANGED Topics/security.md
UNCHANGED Topics/unsorted.md
UNCHANGED Topics/workflows-and-productivity.md
GEO_SHA256_BEFORE=MISSING
GEO_SHA256_AFTER=MISSING
```

## 3a. Seeded fake-vault apply
```text
$ python publish_social_corpus.py --source C:\Users\dougl\Projects\general-ai\.local\social-catalog-20260919\publication-dryrun --vault-root C:\Users\dougl\AppData\Local\Temp\social-publisher-evidence-2bf247aeb74a427a9e55cd755ad25996\fake-vault --apply
EXCLUDED_DIR=Backups/
EXCLUDED_DIR=_review/
EXCLUDED_DIR=_evidence/
EXCLUDED_FILE=run-manifest.json
EXCLUDED_FILE=CONTRACT-EVIDENCE.md
EXCLUDED_FILE=Continuation plan and progress map.md
MODE=apply
SOURCE=C:\Users\dougl\Projects\general-ai\.local\social-catalog-20260919\publication-dryrun
TARGET=C:\Users\dougl\AppData\Local\Temp\social-publisher-evidence-2bf247aeb74a427a9e55cd755ad25996\fake-vault\50 Knowledge\57 Corpus\Saved AI Posts
UNCHANGED 00 - Saved AI Posts Corpus Index.md
UNCHANGED DM resources.md
UNCHANGED Images/crucix-dashboard.png
UNCHANGED Needs review.md
REFUSE Notes/a-comment-gated-glossary-of-ai-builder-terms — DcNkAaQtZwv.md: target is not authored_by: agent
REFUSE Notes/a-curated-subset-of-claude-code-design-skills — DZv8-rvkZ9E.md: locked target
UNCHANGED Notes/a-date-based-reminder-about-future-relevance — Da7zM_GpD_S.md
UNCHANGED Notes/a-fable-five-operating-system-setup-offer — DaRxpoXHFIR.md
UNCHANGED Notes/a-five-advisor-council-for-hard-decisions — DbJsAW7DbiD.md
UNCHANGED Notes/a-four-prompt-opus-and-fable-comparison — DbMSwY9iOTK.md
UNCHANGED Notes/a-hype-versus-output-ranking-of-ai-tools — DbDiZ5OlHVe.md
UNCHANGED Notes/a-personal-claim-about-ai-relevance — Db6ZvnoPGUN.md
UNCHANGED Notes/a-post-that-only-asks-fact-or-hype — DbtEt6ZC1GJ.md
UNCHANGED Notes/a-skeptical-reading-of-stateless-mcp — Db_zB2xkkZt.md
UNCHANGED Notes/a-week-of-fast-moving-ai-headlines — Db23365ACi-.md
UNCHANGED Notes/agent-booking-mistake-exposes-api-authorization-gaps — Db3IJv1AJ1Q.md
UNCHANGED Notes/agent-guide-lead-magnet — DXpxFmOHONg.md
UNCHANGED Notes/agent-strategy-gated-by-a-follow — DYIRI90gs5E.md
UNCHANGED Notes/agentic-claude-model-capability-roundup — DXTngscAIPK.md
UNCHANGED Notes/agentic-os-course-destination — Da_Khm4ARLh.md
UNCHANGED Notes/ai-generated-livestream-renders-episodes-ahead-of-playback — DcoxK0nIJa0.md
UNCHANGED Notes/ai-news-recap-adds-claims-about-agents-and-media — DdD5JcjgQ8s.md
UNCHANGED Notes/animation-resource-giveaway-for-figma-users — DWoYaIxDWJD.md
UNCHANGED Notes/anonymous-ox-alpha-model-claims-and-access-links — DcTaQR3APjQ.md
UNCHANGED Notes/anthropic-s-collection-of-claude-powered-objects — Dc3f2-UoHWf.md
UNCHANGED Notes/anthropic-s-startup-guide-mention-without-a-link — DcbthMGn_bu.md
UNCHANGED Notes/architecture-file-records-decisions-agents-cannot-infer — DdR5eAPOfT6.md
UNCHANGED Notes/astra-experiments-across-games-worlds-and-figma — Dc8lPnHDjXC.md
UNCHANGED Notes/autonomous-decision-tree-pattern-teaser — DcOCgBkNNjK.md
UNCHANGED Notes/base-s-knowledge-graph-context-loading-pitch — DcbFunokXyI.md
UNCHANGED Notes/bedroom-ready-ai-application-infrastructure-stack — DVNcIoBgH9Q.md
UNCHANGED Notes/bilevel-loops-promised-as-a-fivefold-upgrade — DbjLy_tormR.md
UNCHANGED Notes/blueprint-promises-a-prompt-to-build-workflow — DdKmOKvDEIe.md
UNCHANGED Notes/bolt-forge-advertises-expanded-model-usage-limits — DdTs3PIpq3L.md
UNCHANGED Notes/building-an-mcp-host-around-multiple-servers — Dbhdx66GL3O.md
UNCHANGED Notes/cache-to-cache-communication-skips-text-between-models — DdatXCRmVwW.md
UNCHANGED Notes/case-studies-for-less-uniform-websites — DYCIEb8MLKU.md
UNCHANGED Notes/chatbot-assisted-personal-data-cleanup — DYWm6yygPWm.md
UNCHANGED Notes/checklist-for-making-vibecoded-websites-credible — DcoBxsSodtT.md
UNCHANGED Notes/claude-assisted-breach-story-claims-a-dramatic-chain — DdcK88DD-IR.md
UNCHANGED Notes/claude-built-bluetooth-finder-for-a-managed-phone — DbqRmHYjfyD.md
UNCHANGED Notes/claude-code-guide-behind-an-engagement-gate — DcRENuwpjpk.md
UNCHANGED Notes/claude-code-session-to-session-handoffs — DbxTRFJBpzd.md
UNCHANGED Notes/claude-code-workflow-for-web-design — DblU1r_HA5p.md
UNCHANGED Notes/claude-design-access-workaround-teaser — DYC1yvhsckC.md
UNCHANGED Notes/claude-loops-replacing-manual-prompting — DZXsQkKgEeQ.md
UNCHANGED Notes/claude-plugins-skills-and-mcp-starter-set — DZkt4AxCTfJ.md
UNCHANGED Notes/claude-second-brain-skill-teaser — DXxGZjsD_PH.md
UNCHANGED Notes/claude-skills-for-end-to-end-interface-design — DZtuV9Bk5GZ.md
UNCHANGED Notes/codex-and-claude-guide-teaser-requires-a-comment — DdappS3nEtK.md
UNCHANGED Notes/command-line-tools-inside-claude-code — DXjlj-GDXBJ.md
UNCHANGED Notes/comparing-sol-and-fable-on-coding-economics — DastBeBAMB_.md
UNCHANGED Notes/component-library-teaser-for-developers — DXtgNKPEjs7.md
UNCHANGED Notes/computer-vision-reads-poker-tells — Dapvu1TgMX8.md
UNCHANGED Notes/context-graph-as-the-post-swarm-product — Dc05tndxpWt.md
UNCHANGED Notes/conversational-product-building-pitch — DXh-ACgk-f0.md
UNCHANGED Notes/creative-developer-projects-show-small-experiments-shipping — DcuI3KiDuyu.md
UNCHANGED Notes/crucix-local-osint-intelligence-terminal — DbQyH2NBc7C.md
UNCHANGED Notes/day-one-claude-project-showcase — DZZ-FWADu5_.md
UNCHANGED Notes/deepseek-v4-flash-pricing-and-benchmark-pitch — Dbirg1tGZXJ.md
UNCHANGED Notes/designer-made-ui-library-for-ai-prompts — DcPgGapgaJG.md
UNCHANGED Notes/designer-made-ui-library-supplies-prompts-to-ai — DczqUuMgOk2.md
UNCHANGED Notes/designer-oriented-claude-skill-shortlist — DXg6gAVjKwF.md
UNCHANGED Notes/developer-decision-fatigue-meme — DcL1SNXIt6A.md
UNCHANGED Notes/discounted-api-proxy-underground-economy — DYhR9kvDXKz.md
UNCHANGED Notes/early-claude-fable-demos-showcase-rapid-browser-builds — DcyTLjagPxg.md
UNCHANGED Notes/early-knowledge-graph-implementation-teaser — DcHG2kPtZZG.md
UNCHANGED Notes/editable-canva-layers-from-ai-posters — DXs9baSDcG6.md
UNCHANGED Notes/editable-code-based-image-generation-with-reinforcement-learning — DceUGnuh-KA.md
UNCHANGED Notes/eight-frontier-ai-developments-from-july — DbD_eQ2EhbF.md
UNCHANGED Notes/eli5-visual-explainer-workflow-for-claude-code — DcY8rf9jUY7.md
UNCHANGED Notes/entrepreneurship-meme-without-substance — DYezDRbqEYJ.md
UNCHANGED Notes/execute-code-harness-versus-mcp-token-study — Dcd5smMHH8T.md
UNCHANGED Notes/five-browser-resources-for-practical-design-work — DcjDy50DXp4.md
UNCHANGED Notes/five-claude-skills-for-faster-building — DX1skMrlTJL.md
UNCHANGED Notes/five-psychology-lessons-framed-through-claude — DaxObZGACq6.md
UNCHANGED Notes/folder-versus-agentic-system-provocation — DbwnCJqRtXJ.md
UNCHANGED Notes/font-references-for-creative-project-work — DbLQJHKgblS.md
UNCHANGED Notes/frame-based-scroll-animation-production-pipeline — DW7lN7sj2ow.md
UNCHANGED Notes/framer-chimes-and-parallax-animation-tutorial — DcmbRpjsRB4.md
UNCHANGED Notes/frontier-planning-turns-cheap-models-into-executors — Db08WMRlZc5.md
UNCHANGED Notes/fusion-axis-combines-numpad-trackpad-and-controls — DcwhNwfsgnZ.md
UNCHANGED Notes/gbp-management-income-claim-uses-a-personal-results-disclaimer — DdXXo_Bll7v.md
UNCHANGED Notes/gemini-animated-logo-email-tactic — DXs4k6nD3V6.md
UNCHANGED Notes/genjutsu-s-performance-preserving-video-transformation — Dc1kFA-gFa_.md
UNCHANGED Notes/geospy-style-visual-geolocation-from-ordinary-photos — Dc3YS5Ush9I.md
UNCHANGED Notes/gesture-controls-for-ai-coding-agent-prototypes — DcdtNz1DgGL.md
UNCHANGED Notes/google-s-canva-challenge-teaser — Dc1h11QDhc4.md
UNCHANGED Notes/gpt-6-astra-as-a-computer-operating-agent — Dc1qHoaAeeC.md
UNCHANGED Notes/gpt-image-2-creative-showcase-claims — DXery6FkoU4.md
UNCHANGED Notes/graph-debugging-rant-without-the-diagnosis — DcTIPKyt7Am.md
UNCHANGED Notes/graph-theory-turns-rubiks-cube-states-into-a-network — Ddd9mmFDd1d.md
UNCHANGED Notes/grok-bot-as-a-team-of-specialized-agents — DcY1-eIEriY.md
UNCHANGED Notes/grok-bot-research-desk-for-trading-analysis — DcvuQQcjEPD.md
UNCHANGED Notes/grok-bot-s-shared-login-blast-radius — DcHPKO-gQLs.md
UNCHANGED Notes/hands-replace-the-mouse-in-a-gesture-interface — Db--miYgE93.md
UNCHANGED Notes/hermes-agent-turns-imessage-into-delegated-work — Dcw8PvpAsNQ.md
UNCHANGED Notes/hidden-design-resource-directory-teaser — DYCulDljFrW.md
UNCHANGED Notes/higgsfield-open-source-api-story-makes-sweeping-claims — DdZcmXHgO-I.md
UNCHANGED Notes/humanoid-interface-prototype-turns-gestures-into-feedback — Dcjw9HJOicn.md
UNCHANGED Notes/inspiration-list-for-claude-code-interfaces — DdMCJyagZgR.md
UNCHANGED Notes/jarvis-platform-waitlist-teaser — DZ5H6F1Rz1S.md
UNCHANGED Notes/jev-returns-typed-decisions-instead-of-open-ended-prose — DdV0piwMiFX.md
UNCHANGED Notes/karpathy-method-loop-engineering-needs-source-details — Dcw-B00FW8c.md
UNCHANGED Notes/language-differences-in-claude-s-expressed-values — DcOkXhXIPZq.md
UNCHANGED Notes/lean-checked-mathematical-advances-attributed-to-astra — Dbihv5FgPhH.md
UNCHANGED Notes/life-operating-system-slogan — DYiLHRWjJDv.md
UNCHANGED Notes/limits-of-language-models-as-scientific-discoverers — DblwLc1DGTk.md
UNCHANGED Notes/link-only-claude-promotion — DXlFWL5EkaN.md
UNCHANGED Notes/llm-versus-zero-slogan — DZcSLefuxRU.md
UNCHANGED Notes/local-stack-for-a-one-person-agent-company — Db7T7ekFUJd.md
UNCHANGED Notes/longer-agent-loops-as-a-quality-lever — DcMXqu3FIQm.md
UNCHANGED Notes/lovable-case-study-for-a-multimodal-travel-app — DbmXSIsGsIO.md
UNCHANGED Notes/macro-s-open-source-rust-productivity-suite — Db-_SxJA1vc.md
UNCHANGED Notes/magnific-desktop-restyles-footage-with-generative-video — Dcol65KqGRt.md
UNCHANGED Notes/manus-web-list-teased-behind-an-advertisement — DdTaFrPxL7S.md
UNCHANGED Notes/manus-website-tools-behind-a-comment-gate — DaU7F9UPje_.md
UNCHANGED Notes/manus-workflow-promoted-through-comment-replies — DbT2ub4ul2F.md
UNCHANGED Notes/mindchuk-s-promise-for-creative-idea-storage — Dbw6f0NMhFr.md
UNCHANGED Notes/model-choice-changes-ai-video-direction — DaSKuTchY_S.md
UNCHANGED Notes/model-hardware-standard-connects-ai-to-lab-equipment — DcjaksLIKL_.md
UNCHANGED Notes/multi-computer-ai-farm-offered-through-a-comment-gate — DdT8AVqjNqD.md
UNCHANGED Notes/muse-code-as-meta-s-terminal-agent — Dbuq2TOFLZt.md
UNCHANGED Notes/neural-model-hiking-visuals-are-a-creative-experiment — DdFSAeiskGW.md
UNCHANGED Notes/nine-open-source-substitutes-for-paid-software — DcRCbwwgBCJ.md
UNCHANGED Notes/odysseus-automation-business-model-question — DZJK6z4zZqO.md
UNCHANGED Notes/one-prompt-for-a-thousand-agents — Db9f8vyP02z.md
UNCHANGED Notes/one-sitting-claude-project-showcase — DY7SqKBjdU4.md
UNCHANGED Notes/open-source-repositories-for-ai-builders — DYH0A64NmO9.md
UNCHANGED Notes/openart-arena-ranks-creative-models-by-use-case — DdbzswWgCsM.md
UNCHANGED Notes/ornith-1-5-s-range-from-server-to-mobile — DcReeYcE48Y.md
UNCHANGED Notes/osiris-open-source-intelligence-globe — DYoUzjDibG6.md
UNCHANGED Notes/osiris-surveillance-capability-pitch — DYqhTtMxfqZ.md
UNCHANGED Notes/otto-proposes-a-plug-in-computer-for-ai-agents — DdDcXQQAt3L.md
UNCHANGED Notes/palantir-maven-and-ai-targeting-governance — DcW6VyMy2sS.md
UNCHANGED Notes/paper-design-files-expose-structure-to-coding-agents — DctpN2TgTjN.md
UNCHANGED Notes/parametric-design-as-a-taste-control-system — DbFhIg-iYYj.md
UNCHANGED Notes/pay-to-rank-leaderboard-growth-experiment — DcROR_Ykh1i.md
UNCHANGED Notes/persistent-claude-memory-with-obsidian — DV_adJTkyeN.md
UNCHANGED Notes/personalized-patio-outreach-for-contractors — DaXsPn6I2Mf.md
UNCHANGED Notes/phone-farms-exploit-directions-based-local-ranking-signals — DdaiP3dTJge.md
UNCHANGED Notes/physical-status-display-makes-terminal-agents-ambient — DcwC9lUMJ5O.md
UNCHANGED Notes/polar-browser-s-automation-promise — DbcBe_4AFPw.md
UNCHANGED Notes/portable-computer-runs-a-local-agent-on-dgx-spark — DctNmzJgPXb.md
UNCHANGED Notes/portfolio-ebook-promotion-for-designers — DX4vTYIDPR2.md
UNCHANGED Notes/portfolio-template-bundle-promoted-through-a-comment — DdWBqDuIcqp.md
UNCHANGED Notes/prime-agent-s-recursive-harness-and-arc-benchmark — Dbw4LvkMBj9.md
UNCHANGED Notes/promised-ninety-six-percent-efficiency-research — Db7AH33MHvg.md
UNCHANGED Notes/prompt-driven-claude-prototyping-workspace — DXa1R1-DR5m.md
UNCHANGED Notes/prompt-writer-comparison-for-seedance-videos — DXHXJ-rMzlL.md
UNCHANGED Notes/prototype-realtime-news-processing-for-trading-research — DdNjyfNyx2e.md
UNCHANGED Notes/quest-3-prototype-for-mixed-reality-agent-work — DcNrwpyiRlh.md
UNCHANGED Notes/rag-services-as-a-founder-revenue-path — DcTLl70CZM9.md
UNCHANGED Notes/rapid-interactive-builds-attributed-to-gpt-6-astra — Dc6QnFyDhfX.md
UNCHANGED Notes/real-time-monitors-for-a-trading-data-pipeline — DcdsqMsyoEH.md
UNCHANGED Notes/security-cost-warning-without-specifics — DYgukfFNZD5.md
UNCHANGED Notes/seedance-feature-film-launch-and-giveaway — Db3hz3YgHMt.md
UNCHANGED Notes/selling-packaged-open-source-repos-as-agency-offers — Dcv9HtHDLDZ.md
UNCHANGED Notes/seven-ai-breakthroughs-spanning-research-and-robotics — Dblfgz5ksQ3.md
UNCHANGED Notes/seven-github-repositories-behind-ai-startups — DbQdU7BmK7h.md
UNCHANGED Notes/seven-unverified-headlines-in-one-technology-roundup — DbqqVN8ksQV.md
UNCHANGED Notes/seventeen-chatgpt-image-transformation-commands — Dc3abXpAESW.md
UNCHANGED Notes/shadowbroker-self-hosted-geospatial-intelligence-stack — DbaX4PPq2uZ.md
UNCHANGED Notes/six-claude-skills-for-designed-outputs — DZp3_CJCPaI.md
UNCHANGED Notes/six-developer-experiments-span-maps-cad-and-charts — DcyqOCYDlWC.md
UNCHANGED Notes/six-reusable-documents-tame-client-project-chaos — DctXXS8DjnA.md
UNCHANGED Notes/sponsored-ai-series-continuation — DYOqDcVTe88.md
UNCHANGED Notes/sponsored-ai-series-final-teaser — DYQ-NlTzDKk.md
UNCHANGED Notes/sponsored-save-later-vibe-coding-teaser — DcgYTivlSk1.md
UNCHANGED Notes/starport-project-name-without-explanation — DbYtjGXC42I.md
UNCHANGED Notes/structural-fingerprints-in-machine-written-stories — DaQwB1IOdhx.md
UNCHANGED Notes/structured-client-onboarding-workflow — DYDLGtQRwMC.md
UNCHANGED Notes/superbrain-s-answer-to-context-overload — Db8ZLi1FCsm.md
UNCHANGED Notes/teaser-for-hidden-anthropic-coding-rules — DdMtpWRDsuX.md
UNCHANGED Notes/temu-productivity-accessory-endorsement — DblN0Pqg0YS.md
UNCHANGED Notes/terminal-motion-design-automation-pipeline — DYiWOHFuUOC.md
UNCHANGED Notes/testing-memory-tiers-instead-of-name-dropping-rag — Db9xNeMmJ5g.md
UNCHANGED Notes/thirty-nine-editable-figma-prototypes-sold-as-a-bundle — DcxFvjUME1u.md
UNCHANGED Notes/three-dimensional-file-management-interface-concept — Db6HIohBN7u.md
UNCHANGED Notes/three-osint-dashboards-are-teased-without-names — DdSrg4QuKnw.md
UNCHANGED Notes/unexplained-high-stakes-teaser — DWkeVpakZc5.md
UNCHANGED Notes/unlisted-website-reference-collection — DWwdMAPDBUc.md
UNCHANGED Notes/unspecified-ai-release-excitement — DXFIMTpE1Zm.md
UNCHANGED Notes/unspecified-claude-and-davinci-resolve-workflow — DbysdqEIYym.md
UNCHANGED Notes/unspecified-multi-tool-agent-setup-breakdown — DcOo9WcRK4k.md
UNCHANGED Notes/using-frontier-plans-to-guide-cheap-models — Db_zOrOiZl2.md
UNCHANGED Notes/vague-warning-about-popular-ai-coding-tools — Dcz81oJA8Td.md
UNCHANGED Notes/video-guide-request-without-details — DXWt8FgCIp4.md
UNCHANGED Notes/viral-gpt-6-trading-profit-story-lacks-evidence — DdZoKmrk3vQ.md
UNCHANGED Notes/visual-ui-primitives-for-ai-builders — DcPgLEWgTPH.md
UNCHANGED Notes/voice-and-dashboard-controller-for-coordinating-ai-agents — DclXCdMgRF6.md
UNCHANGED Notes/voice-controlled-computer-assistant-built-with-realtime-tools — Dcun2LYA4Vm.md
UNCHANGED Notes/weekly-ai-news-claims-roundup — DXobNJdjVzp.md
UNCHANGED Notes/why-agent-self-improvement-needs-grounded-counter-metrics — DbBDnp6DcKV.md
UNCHANGED Notes/world-monitor-aggregates-open-data-for-live-geopolitics — DcjHVjDDM5N.md
UNCHANGED Notes/zero-asset-procedural-game-experiments-in-claude — DbQxzV5DW9D.md
UNCHANGED Saved AI Posts.base
UNCHANGED Topics/agents-and-coding.md
UNCHANGED Topics/ai-news.md
UNCHANGED Topics/business.md
UNCHANGED Topics/cad-and-3d.md
UNCHANGED Topics/design-tools.md
UNCHANGED Topics/hardware.md
UNCHANGED Topics/research.md
UNCHANGED Topics/security.md
UNCHANGED Topics/unsorted.md
UNCHANGED Topics/workflows-and-productivity.md
GEO_SHA256_BEFORE=MISSING
GEO_SHA256_AFTER=MISSING
```

## 3b. Seeded fake-vault second apply
```text
$ python publish_social_corpus.py --source C:\Users\dougl\Projects\general-ai\.local\social-catalog-20260919\publication-dryrun --vault-root C:\Users\dougl\AppData\Local\Temp\social-publisher-evidence-2bf247aeb74a427a9e55cd755ad25996\fake-vault --apply
EXCLUDED_DIR=Backups/
EXCLUDED_DIR=_review/
EXCLUDED_DIR=_evidence/
EXCLUDED_FILE=run-manifest.json
EXCLUDED_FILE=CONTRACT-EVIDENCE.md
EXCLUDED_FILE=Continuation plan and progress map.md
MODE=apply
SOURCE=C:\Users\dougl\Projects\general-ai\.local\social-catalog-20260919\publication-dryrun
TARGET=C:\Users\dougl\AppData\Local\Temp\social-publisher-evidence-2bf247aeb74a427a9e55cd755ad25996\fake-vault\50 Knowledge\57 Corpus\Saved AI Posts
UNCHANGED 00 - Saved AI Posts Corpus Index.md
UNCHANGED DM resources.md
UNCHANGED Images/crucix-dashboard.png
UNCHANGED Needs review.md
REFUSE Notes/a-comment-gated-glossary-of-ai-builder-terms — DcNkAaQtZwv.md: target is not authored_by: agent
REFUSE Notes/a-curated-subset-of-claude-code-design-skills — DZv8-rvkZ9E.md: locked target
UNCHANGED Notes/a-date-based-reminder-about-future-relevance — Da7zM_GpD_S.md
UNCHANGED Notes/a-fable-five-operating-system-setup-offer — DaRxpoXHFIR.md
UNCHANGED Notes/a-five-advisor-council-for-hard-decisions — DbJsAW7DbiD.md
UNCHANGED Notes/a-four-prompt-opus-and-fable-comparison — DbMSwY9iOTK.md
UNCHANGED Notes/a-hype-versus-output-ranking-of-ai-tools — DbDiZ5OlHVe.md
UNCHANGED Notes/a-personal-claim-about-ai-relevance — Db6ZvnoPGUN.md
UNCHANGED Notes/a-post-that-only-asks-fact-or-hype — DbtEt6ZC1GJ.md
UNCHANGED Notes/a-skeptical-reading-of-stateless-mcp — Db_zB2xkkZt.md
UNCHANGED Notes/a-week-of-fast-moving-ai-headlines — Db23365ACi-.md
UNCHANGED Notes/agent-booking-mistake-exposes-api-authorization-gaps — Db3IJv1AJ1Q.md
UNCHANGED Notes/agent-guide-lead-magnet — DXpxFmOHONg.md
UNCHANGED Notes/agent-strategy-gated-by-a-follow — DYIRI90gs5E.md
UNCHANGED Notes/agentic-claude-model-capability-roundup — DXTngscAIPK.md
UNCHANGED Notes/agentic-os-course-destination — Da_Khm4ARLh.md
UNCHANGED Notes/ai-generated-livestream-renders-episodes-ahead-of-playback — DcoxK0nIJa0.md
UNCHANGED Notes/ai-news-recap-adds-claims-about-agents-and-media — DdD5JcjgQ8s.md
UNCHANGED Notes/animation-resource-giveaway-for-figma-users — DWoYaIxDWJD.md
UNCHANGED Notes/anonymous-ox-alpha-model-claims-and-access-links — DcTaQR3APjQ.md
UNCHANGED Notes/anthropic-s-collection-of-claude-powered-objects — Dc3f2-UoHWf.md
UNCHANGED Notes/anthropic-s-startup-guide-mention-without-a-link — DcbthMGn_bu.md
UNCHANGED Notes/architecture-file-records-decisions-agents-cannot-infer — DdR5eAPOfT6.md
UNCHANGED Notes/astra-experiments-across-games-worlds-and-figma — Dc8lPnHDjXC.md
UNCHANGED Notes/autonomous-decision-tree-pattern-teaser — DcOCgBkNNjK.md
UNCHANGED Notes/base-s-knowledge-graph-context-loading-pitch — DcbFunokXyI.md
UNCHANGED Notes/bedroom-ready-ai-application-infrastructure-stack — DVNcIoBgH9Q.md
UNCHANGED Notes/bilevel-loops-promised-as-a-fivefold-upgrade — DbjLy_tormR.md
UNCHANGED Notes/blueprint-promises-a-prompt-to-build-workflow — DdKmOKvDEIe.md
UNCHANGED Notes/bolt-forge-advertises-expanded-model-usage-limits — DdTs3PIpq3L.md
UNCHANGED Notes/building-an-mcp-host-around-multiple-servers — Dbhdx66GL3O.md
UNCHANGED Notes/cache-to-cache-communication-skips-text-between-models — DdatXCRmVwW.md
UNCHANGED Notes/case-studies-for-less-uniform-websites — DYCIEb8MLKU.md
UNCHANGED Notes/chatbot-assisted-personal-data-cleanup — DYWm6yygPWm.md
UNCHANGED Notes/checklist-for-making-vibecoded-websites-credible — DcoBxsSodtT.md
UNCHANGED Notes/claude-assisted-breach-story-claims-a-dramatic-chain — DdcK88DD-IR.md
UNCHANGED Notes/claude-built-bluetooth-finder-for-a-managed-phone — DbqRmHYjfyD.md
UNCHANGED Notes/claude-code-guide-behind-an-engagement-gate — DcRENuwpjpk.md
UNCHANGED Notes/claude-code-session-to-session-handoffs — DbxTRFJBpzd.md
UNCHANGED Notes/claude-code-workflow-for-web-design — DblU1r_HA5p.md
UNCHANGED Notes/claude-design-access-workaround-teaser — DYC1yvhsckC.md
UNCHANGED Notes/claude-loops-replacing-manual-prompting — DZXsQkKgEeQ.md
UNCHANGED Notes/claude-plugins-skills-and-mcp-starter-set — DZkt4AxCTfJ.md
UNCHANGED Notes/claude-second-brain-skill-teaser — DXxGZjsD_PH.md
UNCHANGED Notes/claude-skills-for-end-to-end-interface-design — DZtuV9Bk5GZ.md
UNCHANGED Notes/codex-and-claude-guide-teaser-requires-a-comment — DdappS3nEtK.md
UNCHANGED Notes/command-line-tools-inside-claude-code — DXjlj-GDXBJ.md
UNCHANGED Notes/comparing-sol-and-fable-on-coding-economics — DastBeBAMB_.md
UNCHANGED Notes/component-library-teaser-for-developers — DXtgNKPEjs7.md
UNCHANGED Notes/computer-vision-reads-poker-tells — Dapvu1TgMX8.md
UNCHANGED Notes/context-graph-as-the-post-swarm-product — Dc05tndxpWt.md
UNCHANGED Notes/conversational-product-building-pitch — DXh-ACgk-f0.md
UNCHANGED Notes/creative-developer-projects-show-small-experiments-shipping — DcuI3KiDuyu.md
UNCHANGED Notes/crucix-local-osint-intelligence-terminal — DbQyH2NBc7C.md
UNCHANGED Notes/day-one-claude-project-showcase — DZZ-FWADu5_.md
UNCHANGED Notes/deepseek-v4-flash-pricing-and-benchmark-pitch — Dbirg1tGZXJ.md
UNCHANGED Notes/designer-made-ui-library-for-ai-prompts — DcPgGapgaJG.md
UNCHANGED Notes/designer-made-ui-library-supplies-prompts-to-ai — DczqUuMgOk2.md
UNCHANGED Notes/designer-oriented-claude-skill-shortlist — DXg6gAVjKwF.md
UNCHANGED Notes/developer-decision-fatigue-meme — DcL1SNXIt6A.md
UNCHANGED Notes/discounted-api-proxy-underground-economy — DYhR9kvDXKz.md
UNCHANGED Notes/early-claude-fable-demos-showcase-rapid-browser-builds — DcyTLjagPxg.md
UNCHANGED Notes/early-knowledge-graph-implementation-teaser — DcHG2kPtZZG.md
UNCHANGED Notes/editable-canva-layers-from-ai-posters — DXs9baSDcG6.md
UNCHANGED Notes/editable-code-based-image-generation-with-reinforcement-learning — DceUGnuh-KA.md
UNCHANGED Notes/eight-frontier-ai-developments-from-july — DbD_eQ2EhbF.md
UNCHANGED Notes/eli5-visual-explainer-workflow-for-claude-code — DcY8rf9jUY7.md
UNCHANGED Notes/entrepreneurship-meme-without-substance — DYezDRbqEYJ.md
UNCHANGED Notes/execute-code-harness-versus-mcp-token-study — Dcd5smMHH8T.md
UNCHANGED Notes/five-browser-resources-for-practical-design-work — DcjDy50DXp4.md
UNCHANGED Notes/five-claude-skills-for-faster-building — DX1skMrlTJL.md
UNCHANGED Notes/five-psychology-lessons-framed-through-claude — DaxObZGACq6.md
UNCHANGED Notes/folder-versus-agentic-system-provocation — DbwnCJqRtXJ.md
UNCHANGED Notes/font-references-for-creative-project-work — DbLQJHKgblS.md
UNCHANGED Notes/frame-based-scroll-animation-production-pipeline — DW7lN7sj2ow.md
UNCHANGED Notes/framer-chimes-and-parallax-animation-tutorial — DcmbRpjsRB4.md
UNCHANGED Notes/frontier-planning-turns-cheap-models-into-executors — Db08WMRlZc5.md
UNCHANGED Notes/fusion-axis-combines-numpad-trackpad-and-controls — DcwhNwfsgnZ.md
UNCHANGED Notes/gbp-management-income-claim-uses-a-personal-results-disclaimer — DdXXo_Bll7v.md
UNCHANGED Notes/gemini-animated-logo-email-tactic — DXs4k6nD3V6.md
UNCHANGED Notes/genjutsu-s-performance-preserving-video-transformation — Dc1kFA-gFa_.md
UNCHANGED Notes/geospy-style-visual-geolocation-from-ordinary-photos — Dc3YS5Ush9I.md
UNCHANGED Notes/gesture-controls-for-ai-coding-agent-prototypes — DcdtNz1DgGL.md
UNCHANGED Notes/google-s-canva-challenge-teaser — Dc1h11QDhc4.md
UNCHANGED Notes/gpt-6-astra-as-a-computer-operating-agent — Dc1qHoaAeeC.md
UNCHANGED Notes/gpt-image-2-creative-showcase-claims — DXery6FkoU4.md
UNCHANGED Notes/graph-debugging-rant-without-the-diagnosis — DcTIPKyt7Am.md
UNCHANGED Notes/graph-theory-turns-rubiks-cube-states-into-a-network — Ddd9mmFDd1d.md
UNCHANGED Notes/grok-bot-as-a-team-of-specialized-agents — DcY1-eIEriY.md
UNCHANGED Notes/grok-bot-research-desk-for-trading-analysis — DcvuQQcjEPD.md
UNCHANGED Notes/grok-bot-s-shared-login-blast-radius — DcHPKO-gQLs.md
UNCHANGED Notes/hands-replace-the-mouse-in-a-gesture-interface — Db--miYgE93.md
UNCHANGED Notes/hermes-agent-turns-imessage-into-delegated-work — Dcw8PvpAsNQ.md
UNCHANGED Notes/hidden-design-resource-directory-teaser — DYCulDljFrW.md
UNCHANGED Notes/higgsfield-open-source-api-story-makes-sweeping-claims — DdZcmXHgO-I.md
UNCHANGED Notes/humanoid-interface-prototype-turns-gestures-into-feedback — Dcjw9HJOicn.md
UNCHANGED Notes/inspiration-list-for-claude-code-interfaces — DdMCJyagZgR.md
UNCHANGED Notes/jarvis-platform-waitlist-teaser — DZ5H6F1Rz1S.md
UNCHANGED Notes/jev-returns-typed-decisions-instead-of-open-ended-prose — DdV0piwMiFX.md
UNCHANGED Notes/karpathy-method-loop-engineering-needs-source-details — Dcw-B00FW8c.md
UNCHANGED Notes/language-differences-in-claude-s-expressed-values — DcOkXhXIPZq.md
UNCHANGED Notes/lean-checked-mathematical-advances-attributed-to-astra — Dbihv5FgPhH.md
UNCHANGED Notes/life-operating-system-slogan — DYiLHRWjJDv.md
UNCHANGED Notes/limits-of-language-models-as-scientific-discoverers — DblwLc1DGTk.md
UNCHANGED Notes/link-only-claude-promotion — DXlFWL5EkaN.md
UNCHANGED Notes/llm-versus-zero-slogan — DZcSLefuxRU.md
UNCHANGED Notes/local-stack-for-a-one-person-agent-company — Db7T7ekFUJd.md
UNCHANGED Notes/longer-agent-loops-as-a-quality-lever — DcMXqu3FIQm.md
UNCHANGED Notes/lovable-case-study-for-a-multimodal-travel-app — DbmXSIsGsIO.md
UNCHANGED Notes/macro-s-open-source-rust-productivity-suite — Db-_SxJA1vc.md
UNCHANGED Notes/magnific-desktop-restyles-footage-with-generative-video — Dcol65KqGRt.md
UNCHANGED Notes/manus-web-list-teased-behind-an-advertisement — DdTaFrPxL7S.md
UNCHANGED Notes/manus-website-tools-behind-a-comment-gate — DaU7F9UPje_.md
UNCHANGED Notes/manus-workflow-promoted-through-comment-replies — DbT2ub4ul2F.md
UNCHANGED Notes/mindchuk-s-promise-for-creative-idea-storage — Dbw6f0NMhFr.md
UNCHANGED Notes/model-choice-changes-ai-video-direction — DaSKuTchY_S.md
UNCHANGED Notes/model-hardware-standard-connects-ai-to-lab-equipment — DcjaksLIKL_.md
UNCHANGED Notes/multi-computer-ai-farm-offered-through-a-comment-gate — DdT8AVqjNqD.md
UNCHANGED Notes/muse-code-as-meta-s-terminal-agent — Dbuq2TOFLZt.md
UNCHANGED Notes/neural-model-hiking-visuals-are-a-creative-experiment — DdFSAeiskGW.md
UNCHANGED Notes/nine-open-source-substitutes-for-paid-software — DcRCbwwgBCJ.md
UNCHANGED Notes/odysseus-automation-business-model-question — DZJK6z4zZqO.md
UNCHANGED Notes/one-prompt-for-a-thousand-agents — Db9f8vyP02z.md
UNCHANGED Notes/one-sitting-claude-project-showcase — DY7SqKBjdU4.md
UNCHANGED Notes/open-source-repositories-for-ai-builders — DYH0A64NmO9.md
UNCHANGED Notes/openart-arena-ranks-creative-models-by-use-case — DdbzswWgCsM.md
UNCHANGED Notes/ornith-1-5-s-range-from-server-to-mobile — DcReeYcE48Y.md
UNCHANGED Notes/osiris-open-source-intelligence-globe — DYoUzjDibG6.md
UNCHANGED Notes/osiris-surveillance-capability-pitch — DYqhTtMxfqZ.md
UNCHANGED Notes/otto-proposes-a-plug-in-computer-for-ai-agents — DdDcXQQAt3L.md
UNCHANGED Notes/palantir-maven-and-ai-targeting-governance — DcW6VyMy2sS.md
UNCHANGED Notes/paper-design-files-expose-structure-to-coding-agents — DctpN2TgTjN.md
UNCHANGED Notes/parametric-design-as-a-taste-control-system — DbFhIg-iYYj.md
UNCHANGED Notes/pay-to-rank-leaderboard-growth-experiment — DcROR_Ykh1i.md
UNCHANGED Notes/persistent-claude-memory-with-obsidian — DV_adJTkyeN.md
UNCHANGED Notes/personalized-patio-outreach-for-contractors — DaXsPn6I2Mf.md
UNCHANGED Notes/phone-farms-exploit-directions-based-local-ranking-signals — DdaiP3dTJge.md
UNCHANGED Notes/physical-status-display-makes-terminal-agents-ambient — DcwC9lUMJ5O.md
UNCHANGED Notes/polar-browser-s-automation-promise — DbcBe_4AFPw.md
UNCHANGED Notes/portable-computer-runs-a-local-agent-on-dgx-spark — DctNmzJgPXb.md
UNCHANGED Notes/portfolio-ebook-promotion-for-designers — DX4vTYIDPR2.md
UNCHANGED Notes/portfolio-template-bundle-promoted-through-a-comment — DdWBqDuIcqp.md
UNCHANGED Notes/prime-agent-s-recursive-harness-and-arc-benchmark — Dbw4LvkMBj9.md
UNCHANGED Notes/promised-ninety-six-percent-efficiency-research — Db7AH33MHvg.md
UNCHANGED Notes/prompt-driven-claude-prototyping-workspace — DXa1R1-DR5m.md
UNCHANGED Notes/prompt-writer-comparison-for-seedance-videos — DXHXJ-rMzlL.md
UNCHANGED Notes/prototype-realtime-news-processing-for-trading-research — DdNjyfNyx2e.md
UNCHANGED Notes/quest-3-prototype-for-mixed-reality-agent-work — DcNrwpyiRlh.md
UNCHANGED Notes/rag-services-as-a-founder-revenue-path — DcTLl70CZM9.md
UNCHANGED Notes/rapid-interactive-builds-attributed-to-gpt-6-astra — Dc6QnFyDhfX.md
UNCHANGED Notes/real-time-monitors-for-a-trading-data-pipeline — DcdsqMsyoEH.md
UNCHANGED Notes/security-cost-warning-without-specifics — DYgukfFNZD5.md
UNCHANGED Notes/seedance-feature-film-launch-and-giveaway — Db3hz3YgHMt.md
UNCHANGED Notes/selling-packaged-open-source-repos-as-agency-offers — Dcv9HtHDLDZ.md
UNCHANGED Notes/seven-ai-breakthroughs-spanning-research-and-robotics — Dblfgz5ksQ3.md
UNCHANGED Notes/seven-github-repositories-behind-ai-startups — DbQdU7BmK7h.md
UNCHANGED Notes/seven-unverified-headlines-in-one-technology-roundup — DbqqVN8ksQV.md
UNCHANGED Notes/seventeen-chatgpt-image-transformation-commands — Dc3abXpAESW.md
UNCHANGED Notes/shadowbroker-self-hosted-geospatial-intelligence-stack — DbaX4PPq2uZ.md
UNCHANGED Notes/six-claude-skills-for-designed-outputs — DZp3_CJCPaI.md
UNCHANGED Notes/six-developer-experiments-span-maps-cad-and-charts — DcyqOCYDlWC.md
UNCHANGED Notes/six-reusable-documents-tame-client-project-chaos — DctXXS8DjnA.md
UNCHANGED Notes/sponsored-ai-series-continuation — DYOqDcVTe88.md
UNCHANGED Notes/sponsored-ai-series-final-teaser — DYQ-NlTzDKk.md
UNCHANGED Notes/sponsored-save-later-vibe-coding-teaser — DcgYTivlSk1.md
UNCHANGED Notes/starport-project-name-without-explanation — DbYtjGXC42I.md
UNCHANGED Notes/structural-fingerprints-in-machine-written-stories — DaQwB1IOdhx.md
UNCHANGED Notes/structured-client-onboarding-workflow — DYDLGtQRwMC.md
UNCHANGED Notes/superbrain-s-answer-to-context-overload — Db8ZLi1FCsm.md
UNCHANGED Notes/teaser-for-hidden-anthropic-coding-rules — DdMtpWRDsuX.md
UNCHANGED Notes/temu-productivity-accessory-endorsement — DblN0Pqg0YS.md
UNCHANGED Notes/terminal-motion-design-automation-pipeline — DYiWOHFuUOC.md
UNCHANGED Notes/testing-memory-tiers-instead-of-name-dropping-rag — Db9xNeMmJ5g.md
UNCHANGED Notes/thirty-nine-editable-figma-prototypes-sold-as-a-bundle — DcxFvjUME1u.md
UNCHANGED Notes/three-dimensional-file-management-interface-concept — Db6HIohBN7u.md
UNCHANGED Notes/three-osint-dashboards-are-teased-without-names — DdSrg4QuKnw.md
UNCHANGED Notes/unexplained-high-stakes-teaser — DWkeVpakZc5.md
UNCHANGED Notes/unlisted-website-reference-collection — DWwdMAPDBUc.md
UNCHANGED Notes/unspecified-ai-release-excitement — DXFIMTpE1Zm.md
UNCHANGED Notes/unspecified-claude-and-davinci-resolve-workflow — DbysdqEIYym.md
UNCHANGED Notes/unspecified-multi-tool-agent-setup-breakdown — DcOo9WcRK4k.md
UNCHANGED Notes/using-frontier-plans-to-guide-cheap-models — Db_zOrOiZl2.md
UNCHANGED Notes/vague-warning-about-popular-ai-coding-tools — Dcz81oJA8Td.md
UNCHANGED Notes/video-guide-request-without-details — DXWt8FgCIp4.md
UNCHANGED Notes/viral-gpt-6-trading-profit-story-lacks-evidence — DdZoKmrk3vQ.md
UNCHANGED Notes/visual-ui-primitives-for-ai-builders — DcPgLEWgTPH.md
UNCHANGED Notes/voice-and-dashboard-controller-for-coordinating-ai-agents — DclXCdMgRF6.md
UNCHANGED Notes/voice-controlled-computer-assistant-built-with-realtime-tools — Dcun2LYA4Vm.md
UNCHANGED Notes/weekly-ai-news-claims-roundup — DXobNJdjVzp.md
UNCHANGED Notes/why-agent-self-improvement-needs-grounded-counter-metrics — DbBDnp6DcKV.md
UNCHANGED Notes/world-monitor-aggregates-open-data-for-live-geopolitics — DcjHVjDDM5N.md
UNCHANGED Notes/zero-asset-procedural-game-experiments-in-claude — DbQxzV5DW9D.md
UNCHANGED Saved AI Posts.base
UNCHANGED Topics/agents-and-coding.md
UNCHANGED Topics/ai-news.md
UNCHANGED Topics/business.md
UNCHANGED Topics/cad-and-3d.md
UNCHANGED Topics/design-tools.md
UNCHANGED Topics/hardware.md
UNCHANGED Topics/research.md
UNCHANGED Topics/security.md
UNCHANGED Topics/unsorted.md
UNCHANGED Topics/workflows-and-productivity.md
GEO_SHA256_BEFORE=MISSING
GEO_SHA256_AFTER=MISSING
```

## 4. Reviewed-tree pin dry run
```text
$ python publish_social_corpus.py --source C:\Users\dougl\Projects\general-ai\.local\social-catalog-20260919\publication-dryrun --vault-root C:\Users\dougl\AppData\Local\Temp\social-publisher-evidence-2bf247aeb74a427a9e55cd755ad25996\pin-vault --pin C:\Users\dougl\Projects\general-ai\.local\social-catalog-20260919\qa\reviewed-tree-pin-20260920.json
PIN_MATCH=legacy-file-map
EXCLUDED_DIR=Backups/
EXCLUDED_DIR=_review/
EXCLUDED_DIR=_evidence/
EXCLUDED_FILE=run-manifest.json
EXCLUDED_FILE=CONTRACT-EVIDENCE.md
EXCLUDED_FILE=Continuation plan and progress map.md
MODE=dry-run
SOURCE=C:\Users\dougl\Projects\general-ai\.local\social-catalog-20260919\publication-dryrun
TARGET=C:\Users\dougl\AppData\Local\Temp\social-publisher-evidence-2bf247aeb74a427a9e55cd755ad25996\pin-vault\50 Knowledge\57 Corpus\Saved AI Posts
CREATE 00 - Saved AI Posts Corpus Index.md
CREATE DM resources.md
CREATE Images/crucix-dashboard.png
CREATE Needs review.md
CREATE Notes/a-comment-gated-glossary-of-ai-builder-terms — DcNkAaQtZwv.md
CREATE Notes/a-curated-subset-of-claude-code-design-skills — DZv8-rvkZ9E.md
CREATE Notes/a-date-based-reminder-about-future-relevance — Da7zM_GpD_S.md
CREATE Notes/a-fable-five-operating-system-setup-offer — DaRxpoXHFIR.md
CREATE Notes/a-five-advisor-council-for-hard-decisions — DbJsAW7DbiD.md
CREATE Notes/a-four-prompt-opus-and-fable-comparison — DbMSwY9iOTK.md
CREATE Notes/a-hype-versus-output-ranking-of-ai-tools — DbDiZ5OlHVe.md
CREATE Notes/a-personal-claim-about-ai-relevance — Db6ZvnoPGUN.md
CREATE Notes/a-post-that-only-asks-fact-or-hype — DbtEt6ZC1GJ.md
CREATE Notes/a-skeptical-reading-of-stateless-mcp — Db_zB2xkkZt.md
CREATE Notes/a-week-of-fast-moving-ai-headlines — Db23365ACi-.md
CREATE Notes/agent-booking-mistake-exposes-api-authorization-gaps — Db3IJv1AJ1Q.md
CREATE Notes/agent-guide-lead-magnet — DXpxFmOHONg.md
CREATE Notes/agent-strategy-gated-by-a-follow — DYIRI90gs5E.md
CREATE Notes/agentic-claude-model-capability-roundup — DXTngscAIPK.md
CREATE Notes/agentic-os-course-destination — Da_Khm4ARLh.md
CREATE Notes/ai-generated-livestream-renders-episodes-ahead-of-playback — DcoxK0nIJa0.md
CREATE Notes/ai-news-recap-adds-claims-about-agents-and-media — DdD5JcjgQ8s.md
CREATE Notes/animation-resource-giveaway-for-figma-users — DWoYaIxDWJD.md
CREATE Notes/anonymous-ox-alpha-model-claims-and-access-links — DcTaQR3APjQ.md
CREATE Notes/anthropic-s-collection-of-claude-powered-objects — Dc3f2-UoHWf.md
CREATE Notes/anthropic-s-startup-guide-mention-without-a-link — DcbthMGn_bu.md
CREATE Notes/architecture-file-records-decisions-agents-cannot-infer — DdR5eAPOfT6.md
CREATE Notes/astra-experiments-across-games-worlds-and-figma — Dc8lPnHDjXC.md
CREATE Notes/autonomous-decision-tree-pattern-teaser — DcOCgBkNNjK.md
CREATE Notes/base-s-knowledge-graph-context-loading-pitch — DcbFunokXyI.md
CREATE Notes/bedroom-ready-ai-application-infrastructure-stack — DVNcIoBgH9Q.md
CREATE Notes/bilevel-loops-promised-as-a-fivefold-upgrade — DbjLy_tormR.md
CREATE Notes/blueprint-promises-a-prompt-to-build-workflow — DdKmOKvDEIe.md
CREATE Notes/bolt-forge-advertises-expanded-model-usage-limits — DdTs3PIpq3L.md
CREATE Notes/building-an-mcp-host-around-multiple-servers — Dbhdx66GL3O.md
CREATE Notes/cache-to-cache-communication-skips-text-between-models — DdatXCRmVwW.md
CREATE Notes/case-studies-for-less-uniform-websites — DYCIEb8MLKU.md
CREATE Notes/chatbot-assisted-personal-data-cleanup — DYWm6yygPWm.md
CREATE Notes/checklist-for-making-vibecoded-websites-credible — DcoBxsSodtT.md
CREATE Notes/claude-assisted-breach-story-claims-a-dramatic-chain — DdcK88DD-IR.md
CREATE Notes/claude-built-bluetooth-finder-for-a-managed-phone — DbqRmHYjfyD.md
CREATE Notes/claude-code-guide-behind-an-engagement-gate — DcRENuwpjpk.md
CREATE Notes/claude-code-session-to-session-handoffs — DbxTRFJBpzd.md
CREATE Notes/claude-code-workflow-for-web-design — DblU1r_HA5p.md
CREATE Notes/claude-design-access-workaround-teaser — DYC1yvhsckC.md
CREATE Notes/claude-loops-replacing-manual-prompting — DZXsQkKgEeQ.md
CREATE Notes/claude-plugins-skills-and-mcp-starter-set — DZkt4AxCTfJ.md
CREATE Notes/claude-second-brain-skill-teaser — DXxGZjsD_PH.md
CREATE Notes/claude-skills-for-end-to-end-interface-design — DZtuV9Bk5GZ.md
CREATE Notes/codex-and-claude-guide-teaser-requires-a-comment — DdappS3nEtK.md
CREATE Notes/command-line-tools-inside-claude-code — DXjlj-GDXBJ.md
CREATE Notes/comparing-sol-and-fable-on-coding-economics — DastBeBAMB_.md
CREATE Notes/component-library-teaser-for-developers — DXtgNKPEjs7.md
CREATE Notes/computer-vision-reads-poker-tells — Dapvu1TgMX8.md
CREATE Notes/context-graph-as-the-post-swarm-product — Dc05tndxpWt.md
CREATE Notes/conversational-product-building-pitch — DXh-ACgk-f0.md
CREATE Notes/creative-developer-projects-show-small-experiments-shipping — DcuI3KiDuyu.md
CREATE Notes/crucix-local-osint-intelligence-terminal — DbQyH2NBc7C.md
CREATE Notes/day-one-claude-project-showcase — DZZ-FWADu5_.md
CREATE Notes/deepseek-v4-flash-pricing-and-benchmark-pitch — Dbirg1tGZXJ.md
CREATE Notes/designer-made-ui-library-for-ai-prompts — DcPgGapgaJG.md
CREATE Notes/designer-made-ui-library-supplies-prompts-to-ai — DczqUuMgOk2.md
CREATE Notes/designer-oriented-claude-skill-shortlist — DXg6gAVjKwF.md
CREATE Notes/developer-decision-fatigue-meme — DcL1SNXIt6A.md
CREATE Notes/discounted-api-proxy-underground-economy — DYhR9kvDXKz.md
CREATE Notes/early-claude-fable-demos-showcase-rapid-browser-builds — DcyTLjagPxg.md
CREATE Notes/early-knowledge-graph-implementation-teaser — DcHG2kPtZZG.md
CREATE Notes/editable-canva-layers-from-ai-posters — DXs9baSDcG6.md
CREATE Notes/editable-code-based-image-generation-with-reinforcement-learning — DceUGnuh-KA.md
CREATE Notes/eight-frontier-ai-developments-from-july — DbD_eQ2EhbF.md
CREATE Notes/eli5-visual-explainer-workflow-for-claude-code — DcY8rf9jUY7.md
CREATE Notes/entrepreneurship-meme-without-substance — DYezDRbqEYJ.md
CREATE Notes/execute-code-harness-versus-mcp-token-study — Dcd5smMHH8T.md
CREATE Notes/five-browser-resources-for-practical-design-work — DcjDy50DXp4.md
CREATE Notes/five-claude-skills-for-faster-building — DX1skMrlTJL.md
CREATE Notes/five-psychology-lessons-framed-through-claude — DaxObZGACq6.md
CREATE Notes/folder-versus-agentic-system-provocation — DbwnCJqRtXJ.md
CREATE Notes/font-references-for-creative-project-work — DbLQJHKgblS.md
CREATE Notes/frame-based-scroll-animation-production-pipeline — DW7lN7sj2ow.md
CREATE Notes/framer-chimes-and-parallax-animation-tutorial — DcmbRpjsRB4.md
CREATE Notes/frontier-planning-turns-cheap-models-into-executors — Db08WMRlZc5.md
CREATE Notes/fusion-axis-combines-numpad-trackpad-and-controls — DcwhNwfsgnZ.md
CREATE Notes/gbp-management-income-claim-uses-a-personal-results-disclaimer — DdXXo_Bll7v.md
CREATE Notes/gemini-animated-logo-email-tactic — DXs4k6nD3V6.md
CREATE Notes/genjutsu-s-performance-preserving-video-transformation — Dc1kFA-gFa_.md
CREATE Notes/geospy-style-visual-geolocation-from-ordinary-photos — Dc3YS5Ush9I.md
CREATE Notes/gesture-controls-for-ai-coding-agent-prototypes — DcdtNz1DgGL.md
CREATE Notes/google-s-canva-challenge-teaser — Dc1h11QDhc4.md
CREATE Notes/gpt-6-astra-as-a-computer-operating-agent — Dc1qHoaAeeC.md
CREATE Notes/gpt-image-2-creative-showcase-claims — DXery6FkoU4.md
CREATE Notes/graph-debugging-rant-without-the-diagnosis — DcTIPKyt7Am.md
CREATE Notes/graph-theory-turns-rubiks-cube-states-into-a-network — Ddd9mmFDd1d.md
CREATE Notes/grok-bot-as-a-team-of-specialized-agents — DcY1-eIEriY.md
CREATE Notes/grok-bot-research-desk-for-trading-analysis — DcvuQQcjEPD.md
CREATE Notes/grok-bot-s-shared-login-blast-radius — DcHPKO-gQLs.md
CREATE Notes/hands-replace-the-mouse-in-a-gesture-interface — Db--miYgE93.md
CREATE Notes/hermes-agent-turns-imessage-into-delegated-work — Dcw8PvpAsNQ.md
CREATE Notes/hidden-design-resource-directory-teaser — DYCulDljFrW.md
CREATE Notes/higgsfield-open-source-api-story-makes-sweeping-claims — DdZcmXHgO-I.md
CREATE Notes/humanoid-interface-prototype-turns-gestures-into-feedback — Dcjw9HJOicn.md
CREATE Notes/inspiration-list-for-claude-code-interfaces — DdMCJyagZgR.md
CREATE Notes/jarvis-platform-waitlist-teaser — DZ5H6F1Rz1S.md
CREATE Notes/jev-returns-typed-decisions-instead-of-open-ended-prose — DdV0piwMiFX.md
CREATE Notes/karpathy-method-loop-engineering-needs-source-details — Dcw-B00FW8c.md
CREATE Notes/language-differences-in-claude-s-expressed-values — DcOkXhXIPZq.md
CREATE Notes/lean-checked-mathematical-advances-attributed-to-astra — Dbihv5FgPhH.md
CREATE Notes/life-operating-system-slogan — DYiLHRWjJDv.md
CREATE Notes/limits-of-language-models-as-scientific-discoverers — DblwLc1DGTk.md
CREATE Notes/link-only-claude-promotion — DXlFWL5EkaN.md
CREATE Notes/llm-versus-zero-slogan — DZcSLefuxRU.md
CREATE Notes/local-stack-for-a-one-person-agent-company — Db7T7ekFUJd.md
CREATE Notes/longer-agent-loops-as-a-quality-lever — DcMXqu3FIQm.md
CREATE Notes/lovable-case-study-for-a-multimodal-travel-app — DbmXSIsGsIO.md
CREATE Notes/macro-s-open-source-rust-productivity-suite — Db-_SxJA1vc.md
CREATE Notes/magnific-desktop-restyles-footage-with-generative-video — Dcol65KqGRt.md
CREATE Notes/manus-web-list-teased-behind-an-advertisement — DdTaFrPxL7S.md
CREATE Notes/manus-website-tools-behind-a-comment-gate — DaU7F9UPje_.md
CREATE Notes/manus-workflow-promoted-through-comment-replies — DbT2ub4ul2F.md
CREATE Notes/mindchuk-s-promise-for-creative-idea-storage — Dbw6f0NMhFr.md
CREATE Notes/model-choice-changes-ai-video-direction — DaSKuTchY_S.md
CREATE Notes/model-hardware-standard-connects-ai-to-lab-equipment — DcjaksLIKL_.md
CREATE Notes/multi-computer-ai-farm-offered-through-a-comment-gate — DdT8AVqjNqD.md
CREATE Notes/muse-code-as-meta-s-terminal-agent — Dbuq2TOFLZt.md
CREATE Notes/neural-model-hiking-visuals-are-a-creative-experiment — DdFSAeiskGW.md
CREATE Notes/nine-open-source-substitutes-for-paid-software — DcRCbwwgBCJ.md
CREATE Notes/odysseus-automation-business-model-question — DZJK6z4zZqO.md
CREATE Notes/one-prompt-for-a-thousand-agents — Db9f8vyP02z.md
CREATE Notes/one-sitting-claude-project-showcase — DY7SqKBjdU4.md
CREATE Notes/open-source-repositories-for-ai-builders — DYH0A64NmO9.md
CREATE Notes/openart-arena-ranks-creative-models-by-use-case — DdbzswWgCsM.md
CREATE Notes/ornith-1-5-s-range-from-server-to-mobile — DcReeYcE48Y.md
CREATE Notes/osiris-open-source-intelligence-globe — DYoUzjDibG6.md
CREATE Notes/osiris-surveillance-capability-pitch — DYqhTtMxfqZ.md
CREATE Notes/otto-proposes-a-plug-in-computer-for-ai-agents — DdDcXQQAt3L.md
CREATE Notes/palantir-maven-and-ai-targeting-governance — DcW6VyMy2sS.md
CREATE Notes/paper-design-files-expose-structure-to-coding-agents — DctpN2TgTjN.md
CREATE Notes/parametric-design-as-a-taste-control-system — DbFhIg-iYYj.md
CREATE Notes/pay-to-rank-leaderboard-growth-experiment — DcROR_Ykh1i.md
CREATE Notes/persistent-claude-memory-with-obsidian — DV_adJTkyeN.md
CREATE Notes/personalized-patio-outreach-for-contractors — DaXsPn6I2Mf.md
CREATE Notes/phone-farms-exploit-directions-based-local-ranking-signals — DdaiP3dTJge.md
CREATE Notes/physical-status-display-makes-terminal-agents-ambient — DcwC9lUMJ5O.md
CREATE Notes/polar-browser-s-automation-promise — DbcBe_4AFPw.md
CREATE Notes/portable-computer-runs-a-local-agent-on-dgx-spark — DctNmzJgPXb.md
CREATE Notes/portfolio-ebook-promotion-for-designers — DX4vTYIDPR2.md
CREATE Notes/portfolio-template-bundle-promoted-through-a-comment — DdWBqDuIcqp.md
CREATE Notes/prime-agent-s-recursive-harness-and-arc-benchmark — Dbw4LvkMBj9.md
CREATE Notes/promised-ninety-six-percent-efficiency-research — Db7AH33MHvg.md
CREATE Notes/prompt-driven-claude-prototyping-workspace — DXa1R1-DR5m.md
CREATE Notes/prompt-writer-comparison-for-seedance-videos — DXHXJ-rMzlL.md
CREATE Notes/prototype-realtime-news-processing-for-trading-research — DdNjyfNyx2e.md
CREATE Notes/quest-3-prototype-for-mixed-reality-agent-work — DcNrwpyiRlh.md
CREATE Notes/rag-services-as-a-founder-revenue-path — DcTLl70CZM9.md
CREATE Notes/rapid-interactive-builds-attributed-to-gpt-6-astra — Dc6QnFyDhfX.md
CREATE Notes/real-time-monitors-for-a-trading-data-pipeline — DcdsqMsyoEH.md
CREATE Notes/security-cost-warning-without-specifics — DYgukfFNZD5.md
CREATE Notes/seedance-feature-film-launch-and-giveaway — Db3hz3YgHMt.md
CREATE Notes/selling-packaged-open-source-repos-as-agency-offers — Dcv9HtHDLDZ.md
CREATE Notes/seven-ai-breakthroughs-spanning-research-and-robotics — Dblfgz5ksQ3.md
CREATE Notes/seven-github-repositories-behind-ai-startups — DbQdU7BmK7h.md
CREATE Notes/seven-unverified-headlines-in-one-technology-roundup — DbqqVN8ksQV.md
CREATE Notes/seventeen-chatgpt-image-transformation-commands — Dc3abXpAESW.md
CREATE Notes/shadowbroker-self-hosted-geospatial-intelligence-stack — DbaX4PPq2uZ.md
CREATE Notes/six-claude-skills-for-designed-outputs — DZp3_CJCPaI.md
CREATE Notes/six-developer-experiments-span-maps-cad-and-charts — DcyqOCYDlWC.md
CREATE Notes/six-reusable-documents-tame-client-project-chaos — DctXXS8DjnA.md
CREATE Notes/sponsored-ai-series-continuation — DYOqDcVTe88.md
CREATE Notes/sponsored-ai-series-final-teaser — DYQ-NlTzDKk.md
CREATE Notes/sponsored-save-later-vibe-coding-teaser — DcgYTivlSk1.md
CREATE Notes/starport-project-name-without-explanation — DbYtjGXC42I.md
CREATE Notes/structural-fingerprints-in-machine-written-stories — DaQwB1IOdhx.md
CREATE Notes/structured-client-onboarding-workflow — DYDLGtQRwMC.md
CREATE Notes/superbrain-s-answer-to-context-overload — Db8ZLi1FCsm.md
CREATE Notes/teaser-for-hidden-anthropic-coding-rules — DdMtpWRDsuX.md
CREATE Notes/temu-productivity-accessory-endorsement — DblN0Pqg0YS.md
CREATE Notes/terminal-motion-design-automation-pipeline — DYiWOHFuUOC.md
CREATE Notes/testing-memory-tiers-instead-of-name-dropping-rag — Db9xNeMmJ5g.md
CREATE Notes/thirty-nine-editable-figma-prototypes-sold-as-a-bundle — DcxFvjUME1u.md
CREATE Notes/three-dimensional-file-management-interface-concept — Db6HIohBN7u.md
CREATE Notes/three-osint-dashboards-are-teased-without-names — DdSrg4QuKnw.md
CREATE Notes/unexplained-high-stakes-teaser — DWkeVpakZc5.md
CREATE Notes/unlisted-website-reference-collection — DWwdMAPDBUc.md
CREATE Notes/unspecified-ai-release-excitement — DXFIMTpE1Zm.md
CREATE Notes/unspecified-claude-and-davinci-resolve-workflow — DbysdqEIYym.md
CREATE Notes/unspecified-multi-tool-agent-setup-breakdown — DcOo9WcRK4k.md
CREATE Notes/using-frontier-plans-to-guide-cheap-models — Db_zOrOiZl2.md
CREATE Notes/vague-warning-about-popular-ai-coding-tools — Dcz81oJA8Td.md
CREATE Notes/video-guide-request-without-details — DXWt8FgCIp4.md
CREATE Notes/viral-gpt-6-trading-profit-story-lacks-evidence — DdZoKmrk3vQ.md
CREATE Notes/visual-ui-primitives-for-ai-builders — DcPgLEWgTPH.md
CREATE Notes/voice-and-dashboard-controller-for-coordinating-ai-agents — DclXCdMgRF6.md
CREATE Notes/voice-controlled-computer-assistant-built-with-realtime-tools — Dcun2LYA4Vm.md
CREATE Notes/weekly-ai-news-claims-roundup — DXobNJdjVzp.md
CREATE Notes/why-agent-self-improvement-needs-grounded-counter-metrics — DbBDnp6DcKV.md
CREATE Notes/world-monitor-aggregates-open-data-for-live-geopolitics — DcjHVjDDM5N.md
CREATE Notes/zero-asset-procedural-game-experiments-in-claude — DbQxzV5DW9D.md
CREATE Saved AI Posts.base
CREATE Topics/agents-and-coding.md
CREATE Topics/ai-news.md
CREATE Topics/business.md
CREATE Topics/cad-and-3d.md
CREATE Topics/design-tools.md
CREATE Topics/hardware.md
CREATE Topics/research.md
CREATE Topics/security.md
CREATE Topics/unsorted.md
CREATE Topics/workflows-and-productivity.md
GEO_SHA256_BEFORE=MISSING
GEO_SHA256_AFTER=MISSING
```

## 5. Deletion-call grep proof
```text
$ grep -En 'os\\.remove|\\.unlink\\(|rmtree\\(|shutil\\.move' C:\Users\dougl\Projects\general-ai\.claude\worktrees\instagram-saved-catalog-29bc2e\.local\publish_social_corpus.py
NO_DELETE_CALLS_FOUND
```

## Script help
```text
$ python publish_social_corpus.py --help
usage: publish_social_corpus.py [-h] --source SOURCE --vault-root VAULT_ROOT
                                [--apply] [--pin PIN] [--write-pin WRITE_PIN]
                                [--backup-root BACKUP_ROOT] [--report REPORT]

Safely publish the reviewed Saved AI Posts corpus into its fixed vault folder.

options:
  -h, --help            show this help message and exit
  --source SOURCE       staging publication-dryrun tree
  --vault-root VAULT_ROOT
                        Obsidian vault root
  --apply               perform creates and agent-authored updates
  --pin PIN             reviewed tree pin JSON
  --write-pin WRITE_PIN
                        write a new pin JSON for this source tree
  --backup-root BACKUP_ROOT
                        backup destination outside the vault
  --report REPORT       write a JSON run report
```

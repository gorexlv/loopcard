# Content and discovery review — 2026-09-19

Independent assessments: design review by content_design_audit; source/browser and detector evidence by content_evidence_audit. Both inspected separate live tabs. No detector findings were supplied to the design assessment. Detector exit 0 with no findings; this does not establish content quality.

## Before

The accepted layout and in-place flip interaction were retained. The problem was the reward for interacting:

- 48 of 52 built-in decks used generic answer templates, representing 144 cards. Turning Color Theory did not explain complementary colors.
- Formula-generated save counts pushed unfinished cards into the default Popular order.
- Bare nouns failed to identify a recall task. The homepage chemistry sample offered little discovery.
- The Journal used repeated blank-card still lifes instead of illustrating its practical advice. Its four articles do contain distinct text; they are not identical placeholders.

Assessment A rated applicable interaction/content heuristics 19/32. This is a baseline content-health score, not a visual or post-change score. Status 3, real-world task 1, control 3, consistency 3, recognition 2, efficiency 2, minimalism 3, help 2; error prevention/recovery not assessed.

## Direction and implementation

A card should offer a clear attempt and a concrete answer. The first iteration comprises six complete, three-card collections: color, conversational English, photography, typography, café French, design. Content diagrams encode the question: color relationships, aperture openings, letterforms, or a sentence to complete. Prompts remain self-contained when diagrams are unavailable.

Discovery lists eight completed built-in decks, including the two existing real-content collections. Forty-four unfinished catalog entries are excluded from discovery; their old detail URLs and SEO route generation remain available. Rewriting those legacy decks is outside this bounded first iteration. Database decks remain eligible and are not overwritten.

The default order is editorial selection. Fabricated save counts are no longer shown. The homepage demonstrates three actual cards from the collections. The Journal opens with a usable language card and replaces repeated stock images with article-specific examples; article bodies, metadata and structured data remain.

## Verification

Desktop and 390px browser inspections cover discovery, front/back states, homepage and Journal. Type checks passed, the production build generated 76 pages, and all 18 Vitest tests passed. Public study was verified through the second card, not just the cover. No post-change attractiveness score is claimed; editorial appeal still requires user judgment.

Questions skipped: the user explicitly requested analysis followed by implementation; layout and brand direction were already settled.

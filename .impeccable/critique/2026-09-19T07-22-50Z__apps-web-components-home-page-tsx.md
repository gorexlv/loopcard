---
target: Loopcard Web visual review
total_score: 25
max_score: 40
na_heuristics:
p0_count: 0
p1_count: 3
target_identity: "file:/Users/rexlv/Workspace/github.com/gorexlv/loopcard/apps/web/components/home-page.tsx"
target_fingerprint: "sha256:3ccb68bbe88702937769fccf4263049165dc73270b90d063f1aa680aa8d6224e"
target_path: /Users/rexlv/Workspace/github.com/gorexlv/loopcard/apps/web/components/home-page.tsx
timestamp: 2026-09-19T07-22-50Z
slug: apps-web-components-home-page-tsx
---
Method: dual-agent (A: /root/design_review · B: /root/design_evidence), parent desktop/mobile screenshot synthesis.

# Loopcard Web visual review — 2026-09-19

Visual score: **34/100**. Independent source + desktop review A: 39/100; synthesis includes mobile text clipping, tiny controls, and discovery hierarchy. These are editorial judgments against the user's quiet, tactile pocket-card brand brief, not automated benchmark scores.

| Dimension | Score |
|---|---:|
| Layout and hierarchy | 7/20 |
| Typography | 8/20 |
| Material and component detail | 8/20 |
| Motion and state continuity | 4/20 |
| Brand specificity and consistency | 7/20 |

## Evidence and limits

Actual screenshots: homepage English/Chinese desktop, English mobile at 390×844, mobile homepage revealed state and deck tiles, public study front/back, mobile market first viewport. Read-only computed styles corroborated measurements. Desktop assessment A viewed home/study at 1280×720. Parent Chinese desktop at 1280×800. Full-page capture stitching produced artifacts and was excluded. Authenticated editor/library not visually scored; source-only inspection noted separately. No production files changed during review.

## Specificity verdict

The page uses generic split hero composition, system serif display type, pale rounded panels, and teal actions. These are coherent enough to operate but do not express a distinctive Loopcard object or interaction language. Quietness comes mostly from reduced content and contrast; the card itself is not yet an authored brand asset. Removing copy did not establish a brand system.

## Priorities

1. P1 — Mobile card previews clip content. At 390px, deck tiles are 165px wide and miniature prompt text has about 52px available at 23px type. “borrow” is visibly truncated. Nested preview cards are decorative at the expense of reading. `globals.css:56`, `quiet.css:177–180`, `deck-tile.tsx:9–19`.
2. P1 — Discovery hierarchy spends the entire 844px mobile market viewport on header, heading, description, large statistics, search, sort and filters. No deck is visible. The homepage also lets a generic slogan compete with its working card. `home-page.tsx:27`, `market/page.tsx`, `afterimage.css`, `quiet.css`.
3. P1 (brand objective) — Card identity is inconsistent: wide homepage demo, different study proportions, dark portrait market preview with 3D rotation, and separate editor preview. Border, radius, content hierarchy and motion have no single source of truth. `quiet.css:21,53,112`, `afterimage.css:61`.
4. P2 — Typography is uncontrolled across platforms and languages. Web has no bundled typeface. Iowan/Baskerville and Avenir/Segoe depend on system availability; Chinese display glyphs fall back. Chinese heading inherits italic treatment and English tracking. Homepage rating labels compute to 10px. Chinese profile label remains English. `globals.css:1`, `quiet.css:14–16`, `account-link.tsx:19–20`.
5. P2 — Motion does not communicate the learning action. Homepage reveal swaps content without an authored face transition. Study uses 5px fade/10px entrance; rating has no departure or continuity. Marketplace uses a separate 550ms 3D flip. Demo rating order is remembered/fuzzy/forgot; study order is forgot/fuzzy/remembered, with keys 3/2/1. `inline-study-demo.tsx:16–28`, `study-experience.tsx:97–105`, `quiet.css:121–122`.

## Implementation cause

Three global stylesheets remain layered: globals, afterimage, quiet. New styling overrides selected properties while inheriting previous layout behavior. Example: `.curated-grid .deck-tile:last-child` outranks `.quiet-home .deck-tile` and removes the last tile's right border. This needs consolidation after the design contract is defined, not further override accumulation.

## What works

The learning flow is focused, primary actions have labels, progress and undo exist, keyboard controls exist, and reduced motion is implemented. These are useful functional foundations, not substitutes for visual quality.

## Cognitive load and emotional journey

Homepage splits attention between immediate demo, Start studying and Create a deck; Start studying opens English vocabulary despite the adjacent chemistry demo. Market exposes search, sort and six category controls before content. New users lose topic continuity; habitual learners face reversed rating positions; mobile users encounter clipped prompts. The journey stays calm but has no distinctive reveal, rating or completion moment.

## Nielsen usability (separate from visual score)

| Heuristic | Score /4 | Finding |
|---|---:|---|
| Status visibility | 3 | Progress present; rating confirmation weak |
| Real-world match | 3 | Card/reveal language understandable |
| Control and freedom | 3 | Back and undo; editor removal recovery absent in source |
| Consistency | 2 | Rating order and card forms differ |
| Error prevention | 2 | Required fields; destructive row removal immediate |
| Recognition | 3 | Labeled actions; some icons require inference |
| Efficiency | 3 | Keyboard and bulk entry |
| Minimalism | 2 | Nested cards and competing actions persist |
| Recovery | 2 | Study undo; authenticated save/error not exercised |
| Help | 2 | FAQ and concise study help |
| Total | 25/40 | Usability estimate, not visual quality |

## Automated check

Detector scanned 17 component TSX and 22 app markup files: both runs exit 0, zero findings. This only indicates no matching mechanical rules. It does not detect the observed design weaknesses. Browser overlay was unavailable because the selected browser's evaluate is read-only; no overlay was claimed.

## Recommended repair order

Define and demonstrate one shared card object and full reveal → rate → next motion sequence; establish explicit Chinese/English type roles and sizes; rebuild homepage and discovery composition around cards; consolidate CSS; validate actual desktop/mobile light/dark screenshots, long content and reduced motion before declaring completion.

Known direction and scope are already supplied by the user: quiet tactile brand, entire web, concise product copy, preserved SEO. This review does not request those decisions again.

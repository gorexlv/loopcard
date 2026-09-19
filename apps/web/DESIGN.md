---
name: Loopcard Web
description: A quiet, tactile pocket-card collection.
colors:
  paper: "#f5f3ed"
  paper-bright: "#fffdf7"
  ink: "#243830"
  muted: "#66716a"
  line: "#dcded4"
  deep-green: "#275d4b"
  card-stock: "#fffdf5"
  card-back: "#f0f4eb"
  card-line: "#d8dbcf"
  card-ink: "#263c32"
  card-muted: "#697469"
typography:
  display:
    fontFamily: "Loop Sans, sans-serif"
    fontSize: "clamp(30px, 3.3vw, 42px)"
    fontWeight: 500
    lineHeight: 1.25
    letterSpacing: "-0.025em"
  body:
    fontFamily: "Loop Sans, sans-serif"
rounded:
  control: "8px"
  card: "12px"
spacing:
  compact: "8px"
  inset: "24px"
  card-inset: "28px"
components:
  button-primary:
    backgroundColor: "{colors.deep-green}"
    textColor: "{colors.paper}"
    rounded: "{rounded.control}"
    padding: "12px 22px"
  button-ghost:
    backgroundColor: "transparent"
    textColor: "{colors.ink}"
    rounded: "{rounded.control}"
    padding: "12px 22px"
---

# Design System: Loopcard Web

## Overview

**Creative North Star: "A quiet, tactile pocket-card collection"**

Warm paper, deep green ink and compact controls frame the card as the primary object. Copy stays brief; a prompt, a turn and a rating communicate the central interaction. The LoopCard mark remains on card faces and collection covers.

**Key Characteristics:**

- Paper surfaces with restrained depth.
- One humanist sans-serif family across Latin and Chinese interface/content text.
- Shared card geometry and purposeful motion across discovery, recall and editing.

This captures the implementation on 2026-09-19. The full card treatment covers `/`, `/market`, `/market/[slug]`, `/study/[slug]`, `/app/study/[id]` and editor previews in `/app/decks/new` and `/app/decks/[id]`. Workspace and login receive supporting typography, palette and spacing. Tools, reading pages, download notices and login now share the same typography, controls and surfaces; this is not a claim of whole-app localization.

## Colors

The light palette uses warm paper neutrals and a deep green action color. Frontmatter records the light tokens; `app/quiet.css` remains the implementation source.

- **Primary:** deep green identifies actions and focus; ink provides the stronger reveal and successful-rating fills.
- **Neutral:** paper is the page, bright paper supports fields and surfaces, muted ink carries secondary labels, and soft lines divide content.
- **Card:** stock and pale green reverse distinguish the two faces without changing the object.
- **Collection tones:** sage, sand, blue and rose differentiate covers by category; they are supporting materials rather than additional primary actions.

Dark mode uses explicit overrides on `html[data-theme=dark]`: forest paper (`#192720`), raised paper (`#23342b`), pale ink (`#eceee4`) and a light green action (`#bad0a8`). Card stock and reverse become separate forest tones. Keep these theme overrides together with their light counterparts.

## Typography

**Single family:** locally hosted Noto Sans SC, named `Loop Sans` in CSS. Both `--font-body` and `--font-display` resolve to this family. No UI role switches to Newsreader, Inter, or a platform-specific display face.

`fonts.css` defines the 100–900 variable weight range. `loop-sans-latin.woff2` (55KB) covers Latin and common punctuation, `loop-sans-ui.woff2` (136KB) covers remaining source characters, and the complete Noto Sans SC file supplies uncommon content. Run `python3 apps/web/scripts/build-fonts.py` to regenerate subsets and their matching unicode ranges. Font synthesis is disabled. The original OFL notice remains in `public/fonts`.

- Page titles: 30–42px, weight 500, line-height 1.25–1.3.
- Section titles: 22–25px, weight 500, line-height 1.4.
- Body: 16px, weight 400, line-height 1.8–1.85; control text 13–15px.
- Card questions fit their longest word and available container width; illustrated prompts use 23–25px in recall and 16–21px in covers.
- Latin heading tracking is restrained; Chinese headings use normal tracking.
- Typography Anatomy uses a static outline illustration of two letterforms. It is educational content, not another loaded interface font.

## Layout

Public collections and discovery use a centered maximum width (1136px); the header reaches 1200px. Catalog covers move from four columns to three at 1000px and two at 700px. Homepage collections retain four columns at the intermediate width. Side margins reduce from 32px to 20px on mobile.

The homepage active card is 320px wide, reducing to at most 280px on mobile, with partial neighboring cards. Study centers a single card in a stage up to 400px wide, reducing to 350px on mobile. The editor combines a card list, fields and the same preview object; the editing stage collapses at 1000px and the broader builder at 700px.

**The Cascade Boundary Rule.** Root layout imports `globals.css`, then `afterimage.css`, then `fonts.css`, `quiet.css`, and `system.css`. The first two still support legacy routes and structures. The last two files own this visual layer and aliases the older `--after-*` palette variables. Do not remove earlier styles as though every route had migrated.

## Elevation & Depth

Depth belongs mainly to physical cards and covers. The shared card shadow is `0 12px 30px #263c3212, 0 2px 4px #263c3208`, with a darker theme equivalent. Covers add a faint inset spine and lift 3px on hover. Primary controls remain flat. Avoid multiplying elevated wrappers around the card object.

## Shapes

Cards have gently rounded corners (12px), a thin stock-colored border and generous internal padding. Controls use tighter corners (8px); icon controls are circular with a 44px hit area. Covers use an asymmetric book-like silhouette (`6px 12px 12px 6px`) and an inset spine.

## Components

### Buttons and fields

Primary and ghost buttons use compact body type, a minimum height of 46px and the frontmatter insets. Reveal fills the available width and uses ink on paper contrast. Catalog search is a quiet, borderless field above a divider; selects stay compact. Editor fields retain explicit labels. Keyboard focus uses a two-pixel action-colored outline with a five-pixel offset. Disabled controls remain visibly disabled.

### Navigation

The header combines the retained mark, muted text links and compact preferences. Below 700px, a disclosure menu replaces desktop links; the language control remains visible. Focused study hides workspace navigation and keeps its own compact back/title/progress row.

### Shared recall card

`RecallCard` renders front and back in the same grid cell. The front carries category, prompt, imprint and index; the reverse carries the answer label, heading/body and matching imprint. The inactive face is hidden from assistive technology. Demo, study, public preview and editor reuse this component; editor preview does not introduce a separate visual card language.

Deal-in takes 420ms, the turn 520ms and filing after a rating 220ms. The common easing is `cubic-bezier(.2,.8,.2,1)`. Filing moves left for `forgot`, vertically for `fuzzy`, and right for `clear`. The pending-motion guard blocks duplicate advances; study undo and deck switching also guard pending commits.

Ratings always read left to right as `forgot`, `fuzzy`, `clear`, displayed as **Again / Almost / Got it** or **再想想 / 有点模糊 / 记住了**. Study keyboard mappings are **1 / 2 / 3** respectively; Space or Enter reveals, and U undoes. Shortcuts defer to focused interactive elements. Do not infer server scheduling from rating motion: public study progress remains local storage state.

With reduced motion enabled, animations and transitions stop, the card uses face visibility rather than a 3D turn, and the rating commit delay becomes zero. Keep both faces usable in this mode.

### Collection cover

`DeckTile` uses the first prompt (or deck title), category, imprint and card count, followed by a simple caption. The cover is a semantic flip button; the caption is the separate detail link. Covers scale at native width:height 1:1.74. Curated diagrams convey the question without altering the saved text prompt. Preserve semantic subscripts through `CardPrompt`, the category tone and responsive long-word sizing.

## Do's and Don'ts

- **Do** reuse the common card object and rating order across applicable surfaces.
- **Do** preserve semantic controls, focus visibility, keyboard behavior, undo and reduced motion.
- **Do** preserve public SEO routes, metadata and structured data while simplifying visible copy.
- **Do** maintain both common CJK subset and full fallback when updating fonts.
- **Don't** expand concise labels into promotional explanations inside the recall flow.
- **Don't** treat supporting styles or bilingual examples as proof that every route is redesigned or translated.
- **Don't** turn card animation or local ratings into claims about backend scheduling.

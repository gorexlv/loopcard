# LoopCard Afterimage redesign — design QA

## Comparison target

- Source visual truth: `/Users/rexlv/.codex/generated_images/01a04927-12e5-7c61-9c05-ad1c639e352d/exec-39a9e58c-7b57-49d0-bbaf-0784b3de3e3e.png`
- Normalized source: `docs/afterimage-qa/source-normalized.png`
- Browser-rendered implementation: `docs/afterimage-qa/final/01-home-desktop.png`
- Full-view comparison: `docs/afterimage-qa/final/home-source-comparison.png`
- Focused hero comparison: `docs/afterimage-qa/final/hero-focused-comparison.png`
- Latest identity/hero comparison: `docs/afterimage-qa/final/identity-detail-comparison.png`
- Additional responsive and interaction evidence: `docs/afterimage-qa/final/02-home-story.png` through `18-journal-dark.png`

## Normalization

- Source image: 1536 × 1024 px, normalized to 1440 × 1024 px with proportional resize and a neutral bottom extension.
- Implementation: 1440 × 1024 CSS px, DPR 1, 1440 × 1024 output pixels.
- Focused comparison: matching 1440 × 720 hero crops.
- State: English, light product theme, cinematic hero video loaded; the hero itself remains dark by design.
- Mobile: 390 × 844 CSS px, DPR 1; static poster fallback with video disabled.

## Findings and iteration history

### Iteration 1 — blocked

- [P1] The first implementation capture occurred during the title mask animation, leaving the headline partially invisible.
  - Fix: stabilized capture timing after the 800 ms reveal and verified the complete title at desktop and mobile sizes.
  - Evidence: `docs/afterimage-qa/home-comparison-v1-stable.png`.
- [P1] Search/filter regression after adding deferred query rendering left the Market result grid unchanged.
  - Fix: restored immediate controlled filtering while preserving the live result announcement and empty state.
  - Evidence: `docs/afterimage-qa/final/05-market-filtered.png`; exact single-result assertion passes.
- [P2] Mobile category controls previously clipped on horizontal edges.
  - Fix: retain wrapped filters at small breakpoints; all controls remain fully visible and keyboard reachable.
  - Evidence: `docs/afterimage-qa/final/09-market-mobile.png`.
- [P2] The 1254 px logo was transferred twice and pushed the page weight to roughly 2.9 MB.
  - Fix: serve a 96 px WebP logo in navigation, reduce the install icon to 512 px, and remove the unused hero source PNG from public output.
  - Evidence: Lighthouse transfer size reduced to 945 KiB.
- [P2] `onCanPlay` delayed the video fade under throttling and produced a 9.0 s LCP.
  - Fix: fade on `loadeddata`; keep the poster as the immediate visual and retain metadata-only video preload.
  - Evidence: final Lighthouse LCP 3.1 s, CLS 0, TBT 10 ms.
- [P1] The first final mobile-menu capture inherited the dark hero foreground on a paper menu, making links too faint.
  - Fix: added an explicit ink foreground, paper surface, compact radius, and high-contrast hover state for the hero menu.
  - Evidence: final `docs/afterimage-qa/final/08-home-mobile.png`.

### Iteration 2 — passed

- The selected composition is preserved: coal-blue macro card imagery, lower-left oversized editorial title, restrained teal action, sparse navigation, and directional negative space.
- Intentional difference: the source mock shows the next section at the fold, while the implementation uses 100svh because the brief explicitly requires a 90–100svh hero. The next chapter begins immediately after the viewport.
- Intentional difference: labels are not baked into the video plate. Product copy remains accessible HTML and the physical card image stays language-neutral.
- No actionable P0, P1, or P2 mismatch remains.

### Iteration 3 — market detail and identity — passed

- Replaced the static front/back comparison rows with a real card object and a restrained physical stack. The card supports front/back reveal, card-back tabs, previous/next navigation, and direct selection from the deck index.
- Rebalanced the detail introduction into an editorial title field and compact metadata/action column. The product task begins immediately after a single explanatory transition.
- Redesigned the LoopCard wordmark as a joined serif/sans signature: an italic editorial “Loop” carries continuity and motion, while compact “Card” provides a functional anchor.
- Replaced the “Open LoopCard” CTA with a persistent Profile affordance. Signed-in users route to `/app/profile`; signed-out users route through login and retain the profile destination.
- Desktop front, desktop back, and full mobile detail states were visually inspected at matching target viewports. Card content is aligned, readable, uncropped, and visually distinct on both faces.
- Added real front/back memory content to the physical cards in the cinematic hero. Desktop alternates prompt and answer on the ten-second loop; mobile and reduced-motion modes hold a static front to avoid motion and loading overhead.

### Iteration 4 — dark-theme contrast — passed

- Fixed the theme-token split that left the Afterimage surfaces on light-theme values after the root theme changed.
- Added a complete dark editorial palette for canvas, raised surfaces, primary text, secondary text, rules, focus color, warning, and error states.
- Preserved the physical card-back metaphor as warm paper with explicitly dark typography instead of allowing global dark tokens to invert and erase its content.
- Verified dark Home, Market index, interactive deck detail, Tools, and Journal states at 1440 × 1024. All primary copy, metadata, controls, filters, form surfaces, card-index rows, and dividers remain legible.

## Required fidelity surfaces

- Fonts and typography: high-contrast editorial serif scale, humanist sans UI copy, matching lower-left composition, stable fallbacks, and Chinese-specific browser language switching verified. No truncation at 1440 or 390 px.
- Spacing and rhythm: asymmetric 12-column composition, rule-led sections, varied layouts, restrained radii, and mobile-specific sequencing verified. The home page no longer renders all 52 decks.
- Colors and tokens: coal navy, warm paper, oxidized teal, amber warning, and red error tokens are limited by semantic role. Text contrast passed automated accessibility checks.
- Image quality: custom hero plate is art-directed for the selected concept, served as responsive WebP poster plus 212 KiB WebM / 720 KiB MP4 fallbacks. No placeholder imagery is used.
- Copy and content: the narrative follows problem → value → method → capability → evidence → action. Chinese and English home modes remain functional.

## Interaction, state, and runtime checks

- Header navigation, primary CTA, locale switch, theme switch, and mobile menu tested.
- Market category filtering, search, sort UI, empty-state route, and deck links tested.
- Market detail card reveal, section tabs, previous/next controls, direct card selection, disabled boundaries, and Profile routing tested.
- Tools input, empty/disabled import, duplicate removal, reversal, clipboard success, and populated output tested.
- Study card keyboard flip, back tabs, favorite action, and memory rating tested.
- App loading, empty, error, disabled, success, hover, active, and focus-visible states are implemented.
- Mobile and reduced-motion contexts suppress the hero video and use the static poster.
- Browser console errors checked across eighteen scripted scenarios: none.
- Unit tests: 11 passed. Next.js production build: passed; 76 routes generated.
- Lighthouse production-mode audit: performance 94, accessibility 100, FCP 0.9 s, LCP 3.1 s, TBT 10 ms, CLS 0.
- Deployed Vercel audit at `https://loopcard.dev`: performance 99, accessibility 100; production desktop and mobile captures saved as `production-home.png` and `production-home-mobile.png`.

## Follow-up polish

- [P3] A future hand-authored 10–12 second card-turn shoot could add real object deformation beyond the current deliberately subtle camera loop.
- [P3] Market and Tools copy remains English-first; the global home experience retains the existing English/Chinese switch.

final result: passed

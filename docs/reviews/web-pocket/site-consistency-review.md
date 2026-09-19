# Web consistency and typography — 2026-09-19

## Decision

The former mix of Newsreader display, Inter UI, Noto Chinese fallback and residual system-font rules produced different texture and proportions between routes and scripts. Keep the accepted quiet paper/green/card direction and replace the interface typography with one locally served Noto Sans SC variable family (`Loop Sans`). Hierarchy comes from size, weight and space.

Research: [official usage/design documentation](https://notofonts.github.io/noto-docs/website/use/) and [official CJK variable font distribution](https://github.com/notofonts/noto-cjk/blob/main/Sans/README.md). A serif display plus Chinese fallback retains the mismatch; platform fonts produce device-dependent results. Noto Sans SC supplies related Latin and Chinese forms within the same licensed family. This is an editorial choice, not a claim that one font is universally more attractive.

## Changes

Unified titles, card text, controls, forms, reading measures and footer/wordmark typography. Removed active Inter/Newsreader declarations. Latin subset is 55KB; source UI subset 136KB. Full CJK fallback remains for other card content. The educational typeface comparison uses outlined glyphs, not additional active fonts.

Tools now uses a light workbench and folded card-pattern guidance instead of a large hero, dark output block and repeated promotional sections. Its editor link is named honestly; it does not automatically import the outline. Detail buttons, sign-in forms, article/about/privacy headings, download states, and 404 use the same surfaces and controls. SEO metadata and structured data remain; download metadata now matches the unreleased store state.

## Evidence and limits

- Browser-inspected: homepage (Chinese and English), market, legacy long-title deck detail, tools (including empty/disabled state), sign-in, about, privacy, download/iOS, article detail and 404. Representative desktop and 390px viewport checks; dark tools and Chinese homepage checked.
- DOM inspection confirmed a single `Loop Sans` computed family for page headings, catalog titles, form controls and buttons. No horizontal overflow on sampled routes. A long card word was reduced to fit and flip remained usable.
- Android download and signup reuse inspected templates. Public study reuses the checked RecallCard; keyboard/rating behavior was preserved.
- `/app` correctly redirects to sign-in. Authenticated library, profile and editor were reviewed at source/component level and receive shared styles, but were not visually verified with a signed-in account. No authentication bypass was added.
- Production build: 76 pages. Vitest: 18 passing tests. TypeScript checks passed. No universal visual score or cross-browser guarantee is claimed.

Existing mobile/backend changes in the shared workspace were left alone.

# Loopcard Web pocket-card redesign — final verification

## Implemented

- Replaced split marketing hero with an interactive card-centred composition.
- Shared RecallCard front/back model across home demo, study, market detail and editor preview; CSS 3D reveal, directional rating departure, next-card entrance, reduced-motion alternative.
- Shared rating order: Again / Almost / Got it (forgot/fuzzy/clear), keys 1/2/3. Synchronous pending guard blocks undo/deck switching during the rating commit window; repeat ratings are blocked.
- Replaced nested miniatures with readable deck covers; container-relative type keeps common long words intact at mobile width.
- Compact market controls put the first covers at approximately y=337 in a 390×844 viewport. Search includes slug for terms such as chemistry. Removed the misleading “Recently added” option, which previously sorted slugs rather than dates; Popular and A–Z remain.
- Self-hosted Inter, Newsreader and Noto Sans SC; small Chinese interface subset plus full-content fallback. Semantic chemical subscripts avoid mismatched fallback glyphs.
- Explicit signed-out Sign in label instead of a fake profile initial. Shared header locale/theme and localized market/demo controls. This is not a complete app-wide translation.

## Verification

- Production build passed with 76 generated pages; temporary /qa-pocket editor route removed.
- Vitest: 17 tests in 5 files passed.
- TypeScript and git diff whitespace checks passed.
- Mechanical design detector: no findings (component/app scope).
- Actual browser checks: home reveal/rate/advance, public study rating, progress, undo and reload recovery; market search; editor input, live back preview, save enabled state; no backend save submitted.
- Desktop and mobile screenshots inspected for home, market, study and editor. Chinese dark homepage checked. Local interface fonts loaded. Mobile home, market and editor had no horizontal document overflow.
- Independent finish reviewer: initial 82/100, disposition fix. Two findings: stranded final letter in mobile “Complementary”, and pending-rating keyboard/deck-switch race.
- Correction: container-relative font size renders “Complementary” at 18px, one 22.5px line within 133px available width; screenshot verified. Synchronous pending ref checked in undo/select, selector disabled. Reviewer marked both findings resolved; final disposition ship, 84/100. This is a human-style qualitative review, not an objective benchmark.

## Evidence

- ../reviews/web-pocket/home-desktop.png
- ../reviews/web-pocket/home-mobile.png
- ../reviews/web-pocket/market-mobile.png

## Boundaries

Authenticated saving and backend scheduling were not changed or exercised. Existing article/SEO metadata, sitemap and structured data remain. Legacy globals/afterimage styles still serve older routes; the new card and catalog selectors own the redesigned surfaces. Full CJK fallback remains a larger download for characters outside the UI subset. Reduced-motion behavior is implemented in source; the current in-app browser did not expose media-preference emulation for this final pass.

# LoopCard Web product experience redesign

## Job, audience, and outcome

LoopCard Web must let a mixed audience—first-time flashcard users and experienced learners—reach the product's value before registration. The primary proof is completing a real recall loop: read a prompt, reveal the answer, rate the memory, and continue. Account creation is requested only when the user chooses to save a deck or sync progress.

## Selected direction

Preserve the existing paper, coal-navy, editorial serif, and turquoise recall signal. Public pages remain expressive, while library, editor, and study surfaces shift to an efficient Operate mode. The product identity comes from the card object, memory index, and recall feedback—not from repeating oversized manifesto headings.

The primary path is:

1. Start a public deck from Home or Market without signing in.
2. Reveal before rating; make rating consequences legible.
3. Allow undo and preserve the local session through refresh.
4. End with a useful result and clear choices to repeat, browse, or save.
5. Create cards through visible front/back fields; keep bulk paste as an optional accelerator.

## Scope and boundaries

- Add an anonymous `/study/[slug]` route backed by existing public deck data.
- Reuse one study experience for anonymous and authenticated decks.
- Improve the logged-in shell and responsive study layout without changing authentication or database schemas.
- Replace delimiter-first creation with structured card rows and live preview while maintaining the existing server payload.
- Compress Market framing and progressively disclose category choices.
- Preserve the current brand assets and public deck content.
- Do not implement a new spaced-repetition backend in this pass; ratings persist locally and communicate their next-loop meaning honestly.

## States and ranges

- Study: front, revealed back, rated/next, undo, refreshed session, completed loop, restart, empty deck.
- Editor: empty first card, 1–500 cards, long text, add, remove, reorder, bulk paste, pending save, saved, parse guidance.
- Market: popular categories, all categories expanded, query, no results, embedded mode, signed-in and signed-out detail actions.
- Responsive targets: 390px phone, intermediate tablet, 1440px desktop; touch targets remain at least 44px.

## Interaction and layout

- Desktop study uses three regions: a restrained deck/context rail, a wide central card stage, and a compact loop summary/help rail. Mobile collapses to a full-height single-card stage with bottom-anchored rating actions.
- Ratings remain disabled until the answer is revealed. Number keys rate, Space/Enter reveals, and `U` undoes the previous rating.
- Market detail makes “Study now” primary and “Save to my decks” secondary.
- The editor shows front/back inputs as the primary model, a live card preview beside them, and bulk paste behind a disclosure.

## Acceptance criteria

- A signed-out user starts a real card in one click from Home or Market.
- A card cannot be rated before reveal.
- A mistaken rating can be undone and refresh preserves the current anonymous session.
- Desktop study no longer appears as a narrow phone floating in empty space.
- Creating a first card requires no delimiter knowledge.
- Mobile Market exposes search and useful deck content earlier, with no 11-option category wall.
- Tests, production build, deterministic detector, and representative desktop/mobile renders pass without unexplained critical findings.

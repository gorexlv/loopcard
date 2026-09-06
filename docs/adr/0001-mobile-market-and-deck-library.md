# ADR 0001: Mobile Market and shared deck library

- Status: Accepted
- Date: 2026-09-02

## Context

LoopCard needs to show the web Market inside the Flutter app and let an authenticated user add a public deck to their own deck list. Platform decks and future user-created decks must share one data model. User-created decks are private by default and may later be published.

## Decision

All decks remain in `decks`. `visibility` controls whether a deck is private or public; a null creator identifies a platform-owned deck, which must be public. Cards and sections remain attached to that single deck record.

`deck_library` records that a user added a public deck. Adding does not copy cards. Its composite primary key makes the operation idempotent. The `add_market_deck(slug)` RPC validates authentication and public visibility before creating the relation.

Flutter opens `https://loopcard.dev/market?embedded=1` in a WebView. The embedded page hides site chrome and emits only `loopcard://market/import?slug=...`. Flutter permits navigation only to the configured Market origin, intercepts that custom URL, and calls the RPC with the app's existing Supabase session. Credentials are never passed into web content.

User-created decks continue to be inserted as private, creator-owned rows. A later publishing feature can validate content and change `visibility` to `public` without moving or duplicating data.

## Consequences

- Public deck updates are immediately visible to users who added the deck.
- Removing a deck from a library deletes only the relation, not shared content.
- Offline Market browsing and independent editing of shared decks require separate future features.
- Database policies must authorize public reads through the parent deck while preserving private creator-only access.

# Web accounts and deck workspace

## Scope

The Web app will support email/password registration, login, logout, persistent sessions, profile editing, owned deck management, public-deck library membership, and studying the resulting personal library. A user-created deck is private by default and can be explicitly published. Social login, collaboration, moderation, image uploads, and advanced rich-text card editing remain outside this iteration.

## Architecture

Next.js App Router uses `@supabase/ssr` on both server and browser. A root proxy refreshes expiring auth cookies. Protected Server Components resolve the authenticated user before reading data; Server Actions perform mutations and redirect with user-safe status messages. Supabase Row Level Security remains the authoritative access boundary, so a forged action or direct REST request cannot read another user's private content.

The existing `decks`, `cards`, and `card_sections` tables remain the single content model. `decks.user_id` is the creator, `visibility` is `private` or `public`, and `deck_library` records public decks saved by a user. Owned and saved decks are presented together but retain distinct management rights. Publishing changes visibility without copying content.

## Pages and flows

- `/login`: sign in or create an account, preserving a safe same-origin `next` destination.
- `/app`: protected dashboard with Profile summary, owned decks, saved decks, and study links.
- `/app/profile`: edit display name and inspect account identity.
- `/app/decks/new`: create a private deck from `front :: back` lines.
- `/app/decks/[id]`: edit owned deck metadata/cards, publish/unpublish, or delete.
- `/market`: public browsing; authenticated Web users save directly, while the mobile embedded protocol remains unchanged.

## Reliability and security

Inputs are length-limited and normalized on the server. Redirect targets are restricted to local paths. Deck replacement is transactional through database RPCs to avoid partially updated cards. Errors are mapped to concise UI messages without leaking database details. Empty/loading/error states remain usable on desktop and mobile.

## Verification

Unit tests cover safe redirects and card-line parsing. Database tests cover private/public visibility, library idempotency, and owner-only mutation. Type checking, production build, and responsive page inspection complete the release gate.

## Deployment configuration

Set `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` in the `loopcard.dev` deployment. Local Web development defaults to the repository's shared Supabase Docker gateway at `http://127.0.0.1:8000`.

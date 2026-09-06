# LoopCard Backend, Auth, and Codex Plugin Design

## Goal

Move LoopCard from bundled demo data to a local-first Supabase backend, add a polished authentication boundary, and expose the same user-owned card data through a CLI and Codex Plugin.

## Recommended architecture

LoopCard uses the local Supabase stack as its only backend for the MVP. Supabase Auth issues JWTs; PostgREST exposes PostgreSQL; PostgreSQL row-level security is the final tenant boundary. The Flutter app and CLI both authenticate as normal users and never receive the service-role key.

The mobile application is split into three layers:

1. `AuthService` owns sessions and email/OAuth flows.
2. `DeckRepository` owns deck/card reads and writes.
3. UI state subscribes to auth changes, loads the signed-in user's data, and falls back to explicit loading/error/empty states rather than bundled records.

The CLI is a small TypeScript executable. It stores a user session locally after email login and calls the Supabase public API with the anon key plus user access token. The Codex Plugin wraps that CLI with an MCP server exposing `list_decks`, `get_deck`, `create_deck`, `list_cards`, `get_card`, and `create_card` tools. This keeps command-line and agent behavior consistent.

## Data model

- `profiles`: one row per `auth.users` record.
- `decks`: title, subtitle, kind, owner, timestamps.
- `cards`: prompt, position, owner, parent deck, timestamps.
- `card_sections`: ordered back-side dimensions with title, heading, and body.
- `practice_attempts`: append-only familiarity results.

UUIDs remain appropriate because records are created by mobile and CLI clients. Every owned table contains `user_id`, every foreign key is indexed, and list queries use composite `(user_id, updated_at desc)` or `(deck_id, position)` indexes.

## Security decision

RLS is enabled and forced on all application tables. Policies use `(select auth.uid()) = user_id` for cached evaluation. Inserts require ownership, and card/section writes additionally verify the parent deck/card belongs to the current user. Anonymous users receive no table grants. The anon key is safe to distribute because it grants no data without a signed user JWT and RLS approval.

## Authentication

Email/password supports sign-up, sign-in, sign-out, validation, and recoverable errors. Google and Apple use Supabase OAuth with a custom `io.loopcard.app://login-callback/` redirect. The local stack starts without provider secrets; provider buttons remain implemented but report a configuration-friendly error until credentials are supplied in `supabase/config.toml` or environment variables. Email auth is the deterministic local verification path.

## Failure modes

- Backend unavailable: login and data screens show retryable errors.
- Expired token: Supabase refreshes it; CLI requires login again if refresh fails.
- Partial nested write: CLI creates a card first, then sections; failure is surfaced with the created card ID. Mobile creation will use a database RPC when introduced.
- RLS regression: SQL integration tests attempt cross-user reads and writes.
- OAuth missing credentials: provider error is displayed without blocking email login.

## Verification

- Supabase health and status checks.
- SQL schema/RLS tests with two authenticated users.
- CLI tests and live CRUD against local Supabase.
- MCP protocol smoke test and plugin validator.
- Flutter analyze, unit/widget tests, authentication UI golden, and Android build.


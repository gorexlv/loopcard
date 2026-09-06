# ADR 0002: Supabase SSR for Web accounts

## Status

Accepted

## Context

LoopCard's Next.js app needs durable authentication and server-rendered private pages while sharing users, profiles, decks, and RLS policies with Flutter.

## Decision

Use `@supabase/ssr` with Next.js Cookie sessions. Server Components perform reads, Server Actions perform commands, and a root proxy refreshes tokens. RLS remains the final authorization layer.

## Consequences

### Positive

- Web and mobile share one identity and data model.
- Protected content is rendered without client-side auth flashes.
- Authorization remains centralized in PostgreSQL policies.

### Negative

- Authenticated pages are dynamic and cannot be statically exported.
- Production requires public Supabase URL/key environment variables and correct email redirect URLs.

### Neutral

- Email confirmation behavior follows the Supabase project's Auth configuration.

## Alternatives considered

- Browser-only Supabase: less server code, but weaker protected-route UX.
- Custom Next.js API/session layer: rejected because it duplicates Supabase Auth and authorization logic.

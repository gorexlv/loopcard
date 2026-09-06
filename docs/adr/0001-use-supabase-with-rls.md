# ADR-0001: Use Supabase Auth and PostgreSQL RLS

## Status

Accepted

## Context

LoopCard needs authentication, cross-device persistence, mobile access, and a CLI/agent surface without building a custom backend. User data must be isolated even if a client query omits its owner filter.

## Decision

Use Supabase Auth, PostgreSQL, PostgREST, and database-enforced row-level security. Flutter and the CLI use the anon key plus a user JWT. No client receives the service-role key.

## Consequences

### Positive

- One identity and data boundary for mobile, CLI, and Codex.
- RLS prevents cross-user access independently of client correctness.
- Local Docker development closely matches hosted Supabase deployment.

### Negative

- OAuth providers still require external Google and Apple credentials.
- Local Supabase requires a substantial Docker footprint.
- Nested writes need careful transaction or RPC design.

### Neutral

- PostgreSQL UUID identifiers become the public record IDs.
- Email auth is used for deterministic local integration testing.

## Alternatives Considered

- Custom REST backend: rejected for MVP operational cost and duplicated auth work.
- Firebase: rejected because relational deck/card/section data and SQL/RLS are a better fit.
- Client-only storage: rejected because it cannot support multi-device data or Codex access.


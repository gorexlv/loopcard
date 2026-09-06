# LoopCard

LoopCard is a general-purpose memory-card generator and study system.

## Monorepo

- `apps/mobile` — Flutter app for Android and iOS
- `apps/web` — Next.js marketing, SEO, market and study experience
- `apps/plugin` — LoopCard CLI, MCP server and Codex plugin
- `packages/shared` — shared deck contracts and public deck fixtures
- `supabase` — database migrations, auth configuration and RLS tests

```sh
npm install
npm run dev:web
npm run test
```

Flutter commands run from `apps/mobile`. Local backend setup is documented in
[`docs/backend-local.md`](docs/backend-local.md).

# LoopCard monorepo and web design

## Product boundary

LoopCard remains a general memory-card product. The web application has four
jobs: acquire users through indexable content, let users experience the core
card workflow, send interested users to the mobile app, and distribute reusable
public decks through a market. The first web release is intentionally narrow:
it does not add author payouts, social feeds, collaborative editing, or a full
CMS.

## Repository architecture

The repository becomes an application monorepo:

- `apps/mobile`: existing Flutter Android/iOS application and tests.
- `apps/web`: Next.js App Router application.
- `apps/plugin`: LoopCard CLI, MCP server, Codex plugin manifest and skill.
- `packages/shared`: framework-neutral TypeScript types and curated public deck
  fixtures shared by the web app and plugin-facing tooling.
- `supabase`: shared backend migrations, RLS tests and local configuration.
- `docs`: product, architecture and operational documentation.

The root owns JavaScript workspace scripts and shared infrastructure. Flutter
continues to be built from `apps/mobile` so mobile tooling stays conventional.

## Web information architecture

The public routes are `/`, `/blog`, `/blog/[slug]`, `/tools`, `/market`, and
`/market/[slug]`. `/app` is the product surface. Marketing pages are server
rendered with per-route metadata, canonical URLs, OpenGraph data, JSON-LD,
sitemap and robots output. Blog and market content are source-controlled for the
MVP, ensuring reliable static generation without a CMS dependency.

The core app uses a portrait study stage centered inside a responsive desktop
shell. A user selects a deck, sees its compact summary, then studies one card at
a time. Clicking flips front/back; tabs switch the back's information dimension;
the three familiarity actions advance the carousel. This deliberately mirrors
the mobile mental model rather than inventing a desktop-only workflow.

## Visual system

The direction is editorial minimalism with tactile card objects: warm ivory and
ink in light mode, deep blue-black in dark mode, sea-glass teal as the primary
action and amber as the learning accent. Display type uses Fraunces while body
copy uses Manrope. Subtle grain, hairline rules, oversized editorial headlines,
and restrained entrance motion create identity without overwhelming the card
content. The study viewport preserves the mobile 390:844 rhythm.

## Data and verification

Public market fixtures implement the same deck/card/section contract as the
database. Personal data remains in Supabase and is never exposed to static SEO
routes. The MVP web app can run with fixtures when Supabase environment values
are absent, which keeps local previews deterministic.

Verification includes workspace builds, Flutter analysis/tests after the move,
plugin CLI/MCP tests, web unit checks, production Next.js build, route HTTP
checks, accessibility-oriented browser smoke tests, and desktop/mobile
screenshots of the landing, market and study routes.

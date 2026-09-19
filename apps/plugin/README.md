# LoopCard CLI

Authenticated CLI and MCP server for managing the signed-in user's LoopCard
decks and cards. See [`../../docs/backend-local.md`](../../docs/backend-local.md)
for setup and examples.

Run `loopcard --help` for commands or `npm run mcp` to start the stdio MCP
server used by the Codex plugin.

## Bundled Skills

- `loopcard` handles authenticated deck and card operations.
- `word-card-generation` defines the reusable content contract and quality gate
  for English vocabulary cards. It normalizes presentation-only differences
  while rejecting ambiguous lexical content.

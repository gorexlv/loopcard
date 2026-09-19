---
name: loopcard
description: Use when the user wants to list, inspect, or create LoopCard decks and memory cards through the installed LoopCard tools.
---

# LoopCard

Use the `loopcard` MCP tools for all deck and card operations.

## Authentication

The tools use the same Supabase user data as the mobile app. If a tool reports that authentication is required, run this locally once:

```bash
loopcard login --email <email> --password <password>
```

Never ask for or use the Supabase service-role key. The CLI stores only the signed-in user's refresh session at `~/.config/loopcard/session.json` with owner-only permissions.

## Workflow

- Use `list_decks` before selecting a deck by name.
- Use `get_deck` when the card list or back sections are needed.
- Use `create_deck` before adding cards to a new collection.
- Use `create_card` with concise front text and one or more clearly named back sections.
- For English vocabulary cards, also use the `word-card-generation` Skill and
  satisfy its content contract before calling `create_card`.
- Report the returned deck or card ID after creating data.

Do not invent IDs or claim a write succeeded without a successful tool result.

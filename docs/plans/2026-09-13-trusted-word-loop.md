# LoopCard — Trusted Word Loop MVP

> 后续需求（2026-09-19）：[多图拍照与 Card Agent 对话生成](2026-09-19-multi-photo-card-agent-requirements.md)
> 扩展本文的单张拍照、直接生成及固定单词卡结构约定；核心流程实现与验证见 [实施记录](2026-09-19-card-agent-implementation.md)。

## Product decision

This milestone narrows LoopCard to one complete job:

> Photograph an English word list, turn the detected words into trustworthy cards, review them on a real schedule, and optionally extend weak memories with a small number of explainable AI suggestions.

The existing generic card/deck architecture remains intact, but no new subject-specific capture flows are added in this milestone.

## User contract

1. OCR happens on device and the user chooses which detected words continue.
2. AI output is always a draft. It is visibly labelled, editable, individually removable, and never saved without confirmation.
3. Every generated word card uses the established back structure:
   - Meaning
   - Example & collocation
   - Common confusion
4. Empty or uncertain sections are omitted instead of fabricated.
5. A study rating changes the card's actual due date:
   - Forgotten: retry in 10 minutes
   - Fuzzy: return in 1 day, then grow cautiously
   - Mastered: return in 3 days, then double up to 90 days
6. AI extension is offered only after a completed study loop and only for fuzzy or forgotten cards.
7. One extension request returns at most three candidates. Each candidate states its parent card, relation type, and reason. The user approves candidates before they join the deck.

## Information model

- `decks` are the unit of ownership, practice, and progress.
- `cards` contain only the front prompt and immutable source metadata.
- `card_sections` contain ordered back tabs.
- `practice_attempts` are append-only learning events.
- `card_memory_states` contain per-user scheduling state, including for cards saved from the public market.
- `card_relations` connect an approved generated card to the card that motivated it.

The schedule is per user, never stored directly on a shared card.

## Primary flow

1. Home → photograph word list.
2. Recognition result → remove OCR noise and choose up to 30 words.
3. Generate → authenticated server function returns structured candidates.
4. Review drafts → edit, remove, retry failed generation, name the deck.
5. Confirm → atomically save the deck, cards, sections, and initial memory states.
6. Deck detail → show `Due now`, `Later`, and total cards.
7. Study → queue only due/unseen cards; if none are due, allow an explicit all-card practice.
8. Result → persist ratings atomically and show the next scheduled return.
9. Extend weak cards → generate at most three explained candidates; approve to append.

## AI boundary

The Edge Function is the sole AI boundary. It validates authentication, normalizes input, caps batch size, requests strict JSON, validates the response, and returns drafts only. It never writes cards.

Two operations are supported:

- `generate_word_cards`: English words → word card drafts.
- `suggest_extensions`: weak approved cards → related card drafts.

The client remains useful when the provider is unavailable: OCR selection is preserved and generation can be retried. There is no silent placeholder definition.

## Success criteria

- A photographed word list can become a saved deck without manual retyping.
- Every saved generated card was explicitly approved by the user.
- A completed rating creates both an immutable attempt and one current memory state.
- Opening a deck reflects due cards from persisted server state.
- Extension cannot add more than three cards in one request and cannot save without approval.
- RLS prevents one user from reading or writing another user's schedules and relations.
- Existing generic, chemistry, idiom, market, Web, and CLI data remain readable.

## Assumptions

- English word cards may display explanations in the user's interface language; the first server prompt defaults to concise English content to avoid translation ambiguity.
- AI generation requires `OPENAI_API_KEY` in the Supabase Function environment. Missing configuration is surfaced as a retryable error.
- Photograph storage and server-side OCR are intentionally out of scope; the image stays on device for this MVP.

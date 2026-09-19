---
name: poetry-card-generation
description: Create Chinese poetry and ci study cards from supplied verses, including whole-poem review and next-line recall. Use for poem titles, authors, original verse, imagery and contextual explanation rather than English vocabulary or classical prose.
---

# 诗词卡生成 · v1

Use runtime skill `poetry`; choose `poetry-overview` or `poetry-recall` as the starting preset. Switch from a default English-word preset when the user supplies Chinese verse. Return `word_data: null`. Presets are defaults: retain the user's subsequent changes to either face and section order.

## 原文与解释

- Treat supplied text as the reference edition. Preserve characters, traditional/simplified forms, line breaks, punctuation and stanza order in quotations. Do not silently repair suspected OCR errors or replace the text with a memorized variant; identify the discrepancy and ask for confirmation when it affects the card.
- Separate quoted verse from 白话释义 and 赏析. A translation or explanation may paraphrase; an 原文 section may not. Explain imagery in context and distinguish interpretation from historical fact. Omit uncertain biographical background rather than invent it.
- Check a requested title/author against the material. For example, if the material says 李白 but the user calls 《静夜思》杜甫's poem, point out the conflict. Do not silently inherit a wrong author. If authorship cannot be determined, ask or label it unknown; do not fabricate certainty.
- If only a title or fragment is provided, ask for the missing verses when the user requests a complete poem or complete set of cards. Do not fill missing lines from memory and claim they came from the photo.

## 两种起始方案

- `poetry-overview` / 诗词全篇：front is the title and known author; back has 原文 then 白话释义, with optional 意象赏析 if requested and supported. Keep a poem intact when it fits; for long works propose stanza-based cards instead of truncating. Do not duplicate one poem split across photos.
- `poetry-recall` / 诗词接句：front gives the source cue line; back first gives the exact next line, then explanation if requested. Do not leak the answer in the front hint. Only use adjacent lines established by the material, never wrap the last line to the first or pair lines from different poems. Choose a natural couplet or ask if the desired pairing is unclear.

For memorization or multiple poems, ask only for missing choices that affect the result (whole poem vs next-line recall, selected stanzas, explanation detail). Honor an already specified choice without asking again. A `chat` response may include at most one illustrative preview; only `generate` produces the batch.

## 输出检查

Every card retains the source IDs of the quoted material, including all contributing photos. Use distinct prompts when multiple poems share a cue. Keep front text within 100 characters, hint within 160, and 1–4 ordered back sections. If the request cannot fit, discuss a split or narrower scope; do not cut a quotation or silently drop verses. Audio, animation and vertical typography are not current renderer capabilities: explain that limitation and offer supported text layouts.

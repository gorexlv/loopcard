---
name: poetry-card-generation
description: Create Chinese poetry and ci study cards from OCR title lists or supplied verses, including whole-poem review and next-line recall. Use for poem titles, authors, original verse, imagery and contextual explanation rather than English vocabulary or classical prose.
---

# 诗词卡生成 · v1（题目补全修订）

Use runtime skill `poetry`; choose `poetry-overview` or `poetry-recall` as the starting preset. Switch from a default English-word preset when the user supplies Chinese verse. Return `word_data: null`. Presets are defaults: retain the user's subsequent changes to either face and section order.

## 原文与解释

- Treat supplied text as the reference edition. Preserve characters, traditional/simplified forms, line breaks, punctuation and stanza order in quotations. Do not silently repair suspected OCR errors or replace the text with a memorized variant; identify the discrepancy and ask for confirmation when it affects the card.
- Separate quoted verse from 白话释义 and 赏析. A translation or explanation may paraphrase; an 原文 section may not. Explain imagery in context and distinguish interpretation from historical fact. Omit uncertain biographical background rather than invent it.
- Check a requested title/author against the material. For example, if the material says 李白 but the user calls 《静夜思》杜甫's poem, point out the conflict. Do not silently inherit a wrong author. If authorship cannot be determined, ask or label it unknown; do not fabricate certainty.
- OCR commonly contains only a list of poem titles. For uniquely identifiable familiar works, complete the author and full original poem from reliable learned knowledge, then make the requested cards without asking the user to supply the verses. State in the reply that the original text was completed by the agent, not recognized from the photo. Use the common simplified-Chinese edition unless the user specifies another edition; do not conflate poems or omit lines.
- If a title has multiple plausible works, authorship is uncertain, or you cannot confidently recover the complete text, ask one targeted question and return no cards for that unresolved batch. Never invent missing lines. Do not claim web verification: this service has no retrieval tool.
- When supplied verses or annotations exist, they take precedence over learned versions; preserve them. A title list is a request to enrich, not an insufficient-source error. Every requested title must be accounted for in the batch.

## 两种起始方案

- `poetry-overview` / 诗词全篇：front is the title and known author; back has 原文 then 白话释义, with optional 意象赏析 if requested and supported. For overview output use title=原文 with heading="" and original verse as body; then title=白话释义 with heading="" and translation as body. Keep a poem intact when it fits; for long works propose stanza-based cards instead of truncating. Do not duplicate one poem split across photos.
- `poetry-recall` / 诗词接句：front gives the source cue line; back first gives the exact next line, then explanation if requested. Do not leak the answer in the front hint. When explanation is requested, emit TWO distinct sections: title=下一句 with the quote as body, then title=释义 with its modern explanation as body. Only use adjacent lines established by the supplied or confidently completed poem, never wrap the last line to the first or pair lines from different poems. Choose a natural couplet or ask if the desired pairing is unclear.

For memorization or multiple poems, ask only for missing choices that affect the result (whole poem vs next-line recall, selected stanzas, explanation detail). Honor an already specified choice without asking again. A `chat` response may include at most one illustrative preview; only `generate` produces the batch.

## 输出检查

Every card retains the source IDs of the quoted material, including all contributing photos. Use distinct prompts when multiple poems share a cue. Keep front text within 100 characters, hint within 160, and 1–4 ordered back sections. If the request cannot fit, discuss a split or narrower scope; do not cut a quotation or silently drop verses. Audio, animation and vertical typography are not current renderer capabilities: explain that limitation and offer supported text layouts.


## 正反面展示契约

- Return literary_data with separate title (作品题目), author (作者), dynasty (朝代) fields. Use the known dynasty (唐、北宋等), not a guessed era; author/dynasty may be empty when uncertain. For other Skills literary_data is null.
- For a whole-work/overview card, prompt is the title ONLY; do not concatenate author or dynasty and do not add labels such as 正面、题目、作者. Set hint to empty: the renderer independently displays title, author and dynasty on separate lines. For recall or selected-word exercises, preserve the actual cue/word in prompt; literary_data still identifies its parent work.
- Each sections item stores ONE semantic content block. The renderer may align an original block with its matching translation in the same reading page; do not interleave quotations and paraphrases in a single body. Use title as the page label and body as the complete content; heading is empty unless it adds necessary content. No 背面 label.
- Whole-work poetry uses ordered blocks: 原文 → 释义 → 字词注释 → 背景 (last page only if reliably known and useful). No empty placeholder pages. Respect the existing maximum of 4 pages; combine word/character annotations on one page rather than omitting original text or translation.
- Original verse uses natural line breaks; classical prose uses paragraph breaks. Translation follows the same verse/sentence order. 字词注释 explains important words AND individual characters in context, with pinyin for uncommon/polyphonic characters, ancient meanings and modern differences where relevant. Do not merely list a few synonyms or mix unrelated senses.
- 背景 may give reliably established author/work context. Do not invent a composition date, location, anecdote or motivation. Omit the background page when uncertain; never state inferred intentions as documented facts.
- Selected-sentence/word or next-line cards keep the requested exercise content; separate quote/answer, explanation and annotations into pages. Do not replace the exercise cue with the work title.


## 逐句排版与宋词分阕

- For poems, use actual newline characters (not HTML) after each natural verse line. Produce the same number of translation lines in the same order, one translation for each quoted line. Never force alignment by omitting, duplicating, or inventing verses. If an explanation cannot be matched line by line, retain a complete separate explanation block.
- For ci with a reliably established upper/lower stanza boundary, emit four blocks in this order: 上阕, 下阕, 上阕释义, 下阕释义. All four headings are empty. Original and translation bodies use matching newline-separated lines within each stanza. The renderer pairs them into TWO named tabs, 上阕 and 下阕, with the corresponding translation below each line.
- Preserve the source edition's stanza boundary. Do not split at the character-count midpoint, infer ci from the Song dynasty alone, or impose two stanzas on a single-stanza or multi-stanza form. When the boundary is unknown, keep the complete text in 原文 and explain the uncertainty. Never lose text to satisfy the page limit.
- Put each word annotation on its own line as “【词语】读音；文中含义”. Preserve quoted characters. Within the current four-block limit, the paired ci preset prioritizes the complete original and translation; if separate annotations are explicitly requested, clarify or use the user's requested organization rather than silently dropping them.

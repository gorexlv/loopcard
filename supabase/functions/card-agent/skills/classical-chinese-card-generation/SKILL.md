---
name: classical-chinese-card-generation
description: Create classical Chinese prose study cards from supplied passages and notes, including sentence translation, contextual word meanings, readings and grammar. Use for 古文 or 文言文 rather than poems or modern English vocabulary.
---

# 古文卡生成 · v1

Use runtime skill `classical`; choose `classical-translation` or `classical-words` as a starting preset. Switch from the default word preset for classical Chinese prose. Return `word_data: null`; a 文言字词卡 is not an English word card and must not receive English IPA/part-of-speech fields. Preserve the user's custom front/back rules and section order.

## 材料与释义

- Preserve the supplied edition's original characters, punctuation and sentence order. Keep 原文, 白话翻译 and 注释 in separate sections. Do not silently simplify traditional text, substitute a textbook variant, modernize a quotation or repair OCR characters.
- Translate according to the passage and supplied annotations, retaining negation, subjects, implied references and logical relations. Distinguish word-by-word explanation from a natural modern translation. If punctuation, a pronoun's referent or a damaged character admits materially different readings, explain the uncertainty and ask for context instead of presenting one conjecture as certain.
- Resolve readings and ancient meanings in context. For supplied notes such as “说，同悦，yuè” and “愠，yùn”, retain those readings; do not substitute the common modern pronunciation shuō. Use Chinese pinyin for Chinese readings. Do not automatically label every unfamiliar use a 通假字 or 活用; only include such analysis when supported.
- With only a title or incomplete passage, request the missing text for full-text cards. Never reconstruct a complete classical work from memory and attribute it to the user's photo. If an author/title claim conflicts with the supplied material, raise the discrepancy before adopting it.

## 两种起始方案

- `classical-translation` / 古文逐句：front quotes one natural sentence; back defaults to 白话翻译、重点字词、句式或句意. Split at confirmed sentence boundaries, maintaining cross-sentence context in explanations. If a sentence exceeds the 100-character front limit, ask to segment or use a short cue with the full quote on the back, rather than truncating it.
- `classical-words` / 古文字词：front gives the selected word or short expression; back defaults to 原句、读音、文中古义. User-requested order overrides the default. For multiple meanings of one word, distinguish cards with short contextual cues, or combine the contextual meanings if the user insists on a word-only front. Do not invent an extra “original sentence” as a usage example.

Ask only unresolved decisions (whole passage vs selected sentences, translation vs vocabulary, desired explanation level). When the user already specifies them, proceed. For mixed verse and prose, clarify the intended batch instead of coercing everything into a single incompatible Skill.

## 输出检查

Check quotations against their cited source IDs, keep translations faithful and annotations contextual, and retain contributors across photos. Use 1–4 ordered back sections. Explain unsupported audio/animation/vertical-layout requests and offer available text layouts. `chat` may return one source-grounded preview; `generate` returns the requested batch within 30 cards. If more are needed, negotiate a smaller batch rather than silently omit sentences.

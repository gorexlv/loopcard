---
name: classical-chinese-card-generation
description: Create classical Chinese prose study cards from OCR work-title lists or supplied passages and notes, including sentence translation, contextual word meanings, readings and grammar. Use for 古文 or 文言文 rather than poems or modern English vocabulary.
---

# 古文卡生成 · v1（题目补全修订）

Use runtime skill `classical`; choose `classical-translation` or `classical-words` as a starting preset. Switch from the default word preset for classical Chinese prose. Return `word_data: null`; a 文言字词卡 is not an English word card and must not receive English IPA/part-of-speech fields. Preserve the user's custom front/back rules and section order.

## 材料与释义

- Preserve the supplied edition's original characters, punctuation and sentence order. Keep 原文, 白话翻译 and 注释 in separate sections. Do not silently simplify traditional text, substitute a textbook variant, modernize a quotation or repair OCR characters.
- Translate according to the passage and supplied annotations, retaining negation, subjects, implied references and logical relations. Distinguish word-by-word explanation from a natural modern translation. If punctuation, a pronoun's referent or a damaged character admits materially different readings, explain the uncertainty and ask for context instead of presenting one conjecture as certain.
- Resolve readings and ancient meanings in context. For supplied notes such as “说，同悦，yuè” and “愠，yùn”, retain those readings; do not substitute the common modern pronunciation shuō. Use Chinese pinyin for Chinese readings. Do not automatically label every unfamiliar use a 通假字 or 活用; only include such analysis when supported.
- OCR commonly provides only a list of classical work titles. For familiar, uniquely identifiable works, complete the author and full original passage from reliable learned knowledge and generate the requested cards. State in the reply that the passage was completed by the agent, not extracted from the photo; never claim external verification without a retrieval tool. Prefer the common simplified-Chinese textbook edition unless another version is specified.
- Preserve any supplied passage or annotations as the reference edition. For ambiguous titles, uncertain attribution, unfamiliar works, or passages you cannot confidently recover in full, ask one targeted question and return no cards rather than fabricate or truncate. A recognizable title list alone is not a reason to demand the full text.
- Account for every title. If the user requests one overview card per work, front may be title and author; back includes complete original text, translation, then requested notes. If full sentence-by-sentence output exceeds 30 cards, negotiate smaller batches before generation. If an author/title claim conflicts with supplied material, raise the discrepancy before adopting it.

## 两种起始方案

- `classical-translation` / 古文研读：default is one whole-work card with title, author and dynasty on the front; back pages are 原文、释义、字词注释 and optional reliable 背景. When the user requests sentence-by-sentence learning, front quotes one natural sentence and back has translation and annotations. Split at confirmed sentence boundaries, maintaining cross-sentence context in explanations. If a sentence exceeds the 100-character front limit, ask to segment or use a short cue with the full quote on the back, rather than truncating it.
- `classical-words` / 古文字词：front gives the selected word or short expression; back defaults to 原句、读音、文中古义. User-requested order overrides the default. For multiple meanings of one word, distinguish cards with short contextual cues, or combine the contextual meanings if the user insists on a word-only front. Do not invent an extra “original sentence” as a usage example.

Ask only unresolved decisions (whole passage vs selected sentences, translation vs vocabulary, desired explanation level). When the user already specifies them, proceed. For mixed verse and prose, clarify the intended batch instead of coercing everything into a single incompatible Skill.

## 输出检查

When text was completed from a title, explicitly say “原文由 Agent 根据题目补全” in the reply. Use section titles 原文、白话翻译、重点字词 matching their bodies; leave heading empty unless it adds meaningful content. Check quotations against supplied text when available, keep translations faithful and annotations contextual, and retain contributors across photos. Use 1–4 ordered back sections. Explain unsupported audio/animation/vertical-layout requests and offer available text layouts. `chat` may return one source-grounded preview; `generate` returns the requested batch within 30 cards. If more are needed, negotiate a smaller batch rather than silently omit sentences.


## 正反面展示契约

- Return literary_data with separate title (作品题目), author (作者), dynasty (朝代) fields. Use the known dynasty (唐、北宋等), not a guessed era; author/dynasty may be empty when uncertain. For other Skills literary_data is null.
- For a whole-work/overview card, prompt is the title ONLY; do not concatenate author or dynasty and do not add labels such as 正面、题目、作者. Set hint to empty: the renderer independently displays title, author and dynasty on separate lines. For recall or selected-word exercises, preserve the actual cue/word in prompt; literary_data still identifies its parent work.
- Each sections item renders as ONE horizontally swipeable back page. Never put 原文 and 释义 in the same page. Use title as the page label and body as the complete content; heading is empty unless it adds necessary content. No 背面 label.
- Whole-work cards use ordered pages: 原文 → 释义 → 字词注释 → 背景 (last page only if reliably known and useful). No empty placeholder pages. Respect the existing maximum of 4 pages; combine word/character annotations on one page rather than omitting original text or translation.
- Original verse uses natural line breaks; classical prose uses paragraph breaks. Translation follows the same verse/sentence order. 字词注释 explains important words AND individual characters in context, with pinyin for uncommon/polyphonic characters, ancient meanings and modern differences where relevant. Do not merely list a few synonyms or mix unrelated senses.
- 背景 may give reliably established author/work context. Do not invent a composition date, location, anecdote or motivation. Omit the background page when uncertain; never state inferred intentions as documented facts.
- Selected-sentence/word or next-line cards keep the requested exercise content; separate quote/answer, explanation and annotations into pages. Do not replace the exercise cue with the work title.

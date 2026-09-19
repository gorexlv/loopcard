# Word-card generation Skill design

> 后续需求（2026-09-19）：[多图拍照与 Card Agent 对话生成](2026-09-19-multi-photo-card-agent-requirements.md)
> 要求通过 Card Agent 对话与多种 Skill 定制卡片正反面；本文的单词卡逻辑将作为其中一种 Skill 的基础。

## Goal

Establish a reusable LoopCard Skill for generating and reviewing English word
cards, then enforce its highest-risk formatting rules in the AI generation
service.

## Structure

- `apps/plugin/skills/word-card-generation/SKILL.md` owns triggering,
  workflow, and the quality gate.
- `apps/plugin/skills/word-card-generation/references/word-card-contract.md`
  owns the detailed field contract, canonical abbreviations, examples, and
  normalize-versus-reject policy.
- `apps/plugin/skills/loopcard/SKILL.md` routes English vocabulary work to the
  specialized Skill.
- `supabase/functions/_shared/word_generation.ts` mirrors the contract in the
  runtime prompt, structured-output schema, and deterministic validation.

## Runtime policy

Recoverable presentation differences are normalized. For example, `verb`
becomes `v.`, and `[bəˈrəʊ]` becomes `/bəˈrəʊ/`. Semantic ambiguity is rejected:
combined parts of speech, missing pronunciations, invalid regions, or multiple
unrelated senses must cause regeneration instead of silently weakening a card.

## Verification

- Deno unit tests cover canonical values, aliases, slash-wrapped IPA, duplicate
  pronunciations, and rejection of combined parts of speech.
- The Skill package passes `skill-creator/scripts/quick_validate.py`.
- Existing plugin tests continue to pass.

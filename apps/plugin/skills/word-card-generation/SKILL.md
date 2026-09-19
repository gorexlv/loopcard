---
name: word-card-generation
description: Use when generating, reviewing, correcting, or importing English vocabulary cards for LoopCard, especially when handling parts of speech, IPA pronunciations, meanings, usage patterns, examples, collocations, hints, or lexical quality.
---

# LoopCard word-card generation

Create one focused, learner-ready card per English word. Accuracy, retrieval
value, and consistent structure take priority over filling optional fields.

## Required workflow

1. Read [the word-card contract](references/word-card-contract.md) before
   drafting or reviewing any English word card.
2. Resolve the intended lemma, part of speech, and target sense from the user's
   context. If context is absent, use the most common contemporary learner
   sense.
3. Produce exactly one part of speech and one target sense per card.
4. Normalize recoverable formatting differences using the contract. Reject or
   regenerate semantically ambiguous content instead of guessing.
5. Run the quality gate below before returning or saving the card.

When creating the card in LoopCard, also follow the `loopcard` Skill for deck
lookup, authentication, tool use, and write confirmation.

## Quality gate

A word card is ready only when all of these are true:

- The prompt is the intended lemma and contains no surrounding explanation.
- The part of speech uses one canonical abbreviation.
- Every IPA value has exactly one enclosing pair of `/` characters.
- UK and US labels appear only for genuinely different pronunciations.
- The definition, grammar pattern, example, and collocations teach the same
  sense.
- The hint aids retrieval without revealing the word or translating it.
- Forms, confusion, and extension fields contain only useful information.
- No etymology, quotation, statistic, or source has been invented.

If any required check fails, correct the card before presenting or saving it.

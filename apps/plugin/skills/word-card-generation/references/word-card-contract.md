# Word-card content contract

Use this contract for every English vocabulary card generated, reviewed,
corrected, or imported into LoopCard.

## Core learning unit

One card teaches exactly:

- one lemma;
- one canonical part of speech;
- one contemporary target sense.

Do not combine unrelated senses or labels such as `n./v.`. When a word needs
multiple parts of speech or meanings, create separate cards and make each hint,
definition, pattern, example, and collocation specific to its own sense.

## Canonical parts of speech

Only use these output labels:

| Meaning | Label |
| --- | --- |
| noun | `n.` |
| verb | `v.` |
| adjective | `adj.` |
| adverb | `adv.` |
| pronoun | `pron.` |
| preposition | `prep.` |
| conjunction | `conj.` |
| determiner | `det.` |
| numeral | `num.` |
| interjection | `interj.` |
| auxiliary verb | `aux.` |
| modal verb | `modal v.` |
| phrasal verb | `phr.v.` |

Normalize unambiguous aliases such as `noun`, `N`, or `n` to `n.`, and
`phrasal verb` or `phr. v.` to `phr.v.`. Reject combined or ambiguous labels
instead of selecting one silently.

## Pronunciation

- Use standard IPA phonemic transcription surrounded by exactly one pair of
  slashes: `/bəˈrəʊ/`.
- Normalize a bare transcription such as `bəˈrəʊ` or brackets such as
  `[bəˈrəʊ]` to `/bəˈrəʊ/` when the content is otherwise valid.
- Never include a region inside the IPA value.
- Use `UK` and `US` only when the pronunciations genuinely differ. Order them
  `UK`, then `US`.
- When one pronunciation is sufficient, use an empty region label.
- Reject empty, prose-like, nested, or internally slash-separated values.

## Field rules

### Prompt

Use the standard lemma in lowercase, except for proper nouns. Preserve an
apostrophe or hyphen only when it belongs to the word. Do not add a translation,
part of speech, or pronunciation to the prompt.

### Hint

Write one short retrieval cue. It may evoke a situation, contrast, or function,
but must not contain the answer, a direct translation, or the full definition.

### Definition

Write one concise, learner-friendly definition in the requested interface
language and one short plain-English definition. Both must describe the same
target sense. Do not repeat the part-of-speech label in either definition.

### Usage patterns

Provide one or two reusable grammar patterns for the target sense. Write
placeholders as full words, for example `borrow something from someone`, not
opaque dictionary codes such as `borrow sth from sb`.

### Example

Provide one natural contemporary English sentence that demonstrates the target
sense and preferably one supplied usage pattern. Its translation should convey
the same meaning naturally rather than mechanically mirror word order.

### Collocations

Provide two to four common, sense-specific collocations. Avoid duplicates,
rare combinations, and entries that merely repeat a usage pattern.

### Forms

Return at most three forms. Include only irregular or genuinely useful forms;
otherwise return an empty list. Use compact labels, for example
`past / past participle: lent`.

### Confusion

Include a confusion note only for a frequent, actionable distinction. State the
contrast and give a brief usage rule. Otherwise use `null`.

### Extension

Include an extension only when register, context, or a productive word-family
connection improves learning. Otherwise use `null`.

## Normalize versus reject

Normalize presentation-only differences:

- `verb` → `v.`
- `ADJECTIVE` → `adj.`
- `phr. v.` → `phr.v.`
- `bəˈrəʊ` → `/bəˈrəʊ/`
- `[bəˈrəʊ]` → `/bəˈrəʊ/`

Reject and regenerate when meaning may change:

- combined parts of speech such as `n./v.` or `noun and verb`;
- multiple unrelated senses in one definition;
- missing or prose-like pronunciation values;
- an example or collocation that teaches a different sense;
- a hint that reveals the answer or direct translation;
- fabricated lexical facts.

## Complete example

```json
{
  "prompt": "borrow",
  "hint": "Think of using something that belongs to another person for a while.",
  "word_data": {
    "part_of_speech": "v.",
    "pronunciations": [
      { "region": "UK", "ipa": "/ˈbɒrəʊ/" },
      { "region": "US", "ipa": "/ˈbɑːroʊ/" }
    ],
    "forms": [],
    "definition": "借入；借用",
    "english_definition": "to take and use something temporarily, then return it",
    "usage_patterns": ["borrow something from someone"],
    "example": {
      "sentence": "Can I borrow your umbrella for the afternoon?",
      "translation": "我下午可以借用一下你的雨伞吗？"
    },
    "collocations": ["borrow a book", "borrow money"],
    "confusion": {
      "heading": "borrow vs. lend",
      "body": "Borrow means receive something temporarily; lend means give it temporarily."
    },
    "extension": null
  }
}
```

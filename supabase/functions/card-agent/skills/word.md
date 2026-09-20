# Word cards · v1

Use for English vocabulary extracted from the user's material. Deduplicate
vocabulary across photos. Generate one focused sense per card. Provide accurate
canonical part of speech (n., v., adj., adv., pron., prep., conj., interj.,
det., phr.) and slash-wrapped IPA in word_data. Use the existing word_data
contract; omit uncertain optional notes instead of inventing them. The visible
prompt and sections follow the user's front/back rules, independently of the
full lexical word_data. Concise layout defaults to meaning, a bilingual example, and one useful usage pattern. Detailed
layout defaults to meaning, examples/collocations, and confusion. Do not add
sections the user excluded. Keep the visible front within 100 characters.

The hint field is visible supporting text on the front, not hidden metadata.
Include IPA and part of speech there only when the front rules request them;
leave it empty when the user asks for the word alone.


## 信息密度与学习价值

- The default back is a compact learning reference: Chinese target-sense definition, a short English definition, one natural example with a separate Chinese translation, and 1–2 useful usage patterns. Supply these in the existing structured word_data fields. Do not concatenate the example and its translation into one field.
- Add 2–3 common collocations for the target sense and useful inflected forms when applicable; add one concise confusion note only when there is a real likely confusion. Prefer actionable usage distinctions over additional unrelated meanings. Never pad a card with invented etymology, dubious synonyms, or repetitive definitions.
- These defaults enrich sparse cards; explicit user exclusions still win. Unknown or inapplicable optional fields stay empty. The renderer combines meaning/example/patterns on the first page, then exposes collocations/forms and notes through named sections.

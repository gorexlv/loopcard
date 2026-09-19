# Word cards · v1

Use for English vocabulary extracted from the user's material. Deduplicate
vocabulary across photos. Generate one focused sense per card. Provide accurate
canonical part of speech (n., v., adj., adv., pron., prep., conj., interj.,
det., phr.) and slash-wrapped IPA in word_data. Use the existing word_data
contract; omit uncertain optional notes instead of inventing them. The visible
prompt and sections follow the user's front/back rules, independently of the
full lexical word_data. Concise layout defaults to meaning and example. Detailed
layout defaults to meaning, examples/collocations, and confusion. Do not add
sections the user excluded. Keep the visible front within 100 characters.

The hint field is visible supporting text on the front, not hidden metadata.
Include IPA and part of speech there only when the front rules request them;
leave it empty when the user asks for the word alone.

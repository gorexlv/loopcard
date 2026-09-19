export const MAX_CAPTURED_WORDS = 30;
export const MAX_EXTENSIONS = 3;

export const CANONICAL_PARTS_OF_SPEECH = [
  "n.",
  "v.",
  "adj.",
  "adv.",
  "pron.",
  "prep.",
  "conj.",
  "det.",
  "num.",
  "interj.",
  "aux.",
  "modal v.",
  "phr.v.",
] as const;

export type GenerationOperation = "generate_word_cards" | "suggest_extensions";

export type WordCardDraft = {
  prompt: string;
  hint: string;
  sections: Array<{ title: string; heading: string; body: string }>;
  word_data: WordCardData;
  parent_card_id: string;
  relation_type:
    | "none"
    | "prerequisite"
    | "contrast"
    | "application"
    | "collocation"
    | "synonym";
  reason: string;
};

export type WordCardData = {
  part_of_speech: string;
  pronunciations: Array<{ region: string; ipa: string }>;
  forms: string[];
  definition: string;
  english_definition: string;
  usage_patterns: string[];
  example: { sentence: string; translation: string };
  collocations: string[];
  confusion: { heading: string; body: string } | null;
  extension: { heading: string; body: string } | null;
};

export type WeakCardInput = {
  id: string;
  prompt: string;
  familiarity: "fuzzy" | "forgotten";
  sections: Array<{ title: string; heading: string; body: string }>;
};

const englishWord = /^[A-Za-z][A-Za-z'-]{0,48}$/;
const uuid =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const relationTypes = new Set([
  "none",
  "prerequisite",
  "contrast",
  "application",
  "collocation",
  "synonym",
]);

const partOfSpeechAliases = new Map<string, string>([
  ["n", "n."],
  ["n.", "n."],
  ["noun", "n."],
  ["v", "v."],
  ["v.", "v."],
  ["verb", "v."],
  ["vt", "v."],
  ["vt.", "v."],
  ["vi", "v."],
  ["vi.", "v."],
  ["transitive verb", "v."],
  ["intransitive verb", "v."],
  ["adj", "adj."],
  ["adj.", "adj."],
  ["adjective", "adj."],
  ["adv", "adv."],
  ["adv.", "adv."],
  ["adverb", "adv."],
  ["pron", "pron."],
  ["pron.", "pron."],
  ["pronoun", "pron."],
  ["prep", "prep."],
  ["prep.", "prep."],
  ["preposition", "prep."],
  ["conj", "conj."],
  ["conj.", "conj."],
  ["conjunction", "conj."],
  ["det", "det."],
  ["det.", "det."],
  ["determiner", "det."],
  ["article", "det."],
  ["num", "num."],
  ["num.", "num."],
  ["numeral", "num."],
  ["interj", "interj."],
  ["interj.", "interj."],
  ["interjection", "interj."],
  ["aux", "aux."],
  ["aux.", "aux."],
  ["auxiliary", "aux."],
  ["auxiliary verb", "aux."],
  ["modal", "modal v."],
  ["modal v", "modal v."],
  ["modal v.", "modal v."],
  ["modal verb", "modal v."],
  ["phr.v", "phr.v."],
  ["phr.v.", "phr.v."],
  ["phr. v", "phr.v."],
  ["phr. v.", "phr.v."],
  ["phrasal verb", "phr.v."],
]);

export function normalizeWords(input: unknown): string[] {
  if (!Array.isArray(input)) throw new Error("words must be an array");
  const seen = new Set<string>();
  const words: string[] = [];
  for (const value of input) {
    if (typeof value !== "string") continue;
    const word = value.trim().toLowerCase();
    if (!englishWord.test(word) || seen.has(word)) continue;
    seen.add(word);
    words.push(word);
  }
  if (words.length === 0 || words.length > MAX_CAPTURED_WORDS) {
    throw new Error(`choose between 1 and ${MAX_CAPTURED_WORDS} English words`);
  }
  return words;
}

export function normalizeWeakCards(input: unknown): WeakCardInput[] {
  if (!Array.isArray(input)) throw new Error("weak_cards must be an array");
  const cards = input.slice(0, MAX_EXTENSIONS).map((value) => {
    if (!value || typeof value !== "object") {
      throw new Error("invalid weak card");
    }
    const row = value as Record<string, unknown>;
    const id = typeof row.id === "string" ? row.id : "";
    const prompt = typeof row.prompt === "string" ? row.prompt.trim() : "";
    const familiarity = row.familiarity;
    if (
      !uuid.test(id) || !englishWord.test(prompt) ||
      (familiarity !== "fuzzy" && familiarity !== "forgotten")
    ) {
      throw new Error("invalid weak card");
    }
    const sections = Array.isArray(row.sections)
      ? row.sections.slice(0, 3).map((section) => {
        const item = section as Record<string, unknown>;
        return {
          title: String(item.title ?? "").slice(0, 80),
          heading: String(item.heading ?? "").slice(0, 1000),
          body: String(item.body ?? "").slice(0, 3000),
        };
      })
      : [];
    return { id, prompt, familiarity, sections } as WeakCardInput;
  });
  if (cards.length === 0) throw new Error("at least one weak card is required");
  return cards;
}

export function buildGenerationPrompt(
  operation: GenerationOperation,
  payload: unknown[],
  outputLanguage = "English",
): string {
  const wordDataRules = `Word-data contract:
- Teach exactly one lemma, one canonical part of speech, and one target sense per card. Never combine labels or unrelated senses.
- part_of_speech must be exactly one of: ${
    CANONICAL_PARTS_OF_SPEECH.join(", ")
  }.
- Every ipa value must be standard phonemic IPA surrounded by exactly one pair of slashes, for example /bəˈrəʊ/. Do not use square brackets, bare IPA, prose, or a region inside ipa.
- pronunciations contains one unlabeled pronunciation when variants do not genuinely differ. If UK and US differ, return exactly two entries ordered UK then US.
- forms contains only irregular or genuinely useful forms, at most 3; otherwise return an empty array.
- definition is one concise learner-friendly definition in ${outputLanguage}; english_definition is one short plain-English definition of the same sense.
- usage_patterns contains one or two reusable grammar patterns for this sense. Spell out placeholders such as something and someone; do not use sth or sb.
- example contains one natural contemporary English sentence demonstrating this sense and a natural ${outputLanguage} translation.
- collocations contains two to four common, non-duplicate collocations specific to this sense.
- confusion is present only for a frequent, actionable distinction; otherwise null.
- extension is present only for a useful register, context, or word-family note; otherwise null.
- hint is one short retrieval cue and must not contain the answer, a direct translation, or the full definition.
- Never invent etymology, quotations, statistics, or named sources.`;
  if (operation === "generate_word_cards") {
    return `Create one precise English vocabulary flashcard for every word in this JSON array:\n${
      JSON.stringify(payload)
    }\n\n${wordDataRules}\n- Preserve input order and spelling.\n- parent_card_id must be an empty string, relation_type must be "none", and reason must be an empty string.\n- Return exactly one card per input word.`;
  }
  return `Suggest at most ${MAX_EXTENSIONS} new English vocabulary cards that would repair the specific memory gaps in these weak cards:\n${
    JSON.stringify(payload)
  }\n\n${wordDataRules}\n- Prefer contrast, collocation, synonym, prerequisite, or practical application.\n- Do not repeat an existing prompt.\n- Every suggestion must name the exact parent_card_id supplied in the input.\n- Give one plain, specific sentence explaining why this card helps.`;
}

function requiredText(
  value: unknown,
  field: string,
  maxLength: number,
): string {
  const text = typeof value === "string" ? value.trim() : "";
  if (text.length === 0 || text.length > maxLength) {
    throw new Error(`model returned invalid ${field}`);
  }
  return text;
}

export function normalizePartOfSpeech(value: unknown): string {
  const label = requiredText(value, "part of speech", 32)
    .toLowerCase()
    .replace(/\s+/g, " ");
  const normalized = partOfSpeechAliases.get(label);
  if (!normalized) {
    throw new Error("model returned invalid part of speech");
  }
  return normalized;
}

export function normalizeIpa(value: unknown): string {
  const text = requiredText(value, "IPA", 80);
  const slashWrapped = text.startsWith("/") && text.endsWith("/");
  const bracketWrapped = text.startsWith("[") && text.endsWith("]");
  let body = slashWrapped || bracketWrapped ? text.slice(1, -1).trim() : text;
  body = body.trim();
  if (
    body.length === 0 || body.length > 76 ||
    /[\/\[\]{}\r\n]/u.test(body) ||
    !/[\p{L}\p{M}]/u.test(body)
  ) {
    throw new Error("model returned invalid IPA");
  }
  return `/${body}/`;
}

function stringList(
  value: unknown,
  field: string,
  maxItems: number,
  maxLength: number,
  minItems = 0,
): string[] {
  if (
    !Array.isArray(value) || value.length < minItems || value.length > maxItems
  ) {
    throw new Error(`model returned invalid ${field}`);
  }
  return value.map((item) => requiredText(item, field, maxLength));
}

function optionalNote(
  value: unknown,
  field: string,
): { heading: string; body: string } | null {
  if (value === null) return null;
  if (!value || typeof value !== "object") {
    throw new Error(`model returned invalid ${field}`);
  }
  const note = value as Record<string, unknown>;
  return {
    heading: requiredText(note.heading, `${field} heading`, 120),
    body: requiredText(note.body, `${field} body`, 500),
  };
}

export function validateWordData(value: unknown): WordCardData {
  if (!value || typeof value !== "object") {
    throw new Error("model response has no word_data");
  }
  const row = value as Record<string, unknown>;
  if (
    !Array.isArray(row.pronunciations) || row.pronunciations.length < 1 ||
    row.pronunciations.length > 2
  ) {
    throw new Error("model returned invalid pronunciations");
  }
  let pronunciations = row.pronunciations.map((value) => {
    if (!value || typeof value !== "object") {
      throw new Error("model returned invalid pronunciation");
    }
    const item = value as Record<string, unknown>;
    const region = typeof item.region === "string"
      ? item.region.trim().toUpperCase()
      : "";
    if (region !== "" && region !== "UK" && region !== "US") {
      throw new Error("model returned invalid pronunciation region");
    }
    return { region, ipa: normalizeIpa(item.ipa) };
  });
  if (pronunciations.length === 1) {
    pronunciations = [{ ...pronunciations[0], region: "" }];
  } else {
    const regions = new Set(pronunciations.map((item) => item.region));
    if (regions.size !== 2 || !regions.has("UK") || !regions.has("US")) {
      throw new Error("model returned ambiguous pronunciation regions");
    }
    if (pronunciations[0].ipa === pronunciations[1].ipa) {
      pronunciations = [{ region: "", ipa: pronunciations[0].ipa }];
    } else {
      pronunciations.sort((left) => left.region === "UK" ? -1 : 1);
    }
  }
  const example = row.example as Record<string, unknown> | undefined;
  if (!example) throw new Error("model response has no example");
  return {
    part_of_speech: normalizePartOfSpeech(row.part_of_speech),
    pronunciations,
    forms: stringList(row.forms, "forms", 3, 80),
    definition: requiredText(row.definition, "definition", 220),
    english_definition: requiredText(
      row.english_definition,
      "English definition",
      220,
    ),
    usage_patterns: stringList(row.usage_patterns, "usage patterns", 2, 120, 1),
    example: {
      sentence: requiredText(example.sentence, "example sentence", 240),
      translation: requiredText(
        example.translation,
        "example translation",
        240,
      ),
    },
    collocations: stringList(row.collocations, "collocations", 4, 80, 2),
    confusion: optionalNote(row.confusion, "confusion"),
    extension: optionalNote(row.extension, "extension"),
  };
}

function sectionsFromWordData(data: WordCardData) {
  return [
    {
      title: "Meaning",
      heading: data.definition,
      body: [data.english_definition, ...data.usage_patterns].join("\n"),
    },
    {
      title: "Example & collocation",
      heading: data.example.sentence,
      body: [data.example.translation, ...data.collocations].join("\n"),
    },
    ...(data.confusion
      ? [{ title: "Common confusion", ...data.confusion }]
      : []),
    ...(data.extension ? [{ title: "Extension", ...data.extension }] : []),
  ];
}

export function validateDrafts(
  value: unknown,
  operation: GenerationOperation,
  expectedWords: string[] = [],
): WordCardDraft[] {
  const source = value && typeof value === "object"
    ? value as Record<string, unknown>
    : {};
  if (!Array.isArray(source.cards)) {
    throw new Error("model response has no cards");
  }
  const limit = operation === "generate_word_cards"
    ? MAX_CAPTURED_WORDS
    : MAX_EXTENSIONS;
  if (source.cards.length === 0 || source.cards.length > limit) {
    throw new Error("model returned an invalid card count");
  }

  const drafts = source.cards.map((value) => {
    const row = value as Record<string, unknown>;
    const prompt = typeof row.prompt === "string" ? row.prompt.trim() : "";
    const hint = typeof row.hint === "string" ? row.hint.trim() : "";
    const parentCardId = typeof row.parent_card_id === "string"
      ? row.parent_card_id
      : "";
    const relationType = typeof row.relation_type === "string"
      ? row.relation_type
      : "";
    const reason = typeof row.reason === "string" ? row.reason.trim() : "";
    const wordData = validateWordData(row.word_data);
    if (
      !englishWord.test(prompt) || hint.length === 0 || hint.length > 160 ||
      !relationTypes.has(relationType)
    ) {
      throw new Error("model returned an invalid card");
    }
    if (
      operation === "generate_word_cards" &&
      (parentCardId !== "" || relationType !== "none" || reason !== "")
    ) {
      throw new Error("captured card contains extension metadata");
    }
    if (
      operation === "suggest_extensions" &&
      (!uuid.test(parentCardId) || relationType === "none" ||
        reason.length === 0 || reason.length > 240)
    ) {
      throw new Error("extension card is missing provenance");
    }
    const sections = sectionsFromWordData(wordData);
    return {
      prompt,
      hint,
      sections,
      word_data: wordData,
      parent_card_id: parentCardId,
      relation_type: relationType as WordCardDraft["relation_type"],
      reason,
    };
  });

  const uniquePrompts = new Set(
    drafts.map((draft) => draft.prompt.toLowerCase()),
  );
  if (uniquePrompts.size !== drafts.length) {
    throw new Error("model returned duplicate cards");
  }

  if (operation === "generate_word_cards") {
    if (drafts.length !== expectedWords.length) {
      throw new Error("model omitted one or more words");
    }
    for (let index = 0; index < expectedWords.length; index += 1) {
      if (
        drafts[index].prompt.toLowerCase() !==
          expectedWords[index].toLowerCase()
      ) {
        throw new Error("model changed the requested word order");
      }
    }
  }
  return drafts;
}

export const wordCardResponseSchema = {
  type: "object",
  additionalProperties: false,
  properties: {
    cards: {
      type: "array",
      minItems: 1,
      maxItems: MAX_CAPTURED_WORDS,
      items: {
        type: "object",
        additionalProperties: false,
        properties: {
          prompt: { type: "string", minLength: 1, maxLength: 50 },
          hint: { type: "string", minLength: 1, maxLength: 160 },
          word_data: {
            type: "object",
            additionalProperties: false,
            properties: {
              part_of_speech: {
                type: "string",
                enum: CANONICAL_PARTS_OF_SPEECH,
              },
              pronunciations: {
                type: "array",
                minItems: 1,
                maxItems: 2,
                items: {
                  type: "object",
                  additionalProperties: false,
                  properties: {
                    region: { type: "string", enum: ["", "UK", "US"] },
                    ipa: {
                      type: "string",
                      minLength: 3,
                      maxLength: 80,
                      pattern: "^/[^/\\r\\n]+/$",
                    },
                  },
                  required: ["region", "ipa"],
                },
              },
              forms: {
                type: "array",
                maxItems: 3,
                items: { type: "string", minLength: 1, maxLength: 80 },
              },
              definition: { type: "string", minLength: 1, maxLength: 220 },
              english_definition: {
                type: "string",
                minLength: 1,
                maxLength: 220,
              },
              usage_patterns: {
                type: "array",
                minItems: 1,
                maxItems: 2,
                items: { type: "string", minLength: 1, maxLength: 120 },
              },
              example: {
                type: "object",
                additionalProperties: false,
                properties: {
                  sentence: { type: "string", minLength: 1, maxLength: 240 },
                  translation: { type: "string", minLength: 1, maxLength: 240 },
                },
                required: ["sentence", "translation"],
              },
              collocations: {
                type: "array",
                minItems: 2,
                maxItems: 4,
                items: { type: "string", minLength: 1, maxLength: 80 },
              },
              confusion: {
                anyOf: [
                  {
                    type: "object",
                    additionalProperties: false,
                    properties: {
                      heading: { type: "string", minLength: 1, maxLength: 120 },
                      body: { type: "string", minLength: 1, maxLength: 500 },
                    },
                    required: ["heading", "body"],
                  },
                  { type: "null" },
                ],
              },
              extension: {
                anyOf: [
                  {
                    type: "object",
                    additionalProperties: false,
                    properties: {
                      heading: { type: "string", minLength: 1, maxLength: 120 },
                      body: { type: "string", minLength: 1, maxLength: 500 },
                    },
                    required: ["heading", "body"],
                  },
                  { type: "null" },
                ],
              },
            },
            required: [
              "part_of_speech",
              "pronunciations",
              "forms",
              "definition",
              "english_definition",
              "usage_patterns",
              "example",
              "collocations",
              "confusion",
              "extension",
            ],
          },
          parent_card_id: { type: "string" },
          relation_type: {
            type: "string",
            enum: [
              "none",
              "prerequisite",
              "contrast",
              "application",
              "collocation",
              "synonym",
            ],
          },
          reason: { type: "string", maxLength: 240 },
        },
        required: [
          "prompt",
          "hint",
          "word_data",
          "parent_card_id",
          "relation_type",
          "reason",
        ],
      },
    },
  },
  required: ["cards"],
} as const;

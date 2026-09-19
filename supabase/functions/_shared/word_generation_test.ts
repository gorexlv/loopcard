import { assertEquals, assertThrows } from "jsr:@std/assert@1";
import { normalizeWords, validateDrafts } from "./word_generation.ts";

const wordData = {
  part_of_speech: "v.",
  pronunciations: [{ region: "UK", ipa: "/ˈbɒrəʊ/" }],
  forms: [],
  definition: "借入；借用",
  english_definition: "to take something temporarily and return it",
  usage_patterns: ["borrow something from someone"],
  example: {
    sentence: "May I borrow this book?",
    translation: "我可以借这本书吗？",
  },
  collocations: ["borrow a book", "borrow money"],
  confusion: null,
  extension: null,
};

Deno.test("normalizes and deduplicates captured words", () => {
  assertEquals(normalizeWords([" Borrow ", "borrow", "well-known", "42"]), [
    "borrow",
    "well-known",
  ]);
});

Deno.test("rejects placeholder or reordered generated cards", () => {
  const valid = {
    cards: [{
      prompt: "borrow",
      hint: "Starts with b and means taking temporarily.",
      word_data: wordData,
      parent_card_id: "",
      relation_type: "none",
      reason: "",
    }],
  };
  assertEquals(
    validateDrafts(valid, "generate_word_cards", ["borrow"]).length,
    1,
  );
  assertThrows(() => validateDrafts(valid, "generate_word_cards", ["lend"]));
});

Deno.test("extension requires visible provenance", () => {
  assertThrows(() =>
    validateDrafts({
      cards: [{
        prompt: "lend",
        hint: "The other direction of borrow.",
        word_data: { ...wordData, definition: "借出" },
        parent_card_id: "",
        relation_type: "contrast",
        reason: "Often confused with borrow",
      }],
    }, "suggest_extensions")
  );
});

Deno.test("rejects duplicate generated prompts", () => {
  const card = {
    prompt: "borrow",
    hint: "Starts with b and means taking temporarily.",
    word_data: wordData,
    parent_card_id: "",
    relation_type: "none",
    reason: "",
  };
  assertThrows(() =>
    validateDrafts({ cards: [card, card] }, "generate_word_cards", [
      "borrow",
      "borrow",
    ])
  );
});

Deno.test("normalizes recoverable word-card formatting", () => {
  const result = validateDrafts(
    {
      cards: [{
        prompt: "borrow",
        hint: "Think of using another person's possession temporarily.",
        word_data: {
          ...wordData,
          part_of_speech: " verb ",
          pronunciations: [{ region: "UK", ipa: "[ˈbɒrəʊ]" }],
        },
        parent_card_id: "",
        relation_type: "none",
        reason: "",
      }],
    },
    "generate_word_cards",
    ["borrow"],
  );

  assertEquals(result[0].word_data.part_of_speech, "v.");
  assertEquals(result[0].word_data.pronunciations, [
    { region: "", ipa: "/ˈbɒrəʊ/" },
  ]);
});

Deno.test("normalizes and orders distinct regional pronunciations", () => {
  const result = validateDrafts(
    {
      cards: [{
        prompt: "borrow",
        hint: "Think of using another person's possession temporarily.",
        word_data: {
          ...wordData,
          part_of_speech: "PHRASAL VERB",
          pronunciations: [
            { region: "US", ipa: "ˈbɑːroʊ" },
            { region: "UK", ipa: "/ˈbɒrəʊ/" },
          ],
        },
        parent_card_id: "",
        relation_type: "none",
        reason: "",
      }],
    },
    "generate_word_cards",
    ["borrow"],
  );

  assertEquals(result[0].word_data.part_of_speech, "phr.v.");
  assertEquals(result[0].word_data.pronunciations, [
    { region: "UK", ipa: "/ˈbɒrəʊ/" },
    { region: "US", ipa: "/ˈbɑːroʊ/" },
  ]);
});

Deno.test("rejects ambiguous combined parts of speech", () => {
  assertThrows(() =>
    validateDrafts(
      {
        cards: [{
          prompt: "borrow",
          hint: "Think of using another person's possession temporarily.",
          word_data: { ...wordData, part_of_speech: "n./v." },
          parent_card_id: "",
          relation_type: "none",
          reason: "",
        }],
      },
      "generate_word_cards",
      ["borrow"],
    )
  );
});

Deno.test("rejects malformed IPA and ambiguous pronunciation regions", () => {
  const draft = (pronunciations: Array<{ region: string; ipa: string }>) => ({
    cards: [{
      prompt: "borrow",
      hint: "Think of using another person's possession temporarily.",
      word_data: { ...wordData, pronunciations },
      parent_card_id: "",
      relation_type: "none",
      reason: "",
    }],
  });

  assertThrows(() =>
    validateDrafts(
      draft([{ region: "", ipa: "/ˈbɒ/rəʊ/" }]),
      "generate_word_cards",
      ["borrow"],
    )
  );
  assertThrows(() =>
    validateDrafts(
      draft([
        { region: "UK", ipa: "/ˈbɒrəʊ/" },
        { region: "UK", ipa: "/ˈbɒrəʊ/" },
      ]),
      "generate_word_cards",
      ["borrow"],
    )
  );
});

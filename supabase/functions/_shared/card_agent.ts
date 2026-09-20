import { validateWordData, wordCardResponseSchema } from "./word_generation.ts";

export const skillDefinitions = {
  word: { version: "1", file: "word.md" },
  knowledge: { version: "1", file: "knowledge.md" },
  poetry: { version: "1", file: "poetry-card-generation/SKILL.md" },
  classical: {
    version: "1",
    file: "classical-chinese-card-generation/SKILL.md",
  },
} as const;

export const presets = [
  {
    id: "word-simple",
    skill: "word",
    name: "简洁单词",
    front: "单词居中，音标与词性作为辅助信息",
    back: "释义、双语例句与常用句型同页，搭配与词形按需查看",
    layout: "centered",
  },
  {
    id: "word-detail",
    skill: "word",
    name: "单词详解",
    front: "单词左对齐，音标与词性作为辅助信息",
    back: "释义、例句与搭配、易混淆点分区排列",
    layout: "stacked",
  },
  {
    id: "knowledge-qa",
    skill: "knowledge",
    name: "知识问答",
    front: "突出问题，必要背景作为辅助信息",
    back: "先给简短答案，再解释或分步推导",
    layout: "stacked",
  },
  {
    "id": "poetry-overview",
    "skill": "poetry",
    "name": "诗词全篇",
    "front": "题目、作者、朝代分行居中",
    "back": "原文与释义逐句对应，字词注释独立分节；双调词按上阕、下阕切换",
    "layout": "centered",
  },
  {
    "id": "poetry-recall",
    "skill": "poetry",
    "name": "诗词接句",
    "front": "展示上一句，不泄露下一句",
    "back": "下一句原文在上，释义在下",
    "layout": "centered",
  },
  {
    "id": "classical-translation",
    "skill": "classical",
    "name": "古文研读",
    "front": "题目、作者、朝代分行居中",
    "back": "原文、释义、字词注释各一页；有可靠背景时增加背景页",
    "layout": "stacked",
  },
  {
    "id": "classical-words",
    "skill": "classical",
    "name": "古文字词",
    "front": "展示字词，必要时附语境",
    "back": "原句、读音、文中古义依次排列",
    "layout": "centered",
  },
] as const;
export type Rules = {
  preset: string;
  skill: string;
  front: string;
  back: string;
  layout: string;
};
function object(v: unknown): Record<string, unknown> {
  if (!v || typeof v !== "object" || Array.isArray(v)) {
    throw Error("invalid_object");
  }
  return v as Record<string, unknown>;
}
function string(v: unknown, max: number, empty = false): string {
  if (typeof v !== "string" || (!empty && !v.trim()) || v.length > max) {
    throw Error("invalid_text");
  }
  return v.trim();
}
export function validateRules(v: unknown): Rules {
  const r = object(v);
  const preset = presets.find((p) => p.id === r.preset);
  if (
    !preset || preset.skill !== r.skill ||
    !["centered", "stacked"].includes(String(r.layout))
  ) throw Error("invalid_rules");
  return {
    preset: preset.id,
    skill: preset.skill,
    front: string(r.front, 800),
    back: string(r.back, 800),
    layout: String(r.layout),
  };
}
export function validateRequest(v: unknown) {
  const r = object(v);
  if (!["chat", "generate"].includes(String(r.action))) {
    throw Error("invalid_action");
  }
  if (
    !Array.isArray(r.sources) || r.sources.length < 1 || r.sources.length > 10
  ) throw Error("invalid_sources");
  const sources = r.sources.map((v) => {
    const s = object(v);
    return { id: string(s.id, 100), text: string(s.text, 4000) };
  });
  if (
    sources.reduce((n, s) => n + s.text.length, sources.length - 1) > 4000 ||
    new Set(sources.map((s) => s.id)).size !== sources.length
  ) throw Error("invalid_sources");
  if (!Array.isArray(r.messages) || r.messages.length > 60) {
    throw Error("invalid_messages");
  }
  const messages = r.messages.map((v) => {
    const m = object(v);
    if (!["user", "assistant"].includes(String(m.role))) {
      throw Error("invalid_role");
    }
    return { role: String(m.role), content: string(m.content, 3000) };
  });
  return {
    action: String(r.action),
    sources,
    messages,
    rules: validateRules(r.rules),
    locale: string(r.locale ?? "en", 20),
  };
}
const text = (max: number) => ({ type: "string", maxLength: max });
export const agentSchema = {
  type: "object",
  additionalProperties: false,
  required: ["reply", "rules", "cards"],
  properties: {
    reply: text(3000),
    rules: {
      type: "object",
      additionalProperties: false,
      required: ["preset", "skill", "front", "back", "layout"],
      properties: {
        preset: { type: "string", enum: presets.map((p) => p.id) },
        skill: { type: "string", enum: Object.keys(skillDefinitions) },
        front: text(800),
        back: text(800),
        layout: { type: "string", enum: ["centered", "stacked"] },
      },
    },
    cards: {
      type: "array",
      maxItems: 30,
      items: {
        type: "object",
        additionalProperties: false,
        required: [
          "prompt",
          "hint",
          "sections",
          "word_data",
          "literary_data",
          "source_ids",
        ],
        properties: {
          prompt: text(100),
          hint: text(160),
          sections: {
            type: "array",
            minItems: 1,
            maxItems: 4,
            items: {
              type: "object",
              additionalProperties: false,
              required: ["title", "heading", "body"],
              properties: {
                title: {
                  ...text(80),
                  description:
                    "Section label matching its body, e.g. 原文, 白话翻译, 释义. Not the work title.",
                },
                heading: {
                  ...text(1000),
                  description:
                    "Optional emphasized content; empty string unless needed. Not a section label.",
                },
                body: {
                  ...text(3000),
                  minLength: 1,
                  description:
                    "Actual content of this section. Nonempty; include explanation separately from the quoted original.",
                },
              },
            },
          },
          literary_data: {
            anyOf: [{
              type: "object",
              additionalProperties: false,
              required: ["title", "author", "dynasty"],
              properties: {
                title: {
                  ...text(100),
                  description: "Work title only, without author or dynasty.",
                },
                author: {
                  ...text(80),
                  description: "Author separately; empty if uncertain.",
                },
                dynasty: {
                  ...text(40),
                  description:
                    "Dynasty separately, e.g. 唐 or 北宋; empty if uncertain.",
                },
              },
            }, { type: "null" }],
          },
          word_data: {
            anyOf: [
              wordCardResponseSchema.properties.cards.items.properties
                .word_data,
              { type: "null" },
            ],
          },
          source_ids: {
            type: "array",
            minItems: 1,
            maxItems: 10,
            items: text(100),
          },
        },
      },
    },
  },
};
export function validateAgentResponse(
  v: unknown,
  request: ReturnType<typeof validateRequest>,
) {
  const r = object(v);
  const rules = validateRules(r.rules);
  if (
    request.action === "generate" &&
    JSON.stringify(rules) !== JSON.stringify(request.rules)
  ) throw Error("generation_changed_rules");
  const reply = string(r.reply, 3000, true);
  if (
    !Array.isArray(r.cards) || r.cards.length > 30 ||
    (request.action === "chat" && r.cards.length > 1)
  ) throw Error("invalid_cards");
  const cards = r.cards.map((v) => {
    const c = object(v);
    if (
      !Array.isArray(c.sections) || c.sections.length < 1 ||
      c.sections.length > 4
    ) throw Error("invalid_sections");
    if (
      !Array.isArray(c.source_ids) || c.source_ids.length < 1 ||
      c.source_ids.length > 10 ||
      new Set(c.source_ids).size !== c.source_ids.length ||
      c.source_ids.some((id) => !request.sources.some((s) => s.id === id))
    ) throw Error("invalid_provenance");
    if (rules.skill !== "word" && c.word_data !== null) {
      throw Error("non_word_card_contains_lexical_data");
    }
    const isLiterary = ["poetry", "classical"].includes(rules.skill);
    if (isLiterary && c.literary_data == null) {
      throw Error("missing_literary_data");
    }
    let literary;
    if (c.literary_data != null) {
      if (!isLiterary) throw Error("non_literary_card_contains_literary_data");
      const data = object(c.literary_data);
      literary = {
        title: string(data.title, 100),
        author: string(data.author, 80, true),
        dynasty: string(data.dynasty, 40, true),
      };
    }
    return {
      prompt: string(c.prompt, 100),
      hint: string(c.hint, 160, true),
      sections: c.sections.map((v) => {
        const s = object(v);
        return {
          title: string(s.title, 80),
          heading: string(s.heading, 1000, true),
          body: string(s.body, 3000),
        };
      }),
      ...(rules.skill === "word"
        ? { word_data: validateWordData(c.word_data) }
        : {}),
      presentation: {
        ...rules,
        ...(literary ? { literary } : {}),
        skill_version:
          skillDefinitions[rules.skill as keyof typeof skillDefinitions]
            .version,
        source_ids: c.source_ids,
        sources: request.sources.filter((source) =>
          (c.source_ids as unknown[]).includes(source.id)
        ),
      },
    };
  });
  if (new Set(cards.map((c) => c.prompt.toLowerCase())).size !== cards.length) {
    throw Error("duplicate_cards");
  }
  if (!reply && cards.length === 0) throw Error("empty_agent_response");
  return { reply, rules, cards };
}

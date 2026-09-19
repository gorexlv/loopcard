import {
  buildGenerationPrompt,
  type GenerationOperation,
  normalizeWeakCards,
  normalizeWords,
  validateDrafts,
  type WeakCardInput,
  wordCardResponseSchema,
} from "../_shared/word_generation.ts";
import { resolveAiProvider } from "../_shared/ai_provider.ts";

const jsonHeaders = { "content-type": "application/json; charset=utf-8" };

function response(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}

function publishableKey(): string {
  const legacy = Deno.env.get("SUPABASE_ANON_KEY");
  if (legacy) return legacy;
  const values = Deno.env.get("SUPABASE_PUBLISHABLE_KEYS");
  if (!values) return "";
  try {
    const parsed = JSON.parse(values) as Record<string, string>;
    return Object.values(parsed)[0] ?? "";
  } catch {
    return "";
  }
}

async function isAuthenticated(request: Request): Promise<boolean> {
  const authorization = request.headers.get("authorization") ?? "";
  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const apiKey = publishableKey();
  if (!authorization.startsWith("Bearer ") || !supabaseUrl || !apiKey) {
    return false;
  }
  const result = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: { authorization, apikey: apiKey },
  });
  return result.ok;
}

function extractOutputText(payload: Record<string, unknown>): string {
  if (typeof payload.output_text === "string") return payload.output_text;
  if (!Array.isArray(payload.output)) return "";
  for (const item of payload.output) {
    const message = item as Record<string, unknown>;
    if (!Array.isArray(message.content)) continue;
    for (const content of message.content) {
      const part = content as Record<string, unknown>;
      if (part.type === "output_text" && typeof part.text === "string") {
        return part.text;
      }
    }
  }
  return "";
}

Deno.serve(async (request: Request) => {
  if (request.method !== "POST") {
    return response(405, { error: "method_not_allowed" });
  }
  if (!(await isAuthenticated(request))) {
    return response(401, { error: "authentication_required" });
  }

  const ai = resolveAiProvider((name) => Deno.env.get(name));
  if (!ai) {
    return response(503, {
      error: "generation_not_configured",
      retryable: false,
    });
  }

  let operation: GenerationOperation;
  let expectedWords: string[] = [];
  let promptPayload: unknown[];
  let outputLanguage = "English";
  let weakCards: WeakCardInput[] = [];
  try {
    const body = await request.json() as Record<string, unknown>;
    if (
      body.operation !== "generate_word_cards" &&
      body.operation !== "suggest_extensions"
    ) {
      throw new Error("unknown operation");
    }
    operation = body.operation;
    const locale = typeof body.output_locale === "string"
      ? body.output_locale
      : "en";
    outputLanguage = ({
      en: "English",
      "zh-Hans": "Simplified Chinese",
      "zh-Hant": "Traditional Chinese",
      ja: "Japanese",
      ko: "Korean",
      es: "Spanish",
      fr: "French",
      de: "German",
      pt: "Portuguese",
      ru: "Russian",
    } as Record<string, string>)[locale] ?? "English";
    if (operation === "generate_word_cards") {
      expectedWords = normalizeWords(body.words);
      promptPayload = expectedWords;
    } else {
      weakCards = normalizeWeakCards(body.weak_cards);
      promptPayload = weakCards;
    }
  } catch (error) {
    return response(400, {
      error: "invalid_request",
      message: error instanceof Error ? error.message : "Invalid request",
    });
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 25_000);
  try {
    const modelResponse = await fetch(ai.endpoint, {
      method: "POST",
      signal: controller.signal,
      headers: {
        authorization: `Bearer ${ai.apiKey}`,
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: ai.model,
        store: false,
        max_output_tokens: operation === "generate_word_cards" ? 6500 : 1800,
        ...(ai.provider === "deepseek"
          ? { reasoning: { effort: "none" } }
          : {}),
        input: [
          {
            role: "system",
            content:
              "You are a careful lexicographer creating concise study drafts. Accuracy and natural usage matter more than filling every optional field. Return only the requested structured data.",
          },
          {
            role: "user",
            content: buildGenerationPrompt(
              operation,
              promptPayload,
              outputLanguage,
            ),
          },
        ],
        text: {
          format: {
            type: "json_schema",
            name: "loopcard_word_cards",
            schema: wordCardResponseSchema,
            ...(ai.supportsStrictFormat ? { strict: true } : {}),
          },
        },
      }),
    });
    const payload = await modelResponse.json() as Record<string, unknown>;
    if (!modelResponse.ok) {
      return response(modelResponse.status >= 500 ? 503 : 502, {
        error: "provider_error",
        retryable: true,
        provider: ai.provider,
        upstream_status: modelResponse.status,
      });
    }
    const outputText = extractOutputText(payload);
    if (!outputText) {
      return response(502, { error: "empty_generation", retryable: true });
    }
    const cards = validateDrafts(
      JSON.parse(outputText),
      operation,
      expectedWords,
    );
    if (operation === "suggest_extensions") {
      const parentIds = new Set(weakCards.map((card) => card.id));
      const existingPrompts = new Set(
        weakCards.map((card) => card.prompt.toLowerCase()),
      );
      if (
        cards.some((card) =>
          !parentIds.has(card.parent_card_id) ||
          existingPrompts.has(card.prompt.toLowerCase())
        )
      ) {
        return response(502, { error: "invalid_generation", retryable: true });
      }
    }
    return response(200, { operation, cards });
  } catch (error) {
    const timeoutError = error instanceof DOMException &&
      error.name === "AbortError";
    return response(timeoutError ? 504 : 502, {
      error: timeoutError ? "generation_timeout" : "invalid_generation",
      retryable: true,
    });
  } finally {
    clearTimeout(timeout);
  }
});

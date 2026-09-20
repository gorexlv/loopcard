import { assertEquals } from "jsr:@std/assert@1";
import { resolveAiProvider } from "./ai_provider.ts";

function env(values: Record<string, string>) {
  return (name: string) => values[name];
}

Deno.test("prefers configured DeepSeek and uses its Responses endpoint", () => {
  const config = resolveAiProvider(env({
    AI_PROVIDER: "deepseek",
    DEEPSEEK_API_KEY: "temporary-key",
  }));

  assertEquals(config?.provider, "deepseek");
  assertEquals(config?.endpoint, "https://api.deepseek.com/responses");
  assertEquals(config?.model, "deepseek-flash");
  assertEquals(config?.supportsStrictFormat, false);
});

Deno.test("keeps OpenAI as an explicit fallback", () => {
  const config = resolveAiProvider(env({
    AI_PROVIDER: "openai",
    OPENAI_API_KEY: "fallback-key",
    OPENAI_MODEL: "gpt-test",
  }));

  assertEquals(config?.provider, "openai");
  assertEquals(config?.model, "gpt-test");
  assertEquals(config?.supportsStrictFormat, true);
});

Deno.test("does not silently use another provider when its key is missing", () => {
  assertEquals(
    resolveAiProvider(env({
      AI_PROVIDER: "deepseek",
      OPENAI_API_KEY: "must-not-be-used",
    })),
    null,
  );
});

Deno.test("OpenRouter is opt-in and never borrows another provider's key", () => {
  const config = resolveAiProvider(env({
    AI_PROVIDER: "openrouter",
    OPENROUTER_API_KEY: "temporary-key",
    AI_MODEL: "qwen/qwen3-vl-235b-a22b-instruct",
  }));
  assertEquals(config?.endpoint, "https://openrouter.ai/api/v1/responses");
  assertEquals(config?.supportsStrictFormat, true);
  assertEquals(
    resolveAiProvider(env({ OPENROUTER_API_KEY: "ocr-only" })),
    null,
  );
  assertEquals(
    resolveAiProvider(
      env({ AI_PROVIDER: "openrouter", OPENAI_API_KEY: "unused" }),
    ),
    null,
  );
});

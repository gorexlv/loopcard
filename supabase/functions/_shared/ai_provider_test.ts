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

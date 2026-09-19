export type AiProvider = "deepseek" | "openai";

export type AiProviderConfig = {
  provider: AiProvider;
  apiKey: string;
  endpoint: string;
  model: string;
  supportsStrictFormat: boolean;
};

export function resolveAiProvider(
  read: (name: string) => string | undefined,
): AiProviderConfig | null {
  const requested = read("AI_PROVIDER")?.trim().toLowerCase();
  if (requested === "deepseek" || (!requested && read("DEEPSEEK_API_KEY"))) {
    const apiKey = read("DEEPSEEK_API_KEY")?.trim();
    if (!apiKey) return null;
    return {
      provider: "deepseek",
      apiKey,
      endpoint: "https://api.deepseek.com/responses",
      model: read("AI_MODEL")?.trim() || "deepseek-flash",
      supportsStrictFormat: false,
    };
  }
  if (requested !== undefined && requested !== "openai") return null;
  const apiKey = read("OPENAI_API_KEY")?.trim();
  if (!apiKey) return null;
  return {
    provider: "openai",
    apiKey,
    endpoint: "https://api.openai.com/v1/responses",
    model: read("AI_MODEL")?.trim() || read("OPENAI_MODEL")?.trim() ||
      "gpt-4o-mini",
    supportsStrictFormat: true,
  };
}

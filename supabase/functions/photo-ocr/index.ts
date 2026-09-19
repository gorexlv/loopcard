import {
  MAX_IMAGE_BYTES,
  OCR_MODEL,
  ocrRequest,
  parseOcrResponse,
  validateImage,
} from "../_shared/photo_ocr.ts";
const headers = {
  "content-type": "application/json",
  "access-control-allow-origin": "*",
  "access-control-allow-headers":
    "authorization, apikey, content-type, x-client-info",
};
const reply = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers });
Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers });
  if (request.method !== "POST") {
    return reply(405, { error: "method_not_allowed" });
  }
  try {
    const authorization = request.headers.get("authorization") ?? "";
    const anon = Deno.env.get("SUPABASE_ANON_KEY") ||
      Object.values(
        JSON.parse(Deno.env.get("SUPABASE_PUBLISHABLE_KEYS") || "{}"),
      )[0];
    if (!authorization.startsWith("Bearer ") || !anon) {
      return reply(401, { error: "authentication_required" });
    }
    const auth = await fetch(`${Deno.env.get("SUPABASE_URL")}/auth/v1/user`, {
      headers: { authorization, apikey: String(anon) },
      signal: AbortSignal.timeout(5000),
    });
    if (!auth.ok) return reply(401, { error: "authentication_required" });
    // Bound streamed request bodies, including requests without Content-Length.
    const limit = Math.ceil(MAX_IMAGE_BYTES / 3) * 4 + 1024;
    const reader = request.body?.getReader();
    if (!reader) return reply(400, { error: "invalid_image" });
    const chunks: Uint8Array[] = [];
    let size = 0;
    while (true) {
      const { value, done } = await reader.read();
      if (done) break;
      size += value.length;
      if (size > limit) {
        await reader.cancel();
        return reply(413, { error: "image_too_large" });
      }
      chunks.push(value);
    }
    const bytes = new Uint8Array(size);
    let offset = 0;
    for (const chunk of chunks) {
      bytes.set(chunk, offset);
      offset += chunk.length;
    }
    let image: string;
    try {
      image = validateImage(JSON.parse(new TextDecoder().decode(bytes)));
    } catch {
      return reply(400, { error: "invalid_image" });
    }
    const key = Deno.env.get("OPENROUTER_API_KEY");
    if (!key) return reply(503, { error: "ocr_not_configured" });
    const model = Deno.env.get("OCR_MODEL") || OCR_MODEL;
    const response = await fetch(
      "https://openrouter.ai/api/v1/chat/completions",
      {
        method: "POST",
        headers: {
          authorization: `Bearer ${key}`,
          "content-type": "application/json",
        },
        body: JSON.stringify(ocrRequest(image, model)),
        signal: AbortSignal.timeout(55000),
      },
    );
    if (!response.ok) {
      return reply(response.status === 429 ? 429 : 502, {
        error: "ocr_provider_error",
      });
    }
    const text = parseOcrResponse(await response.json());
    return reply(200, { text, model });
  } catch {
    return reply(502, { error: "ocr_failed" });
  }
});

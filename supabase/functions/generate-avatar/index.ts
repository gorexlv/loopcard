const headers = {
  "content-type": "application/json",
  "access-control-allow-origin": "*",
  "access-control-allow-headers":
    "authorization, apikey, content-type, x-client-info",
};
const respond = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers });

type Dependencies = {
  env: (key: string) => string | undefined;
  fetch: typeof fetch;
};

export function avatarPrompt(seed: string): string {
  const animals = ["owl", "fox", "otter", "red panda", "rabbit", "bear"];
  const colors = ["teal", "warm amber", "sage green", "soft coral", "lavender"];
  let hash = 0;
  for (const char of seed) {
    hash = (Math.imul(hash, 31) + char.charCodeAt(0)) >>> 0;
  }
  return `Create a single original Pixar-style polished 3D animated ${
    animals[hash % animals.length]
  } character portrait for a learning app. Large kind expressive eyes, gentle curious smile, refined cinematic soft studio lighting, dimensional fur or feathers, ${
    colors[(hash >>> 8) % colors.length]
  } accents, warm ivory seamless background. Head and upper shoulders centered, face inside central 65 percent, generous safe margin for circular crop, legible at 72 pixels. No text, logo, watermark, border or existing movie characters.`;
}

export async function handleRequest(
  request: Request,
  deps: Dependencies = { env: (key) => Deno.env.get(key), fetch },
): Promise<Response> {
  if (request.method === "OPTIONS") return new Response("ok", { headers });
  if (request.method !== "POST") {
    return respond(405, { error: "method_not_allowed" });
  }
  const authorization = request.headers.get("authorization") ?? "";
  if (!authorization.startsWith("Bearer ")) {
    return respond(401, { error: "authentication_required" });
  }
  const base = deps.env("SUPABASE_URL");
  const serviceKey = deps.env("SUPABASE_SERVICE_ROLE_KEY");
  if (!base || !serviceKey) {
    return respond(503, { error: "generation_not_configured" });
  }
  const serviceHeaders = {
    apikey: serviceKey,
    authorization: `Bearer ${serviceKey}`,
    "content-type": "application/json",
  };
  const call = (path: string, init: RequestInit = {}) =>
    deps.fetch(`${base}${path}`, {
      ...init,
      headers: { ...serviceHeaders, ...init.headers },
      signal: AbortSignal.timeout(10000),
    });
  try {
    // Never accept a client-provided user ID or prompt.
    const auth = await call("/auth/v1/user", { headers: { authorization } });
    if (!auth.ok) return respond(401, { error: "authentication_required" });
    const user = await auth.json();
    if (typeof user.id !== "string" || !/^[0-9a-f-]{36}$/i.test(user.id)) {
      return respond(401, { error: "authentication_required" });
    }
    const metadata = user.user_metadata ?? {};
    const existing = [metadata.avatar_url, metadata.picture].find(
      (value) => typeof value === "string" && value.trim().length > 0,
    );
    if (existing) return respond(200, { avatar_url: existing });
    const record = await call(
      `/rest/v1/generated_avatars?user_id=eq.${user.id}&select=avatar_url`,
    );
    if (!record.ok) throw Error("avatar_read_failed");
    const rows = await record.json();
    if (rows[0]?.avatar_url) {
      return respond(200, { avatar_url: rows[0].avatar_url });
    }
    const openRouter = !!deps.env("OPENROUTER_API_KEY");
    const apiKey = openRouter
      ? deps.env("OPENROUTER_API_KEY")
      : deps.env("OPENAI_API_KEY");
    if (!apiKey) return respond(503, { error: "generation_not_configured" });
    const claim = await call("/rest/v1/rpc/claim_avatar_generation", {
      method: "POST",
      body: JSON.stringify({ target_user: user.id }),
    });
    if (!claim.ok) throw Error("avatar_claim_failed");
    if (await claim.json() !== true) return respond(202, { status: "pending" });

    const generated = await deps.fetch(
      openRouter
        ? "https://openrouter.ai/api/v1/images"
        : "https://api.openai.com/v1/images/generations",
      {
        method: "POST",
        headers: {
          authorization: `Bearer ${apiKey}`,
          "content-type": "application/json",
        },
        signal: AbortSignal.timeout(120000),
        body: JSON.stringify({
          model: deps.env("AVATAR_IMAGE_MODEL") ||
            (openRouter ? "openai/gpt-image-2" : "gpt-image-2"),
          prompt: avatarPrompt(user.id),
          n: 1,
          quality: "low",
          ...(openRouter ? { aspect_ratio: "1:1" } : {
            size: "1024x1024",
            output_format: "webp",
            output_compression: 80,
          }),
        }),
      },
    );
    if (!generated.ok) throw Error("avatar_generation_failed");
    const output = await generated.json();
    const encoded = output.data?.[0]?.b64_json;
    if (
      typeof encoded !== "string" || !encoded.length || encoded.length > 7000000
    ) throw Error("invalid_image");
    const bytes = Uint8Array.from(atob(encoded), (char) => char.charCodeAt(0));
    const webp = new TextDecoder().decode(bytes.slice(0, 4)) === "RIFF" &&
      new TextDecoder().decode(bytes.slice(8, 12)) === "WEBP";
    const png = [137, 80, 78, 71, 13, 10, 26, 10].every((byte, index) =>
      bytes[index] === byte
    );
    if (bytes.length > 5242880 || (!webp && !png)) throw Error("invalid_image");
    const mime = webp ? "image/webp" : "image/png";
    const path = `generated-avatars/${user.id}/avatar.${webp ? "webp" : "png"}`;
    const upload = await call(`/storage/v1/object/${path}`, {
      method: "POST",
      body: bytes,
      headers: {
        "content-type": mime,
        "x-upsert": "true",
        "cache-control": "31536000",
      },
    });
    if (!upload.ok) throw Error("avatar_upload_failed");
    const avatarUrl = `${base}/storage/v1/object/public/${path}`;
    const saved = await call(
      `/rest/v1/generated_avatars?user_id=eq.${user.id}`,
      {
        method: "PATCH",
        body: JSON.stringify({ avatar_url: avatarUrl }),
      },
    );
    if (!saved.ok) throw Error("avatar_save_failed");
    return respond(200, { avatar_url: avatarUrl });
  } catch {
    // Do not return provider responses, tokens, or account details to the client.
    return respond(502, { error: "avatar_unavailable" });
  }
}

if (import.meta.main) Deno.serve((request) => handleRequest(request));

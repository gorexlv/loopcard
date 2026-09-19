import { handleRequest } from "../../functions/generate-avatar/index.ts";

const id = "00000000-0000-0000-0000-000000000123";
function assert(value: unknown, message = "assertion failed"): asserts value {
  if (!value) throw Error(message);
}
const json = (value: unknown, status = 200) =>
  new Response(JSON.stringify(value), { status });
const request = () =>
  new Request("https://local/generate-avatar", {
    method: "POST",
    headers: { authorization: "Bearer test-user" },
  });
function fixture(
  options: {
    existing?: string;
    stored?: string;
    claim?: boolean;
    failed?: boolean;
    router?: boolean;
  } = {},
) {
  const calls: string[] = [];
  const deps = {
    env: (key: string) =>
      ({
        SUPABASE_URL: "https://local",
        SUPABASE_SERVICE_ROLE_KEY: "service-test",
        ...(options.router
          ? { OPENROUTER_API_KEY: "image-test" }
          : { OPENAI_API_KEY: "image-test" }),
      } as Record<string, string>)[key],
    fetch: (async (url: string | URL | Request, init?: RequestInit) => {
      const path = String(url);
      calls.push(path);
      if (path.endsWith("/auth/v1/user")) {
        return json({ id, user_metadata: { avatar_url: options.existing } });
      }
      if (path.includes("select=avatar_url")) {
        return json([{ avatar_url: options.stored }]);
      }
      if (path.includes("/rpc/")) return json(options.claim ?? true);
      if (path.includes("images")) {
        assert(
          !String(init?.body).includes(id),
          "user ID must not be sent to image provider",
        );
        if (options.failed) {
          return json({ error: "private-provider-error" }, 500);
        }
        return json({ data: [{ b64_json: btoa("RIFFxxxxWEBPxxxx") }] });
      }
      if (path.includes("/storage/")) return json({ Key: "avatar.webp" });
      if (init?.method === "PATCH") return json(null);
      throw Error(`unexpected call ${path}`);
    }) as typeof fetch,
  };
  return { deps, calls };
}
Deno.test("rejects unauthenticated generation without contacting provider", async () => {
  const f = fixture();
  const response = await handleRequest(
    new Request("https://local", { method: "POST" }),
    f.deps,
  );
  assert(response.status === 401 && f.calls.length === 0);
});
Deno.test("preserves existing provider and generated avatars without generation", async () => {
  for (
    const options of [{ existing: "https://avatar/existing" }, {
      stored: "https://avatar/stored",
    }]
  ) {
    const f = fixture(options);
    const response = await handleRequest(request(), f.deps);
    assert(response.status === 200);
    assert(
      (await response.json()).avatar_url ===
        (options.existing ?? options.stored),
    );
    assert(!f.calls.some((url) => url.includes("images")));
  }
});
Deno.test("concurrent claim does not call image generation", async () => {
  const f = fixture({ claim: false });
  assert((await handleRequest(request(), f.deps)).status === 202);
  assert(!f.calls.some((url) => url.includes("images")));
});
Deno.test("generates, uploads and persists authenticated account avatar for both providers", async () => {
  for (const router of [false, true]) {
    const f = fixture({ router });
    const response = await handleRequest(request(), f.deps);
    assert(response.status === 200);
    assert(
      (await response.json()).avatar_url ===
        `https://local/storage/v1/object/public/generated-avatars/${id}/avatar.webp`,
    );
    assert(f.calls.length === 6);
  }
});
Deno.test("generation failure is recoverable and does not expose provider details", async () => {
  const f = fixture({ failed: true });
  const response = await handleRequest(request(), f.deps);
  assert(response.status === 502);
  assert(
    !JSON.stringify(await response.json()).includes("private-provider-error"),
  );
  assert(!f.calls.some((url) => url.includes("/storage/")));
});

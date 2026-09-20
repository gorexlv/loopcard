import { assertEquals, assertThrows } from "jsr:@std/assert@1";
import { parseAgentJson } from "./agent_response.ts";
Deno.test("accepts structured JSON with or without a single markdown wrapper", () => {
  assertEquals(parseAgentJson('{"reply":"原文"}'), { reply: "原文" });
  assertEquals(parseAgentJson('```json\n{"reply":"原文"}\n```'), {
    reply: "原文",
  });
});
Deno.test("does not extract partial JSON or invent missing output", () => {
  assertThrows(() => parseAgentJson(undefined));
  assertThrows(() => parseAgentJson('Explanation {"reply":"text"}'));
  assertThrows(() => parseAgentJson('```json\n{"reply":\n```'));
});

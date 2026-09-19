import { assertEquals, assertThrows } from "jsr:@std/assert@1";
import {
  OCR_MODEL,
  ocrRequest,
  parseOcrResponse,
  validateImage,
} from "./photo_ocr.ts";
Deno.test("OCR rejects remote URLs, invalid base64 and mismatched signatures", () => {
  for (
    const image of [
      "https://example.com/a.jpg",
      "data:image/png;base64,???",
      "data:image/jpeg;base64," + btoa("not an image payload"),
    ]
  ) assertThrows(() => validateImage({ image }));
});
Deno.test("OCR preserves original transcription and rejects truncated output", () => {
  const text = "學而時習之，不亦說乎？\n〔不清〕";
  assertEquals(
    parseOcrResponse({
      choices: [{ finish_reason: "stop", message: { content: text } }],
    }),
    text,
  );
  assertThrows(() =>
    parseOcrResponse({
      choices: [{ finish_reason: "length", message: { content: text } }],
    })
  );
  assertThrows(() =>
    parseOcrResponse({ choices: [{ finish_reason: "stop", message: {} }] })
  );
});
Deno.test("OCR pins Qwen3-VL and treats the photo as data", () => {
  const image = "data:image/png;base64," + btoa("\x89PNG\r\n\x1a\nxxxx");
  assertEquals(validateImage({ image }), image);
  const request = ocrRequest(image);
  assertEquals(request.model, OCR_MODEL);
  assertEquals((request.messages[1].content as any[])[1].image_url.url, image);
});

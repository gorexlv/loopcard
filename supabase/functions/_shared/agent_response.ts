/** Accept JSON or a single JSON markdown fence; never repair/truncate model data. */
export function parseAgentJson(value: unknown): unknown {
  if (typeof value !== "string") throw Error("missing_output_text");
  const text = value.trim();
  const fenced = /^```(?:json)?\s*\n([\s\S]*?)\n```$/i.exec(text);
  return JSON.parse(fenced ? fenced[1] : text);
}

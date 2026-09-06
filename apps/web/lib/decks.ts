export type WebCard = { id: string; prompt: string; answer: string };
export type WebDeck = {
  id: string;
  title: string;
  subtitle: string;
  kind: string;
  visibility: 'private' | 'public';
  marketSlug: string | null;
  owned: boolean;
  cards: WebCard[];
};

type Row = Record<string, unknown>;

export function parseCardLines(value: string): Array<{ prompt: string; answer: string }> {
  return value.split(/\r?\n/).map((line) => line.trim()).filter(Boolean).slice(0, 500).map((line) => {
    const separator = line.indexOf('::');
    return separator < 0
      ? { prompt: line.slice(0, 1000), answer: '' }
      : { prompt: line.slice(0, separator).trim().slice(0, 1000), answer: line.slice(separator + 2).trim().slice(0, 10000) };
  }).filter((card) => card.prompt.length > 0);
}

export function parseCardDrafts(value: string): Array<{ prompt: string; answer: string }> {
  try {
    const parsed: unknown = JSON.parse(value);
    if (!Array.isArray(parsed)) return [];
    return parsed.slice(0, 500).map((card) => {
      const draft = card && typeof card === 'object' ? card as Record<string, unknown> : {};
      return {
        prompt: String(draft.prompt ?? '').trim().slice(0, 1000),
        answer: String(draft.answer ?? '').trim().slice(0, 10000),
      };
    }).filter((card) => card.prompt.length > 0);
  } catch {
    return [];
  }
}

export function cardsToLines(cards: WebCard[]) {
  return cards.map((card) => `${card.prompt} :: ${card.answer}`).join('\n');
}

export function deckFromRow(row: Row, owned: boolean): WebDeck {
  const cards = [...((row.cards as Row[] | null) ?? [])].sort((a, b) => Number(a.position) - Number(b.position));
  return {
    id: String(row.id), title: String(row.title), subtitle: String(row.subtitle ?? ''),
    kind: String(row.kind ?? 'generic'), visibility: row.visibility === 'public' ? 'public' : 'private',
    marketSlug: typeof row.market_slug === 'string' ? row.market_slug : null, owned,
    cards: cards.map((card) => {
      const sections = [...((card.card_sections as Row[] | null) ?? [])].sort((a, b) => Number(a.position) - Number(b.position));
      const first = sections[0];
      return { id: String(card.id), prompt: String(card.prompt), answer: String(first?.body ?? first?.heading ?? '') };
    }),
  };
}

export const deckSelection = 'id,user_id,title,subtitle,kind,visibility,market_slug,updated_at,cards(id,prompt,position,card_sections(title,heading,body,position))';

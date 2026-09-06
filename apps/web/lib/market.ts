import { publicDecks, type PublicDeck } from '@loopcard/shared';
import { createClient } from './supabase/server';

type Row = Record<string, unknown>;
const selection = 'id,user_id,title,subtitle,kind,market_slug,cards(id,prompt,position,card_sections(title,heading,body,position))';
const MARKET_QUERY_TIMEOUT_MS = 1_500;

async function withTimeout<T>(promise: PromiseLike<T>): Promise<T> {
  return Promise.race([
    Promise.resolve(promise),
    new Promise<never>((_, reject) => {
      setTimeout(() => reject(new Error('Market query timed out')), MARKET_QUERY_TIMEOUT_MS);
    }),
  ]);
}

function fromRow(row: Row): PublicDeck {
  const cards = [...((row.cards as Row[] | null) ?? [])].sort((a, b) => Number(a.position) - Number(b.position));
  return {
    slug: String(row.market_slug ?? row.id), title: String(row.title), subtitle: String(row.subtitle ?? ''),
    description: String(row.subtitle || 'A community flashcard deck.'), category: String(row.kind ?? 'General'),
    author: row.user_id ? 'LoopCard community' : 'LoopCard Studio', saves: 0, accent: row.user_id ? '#dc6d73' : '#2dbda6',
    cards: cards.map((card) => ({ id: String(card.id), prompt: String(card.prompt), sections: [...((card.card_sections as Row[] | null) ?? [])].sort((a, b) => Number(a.position) - Number(b.position)).map((section) => ({ title: String(section.title), heading: String(section.heading ?? ''), body: String(section.body ?? '') })) })),
  };
}

export async function getMarketDecks(): Promise<PublicDeck[]> {
  try {
    const supabase = await createClient();
    const { data, error } = await withTimeout(supabase.from('decks').select(selection).eq('visibility', 'public').order('updated_at', { ascending: false }));
    if (error || !data?.length) return publicDecks;
    const databaseDecks = data.map((row) => fromRow(row));
    const databaseSlugs = new Set(databaseDecks.map((deck) => deck.slug));
    return [...databaseDecks, ...publicDecks.filter((deck) => !databaseSlugs.has(deck.slug))];
  } catch { return publicDecks; }
}

export async function getMarketDeck(identifier: string): Promise<PublicDeck | undefined> {
  const fallback = publicDecks.find((deck) => deck.slug === identifier);
  try {
    const supabase = await createClient();
    const query = /^[0-9a-f-]{36}$/i.test(identifier)
      ? supabase.from('decks').select(selection).eq('id', identifier)
      : supabase.from('decks').select(selection).eq('market_slug', identifier);
    const { data, error } = await withTimeout(query.eq('visibility', 'public').maybeSingle());
    return !error && data ? fromRow(data) : fallback;
  } catch { return fallback; }
}

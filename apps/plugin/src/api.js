import { anonymousClient, authenticatedClient } from './client.js';
import { clearSession, config, writeSession } from './config.js';

function ensure(data, error) {
  if (error) throw new Error(error.message);
  return data;
}

export async function login(email, password, overrides = {}) {
  const client = anonymousClient(overrides);
  const { data, error } = await client.auth.signInWithPassword({ email, password });
  ensure(data, error);
  if (!data.session) throw new Error('No session returned');
  const current = config(overrides);
  await writeSession(current.sessionPath, data.session);
  return { id: data.user.id, email: data.user.email };
}

export async function logout(overrides = {}) {
  const current = config(overrides);
  try {
    const { client } = await authenticatedClient(overrides);
    await client.auth.signOut();
  } finally {
    await clearSession(current.sessionPath);
  }
  return { signedOut: true };
}

export async function listDecks(overrides = {}) {
  const { client } = await authenticatedClient(overrides);
  const { data, error } = await client
    .from('decks')
    .select('id,title,subtitle,kind,created_at,updated_at,cards(count)')
    .order('updated_at', { ascending: false });
  return ensure(data, error);
}

export async function getDeck(id, overrides = {}) {
  const { client } = await authenticatedClient(overrides);
  const { data, error } = await client
    .from('decks')
    .select('id,title,subtitle,kind,created_at,updated_at,cards(id,prompt,position,card_sections(id,title,heading,body,position))')
    .eq('id', id)
    .single();
  return ensure(data, error);
}

export async function createDeck(input, overrides = {}) {
  const { client, user } = await authenticatedClient(overrides);
  const { data, error } = await client
    .from('decks')
    .insert({
      user_id: user.id,
      title: input.title,
      subtitle: input.subtitle ?? '',
      kind: input.kind ?? 'generic',
    })
    .select('id,title,subtitle,kind,created_at,updated_at')
    .single();
  return ensure(data, error);
}

export async function listCards(deckId, overrides = {}) {
  const { client } = await authenticatedClient(overrides);
  const query = client
    .from('cards')
    .select('id,deck_id,prompt,position,created_at,updated_at,card_sections(id,title,heading,body,position)')
    .order('position');
  if (deckId) query.eq('deck_id', deckId);
  const { data, error } = await query;
  return ensure(data, error);
}

export async function getCard(id, overrides = {}) {
  const { client } = await authenticatedClient(overrides);
  const { data, error } = await client
    .from('cards')
    .select('id,deck_id,prompt,position,created_at,updated_at,card_sections(id,title,heading,body,position)')
    .eq('id', id)
    .single();
  return ensure(data, error);
}

export async function createCard(input, overrides = {}) {
  const { client, user } = await authenticatedClient(overrides);
  let position = input.position;
  if (position === undefined) {
    const { data, error } = await client
      .from('cards')
      .select('position')
      .eq('deck_id', input.deckId)
      .order('position', { ascending: false })
      .limit(1);
    ensure(data, error);
    position = data.length === 0 ? 0 : data[0].position + 1;
  }
  const { data: card, error } = await client
    .from('cards')
    .insert({
      user_id: user.id,
      deck_id: input.deckId,
      prompt: input.prompt,
      position,
    })
    .select('id,deck_id,prompt,position,created_at,updated_at')
    .single();
  ensure(card, error);
  const sections = input.sections ?? [];
  if (sections.length > 0) {
    const { error: sectionError } = await client.from('card_sections').insert(
      sections.map((section, index) => ({
        user_id: user.id,
        card_id: card.id,
        title: section.title,
        heading: section.heading ?? '',
        body: section.body ?? '',
        position: section.position ?? index,
      })),
    );
    ensure(null, sectionError);
  }
  return getCard(card.id, overrides);
}

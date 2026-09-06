'use server';
import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { requireUser } from '../../lib/auth';
import { parseCardDrafts, parseCardLines } from '../../lib/decks';

function deckFields(formData: FormData) {
  const title = String(formData.get('title') ?? '').trim().slice(0, 120);
  if (!title) throw new Error('A title is required');
  return {
    input_deck_id: formData.get('deckId') ? String(formData.get('deckId')) : null,
    input_title: title,
    input_subtitle: String(formData.get('subtitle') ?? '').trim().slice(0, 240),
    input_kind: ['generic', 'word', 'formula', 'idiom', 'concept', 'equation'].includes(String(formData.get('kind'))) ? String(formData.get('kind')) : 'generic',
    input_visibility: formData.get('visibility') === 'public' ? 'public' : 'private',
    input_cards: parseCards(formData),
  };
}

function parseCards(formData: FormData) {
  const json = String(formData.get('cardsJson') ?? '');
  if (!json) return parseCardLines(String(formData.get('cards') ?? ''));
  return parseCardDrafts(json);
}

export async function saveDeck(formData: FormData) {
  const { supabase } = await requireUser();
  const { data, error } = await supabase.rpc('save_owned_deck', deckFields(formData));
  if (error) redirect(`/app?error=${encodeURIComponent('Could not save the deck')}`);
  revalidatePath('/app'); revalidatePath('/market');
  redirect(`/app/decks/${data}?saved=1`);
}

export async function deleteDeck(formData: FormData) {
  const { supabase, user } = await requireUser();
  const id = String(formData.get('deckId') ?? '');
  if (id) await supabase.from('decks').delete().eq('id', id).eq('user_id', user.id);
  revalidatePath('/app'); revalidatePath('/market'); redirect('/app');
}

export async function updateProfile(formData: FormData) {
  const { supabase, user } = await requireUser();
  const displayName = String(formData.get('displayName') ?? '').trim().slice(0, 80);
  const { error } = await supabase.from('profiles').update({ display_name: displayName || null }).eq('id', user.id);
  if (error) redirect('/app/profile?error=Could%20not%20update%20profile');
  revalidatePath('/app'); redirect('/app/profile?saved=1');
}

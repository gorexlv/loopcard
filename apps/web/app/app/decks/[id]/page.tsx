import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { DeckEditor } from '../../../../components/deck-editor';
import { DeleteDeckForm } from '../../../../components/delete-deck-form';
import { requireUser } from '../../../../lib/auth';
import { deckFromRow, deckSelection } from '../../../../lib/decks';
export const metadata: Metadata = { title: 'Edit deck', robots: { index: false, follow: false } };
export default async function EditDeckPage({ params, searchParams }: { params: Promise<{ id: string }>; searchParams: Promise<{ saved?: string }> }) {
  const { supabase, user } = await requireUser(); const { id } = await params;
  const { data } = await supabase.from('decks').select(deckSelection).eq('id', id).eq('user_id', user.id).maybeSingle();
  if (!data) notFound(); const deck = deckFromRow(data, true); const query = await searchParams;
  return <main className="workspace-page editor-page"><header className="workspace-header"><div><span className="eyebrow">{deck.visibility === 'public' ? 'Published' : 'Private deck'}</span><h1>Edit deck</h1></div></header>{query.saved && <div className="form-message" role="status">Saved.</div>}<DeckEditor deck={deck} /><DeleteDeckForm deckId={deck.id} /></main>;
}

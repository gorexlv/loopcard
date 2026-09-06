import { publicDecks, type PublicDeck } from '@loopcard/shared';
import { notFound } from 'next/navigation';
import { StudyExperience } from '../../../../components/study-experience';
import { requireUser } from '../../../../lib/auth';
import { deckFromRow, deckSelection } from '../../../../lib/decks';

export default async function StudyDeckPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  if (process.env.NEXT_PUBLIC_DESIGN_PREVIEW === '1' && id === 'preview') {
    return <StudyExperience decks={[publicDecks[0]]} />;
  }
  const { supabase, user } = await requireUser();
  const { data } = await supabase.from('decks').select(deckSelection).eq('id', id).maybeSingle();
  if (!data) notFound();
  const owned = data.user_id === user.id;
  if (!owned) {
    const { data: saved } = await supabase.from('deck_library').select('deck_id').eq('user_id', user.id).eq('deck_id', id).maybeSingle();
    if (!saved) notFound();
  }
  const deck = deckFromRow(data, owned);
  const publicDeck: PublicDeck = { slug: deck.id, title: deck.title, subtitle: deck.subtitle, description: deck.subtitle, category: deck.kind, author: owned ? 'You' : 'LoopCard community', saves: 0, accent: '#2dbda6', cards: deck.cards.map((card) => ({ id: card.id, prompt: card.prompt, sections: [{ title: 'Answer', heading: '', body: card.answer }] })) };
  return <StudyExperience decks={[publicDeck]} returnHref="/app" />;
}

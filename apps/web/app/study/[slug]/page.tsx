import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { StudyExperience } from '../../../components/study-experience';
import { getMarketDeck } from '../../../lib/market';

export const metadata: Metadata = { title: 'Study a flashcard deck', robots: { index: false, follow: false } };

export default async function PublicStudyPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const deck = await getMarketDeck(slug);
  if (!deck) notFound();
  return <StudyExperience decks={[deck]} anonymous returnHref={`/market/${deck.slug}`} saveHref={`/login?next=${encodeURIComponent(`/market/${deck.slug}`)}`} />;
}

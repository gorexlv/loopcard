import type { PublicDeck } from '@loopcard/shared';
import Link from 'next/link';

export function DeckTile({ deck, embedded = false, chinese = false }: { deck: PublicDeck; embedded?: boolean; chinese?: boolean }) {
  const href = `/market/${deck.slug}${embedded ? '?embedded=1' : ''}`;
  const prompt = deck.cards[0]?.prompt || deck.title;
  const tone = ['Language', '语言'].includes(deck.category) ? 'sage' : ['Science', '科学'].includes(deck.category) ? 'blue' : ['Design', '设计'].includes(deck.category) ? 'rose' : 'sand';
  return <Link href={href} className="deck-book" data-tone={tone}>
    <div className="deck-cover"><span className="deck-cover-category">{deck.category}</span><strong className={prompt.length > 20 ? 'long-cover' : ''}>{prompt}</strong><span className="deck-cover-bottom"><span>LoopCard</span><span>{deck.cards.length.toString().padStart(2, '0')}</span></span></div>
    <div className="deck-book-caption"><h3>{deck.title}</h3><span>{deck.cards.length} {chinese ? '张卡片' : 'cards'}</span></div>
  </Link>;
}

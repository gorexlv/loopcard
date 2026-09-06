import type { PublicDeck } from '@loopcard/shared';
import Link from 'next/link';

export function DeckTile({ deck, embedded = false }: { deck: PublicDeck; embedded?: boolean }) {
  const href = `/market/${deck.slug}${embedded ? '?embedded=1' : ''}`;
  const firstCard = deck.cards[0];
  const front = firstCard?.prompt || deck.title.slice(0, 2);
  const back = firstCard?.sections[0]?.heading || firstCard?.sections[0]?.body || deck.description;
  return <Link href={href} className="deck-tile" style={{ '--accent': deck.accent } as React.CSSProperties}>
    <div className="deck-tile-top"><span className="category">{deck.category}</span><span className="deck-open">Open deck ↗</span></div>
    <div className="deck-face-stack" aria-label={`Front and back preview for ${deck.title}`}>
      <div className="deck-face deck-face-back"><small>BACK</small><strong>{back}</strong><span>{firstCard?.sections[0]?.title || 'Answer'}</span></div>
      <div className="deck-face deck-face-front"><small>FRONT</small><strong>{front}</strong><span>Tap to reveal</span></div>
    </div>
    <div className="deck-tile-copy"><h3>{deck.title}</h3><p>{deck.description}</p></div>
    <div className="deck-meta"><span>{deck.cards.length} cards</span><span>{deck.saves.toLocaleString()} saves</span></div>
  </Link>;
}

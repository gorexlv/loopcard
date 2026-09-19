import type { CSSProperties } from 'react';
import type { PublicDeck } from '@loopcard/shared';
import Link from 'next/link';
import { CardPrompt } from './recall-card';

export function DeckTile({ deck, embedded = false, chinese = false }: { deck: PublicDeck; embedded?: boolean; chinese?: boolean }) {
  const href = `/market/${deck.slug}${embedded ? '?embedded=1' : ''}`;
  const prompt = deck.cards[0]?.prompt || deck.title;
  const longestWord = Math.max(1, ...prompt.split(/\s+/).map((word) => Array.from(word).length));
  const tone = ({ Language: 'sage', Science: 'blue', Design: 'rose', Arts: 'rose', Culture: 'sage', Business: 'blue', Technology: 'blue', Wellness: 'sage', '文化': 'sand' } as Record<string, string>)[deck.category] ?? 'sand';
  return <Link href={href} className="deck-book" data-tone={tone}>
    <div className="deck-cover" style={{ '--cover-word-length': longestWord } as CSSProperties}><span className="deck-cover-category">{deck.category}</span><strong className={prompt.length > 12 ? 'long-cover' : ''}><CardPrompt text={prompt} /></strong><span className="deck-cover-bottom"><span>LoopCard</span><span>{deck.cards.length.toString().padStart(2, '0')}</span></span></div>
    <div className="deck-book-caption"><h3>{deck.title}</h3><span>{deck.cards.length} {chinese ? '张卡片' : 'cards'}</span></div>
  </Link>;
}

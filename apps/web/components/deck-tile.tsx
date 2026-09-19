'use client';

import { useState, type CSSProperties } from 'react';
import type { PublicDeck } from '@loopcard/shared';
import Link from 'next/link';
import { CardVisual, visualQuestion } from './card-visual';
import { CardPrompt } from './recall-card';

export function DeckTile({ deck, embedded = false, chinese = false }: { deck: PublicDeck; embedded?: boolean; chinese?: boolean }) {
  const [flipped, setFlipped] = useState(false);
  const answer = deck.cards[0]?.sections[0];
  const href = `/market/${deck.slug}${embedded ? '?embedded=1' : ''}`;
  const prompt = visualQuestion(deck.cards[0]?.prompt || deck.title, deck.cards[0]?.visual);
  const longestWord = Math.max(1, ...prompt.split(/\s+/).map((word) => Array.from(word).length));
  const tone = ({ Language: 'sage', Science: 'blue', Design: 'rose', Arts: 'rose', Culture: 'sage', Business: 'blue', Technology: 'blue', Wellness: 'sage', '文化': 'sand' } as Record<string, string>)[deck.category] ?? 'sand';
  return <article className="deck-book" data-tone={tone}>
    <div className="deck-perspective">
      <button type="button" className="deck-flip" data-flipped={flipped} aria-pressed={flipped}
        aria-label={`${deck.title} — ${chinese ? (flipped ? '查看正面' : '翻看答案') : (flipped ? 'Show prompt' : 'Reveal answer')}`}
        onClick={() => setFlipped((value) => !value)} style={{ '--cover-word-length': longestWord } as CSSProperties}>
        <span className="deck-cover" data-illustrated={Boolean(deck.cards[0]?.visual)} aria-hidden={flipped}>
          <span className="deck-cover-category">{deck.category}</span>
          <CardVisual kind={deck.cards[0]?.visual} />
          <strong className={prompt.length > 12 ? 'long-cover' : ''}><CardPrompt text={prompt} /></strong>
          <span className="deck-cover-bottom"><span>LoopCard</span><span>{deck.cards.length.toString().padStart(2, '0')}</span></span>
        </span>
        <span className="deck-cover deck-cover-back" aria-hidden={!flipped}>
          <span className="deck-cover-category">{answer?.title || deck.category}</span>
          <span className="deck-cover-answer"><strong>{answer?.heading || prompt}</strong><span>{answer?.body || (chinese ? '暂无答案' : 'No answer yet')}</span></span>
          <span className="deck-cover-bottom"><span>LoopCard</span><span>01</span></span>
        </span>
      </button>
    </div>
    <Link href={href} className="deck-book-caption"><h3>{deck.title}<span aria-hidden="true"> ↗</span></h3><span>{deck.cards.length} {chinese ? '张卡片' : 'cards'}</span></Link>
  </article>;
}

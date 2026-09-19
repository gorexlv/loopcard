'use client';

import type { PublicDeck } from '@loopcard/shared';
import { useEffect, useState } from 'react';
import { RecallCard } from './recall-card';
import { Icon } from './ui-icon';

export function MarketDeckPreview({ deck }: { deck: PublicDeck }) {
  const [cardIndex, setCardIndex] = useState(0);
  const [sectionIndex, setSectionIndex] = useState(0);
  const [flipped, setFlipped] = useState(false);
  const [chinese, setChinese] = useState(false);
  useEffect(() => { setChinese(document.documentElement.dataset.locale === 'zh'); }, []);
  const card = deck.cards[cardIndex];
  const section = card?.sections[sectionIndex] ?? card?.sections[0];
  if (!card) return <p className="market-preview-empty">No cards yet.</p>;
  function select(index: number) { setCardIndex(index); setSectionIndex(0); setFlipped(false); }
  return <section className="deck-reader" aria-label={chinese ? '预览卡片' : 'Preview cards'}>
    <div className="deck-reader-stage"><RecallCard key={card.id} prompt={card.prompt} heading={section?.heading} body={section?.body} category={deck.category} answerLabel={section?.title} flipped={flipped} onFlip={() => setFlipped(!flipped)} index={cardIndex + 1} chinese={chinese} />
      <div className="deck-reader-controls"><button className="icon-button" onClick={() => select(cardIndex - 1)} disabled={cardIndex === 0} aria-label={chinese ? '上一张' : 'Previous card'}><Icon name="back" /></button><span>{cardIndex + 1} / {deck.cards.length}</span><button className="icon-button" onClick={() => select(cardIndex + 1)} disabled={cardIndex === deck.cards.length - 1} aria-label={chinese ? '下一张' : 'Next card'}><Icon name="back" style={{ transform: 'rotate(180deg)' }} /></button></div>
      {card.sections.length > 1 && <div className="focus-tabs">{card.sections.map((item, index) => <button key={index} aria-pressed={flipped && index === sectionIndex} onClick={() => { setSectionIndex(index); setFlipped(true); }}>{item.title}</button>)}</div>}
    </div>
    <nav className="deck-reader-index" aria-label={chinese ? '卡片目录' : 'Card index'}>{deck.cards.map((item, index) => <button key={item.id} aria-current={index === cardIndex ? 'true' : undefined} onClick={() => select(index)}><span>{String(index + 1).padStart(2, '0')}</span><strong>{item.prompt}</strong><Icon name="back" style={{ transform: 'rotate(180deg)' }} /></button>)}</nav>
  </section>;
}

'use client';

import type { PublicDeck } from '@loopcard/shared';
import type { CSSProperties } from 'react';
import { useEffect, useState } from 'react';

export function MarketDeckPreview({ deck }: { deck: PublicDeck }) {
  const [cardIndex, setCardIndex] = useState(0);
  const [sectionIndex, setSectionIndex] = useState(0);
  const [flipped, setFlipped] = useState(false);
  const card = deck.cards[cardIndex];
  const section = card?.sections[sectionIndex] ?? card?.sections[0];

  useEffect(() => { setSectionIndex(0); setFlipped(false); }, [cardIndex]);
  if (!card) return <div className="market-preview-empty">This deck has no cards yet.</div>;

  const move = (amount: number) => setCardIndex((current) => Math.min(deck.cards.length - 1, Math.max(0, current + amount)));
  const flip = () => setFlipped((value) => !value);

  return <section className="market-preview" aria-labelledby="preview-title">
    <header className="market-preview-heading">
      <div><span className="chapter-label">Interactive preview</span><h2 id="preview-title">A deck you can<br /><em>actually open.</em></h2></div>
      <p>Choose a card, recall the answer, then turn it over. Each back keeps related context in a small set of focused tabs.</p>
    </header>
    <div className="market-preview-layout">
      <div className="market-preview-stage" style={{ '--deck-accent': deck.accent } as CSSProperties}>
        <div className="preview-status"><span>{String(cardIndex + 1).padStart(2, '0')} / {String(deck.cards.length).padStart(2, '0')}</span><span>{flipped ? 'BACK' : 'FRONT'}</span></div>
        <div className="preview-card-stack">
          <button className={`market-preview-card ${flipped ? 'is-flipped' : ''}`} type="button" onClick={flip} aria-label={flipped ? 'Show card front' : 'Reveal card answer'} aria-pressed={flipped}>
            <span className="preview-card-face preview-card-front"><small>RECALL</small><strong>{card.prompt}</strong><span>Tap to reveal</span></span>
            <span className="preview-card-face preview-card-back">
              <small>{section?.title || 'ANSWER'}</small>
              <strong>{section?.heading || section?.body || card.prompt}</strong>
              {section?.heading && <p>{section.body}</p>}
              <span className="preview-back-hint">Tap to return</span>
            </span>
          </button>
        </div>
        <div className="preview-footer">
          <div className="preview-tabs" role="tablist" aria-label="Card details">
            {card.sections.map((item, index) => <button key={`${card.id}-${item.title}`} type="button" role="tab" aria-selected={sectionIndex === index} className={sectionIndex === index ? 'active' : ''} onClick={() => { setSectionIndex(index); setFlipped(true); }}>{item.title}</button>)}
          </div>
          <div className="preview-controls" aria-label="Card navigation">
            <button type="button" onClick={() => move(-1)} disabled={cardIndex === 0} aria-label="Previous card">←</button>
            <button type="button" onClick={() => move(1)} disabled={cardIndex === deck.cards.length - 1} aria-label="Next card">→</button>
          </div>
        </div>
      </div>
      <aside className="preview-index" aria-label="Cards in this deck">
        <div className="preview-index-label"><span>Card index</span><small>{deck.cards.length} cards</small></div>
        <ol>{deck.cards.map((item, index) => <li key={item.id}><button type="button" className={cardIndex === index ? 'active' : ''} onClick={() => setCardIndex(index)} aria-current={cardIndex === index ? 'true' : undefined}><span>{String(index + 1).padStart(2, '0')}</span><strong>{item.prompt}</strong><small>{item.sections.map((part) => part.title).join(' · ')}</small></button></li>)}</ol>
      </aside>
    </div>
  </section>;
}

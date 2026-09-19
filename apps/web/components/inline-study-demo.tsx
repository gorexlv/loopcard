'use client';

import Link from 'next/link';
import { useState } from 'react';
import { Icon } from './ui-icon';
import { RecallCard, RecallRatings, useCardMotion, type MemoryRating } from './recall-card';

const cards = [
  { front: 'H₂O', back: ['Water', '水'], detail: ['Two hydrogen atoms. One oxygen atom.', '两个氢原子，一个氧原子。'] },
  { front: 'CO₂', back: ['Carbon dioxide', '二氧化碳'], detail: ['One carbon atom. Two oxygen atoms.', '一个碳原子，两个氧原子。'] },
  { front: 'NaCl', back: ['Sodium chloride', '氯化钠'], detail: ['The compound we know as table salt.', '我们熟悉的食盐。'] },
];

export function InlineStudyDemo({ chinese = false }: { chinese?: boolean }) {
  const [index, setIndex] = useState(0);
  const [revealed, setRevealed] = useState(false);
  const [complete, setComplete] = useState(false);
  const [lastRating, setLastRating] = useState<MemoryRating | null>(null);
  const { leaving, advance } = useCardMotion();
  const card = cards[index];
  const rate = (value: MemoryRating) => {
    if (!revealed) return;
    advance(value, () => { setLastRating(value); if (index === cards.length - 1) setComplete(true); else { setIndex(index + 1); setRevealed(false); } });
  };
  const restart = () => { setIndex(0); setRevealed(false); setComplete(false); setLastRating(null); };

  return <div className="pocket-demo">
    <div className="pocket-desk">
      <div className="pocket-peek peek-left" aria-hidden="true"><span>Language</span><strong>serene</strong><small>/səˈriːn/</small></div>
      <div className="pocket-peek peek-right" aria-hidden="true"><span>Ideas</span><strong>Less,<br />but better.</strong><small>LoopCard</small></div>
      <div className="pocket-active">{complete ? <div className="pocket-complete"><Icon name="check" /><h2>{chinese ? '三张，记在心里。' : 'A little more yours.'}</h2><button className="button button-ghost" onClick={restart}><Icon name="repeat" />{chinese ? '再来一轮' : 'One more loop'}</button><Link href="/market">{chinese ? '挑选下一本' : 'Find your next deck'}</Link></div> : <RecallCard key={index} prompt={card.front} heading={card.back[chinese ? 1 : 0]} body={card.detail[chinese ? 1 : 0]} category={chinese ? '化学式' : 'Chemistry'} flipped={revealed} onFlip={() => setRevealed(!revealed)} index={index + 1} leaving={leaving} chinese={chinese} />}</div>
    </div>
    <div className="pocket-toolbar"><span>{chinese ? '化学式入门' : 'A little chemistry'}</span><div className="pocket-dots" aria-label={`${index + 1} / ${cards.length}`}>{cards.map((_, i) => <i key={i} data-current={i === index} data-done={i < index || complete} />)}</div></div>
    <div className="pocket-actions">{!complete && (revealed ? <RecallRatings chinese={chinese} onRate={rate} disabled={Boolean(leaving)} /> : <button className="recall-reveal" onClick={() => setRevealed(true)}><Icon name="flip" />{chinese ? '翻看答案' : 'Turn the card'}</button>)}</div>
    <p className="sr-only" aria-live="polite">{complete ? (chinese ? '本轮完成' : 'Loop complete') : `${index + 1} / ${cards.length}`}{lastRating ? ` · ${lastRating}` : ''}</p>
  </div>;
}

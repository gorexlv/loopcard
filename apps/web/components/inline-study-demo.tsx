'use client';

import Link from 'next/link';
import { getPublicDeck } from '@loopcard/shared';
import { useState } from 'react';
import { Icon } from './ui-icon';
import { RecallCard, RecallRatings, useCardMotion, type MemoryRating } from './recall-card';

const cards = ['arts-37-color-theory', 'everyday-english-core', 'arts-40-photography-basics'].map((slug) => { const deck = getPublicDeck(slug)!; return { ...deck.cards[0], category: deck.category }; });

const chineseCards = [
  { prompt: '蓝与橙，为什么放在一起更醒目？', category: '色彩', heading: '色轮上的对面。', body: '在传统美术色轮上，蓝与橙互为补色。放在一起，彼此的对比更明显。' },
  { prompt: 'borrow 还是 lend？', category: '英语', heading: 'May I borrow your pen?', body: '你向对方借入，用 borrow；对方向你借出，用 lend。同一支笔，两个方向。' },
  { prompt: 'f/2 与 f/8，哪个进光更多？', category: '摄影', heading: 'f/2。', body: '焦距相同时，f 值越小，光圈开口越大。快门速度不变时，进入的光也越多。' },
];

export function InlineStudyDemo({ chinese = false }: { chinese?: boolean }) {
  const [index, setIndex] = useState(0);
  const [revealed, setRevealed] = useState(false);
  const [complete, setComplete] = useState(false);
  const [lastRating, setLastRating] = useState<MemoryRating | null>(null);
  const { leaving, advance } = useCardMotion();
  const card = cards[index];
  const translated = chinese ? chineseCards[index] : null;
  const rate = (value: MemoryRating) => {
    if (!revealed) return;
    advance(value, () => { setLastRating(value); if (index === cards.length - 1) setComplete(true); else { setIndex(index + 1); setRevealed(false); } });
  };
  const restart = () => { setIndex(0); setRevealed(false); setComplete(false); setLastRating(null); };

  return <div className="pocket-demo">
    <div className="pocket-desk">
      <div className="pocket-peek peek-left" aria-hidden="true"><span>Language</span><strong>serene</strong><small>/səˈriːn/</small></div>
      <div className="pocket-peek peek-right" aria-hidden="true"><span>Photography</span><strong>f/2<br />f/8</strong><small>Light &amp; aperture</small></div>
      <div className="pocket-active">{complete ? <div className="pocket-complete"><Icon name="check" /><h2>{chinese ? '完成三张。' : 'Three cards explored.'}</h2><button className="button button-ghost" onClick={restart}><Icon name="repeat" />{chinese ? '再来一轮' : 'One more loop'}</button><Link href="/market">{chinese ? '挑选下一本' : 'Find your next deck'}</Link></div> : <RecallCard key={index} prompt={translated?.prompt ?? card.prompt} visual={card.visual} heading={translated?.heading ?? card.sections[0].heading} body={translated?.body ?? card.sections[0].body} category={translated?.category ?? card.category} flipped={revealed} onFlip={() => setRevealed(!revealed)} index={index + 1} leaving={leaving} chinese={chinese} />}</div>
    </div>
    <div className="pocket-toolbar"><span>{chinese ? '三张精选' : 'Three small discoveries'}</span><div className="pocket-dots" aria-label={`${index + 1} / ${cards.length}`}>{cards.map((_, i) => <i key={i} data-current={i === index} data-done={i < index || complete} />)}</div></div>
    <div className="pocket-actions">{!complete && (revealed ? <RecallRatings chinese={chinese} onRate={rate} disabled={Boolean(leaving)} /> : <button className="recall-reveal" onClick={() => setRevealed(true)}><Icon name="flip" />{chinese ? '翻看答案' : 'Turn the card'}</button>)}</div>
    <p className="sr-only" aria-live="polite">{complete ? (chinese ? '本轮完成' : 'Loop complete') : `${index + 1} / ${cards.length}`}{lastRating ? ` · ${lastRating}` : ''}</p>
  </div>;
}

'use client';

import { useState } from 'react';

const cards = [
  { front: 'H₂O', back: 'Water', detail: 'Two hydrogen atoms bonded to one oxygen atom.' },
  { front: 'CO₂', back: 'Carbon dioxide', detail: 'One carbon atom bonded to two oxygen atoms.' },
  { front: 'NaCl', back: 'Sodium chloride', detail: 'An ionic compound commonly known as table salt.' },
];

export function InlineStudyDemo({ chinese = false }: { chinese?: boolean }) {
  const [index, setIndex] = useState(0);
  const [revealed, setRevealed] = useState(false);
  const [complete, setComplete] = useState(false);
  const card = cards[index];
  const rate = () => {
    if (!revealed) return;
    if (index === cards.length - 1) setComplete(true);
    else { setIndex((value) => value + 1); setRevealed(false); }
  };
  const restart = () => { setIndex(0); setRevealed(false); setComplete(false); };

  return <div className="memory-card-scene inline-study-demo">
    <div className="scene-progress"><span>{chinese ? '化学式入门' : 'Common Chemical Formulas'}</span><span>{Math.min(index + 1, cards.length)} / {cards.length}</span></div>
    {complete ? <div className="inline-demo-complete"><strong>{chinese ? '你完成了一轮。' : 'You completed a loop.'}</strong><p>{chinese ? '真实学习也是这样简单：回忆、翻面、评价。' : 'That is the whole rhythm: recall, reveal, rate.'}</p><button type="button" onClick={restart}>{chinese ? '再试一次' : 'Try again'}</button></div> : <>
      <button className={`scene-card ${revealed ? 'is-revealed' : ''}`} type="button" onClick={() => setRevealed((value) => !value)} aria-label={revealed ? 'Show prompt' : 'Reveal answer'}><small>{revealed ? 'BACK' : 'FRONT'}</small>{revealed ? <><strong>{card.back}</strong><p>{card.detail}</p></> : <><strong>{card.front}</strong><span>{chinese ? '点击翻看答案' : 'Tap to reveal'}</span></>}</button>
      <div className="scene-ratings" aria-label={chinese ? '评价记忆' : 'Rate this memory'}><button type="button" disabled={!revealed} onClick={rate}>{chinese ? '记住了' : 'Remembered'}</button><button type="button" disabled={!revealed} onClick={rate}>{chinese ? '有点模糊' : 'A little fuzzy'}</button><button type="button" disabled={!revealed} onClick={rate}>{chinese ? '没记住' : 'Not yet'}</button></div>
    </>}
  </div>;
}

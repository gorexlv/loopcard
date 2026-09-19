'use client';

import { useEffect, useRef, useState } from 'react';
import { Icon } from './ui-icon';

export type MemoryRating = 'forgot' | 'fuzzy' | 'clear';
export const ratingOrder: MemoryRating[] = ['forgot', 'fuzzy', 'clear'];

/** One motion contract for the demo, study, preview and editor. */
export function useCardMotion() {
  const [leaving, setLeaving] = useState<MemoryRating | null>(null);
  const pending = useRef(false);
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);
  useEffect(() => () => { if (timer.current) clearTimeout(timer.current); }, []);
  function advance(value: MemoryRating, commit: () => void) {
    if (pending.current) return;
    pending.current = true;
    setLeaving(value);
    const duration = matchMedia('(prefers-reduced-motion: reduce)').matches ? 0 : 220;
    timer.current = setTimeout(() => { commit(); setLeaving(null); pending.current = false; }, duration);
  }
  return { leaving, advance };
}

export function RecallCard({ prompt, heading, body, category, answerLabel, flipped, onFlip, index = 1, leaving = null, disabled = false, chinese = false }: {
  prompt: string; heading?: string; body?: string; category: string; answerLabel?: string;
  flipped: boolean; onFlip: () => void; index?: number; leaving?: MemoryRating | null; disabled?: boolean; chinese?: boolean;
}) {
  return <div className="recall-object" data-leaving={leaving ?? undefined}>
    <button className="recall-card" type="button" data-flipped={flipped} aria-pressed={flipped} disabled={disabled || Boolean(leaving)} aria-label={chinese ? (flipped ? '查看正面' : '翻看答案') : (flipped ? 'Show prompt' : 'Reveal answer')} onClick={onFlip}>
      <span className="recall-face recall-front" aria-hidden={flipped}>
        <span className="recall-meta"><span>{category}</span><Icon name="flip" /></span>
        <span className={`recall-word ${prompt.length > 35 ? 'recall-word-long' : ''}`}>{prompt}</span>
        <span className="recall-imprint"><span>LoopCard</span><span>{String(index).padStart(2, '0')}</span></span>
      </span>
      <span className="recall-face recall-back" aria-hidden={!flipped}>
        <span className="recall-meta"><span>{answerLabel || (chinese ? '答案' : 'Answer')}</span><Icon name="flip" /></span>
        <span className="recall-answer">{heading && <strong>{heading}</strong>}{body && <span>{body}</span>}</span>
        <span className="recall-imprint"><span>LoopCard</span><span>{String(index).padStart(2, '0')}</span></span>
      </span>
    </button>
  </div>;
}

export function RecallRatings({ chinese = false, onRate, disabled = false, keyboard = false }: { chinese?: boolean; onRate: (value: MemoryRating) => void; disabled?: boolean; keyboard?: boolean }) {
  const labels = chinese ? ['再想想', '有点模糊', '记住了'] : ['Again', 'Almost', 'Got it'];
  return <div className="recall-ratings" aria-label={chinese ? '评价记忆' : 'Rate this memory'}>{ratingOrder.map((value, index) => <button type="button" key={value} data-rating={value} disabled={disabled} onClick={() => onRate(value)}><Icon name={value === 'clear' ? 'check' : value === 'fuzzy' ? 'minus' : 'repeat'} /><span>{labels[index]}</span>{keyboard && <kbd>{index + 1}</kbd>}</button>)}</div>;
}

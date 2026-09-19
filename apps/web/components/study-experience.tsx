'use client';

import type { PublicDeck } from '@loopcard/shared';
import Link from 'next/link';
import { useCallback, useEffect, useMemo, useState } from 'react';
import { Logo } from './site-header';
import { Icon } from './ui-icon';
import { RecallCard, RecallRatings, useCardMotion } from './recall-card';

type Rating = 'clear' | 'fuzzy' | 'forgot';
type RatedCard = { cardIndex: number; value: Rating };
type StoredSession = { cardIndex: number; ratings: RatedCard[] };

export function StudyExperience({ decks, anonymous = false, returnHref = '/app', saveHref }: { decks: PublicDeck[]; anonymous?: boolean; returnHref?: string; saveHref?: string }) {
  const [deckIndex, setDeckIndex] = useState(0);
  const [cardIndex, setCardIndex] = useState(0);
  const [sectionIndex, setSectionIndex] = useState(0);
  const [flipped, setFlipped] = useState(false);
  const [ratings, setRatings] = useState<RatedCard[]>([]);
  const [restored, setRestored] = useState(false);
  const deck = decks[deckIndex];
  const card = deck?.cards[cardIndex];
  const section = card?.sections[Math.min(sectionIndex, (card?.sections.length ?? 1) - 1)];
  const complete = Boolean(deck && ratings.length >= deck.cards.length);
  const [chinese, setChinese] = useState(false);
  useEffect(() => { setChinese(document.documentElement.dataset.locale === 'zh'); }, []);
  const { leaving, advance } = useCardMotion();
  const labels = chinese
    ? { back: '返回卡包', hint: '先在心里作答，再翻看答案', reveal: '翻看答案', clear: '记住了', fuzzy: '有点模糊', forgot: '没记住', complete: '本轮完成', again: '再来一轮', browse: '发现更多卡包', save: '保存到我的卡包', undo: '撤销上次评分', progress: '本轮进度', keyboard: '快捷键', reviewed: '张卡已复习' }
    : { back: 'Back to decks', hint: 'Recall first, then reveal the answer', reveal: 'Reveal answer', clear: 'Remembered', fuzzy: 'A little fuzzy', forgot: 'Not yet', complete: 'Loop complete', again: 'Review again', browse: 'Browse more decks', save: 'Save to my decks', undo: 'Undo last rating', progress: 'This loop', keyboard: 'Keyboard', reviewed: 'cards reviewed' };
  const storageKey = useMemo(() => deck ? `loopcard-study:${deck.slug}` : '', [deck]);
  const counts = useMemo(() => ratings.reduce((result, item) => ({ ...result, [item.value]: result[item.value] + 1 }), { clear: 0, fuzzy: 0, forgot: 0 }), [ratings]);

  useEffect(() => {
    if (!storageKey || !deck) return;
    try {
      const stored = JSON.parse(localStorage.getItem(storageKey) ?? 'null') as StoredSession | null;
      if (stored && Array.isArray(stored.ratings)) {
        setRatings(stored.ratings.filter((item) => item.cardIndex < deck.cards.length));
        setCardIndex(Math.min(Math.max(0, stored.cardIndex), Math.max(0, deck.cards.length - 1)));
      }
    } catch { localStorage.removeItem(storageKey); }
    setRestored(true);
  }, [deck, storageKey]);

  useEffect(() => {
    if (!restored || !storageKey) return;
    localStorage.setItem(storageKey, JSON.stringify({ cardIndex, ratings } satisfies StoredSession));
  }, [cardIndex, ratings, restored, storageKey]);

  const reveal = useCallback(() => setFlipped(true), []);
  const rate = useCallback((value: Rating) => {
    if (!deck || !flipped || complete || leaving) return;
    advance(value, () => {
    setRatings((items) => [...items, { cardIndex, value }]);
    setSectionIndex(0); setFlipped(false);
    setCardIndex((current) => current + 1 < deck.cards.length ? current + 1 : current);
    });
  }, [cardIndex, complete, deck, flipped, leaving, advance]);
  const undo = useCallback(() => {
    setRatings((items) => {
      const previous = items.at(-1);
      if (!previous) return items;
      setCardIndex(previous.cardIndex); setSectionIndex(0); setFlipped(true);
      return items.slice(0, -1);
    });
  }, []);
  const restart = useCallback(() => { setRatings([]); setCardIndex(0); setSectionIndex(0); setFlipped(false); }, []);

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      const target = event.target as HTMLElement | null;
      if (event.altKey || event.ctrlKey || event.metaKey || target?.closest('input, textarea, select, button, a, summary, [contenteditable]')) return;
      if ((event.key === ' ' || event.key === 'Enter') && !flipped && !complete) { event.preventDefault(); reveal(); }
      if (event.key === '1') rate('forgot');
      if (event.key === '2') rate('fuzzy');
      if (event.key === '3') rate('clear');
      if (event.key.toLowerCase() === 'u') undo();
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [complete, flipped, rate, reveal, undo]);

  function selectDeck(index: number) { setDeckIndex(index); setCardIndex(0); setSectionIndex(0); setFlipped(false); setRatings([]); setRestored(false); }
  if (!deck || !card) return <main className="empty-study"><Logo /><h1>This deck has no cards yet.</h1><Link href={returnHref}>Return to decks</Link></main>;

  return <main className="focus-study">
    <header className="focus-header">
      <Link className="icon-button" href={returnHref} aria-label={labels.back}><Icon name="back" /></Link>
      <div><h1>{deck.title}</h1>{decks.length > 1 && <select aria-label="Choose a deck" value={deckIndex} onChange={(event) => selectDeck(Number(event.target.value))}>{decks.map((item, index) => <option key={item.slug} value={index}>{item.title}</option>)}</select>}</div>
      <span className="focus-count">{complete ? deck.cards.length : cardIndex + 1}<span> / {deck.cards.length}</span></span>
    </header>
    <progress className="focus-progress" value={ratings.length} max={deck.cards.length} aria-label={labels.progress} />
    <section className="focus-stage" aria-label={`Study ${deck.title}`}>
      {complete ? <div className="focus-complete">
        <span className="complete-mark"><Icon name="check" /></span><h2>{labels.complete}</h2>
        <div className="focus-results">{(['clear', 'fuzzy', 'forgot'] as const).map((value) => <div key={value}><b>{counts[value]}</b><span>{labels[value]}</span></div>)}</div>
        <button className="button button-teal" onClick={restart}><Icon name="repeat" />{labels.again}</button>
        <Link className="study-save-link" href={anonymous && saveHref ? saveHref : returnHref}>{anonymous && saveHref ? labels.save : labels.back}</Link>
        <Link className="study-save-link" href="/market">{labels.browse}</Link>
      </div> : <>
        <RecallCard key={`${deck.slug}-${cardIndex}`} prompt={card.prompt} heading={section?.heading} body={section?.body} category={deck.category} answerLabel={section?.title} flipped={flipped} onFlip={() => setFlipped(!flipped)} index={cardIndex + 1} leaving={leaving} chinese={chinese} />
        {flipped && card.sections.length > 1 && <div className="focus-tabs" aria-label="Card back sections">{card.sections.map((item, index) => <button type="button" aria-pressed={index === sectionIndex} key={item.title} onClick={() => setSectionIndex(index)}>{item.title}</button>)}</div>}
        <div className="focus-controls">{!flipped ? <button className="recall-reveal" type="button" onClick={reveal}><Icon name="flip" />{labels.reveal}<kbd>Space</kbd></button> : <RecallRatings chinese={chinese} onRate={rate} disabled={Boolean(leaving)} keyboard />}</div>
      </>}
      <footer className="focus-footer"><button type="button" className="icon-button" onClick={undo} disabled={!ratings.length || Boolean(leaving)} aria-label={labels.undo} title={`${labels.undo} (U)`}><Icon name="undo" /></button>
        <details className="focus-help"><summary aria-label={chinese ? '学习说明' : 'Study help'}><Icon name="help" /></summary><div><p>{labels.hint}</p><p><kbd>Space</kbd> {labels.reveal} · <kbd>U</kbd> {labels.undo}</p>{anonymous && <p>{chinese ? '进度保存在此浏览器。' : 'Progress stays in this browser.'}</p>}</div></details>
      </footer>
    </section>
    <p className="sr-only" aria-live="polite">{complete ? labels.complete : flipped ? `${section?.heading ?? ''} ${section?.body ?? ''}` : `${ratings.length} / ${deck.cards.length}`}</p>
  </main>;
}

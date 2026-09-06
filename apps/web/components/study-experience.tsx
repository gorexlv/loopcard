'use client';

import type { PublicDeck } from '@loopcard/shared';
import Link from 'next/link';
import { useCallback, useEffect, useMemo, useState } from 'react';
import { Logo } from './site-header';

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
  const chinese = /[\u3400-\u9fff]/.test(`${deck?.title ?? ''}${card?.prompt ?? ''}`);
  const labels = chinese
    ? { back: '返回卡包', hint: '先在心里作答，再翻看答案', reveal: '翻看答案', clear: '记住了', clearHelp: '下轮稍后出现', fuzzy: '有点模糊', fuzzyHelp: '下轮较早出现', forgot: '没记住', forgotHelp: '下轮优先出现', complete: '本轮完成', again: '再来一轮', browse: '发现更多卡包', save: '保存到我的卡包', undo: '撤销上次评分', progress: '本轮进度', keyboard: '快捷键', reviewed: '张卡已复习' }
    : { back: 'Back to decks', hint: 'Recall first, then reveal the answer', reveal: 'Reveal answer', clear: 'Remembered', clearHelp: 'Returns later', fuzzy: 'A little fuzzy', fuzzyHelp: 'Returns sooner', forgot: 'Not yet', forgotHelp: 'Returns first', complete: 'Loop complete', again: 'Review again', browse: 'Browse more decks', save: 'Save to my decks', undo: 'Undo last rating', progress: 'This loop', keyboard: 'Keyboard', reviewed: 'cards reviewed' };
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
    if (!deck || !flipped || complete) return;
    setRatings((items) => [...items, { cardIndex, value }]);
    setSectionIndex(0); setFlipped(false);
    setCardIndex((current) => current + 1 < deck.cards.length ? current + 1 : current);
  }, [cardIndex, complete, deck, flipped]);
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
      if (target?.matches('input, textarea, select')) return;
      if ((event.key === ' ' || event.key === 'Enter') && !flipped && !complete) { event.preventDefault(); reveal(); }
      if (event.key === '1') rate('clear');
      if (event.key === '2') rate('fuzzy');
      if (event.key === '3') rate('forgot');
      if (event.key.toLowerCase() === 'u') undo();
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [complete, flipped, rate, reveal, undo]);

  function selectDeck(index: number) { setDeckIndex(index); setCardIndex(0); setSectionIndex(0); setFlipped(false); setRatings([]); setRestored(false); }
  if (!deck || !card) return <main className="empty-study"><Logo /><h1>This deck has no cards yet.</h1><Link href={returnHref}>Return to decks</Link></main>;

  return <main className="app-page study-workspace">
    <aside className="app-sidebar study-context"><Logo /><Link className="study-back-link" href={returnHref}>← {labels.back}</Link><div className="study-deck-summary"><span>{deck.category}</span><h1>{deck.title}</h1><p>{deck.description}</p></div>{decks.length > 1 && <nav aria-label="Choose a deck">{decks.map((item, index) => <button key={item.slug} className={`app-deck-button ${index === deckIndex ? 'active' : ''}`} onClick={() => selectDeck(index)}><strong>{item.title}</strong><small>{item.cards.length} cards</small></button>)}</nav>}{anonymous && <p className="study-local-note">Progress is saved in this browser. Sign in only when you want to keep the deck across devices.</p>}</aside>
    <section className="study-wrap" aria-label={`Study ${deck.title}`}><div className="study-stage"><header className="study-top"><span>{deck.title}</span><span>{complete ? deck.cards.length : Math.min(cardIndex + 1, deck.cards.length)} / {deck.cards.length}</span></header>{complete ? <div className="study-complete"><p>{labels.complete}</p><h2>Memory in motion.</h2><strong>{deck.cards.length}</strong><span>{labels.reviewed}</span><div className="study-complete-breakdown"><span><b>{counts.clear}</b>{labels.clear}</span><span><b>{counts.fuzzy}</b>{labels.fuzzy}</span><span><b>{counts.forgot}</b>{labels.forgot}</span></div><div className="study-complete-actions"><button className="button button-teal" onClick={restart}>{labels.again}</button><Link className="button button-ghost" href="/market">{labels.browse}</Link>{anonymous && saveHref && <Link className="study-save-link" href={saveHref}>{labels.save} →</Link>}</div></div> : <><button className={`study-card ${flipped ? 'is-flipped' : 'is-front'}`} type="button" aria-label={flipped ? 'Show card front' : 'Show card back'} aria-pressed={flipped} onClick={() => setFlipped((value) => !value)}>{!flipped ? <><span className="study-face-label">FRONT</span><span className="study-prompt">{card.prompt}</span><span className="study-hint">{labels.hint}</span></> : <div className="study-back-content"><span className="back-kicker">{section.title}</span><h2>{section.heading}</h2><p>{section.body}</p></div>}</button>{flipped && card.sections.length > 1 && <div className="study-tabs" role="tablist" aria-label="Card back sections">{card.sections.map((item, index) => <button type="button" role="tab" aria-selected={index === sectionIndex} key={item.title} className={index === sectionIndex ? 'active' : ''} onClick={() => setSectionIndex(index)}>{item.title}</button>)}</div>}{!flipped ? <button className="study-reveal" type="button" onClick={reveal}>{labels.reveal}<kbd>Space</kbd></button> : <div className="study-actions" aria-label="Rate this memory"><button style={{ '--action': '#23bfa5' } as React.CSSProperties} onClick={() => rate('clear')}><kbd>1</kbd><strong>{labels.clear}</strong><small>{labels.clearHelp}</small></button><button style={{ '--action': '#f0a212' } as React.CSSProperties} onClick={() => rate('fuzzy')}><kbd>2</kbd><strong>{labels.fuzzy}</strong><small>{labels.fuzzyHelp}</small></button><button style={{ '--action': '#df5366' } as React.CSSProperties} onClick={() => rate('forgot')}><kbd>3</kbd><strong>{labels.forgot}</strong><small>{labels.forgotHelp}</small></button></div>}</>}</div></section>
    <aside className="study-inspector"><h2>{labels.progress}</h2><dl><div><dt>{ratings.length}</dt><dd>Reviewed</dd></div><div><dt>{counts.clear}</dt><dd>{labels.clear}</dd></div><div><dt>{counts.fuzzy + counts.forgot}</dt><dd>Returning soon</dd></div></dl><div className="study-progress-track" aria-label={`${ratings.length} of ${deck.cards.length} reviewed`}><span style={{ width: `${(ratings.length / deck.cards.length) * 100}%` }} /></div><button type="button" className="study-undo" onClick={undo} disabled={!ratings.length}>{labels.undo} <kbd>U</kbd></button><div className="study-shortcuts"><h2>{labels.keyboard}</h2><p><kbd>Space</kbd> Reveal</p><p><kbd>1</kbd><kbd>2</kbd><kbd>3</kbd> Rate</p><p><kbd>U</kbd> Undo</p></div></aside>
    <p className="sr-only" aria-live="polite">{flipped ? `Answer revealed: ${section?.heading}` : `${ratings.length} cards reviewed`}</p>
  </main>;
}

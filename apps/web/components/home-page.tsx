'use client';

import type { PublicDeck } from '@loopcard/shared';
import Link from 'next/link';
import { useEffect, useState } from 'react';
import { homeCopy } from '../lib/home-copy';
import { resolveLocale, resolveTheme, type Locale, type Theme } from '../lib/preferences';
import { DeckTile } from './deck-tile';
import { InlineStudyDemo } from './inline-study-demo';
import { SiteFooter } from './site-footer';
import { SiteHeader } from './site-header';

export function HomePage({ decks }: { decks: PublicDeck[] }) {
  const [locale, setLocale] = useState<Locale>('en');
  const [theme, setTheme] = useState<Theme>('light');
  useEffect(() => { setLocale(resolveLocale(localStorage.getItem('loopcard-locale'))); setTheme(resolveTheme(localStorage.getItem('loopcard-theme'), matchMedia('(prefers-color-scheme: dark)').matches)); }, []);
  useEffect(() => { document.documentElement.dataset.locale = locale; document.documentElement.lang = locale === 'zh' ? 'zh-CN' : 'en'; }, [locale]);
  useEffect(() => { document.documentElement.dataset.theme = theme; }, [theme]);
  const copy = homeCopy[locale];
  const changeLocale = () => { const next = locale === 'en' ? 'zh' : 'en'; localStorage.setItem('loopcard-locale', next); setLocale(next); };
  const changeTheme = () => { const next = theme === 'light' ? 'dark' : 'light'; localStorage.setItem('loopcard-theme', next); setTheme(next); };
  const featured = decks.slice(0, 4);

  const zh = locale === 'zh';
  return <div className="home-shell quiet-home"><SiteHeader copy={copy} locale={locale} theme={theme} onLocale={changeLocale} onTheme={changeTheme} /><main>
    <section className="pocket-home" aria-label={zh ? '试学卡片' : 'Try a card'}>
      <header className="pocket-heading"><h1>{zh ? '每天，留住一点。' : 'A little, every day.'}</h1><p>{zh ? '翻一张卡片，让记忆多停留一会儿。' : 'A card, a quiet moment, something that stays.'}</p></header>
      <InlineStudyDemo chinese={zh} />
      <div className="pocket-links"><Link href="/study/chemistry-formulas">{zh ? '继续学习' : 'Keep studying'} <span aria-hidden="true">↗</span></Link><span aria-hidden="true">·</span><Link href="/app/decks/new">{zh ? '制作我的卡片' : 'Make your own'}</Link></div>
    </section>
    <section className="quiet-collection"><header><h2>{zh ? '你的下一本' : 'Your next little collection'}</h2><Link className="text-link" href="/market">{zh ? '全部卡包' : 'All decks'}</Link></header><div className="curated-grid">{featured.map((deck) => <DeckTile key={deck.slug} deck={deck} chinese={zh} />)}</div></section>
    <section className="quiet-faq"><h2>{zh ? '关于 LoopCard' : 'About LoopCard'}</h2><div>{copy.faqs.map(([question, answer]) => <details key={question}><summary>{question}</summary><p>{answer}</p></details>)}</div></section>
  </main><SiteFooter copy={copy} /></div>;
}

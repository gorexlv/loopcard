'use client';

import type { PublicDeck } from '@loopcard/shared';
import Link from 'next/link';
import { useEffect, useState } from 'react';
import { homeCopy } from '../lib/home-copy';
import { resolveLocale, resolveTheme, type Locale, type Theme } from '../lib/preferences';
import { AnimatedHero } from './animated-hero';
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
  const n = locale === 'zh' ? {
    heroLabel: 'LoopCard · 主动回忆', scroll: '继续了解', why: '为什么是 LoopCard', saving: '保存，不等于记住。', whyBody: '笔记保存信息，记忆却要求你亲自把它找回来。LoopCard 把值得留下的材料，变成一个明确的问题、一个逐层揭示的背面，以及可以重复的复习循环。', sequenceLabel: '02 · 从素材到回忆', sequenceTitle: '一个想法，\n四个动作。', moves: [['01 / 素材','留下重要内容','一句话、一个公式、一张图片、一个名字或问题。'],['02 / 正面','只问一件事','问题保持单一，回忆才足够诚实。'],['03 / 背面','分层揭示','答案优先，语境、例子与来源随后展开。'],['04 / 循环','评价记忆','清晰、模糊或忘记，决定什么内容再次出现。']], stageLabel: '03 · 回忆发生的瞬间', stageTitle: '没有信息流。\n没有干扰。\n只有卡片。', stageBody: '在记忆需要向前一步的时候，界面主动退后一步。', open: '打开卡包练习 →', evidenceLabel: '04 · 适合真实材料', evidenceTitle: '为你真正使用的\n内容制作卡片。', caseBodies: ['含义、例句、语义差别。','名称、结构、使用语境。','定义、辨析、实际应用。'], metricBodies: ['平均一次专注循环','一次只记一个想法','可直接使用的卡包'], curatedLabel: '05 · 从这里开始', curatedTitle: '从市场精选\n一小组卡包。', browse: '浏览全部卡包 →', finalLabel: '下一张卡片，由你决定', finalTitle: '制作真正\n值得记住的内容。', finalBody: '先从一个想法开始，只在必要时丰富卡片背面。', finalAction: '创建卡包'
  } : {
    heroLabel: 'LoopCard · Active recall', scroll: 'Scroll to understand', why: 'Why LoopCard', saving: 'Saving is not\nremembering.', whyBody: 'Notes preserve information. Memory requires you to retrieve it. LoopCard turns material you want to keep into one clear prompt, one revealing back, and a repeatable review loop.', sequenceLabel: '02 · From source to recall', sequenceTitle: 'One thought.\nFour deliberate moves.', moves: [['01 / SOURCE','Capture what matters','A sentence, formula, image, name, or question.'],['02 / FRONT','Ask one clear thing','The prompt stays singular so recall stays honest.'],['03 / BACK','Reveal in layers','Answer first. Context, examples, or sources follow.'],['04 / LOOP','Rate the memory','Clear, fuzzy, or forgotten decides what returns.']], stageLabel: '03 · The moment of recall', stageTitle: 'No feed.\nNo clutter.\nJust the card.', stageBody: 'The interface steps back at the exact moment your memory needs to step forward.', open: 'Open a deck study →', evidenceLabel: '04 · Built for real material', evidenceTitle: 'Cards for the things\nyou actually use.', caseBodies: ['Meaning, example, nuance.','Name, structure, context.','Definition, distinction, application.'], metricBodies: ['Average focused loop','One thought at a time','Ready-made decks'], curatedLabel: '05 · Start somewhere', curatedTitle: 'A small edit\nfrom the Market.', browse: 'Browse all decks →', finalLabel: 'The next card is yours', finalTitle: 'Make something\nworth recalling.', finalBody: 'Start with one idea. Build the back only when it earns its place.', finalAction: 'Create a deck'
  };
  const changeLocale = () => { const next = locale === 'en' ? 'zh' : 'en'; localStorage.setItem('loopcard-locale', next); setLocale(next); };
  const changeTheme = () => { const next = theme === 'light' ? 'dark' : 'light'; localStorage.setItem('loopcard-theme', next); setTheme(next); };
  const featured = decks.slice(0, 4);

  return <div className="home-shell afterimage-home"><div className="hero-header"><SiteHeader copy={copy} locale={locale} theme={theme} onLocale={changeLocale} onTheme={changeTheme} /></div><main>
    <AnimatedHero copy={copy.hero} />
    <section className="editorial-statement" id="why"><header><span>01</span><span>{n.why}</span></header><div><h2>{n.saving.split('\n').map((line,index)=><span key={line}>{index>0&&<br/>}{line}</span>)}</h2><p>{n.whyBody}</p></div></section>
    <section className="source-sequence" aria-labelledby="sequence-title"><header><span className="chapter-label">{n.sequenceLabel}</span><h2 id="sequence-title">{n.sequenceTitle.split('\n').map((line,index)=><span key={line}>{index>0&&<br/>}{line}</span>)}</h2></header><ol>{n.moves.map(([label,title,body])=><li key={label}><small>{label}</small><strong>{title}</strong><p>{body}</p></li>)}</ol></section>
    <section className="memory-stage"><div className="memory-stage-copy"><span className="chapter-label">{n.stageLabel}</span><h2>{n.stageTitle.split('\n').map((line,index)=><span key={line}>{index>0&&<br/>}{index===2?<em>{line}</em>:line}</span>)}</h2><p>{n.stageBody}</p><Link className="underlined-link" href="/study/chemistry-formulas">{n.open}</Link></div><InlineStudyDemo chinese={locale === 'zh'} /></section>
    <section className="evidence-section"><div className="evidence-lead"><span className="chapter-label">{n.evidenceLabel}</span><h2>{n.evidenceTitle.split('\n').map((line,index)=><span key={line}>{index>0&&<br/>}{line}</span>)}</h2></div><div className="evidence-cases"><article><span>Language</span><strong>“retain”</strong><p>{n.caseBodies[0]}</p></article><article><span>Science</span><strong>H₂O</strong><p>{n.caseBodies[1]}</p></article><article><span>Work</span><strong>Opportunity cost</strong><p>{n.caseBodies[2]}</p></article></div><div className="evidence-metrics"><dl><div><dt>3 min</dt><dd>{n.metricBodies[0]}</dd></div><div><dt>1 card</dt><dd>{n.metricBodies[1]}</dd></div><div><dt>52+</dt><dd>{n.metricBodies[2]}</dd></div></dl></div></section>
    <section className="curated-section"><header><span className="chapter-label">{n.curatedLabel}</span><h2>{n.curatedTitle.split('\n').map((line,index)=><span key={line}>{index>0&&<br/>}{line}</span>)}</h2><Link className="underlined-link" href="/market">{n.browse}</Link></header><div className="curated-grid">{featured.map((deck) => <DeckTile key={deck.slug} deck={deck} />)}</div></section>
    <section className="final-invitation"><span className="chapter-label">{n.finalLabel}</span><h2>{n.finalTitle.split('\n').map((line,index)=><span key={line}>{index>0&&<br/>}{line}</span>)}</h2><p>{n.finalBody}</p><Link className="afterimage-primary" href="/app">{n.finalAction} <span aria-hidden="true">→</span></Link></section>
  </main><SiteFooter copy={copy} /></div>;
}

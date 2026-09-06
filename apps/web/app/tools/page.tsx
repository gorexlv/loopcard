import type { Metadata } from 'next';
import Link from 'next/link';
import { CardTool } from '../../components/card-tool';
import { SiteFooter } from '../../components/site-footer';
import { SiteHeader } from '../../components/site-header';
import { pageMetadata } from '../../lib/seo';
export const metadata: Metadata = pageMetadata({ title: 'Free Flashcard Maker from Notes', description: 'Turn pasted notes and lists into a clean flashcard outline in your browser. Use the free LoopCard tool instantly—no account, upload, or installation required.', path: '/tools' });

const templates = [
  ['Vocabulary', 'Word → meaning', 'borrow', 'take and use temporarily'],
  ['Concept', 'Idea → explanation', 'Opportunity cost', 'The value of the next-best option'],
  ['Formula', 'Name → notation', 'Water', 'H₂O'],
  ['Timeline', 'Event → date', 'First moon landing', '1969'],
  ['Person', 'Name → contribution', 'Ada Lovelace', 'Early computing pioneer'],
  ['Question', 'Prompt → answer', 'Why does recall work?', 'It strengthens retrieval paths'],
] as const;

const features = [
  ['01', 'Private by default', 'Your draft stays in this browser.'],
  ['02', 'Instant outline', 'Every clean line becomes one card.'],
  ['03', 'Tidy before import', 'Dedupe, reorder, and copy in one tap.'],
  ['04', 'Any subject', 'Words, formulas, people, places, ideas.'],
] as const;

export default function ToolsPage() {
  return <><SiteHeader /><main>
    <section className="page-hero compact-hero tools-hero"><div><span className="eyebrow">Free tool · No account required</span><h1>Notes in.<br /><em>Cards out.</em></h1></div><p>One idea per line. A focused deck in seconds.</p></section>
    <section className="tool-stage"><CardTool /></section>
    <section className="section tool-feature-strip" aria-label="Tool benefits">{features.map(([number, title, copy]) => <article key={number}><span>{number}</span><strong>{title}</strong><p>{copy}</p></article>)}</section>
    <section className="section template-gallery"><header><div><span className="eyebrow">Six useful shapes</span><h2>Start with a card pattern.</h2></div><p>Choose the relationship you want to remember. Keep the front singular and put context on the back.</p></header><div className="template-grid">{templates.map(([type, pattern, front, back]) => <article key={type} className="template-card"><div className="template-card-head"><span>{type}</span><small>{pattern}</small></div><div className="template-faces"><div><small>FRONT</small><strong>{front}</strong></div><div><small>BACK</small><strong>{back}</strong></div></div></article>)}</div></section>
    <section className="section tool-flow"><div className="tool-flow-title"><span className="eyebrow">A three-minute workflow</span><h2>Capture.<br />Shape.<br /><em>Remember.</em></h2></div><ol><li><span>01</span><div><strong>Paste the raw material</strong><p>Notes, terms, questions, or any list with one thought per line.</p></div></li><li><span>02</span><div><strong>Scan the outline</strong><p>Split overloaded prompts and remove anything you do not need.</p></div></li><li><span>03</span><div><strong>Build the backs</strong><p>Add one answer first, then optional context, examples, or distinctions.</p></div></li><li><span>04</span><div><strong>Run the first loop</strong><p>Recall before revealing. Rate honestly. Repeat only what needs attention.</p></div></li></ol></section>
    <section className="section tool-cta"><span className="eyebrow">Ready when you are</span><h2>Turn today’s notes into tomorrow’s memory.</h2><div><Link className="button button-teal" href="/login?next=/app/decks/new">Create a full deck →</Link><Link className="button button-ghost" href="/market">Browse 50+ decks</Link></div></section>
  </main><SiteFooter /></>;
}

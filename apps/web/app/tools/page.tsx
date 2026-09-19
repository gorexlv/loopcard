import type { Metadata } from 'next';
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

export default function ToolsPage() {
  return <><SiteHeader /><main>
    <section className="page-hero compact-hero tools-hero"><div><h1>Notes in.<br /><em>Cards out.</em></h1></div><p>One idea per line. A focused deck in seconds.</p></section>
    <section className="tool-stage"><CardTool /></section>
    <details className="tool-guide"><summary>Card patterns</summary>
    <section className="section template-gallery"><header><div><h2>Start with a card pattern.</h2></div><p>Choose the relationship you want to remember. Keep the front singular and put context on the back.</p></header><div className="template-grid">{templates.map(([type, pattern, front, back]) => <article key={type} className="template-card"><div className="template-card-head"><span>{type}</span><small>{pattern}</small></div><div className="template-faces"><div><small>FRONT</small><strong>{front}</strong></div><div><small>BACK</small><strong>{back}</strong></div></div></article>)}</div></section>
    </details>
  </main><SiteFooter /></>;
}

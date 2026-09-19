import type { Metadata } from 'next';
import { JournalExample, JournalFigure } from '../../components/journal-example';
import Link from 'next/link';
import { SiteFooter } from '../../components/site-footer';
import { SiteHeader } from '../../components/site-header';
import { articles } from '../../lib/articles';
import { pageMetadata } from '../../lib/seo';
export const metadata: Metadata = pageMetadata({ title: 'Active Recall and Flashcard Guides', description: 'Practical, evidence-informed guides to active recall, better flashcard design, memory practice, and sustainable review habits from the LoopCard team.', path: '/blog' });
export default function BlogPage() {
  return <><SiteHeader /><main className="journal-page">
    <section className="journal-hero"><div className="journal-hero-copy"><h1>A word you know.<br /><em>Can you use it?</em></h1><p>Fill the blank. Turn the card.</p></div><JournalExample /></section>
    <section className="section journal-grid">{articles.map((article, index) => <Link key={article.slug} href={`/blog/${article.slug}`} className={`journal-story ${article.featured ? 'featured' : ''}`}><div className="journal-story-image"><JournalFigure kind={index} /></div><div className="journal-story-copy"><small><time dateTime={article.isoDate}>{article.date}</time></small><h2>{article.title}</h2><p>{article.excerpt}</p><span className="journal-read">Read →</span></div></Link>)}</section>
    <section className="journal-cta"><div><span className="eyebrow">Put the ideas to work</span><h2>Make a card.<br />Run a loop.</h2></div><div><Link className="button button-teal" href="/tools">Open card tools →</Link><Link className="text-link" href="/market">Explore the market</Link></div></section>
  </main><SiteFooter /></>;
}

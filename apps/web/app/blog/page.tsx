import type { Metadata } from 'next';
import Image from 'next/image';
import Link from 'next/link';
import { SiteFooter } from '../../components/site-footer';
import { SiteHeader } from '../../components/site-header';
import { articles } from '../../lib/articles';
import { pageMetadata } from '../../lib/seo';
export const metadata: Metadata = pageMetadata({ title: 'Active Recall and Flashcard Guides', description: 'Practical, evidence-informed guides to active recall, better flashcard design, memory practice, and sustainable review habits from the LoopCard team.', path: '/blog' });
export default function BlogPage() {
  return <><SiteHeader /><main className="journal-page">
    <section className="journal-hero"><div className="journal-hero-copy"><span className="eyebrow">LoopCard Journal · Issue 01</span><h1>Ideas worth<br /><em>keeping.</em></h1><p>Short notes on memory, attention, and making better cards.</p><div className="journal-topics"><span>Recall</span><span>Card craft</span><span>Practice</span></div></div><div className="journal-hero-image"><Image src="/images/journal/cards-loop-still-life.webp" alt="Blank memory cards arranged in a loop on textured paper" fill sizes="(max-width: 800px) 100vw, 52vw" loading="eager" preload /></div></section>
    <section className="section journal-grid">{articles.map((article, index) => <Link key={article.slug} href={`/blog/${article.slug}`} className={`journal-story ${article.featured ? 'featured' : ''}`}><div className="journal-story-image"><Image src={index % 2 === 0 ? '/images/journal/notebook-card-study.webp' : '/images/journal/cards-loop-still-life.webp'} alt="" fill sizes={article.featured ? '(max-width: 800px) 100vw, 55vw' : '(max-width: 800px) 100vw, 28vw'} /></div><div className="journal-story-copy"><span className="journal-number">0{index + 1}</span><small><time dateTime={article.isoDate}>{article.date}</time> · {article.read}</small><h2>{article.title}</h2><p>{article.excerpt}</p><span className="journal-read">Read →</span></div></Link>)}</section>
    <section className="section journal-notes"><header><span className="eyebrow">Field notes</span><h2>Three things to try today.</h2></header><div><article><span>01</span><strong>Close the source.</strong><p>Recall first. Check second.</p></article><article><span>02</span><strong>Ask one thing.</strong><p>A clean prompt earns a clean answer.</p></article><article><span>03</span><strong>Stop while fresh.</strong><p>Short loops are easier to return to.</p></article></div></section>
    <section className="journal-cta"><div><span className="eyebrow">Put the ideas to work</span><h2>Make a card.<br />Run a loop.</h2></div><div><Link className="button button-teal" href="/tools">Open card tools →</Link><Link className="text-link" href="/market">Explore the market</Link></div></section>
  </main><SiteFooter /></>;
}

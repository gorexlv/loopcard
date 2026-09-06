import { publicDecks } from '@loopcard/shared';
import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { JsonLd } from '../../../components/json-ld';
import { MarketDeckPreview } from '../../../components/market-deck-preview';
import { SiteFooter } from '../../../components/site-footer';
import { SiteHeader } from '../../../components/site-header';
import { getMarketDeck } from '../../../lib/market';
import { pageMetadata, site } from '../../../lib/seo';
import { createClient } from '../../../lib/supabase/server';
import { addMarketDeck } from '../actions';

export async function generateStaticParams() { return publicDecks.map(({ slug }) => ({ slug })); }
export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const slug = (await params).slug;
  const deck = await getMarketDeck(slug);
  if (!deck) return {};
  return pageMetadata({ title: `${deck.title} Flashcard Deck`, description: `Preview and study ${deck.title}, a free ${deck.category.toLowerCase()} flashcard deck by ${deck.author}. ${deck.description} Review each card with active recall.`, path: `/market/${slug}` });
}

export default async function MarketDetail({ params, searchParams }: { params: Promise<{ slug: string }>; searchParams: Promise<{ embedded?: string; status?: string; error?: string }> }) {
  const slug = (await params).slug;
  const deck = await getMarketDeck(slug);
  if (!deck) notFound();
  const query = await searchParams;
  const embedded = query.embedded === '1';
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  const jsonLd = [{ '@context': 'https://schema.org', '@type': 'LearningResource', name: deck.title, description: deck.description, learningResourceType: 'Flashcard deck', educationalUse: 'Practice', numberOfCredits: deck.cards.length, author: { '@type': 'Organization', name: deck.author }, url: `${site.url}/market/${slug}`, isAccessibleForFree: true }, { '@context': 'https://schema.org', '@type': 'BreadcrumbList', itemListElement: [{ '@type': 'ListItem', position: 1, name: 'Home', item: site.url }, { '@type': 'ListItem', position: 2, name: 'Flashcard decks', item: `${site.url}/market` }, { '@type': 'ListItem', position: 3, name: deck.title, item: `${site.url}/market/${slug}` }] }];
  const marketHref = embedded ? '/market?embedded=1' : '/market';
  const studyHref = `/study/${deck.slug}`;
  const loginHref = `/login?next=${encodeURIComponent(`/market/${deck.slug}`)}`;

  return <div className={embedded ? 'market-shell market-shell-embedded' : 'market-shell'}>
    {!embedded && <SiteHeader />}
    <main className="market-detail">
      <nav className="breadcrumbs" aria-label="Breadcrumb">{!embedded && <><Link href="/">Home</Link><span>／</span></>}<Link href={marketHref}>Flashcard decks</Link><span>／</span><span>{deck.title}</span></nav>
      <header className="deck-detail-hero">
        <div className="deck-detail-title"><span className="eyebrow">{deck.category} · By {deck.author}</span><h1>{deck.title}</h1></div>
        <div className="deck-detail-summary"><p>{deck.description}</p><dl><div><dt>{deck.cards.length}</dt><dd>Cards</dd></div><div><dt>{deck.saves.toLocaleString()}</dt><dd>Saves</dd></div></dl>
          {query.status === 'added' && <div className="form-message" role="status">Added to your decks. You can start now.</div>}
          {query.status === 'already' && <div className="form-message" role="status">Already in your library. Ready when you are.</div>}
          {query.error && <div className="form-message form-error" role="alert">{query.error}</div>}
          {embedded ? <a className="afterimage-primary market-import-button" href={`loopcard://market/import?slug=${encodeURIComponent(deck.slug)}`}>Add to my decks <span>→</span></a> : <div className="market-detail-actions"><Link className="afterimage-primary market-study-button" href={studyHref}>Study now <span>→</span></Link>{user ? <form action={addMarketDeck}><input type="hidden" name="slug" value={deck.slug} /><button className="market-save-button" type="submit">Save to my decks</button></form> : <Link className="market-save-button" href={loginHref}>Sign in to save</Link>}</div>}
        </div>
      </header>
      <MarketDeckPreview deck={deck} />
      {!embedded && <section className="deck-method deck-method-compact"><h2>Recall → reveal → rate.</h2><p>Try the full loop without an account. Save only when the deck earns a place in your library.</p><Link className="text-link" href="/tools">Make cards from your own notes →</Link></section>}
    </main>
    {!embedded && <SiteFooter />}
    <JsonLd data={jsonLd} />
  </div>;
}

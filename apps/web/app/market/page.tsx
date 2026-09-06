import type { Metadata } from 'next';
import { MarketCatalog } from '../../components/market-catalog';
import { SiteFooter } from '../../components/site-footer';
import { SiteHeader } from '../../components/site-header';
import { pageMetadata } from '../../lib/seo';
import { getMarketDecks } from '../../lib/market';
export const metadata: Metadata = pageMetadata({ title: 'Free Flashcard Decks for Every Subject', description: 'Browse free, curated flashcard decks for language, science, culture, and design. Preview every memory card, then start an active-recall review loop.', path: '/market' });
export default async function MarketPage({ searchParams }: { searchParams: Promise<{ embedded?: string }> }) {
  const embedded = (await searchParams).embedded === '1';
  const publicDecks = await getMarketDecks();
  const categories = new Set(publicDecks.map((deck) => deck.category)).size;
  const cards = publicDecks.reduce((total, deck) => total + deck.cards.length, 0);
  return <div className={embedded ? 'market-shell market-shell-embedded' : 'market-shell'}>{!embedded && <SiteHeader />}<main><section className="market-showcase market-index"><div className="market-showcase-copy"><h1>Find a deck.<br /><em>Start recalling.</em></h1><p>Open any card before you commit. Study immediately, then save only what deserves a place in your loop.</p></div><dl className="market-stats" aria-label="Market collection"><div><dt>{publicDecks.length}</dt><dd>Decks</dd></div><div><dt>{cards}</dt><dd>Cards</dd></div><div><dt>{categories}</dt><dd>Subjects</dd></div></dl></section><MarketCatalog decks={publicDecks} embedded={embedded} /></main>{!embedded && <SiteFooter />}</div>;
}

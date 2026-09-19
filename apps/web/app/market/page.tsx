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
  return <div className={embedded ? 'market-shell market-shell-embedded' : 'market-shell'}>{!embedded && <SiteHeader />}<main><MarketCatalog decks={publicDecks} embedded={embedded} /></main>{!embedded && <SiteFooter />}</div>;
}

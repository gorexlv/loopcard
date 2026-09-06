'use client';

import type { PublicDeck } from '@loopcard/shared';
import { useMemo, useState } from 'react';
import { DeckTile } from './deck-tile';

export function MarketCatalog({ decks, embedded = false }: { decks: PublicDeck[]; embedded?: boolean }) {
  const [active, setActive] = useState('All decks');
  const [query, setQuery] = useState('');
  const [sort, setSort] = useState<'popular' | 'newest' | 'az'>('popular');
  const [limit, setLimit] = useState(12);
  const [showAllCategories, setShowAllCategories] = useState(false);
  const categories = useMemo(() => ['All decks', ...new Set(decks.map((deck) => deck.category))], [decks]);
  const featuredCategories = useMemo(() => categories.slice(0, 5), [categories]);
  const moreCategories = useMemo(() => categories.slice(5), [categories]);
  const filtered = useMemo(() => {
    const needle = query.trim().toLowerCase();
    const result = decks.filter((deck) => (active === 'All decks' || deck.category === active) && (!needle || `${deck.title} ${deck.description} ${deck.category}`.toLowerCase().includes(needle)));
    return [...result].sort((a, b) => sort === 'az' ? a.title.localeCompare(b.title) : sort === 'newest' ? b.slug.localeCompare(a.slug) : b.saves - a.saves);
  }, [active, decks, query, sort]);
  const visible = filtered.slice(0, limit);

  function chooseCategory(category: string) {
    setActive(category);
    setLimit(12);
  }

  return <section className="section market-catalog">
    <div className="market-controls">
      <label className="market-search"><span>Search decks</span><input value={query} onChange={(event) => { setQuery(event.target.value); setLimit(12); }} placeholder="Try “design”, “Spanish”, “history”…" /></label>
      <label className="market-sort"><span>Sort</span><select value={sort} onChange={(event) => setSort(event.target.value as typeof sort)}><option value="popular">Most saved</option><option value="newest">Recently added</option><option value="az">A–Z</option></select></label>
    </div>
    <div className="filter-viewport"><div className="filter-row" aria-label="Popular flashcard deck categories">{featuredCategories.map((category) => <button type="button" key={category} className={`filter-chip ${category === active ? 'active' : ''}`} aria-pressed={category === active} onClick={() => chooseCategory(category)}>{category}<small>{category === 'All decks' ? decks.length : decks.filter((deck) => deck.category === category).length}</small></button>)}{moreCategories.length > 0 && <button className="filter-more" type="button" aria-expanded={showAllCategories} onClick={() => setShowAllCategories((value) => !value)}>{showAllCategories ? 'Fewer subjects' : `All subjects +${moreCategories.length}`}</button>}</div>{showAllCategories && <div className="filter-row filter-row-more" aria-label="More flashcard deck categories">{moreCategories.map((category) => <button type="button" key={category} className={`filter-chip ${category === active ? 'active' : ''}`} aria-pressed={category === active} onClick={() => chooseCategory(category)}>{category}<small>{decks.filter((deck) => deck.category === category).length}</small></button>)}</div>}</div>
    <div className="market-results-head" aria-live="polite"><p><strong>{filtered.length}</strong> decks</p><span>{active === 'All decks' ? 'All subjects' : active}{query ? ` · “${query}”` : ''}</span></div>
    {visible.length ? <div className="deck-grid market-deck-grid">{visible.map((deck) => <DeckTile key={deck.slug} deck={deck} embedded={embedded} />)}</div> : <div className="market-empty" role="status"><strong>No decks found</strong><p>Try another keyword or return to all subjects.</p><button type="button" onClick={() => { setQuery(''); chooseCategory('All decks'); }}>Reset filters</button></div>}
    {visible.length < filtered.length && <button className="market-load" type="button" onClick={() => setLimit((value) => value + 12)}>Show 12 more <span>{filtered.length - visible.length} remaining</span></button>}
  </section>;
}

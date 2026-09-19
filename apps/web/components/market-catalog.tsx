'use client';

import { editorialOrder, type PublicDeck } from '@loopcard/shared';
import { useEffect, useMemo, useState } from 'react';
import { DeckTile } from './deck-tile';

export function MarketCatalog({ decks, embedded = false }: { decks: PublicDeck[]; embedded?: boolean }) {
  const [active, setActive] = useState('All');
  const [query, setQuery] = useState('');
  const [sort, setSort] = useState<'selected' | 'az'>('selected');
  const [limit, setLimit] = useState(12);
  const [chinese, setChinese] = useState(false);
  useEffect(() => { setChinese(document.documentElement.dataset.locale === 'zh'); }, []);
  const available = useMemo(() => decks.filter((deck) => deck.editorialStatus !== 'draft'), [decks]);
  const categories = useMemo(() => [...new Set(available.map((deck) => deck.category))], [available]);
  const filtered = useMemo(() => {
    const needle = query.trim().toLowerCase();
    return available.filter((deck) => (active === 'All' || deck.category === active) && (!needle || `${deck.title} ${deck.description} ${deck.category} ${deck.slug}`.toLowerCase().includes(needle))).sort((a, b) => sort === 'az' ? a.title.localeCompare(b.title) : (editorialOrder.indexOf(a.slug) < 0 ? 99 : editorialOrder.indexOf(a.slug)) - (editorialOrder.indexOf(b.slug) < 0 ? 99 : editorialOrder.indexOf(b.slug)));
  }, [active, available, query, sort]);
  return <section className="deck-catalog">
    <header className="catalog-heading"><h1>{chinese ? '发现下一本' : 'Find your next deck.'}</h1><p>{chinese ? '语言、科学与生活里的小知识。' : 'Language, science, and things worth keeping.'}</p></header>
    <div className="catalog-toolbar"><label className="catalog-search"><svg aria-hidden="true" width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><circle cx="10" cy="10" r="6"/><path d="m15 15 5 5"/></svg><input aria-label={chinese ? '搜索卡包' : 'Search decks'} value={query} onChange={(event) => { setQuery(event.target.value); setLimit(12); }} placeholder={chinese ? '搜索卡包' : 'Search decks'} /></label><label className="catalog-category"><span className="sr-only">{chinese ? '分类' : 'Subject'}</span><select value={active} onChange={(event) => { setActive(event.target.value); setLimit(12); }}><option value="All">{chinese ? '全部主题' : 'All subjects'}</option>{categories.map((category) => <option key={category}>{category}</option>)}</select></label><label className="catalog-sort"><span className="sr-only">{chinese ? '排序' : 'Sort'}</span><select value={sort} onChange={(event) => setSort(event.target.value as typeof sort)}><option value="selected">{chinese ? '精选' : 'Selected'}</option><option value="az">A–Z</option></select></label></div>
    <p className="catalog-count" aria-live="polite">{filtered.length} {chinese ? '本卡包' : 'decks'}</p>
    {filtered.length ? <div className="catalog-grid">{filtered.slice(0, limit).map((deck) => <DeckTile key={deck.slug} deck={deck} embedded={embedded} chinese={chinese} />)}</div> : <div className="catalog-empty"><h2>{chinese ? '没有找到卡包' : 'No decks found'}</h2><button className="button button-ghost" onClick={() => { setQuery(''); setActive('All'); }}>{chinese ? '清除筛选' : 'Clear filters'}</button></div>}
    {limit < filtered.length && <button className="catalog-more button button-ghost" onClick={() => setLimit(limit + 12)}>{chinese ? '查看更多' : 'Show more'}</button>}
  </section>;
}

import type { Metadata } from 'next';
import Link from 'next/link';
import { requireUser } from '../../lib/auth';
import { deckFromRow, deckSelection } from '../../lib/decks';

export const metadata: Metadata = { title: 'My decks', robots: { index: false, follow: false } };
export default async function AppPage({ searchParams }: { searchParams: Promise<{ error?: string }> }) {
  const { supabase, user } = await requireUser();
  const [{ data: profile }, { data: ownedRows }, { data: savedRows }] = await Promise.all([
    supabase.from('profiles').select('display_name').eq('id', user.id).maybeSingle(),
    supabase.from('decks').select(deckSelection).eq('user_id', user.id).order('updated_at', { ascending: false }),
    supabase.from('deck_library').select(`added_at,decks(${deckSelection})`).eq('user_id', user.id).order('added_at', { ascending: false }),
  ]);
  const owned = (ownedRows ?? []).map((row) => deckFromRow(row, true));
  const saved = (savedRows ?? []).flatMap((row) => row.decks ? [deckFromRow(row.decks as unknown as Record<string, unknown>, false)] : []);
  const query = await searchParams;
  return <main className="workspace-page"><header className="workspace-header"><div><span className="eyebrow">Welcome, {profile?.display_name || user.email?.split('@')[0]}</span><h1>Your memory index</h1><p>Study what is ready, shape your own cards, and keep useful public decks close.</p></div><Link className="button button-teal" href="/app/decks/new">Create a deck</Link></header>{query.error && <div className="form-message form-error" role="alert">{query.error}</div>}<DeckSection title="Created by you" decks={owned} empty="Your own decks will live here. Start with one clear prompt." /><DeckSection title="Saved for study" decks={saved} empty="Save a public deck when it earns a place in your memory index." market /></main>;
}

function DeckSection({ title, decks, empty, market = false }: { title: string; decks: ReturnType<typeof deckFromRow>[]; empty: string; market?: boolean }) {
  return <section className="library-section"><div className="library-heading"><h2>{title}</h2>{market && <Link href="/market">Browse Market →</Link>}</div>{decks.length ? <div className="library-grid">{decks.map((deck) => <article className="library-card" key={deck.id}><span>{deck.visibility === 'public' ? 'Public' : deck.owned ? 'Private' : 'Saved'}</span><h3>{deck.title}</h3><p>{deck.subtitle || `${deck.cards.length} cards`}</p><div><Link href={`/app/study/${deck.id}`}>Study</Link>{deck.owned && <Link href={`/app/decks/${deck.id}`}>Edit</Link>}</div></article>)}</div> : <div className="empty-state"><p>{empty}</p>{!market && <Link href="/app/decks/new">Create a deck →</Link>}</div>}</section>;
}

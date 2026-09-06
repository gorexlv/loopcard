import type { Metadata } from 'next';
import { DeckEditor } from '../../../../components/deck-editor';
export const metadata: Metadata = { title: 'New deck', robots: { index: false, follow: false } };
export default function NewDeckPage() { return <main className="workspace-page editor-page"><header className="workspace-header"><div><span className="eyebrow">Private by default</span><h1>Create a deck</h1><p>Start with one clear prompt. Add context only when it helps recall.</p></div></header><DeckEditor /></main>; }

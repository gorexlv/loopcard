import type { Metadata } from 'next';
import { DeckEditor } from '../../../../components/deck-editor';
export const metadata: Metadata = { title: 'New deck', robots: { index: false, follow: false } };
export default function NewDeckPage() { return <main className="workspace-page editor-page"><header className="workspace-header"><div><h1>Create a deck</h1></div></header><DeckEditor /></main>; }

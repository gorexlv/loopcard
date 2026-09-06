'use client';

import { useMemo, useState } from 'react';
import { useFormStatus } from 'react-dom';
import { saveDeck } from '../app/app/actions';
import type { WebDeck } from '../lib/decks';
import { parseCardLines } from '../lib/decks';

type DraftCard = { prompt: string; answer: string };

function SaveButton({ canSave }: { canSave: boolean }) {
  const { pending } = useFormStatus();
  return <button className="button button-teal editor-save" type="submit" disabled={pending || !canSave}>{pending ? 'Saving deck…' : 'Save deck'}</button>;
}

export function DeckEditor({ deck }: { deck?: WebDeck }) {
  const [cards, setCards] = useState<DraftCard[]>(deck?.cards.map(({ prompt, answer }) => ({ prompt, answer })) ?? [{ prompt: '', answer: '' }]);
  const [selected, setSelected] = useState(0);
  const [bulk, setBulk] = useState('');
  const active = cards[Math.min(selected, cards.length - 1)];
  const validCount = useMemo(() => cards.filter((card) => card.prompt.trim()).length, [cards]);

  function updateCard(index: number, field: keyof DraftCard, value: string) {
    setCards((items) => items.map((item, itemIndex) => itemIndex === index ? { ...item, [field]: value } : item));
  }
  function addCard() { setCards((items) => [...items, { prompt: '', answer: '' }]); setSelected(cards.length); }
  function removeCard(index: number) {
    setCards((items) => items.length === 1 ? [{ prompt: '', answer: '' }] : items.filter((_, itemIndex) => itemIndex !== index));
    setSelected((value) => Math.max(0, Math.min(value, cards.length - 2)));
  }
  function moveCard(index: number, amount: -1 | 1) {
    const target = index + amount;
    if (target < 0 || target >= cards.length) return;
    setCards((items) => { const next = [...items]; [next[index], next[target]] = [next[target], next[index]]; return next; });
    setSelected(target);
  }
  function importBulk() {
    const parsed = parseCardLines(bulk);
    if (!parsed.length) return;
    const current = cards.filter((card) => card.prompt.trim() || card.answer.trim());
    setCards([...current, ...parsed]);
    setSelected(current.length);
    setBulk('');
  }

  return <form action={saveDeck} className="deck-editor visual-deck-editor">
    <input type="hidden" name="deckId" value={deck?.id ?? ''} />
    <input type="hidden" name="cardsJson" value={JSON.stringify(cards)} />
    <section className="deck-basics" aria-labelledby="deck-basics-title"><h2 id="deck-basics-title">Deck details</h2><div className="editor-fields"><label>Title<input name="title" required maxLength={120} defaultValue={deck?.title ?? ''} placeholder="Everyday phrases" /></label><label>Subtitle<input name="subtitle" maxLength={240} defaultValue={deck?.subtitle ?? ''} placeholder="What will this deck help you remember?" /></label><div className="form-row"><label>Card type<select name="kind" defaultValue={deck?.kind ?? 'generic'}><option value="generic">General</option><option value="word">Words</option><option value="formula">Formulas</option><option value="idiom">Idioms</option><option value="concept">Concepts</option><option value="equation">Equations</option></select></label><label>Who can see it?<select name="visibility" defaultValue={deck?.visibility ?? 'private'}><option value="private">Only me</option><option value="public">Everyone</option></select></label></div></div></section>

    <section className="card-builder" aria-labelledby="card-builder-title"><header><div><h2 id="card-builder-title">Cards</h2><p>{validCount} ready · add one clear thought at a time</p></div><button type="button" className="editor-add" onClick={addCard}>＋ Add card</button></header><div className="card-builder-layout"><ol className="editor-card-list">{cards.map((card, index) => <li key={index} className={selected === index ? 'active' : ''}><button type="button" className="editor-card-select" onClick={() => setSelected(index)}><span>{String(index + 1).padStart(2, '0')}</span><strong>{card.prompt.trim() || 'Untitled card'}</strong><small>{card.answer.trim() ? 'Front and back ready' : 'Add an answer'}</small></button><div className="editor-row-actions"><button type="button" onClick={() => moveCard(index, -1)} disabled={index === 0} aria-label={`Move card ${index + 1} up`}>↑</button><button type="button" onClick={() => moveCard(index, 1)} disabled={index === cards.length - 1} aria-label={`Move card ${index + 1} down`}>↓</button><button type="button" onClick={() => removeCard(index)} aria-label={`Remove card ${index + 1}`}>Remove</button></div></li>)}</ol><div className="card-edit-stage"><div className="card-edit-fields"><label>Front<textarea value={active.prompt} maxLength={1000} rows={4} onChange={(event) => updateCard(selected, 'prompt', event.target.value)} placeholder="Ask one clear question" /></label><label>Back<textarea value={active.answer} maxLength={10000} rows={7} onChange={(event) => updateCard(selected, 'answer', event.target.value)} placeholder="Give the shortest useful answer" /></label></div><div className="editor-preview" aria-label="Live card preview"><span>PREVIEW · {String(selected + 1).padStart(2, '0')}</span><strong>{active.prompt.trim() || 'Your prompt appears here'}</strong><p>{active.answer.trim() || 'The answer appears on the back.'}</p></div></div></div></section>

    <details className="bulk-entry"><summary>Paste many cards</summary><div><p>Optional power tool: put one card on each line and separate front from back with <code>::</code>. Review the parsed cards above before saving.</p><textarea value={bulk} rows={7} onChange={(event) => setBulk(event.target.value)} placeholder={'borrow :: take and use temporarily\nserene :: calm and peaceful'} /><button type="button" onClick={importBulk} disabled={!bulk.trim()}>Add parsed cards</button></div></details>
    <footer className="editor-footer"><p>{validCount ? `${validCount} card${validCount === 1 ? '' : 's'} will be saved.` : 'Add a front before saving.'}</p><SaveButton canSave={validCount > 0} /></footer>
  </form>;
}

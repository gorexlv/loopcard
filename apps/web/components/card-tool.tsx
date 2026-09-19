'use client';
import Link from 'next/link';
import { useMemo, useState } from 'react';

const sample = 'Photosynthesis converts light energy into chemical energy.\nMitochondria produce most cellular ATP.\nDNA stores hereditary information.';

export function CardTool() {
  const [value, setValue] = useState(sample);
  const [message, setMessage] = useState('');
  const cards = useMemo(() => value.split(/\n+/).map((line) => line.trim()).filter(Boolean).slice(0, 12), [value]);

  async function copyOutline() {
    try {
      await navigator.clipboard.writeText(cards.map((card, index) => `${index + 1}. ${card}`).join('\n'));
      setMessage('Outline copied');
    } catch {
      setMessage('Copy unavailable in this browser');
    }
    window.setTimeout(() => setMessage(''), 1800);
  }

  function removeDuplicates() {
    setValue([...new Set(value.split(/\n+/).map((line) => line.trim()).filter(Boolean))].join('\n'));
    setMessage('Duplicates removed');
  }

  function reverseOrder() {
    setValue(value.split(/\n+/).filter(Boolean).reverse().join('\n'));
    setMessage('Order reversed');
  }

  return <div className="tool-workbench">
    <div className="tool-panel"><div className="tool-input"><div className="tool-label-row"><label className="eyebrow" htmlFor="source-notes">Paste one idea per line</label><div><button type="button" onClick={() => setValue(sample)}>Example</button><button type="button" onClick={() => setValue('')}>Clear</button></div></div><textarea id="source-notes" value={value} onChange={(event) => setValue(event.target.value)} placeholder="One fact, term, or question per line…" /><p>{cards.length} cards · Local preview</p></div><div className="tool-output"><div className="tool-output-head"><span className="eyebrow">Card outline</span><strong>{cards.length}</strong></div><div className="tool-card-list">{cards.map((card, index) => <article key={`${card}-${index}`}><span>Card {String(index + 1).padStart(2, '0')}</span><strong>{card}</strong></article>)}</div><Link className={`button button-teal tool-import ${cards.length ? '' : 'disabled'}`} aria-disabled={!cards.length} href={cards.length ? '/login?next=/app/decks/new' : '#'}>Open deck editor →</Link></div></div>
    <div className="tool-utility-bar"><span role="status">{message || 'Quick actions'}</span><div><button type="button" disabled={!cards.length} onClick={removeDuplicates}>Remove duplicates</button><button type="button" disabled={!cards.length} onClick={reverseOrder}>Reverse order</button><button type="button" disabled={!cards.length} onClick={copyOutline}>Copy outline</button></div></div>
  </div>;
}

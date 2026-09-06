'use client';

import { useState } from 'react';
import { deleteDeck } from '../app/app/actions';

export function DeleteDeckForm({ deckId }: { deckId: string }) {
  const [confirming, setConfirming] = useState(false);
  return <form action={deleteDeck} className="danger-zone"><input type="hidden" name="deckId" value={deckId} /><div><strong>Delete this deck</strong><p>{confirming ? 'This permanently removes its cards and review history. This cannot be undone.' : 'Your deck stays safe until you confirm.'}</p></div>{confirming ? <div className="danger-actions"><button type="button" onClick={() => setConfirming(false)}>Cancel</button><button className="danger-confirm" type="submit">Delete permanently</button></div> : <button type="button" onClick={() => setConfirming(true)}>Delete…</button>}</form>;
}

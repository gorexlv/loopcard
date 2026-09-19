'use client';

import { useState } from 'react';
import { getPublicDeck } from '@loopcard/shared';
import { RecallCard } from './recall-card';

export function JournalExample() {
  const [flipped, setFlipped] = useState(false);
  const card = getPublicDeck('everyday-english-core')!.cards[0];
  return <div className="journal-example"><RecallCard prompt={card.prompt} visual={card.visual} heading={card.sections[0].heading} body={card.sections[0].body} category="In conversation" flipped={flipped} onFlip={() => setFlipped(!flipped)} /></div>;
}

export function JournalFigure({ kind }: { kind: number }) {
  return <div className={`journal-figure journal-figure-${kind}`}>
    {kind === 0 ? <><small>Without looking it up</small><strong>May I <span>_____</span><br />your pen?</strong><span>borrow / lend</span></> : kind === 1 ? <><small>A smaller question</small><del>Explain plants.</del><strong>What do roots<br />absorb?</strong></> : kind === 2 ? <><small>A loop you can finish</small><div className="figure-loop"><span>Try</span><i>→</i><span>Check</span><i>→</i><span>Return</span></div><strong>One card today.<br />A way back tomorrow.</strong></> : <><small>Answer first</small><strong>borrow</strong><span>You borrow from me.<br />I lend to you.</span><hr /><small>Same pen. Opposite directions.</small></>}
  </div>;
}

import type { MemoryCard } from '@loopcard/shared';

/** Content diagrams: the visual supplies evidence for the question. */
export function CardVisual({ kind }: { kind: MemoryCard['visual'] }) {
  if (!kind) return null;
  if (kind === 'color') return <span className="card-visual visual-color" role="img" aria-label="Blue and orange, a complementary color pair"><i /><i /></span>;
  if (kind === 'type') return <span className="card-visual visual-type" role="img" aria-label="Lowercase a in two typefaces at the same font size"><img src="/fonts/type-specimen.svg" alt="" width="230" height="130" /></span>;
  if (kind === 'dialogue') return <span className="card-visual visual-dialogue"><span>May I</span><span className="dialogue-gap">_____</span><span>your pen?</span></span>;
  if (kind === 'cafe') return <span className="card-visual visual-cafe" role="img" aria-label="A cup of coffee"><svg viewBox="0 0 160 110" fill="none"><path d="M39 37h67v25a30 30 0 0 1-30 30h-7a30 30 0 0 1-30-30V37Z" fill="currentColor" opacity=".12"/><path d="M39 37h67v25a30 30 0 0 1-30 30h-7a30 30 0 0 1-30-30V37Zm67 6h7a15 15 0 0 1 0 30h-9M27 98h99M64 22V9M83 22V9" stroke="currentColor" strokeWidth="2"/></svg></span>;
  if (kind === 'hierarchy') return <span className="card-visual visual-hierarchy" role="img" aria-label="A large bold heading above two small lines of text"><b>Aa</b><i /><i /></span>;
  return <span className="card-visual visual-aperture" role="img" aria-label="Two equal lenses: f/2 has a wide opening, f/8 a small opening"><span><i className="aperture-wide"/><small>f/2</small></span><span><i className="aperture-small"/><small>f/8</small></span></span>;
}

export function visualQuestion(prompt: string, kind: MemoryCard['visual']) {
  if (/[\u3400-\u9fff]/.test(prompt)) return prompt;
  if (kind === 'dialogue') return 'borrow or lend?';
  if (kind === 'aperture') return 'Which lets in more light?';
  if (kind === 'color') return 'Why do these colors stand out together?';
  if (kind === 'hierarchy') return 'Where did your eye go first?';
  return prompt;
}

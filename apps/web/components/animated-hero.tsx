'use client';

import Link from 'next/link';
import { useState } from 'react';
import type { HomeCopy } from '../lib/home-copy';

export function AnimatedHero({ copy }: { copy: HomeCopy['hero'] }) {
  const [ready, setReady] = useState(false);
  return <section className="afterimage-hero">
    <div className="afterimage-media" aria-hidden="true">
      <picture><source media="(max-width: 700px)" srcSet="/media/afterimage-hero-mobile.webp" /><img src="/media/afterimage-hero-poster.webp" alt="" fetchPriority="high" /></picture>
      <video className={ready ? 'is-ready' : ''} autoPlay muted loop playsInline preload="metadata" poster="/media/afterimage-hero-poster.webp" onLoadedData={() => setReady(true)}>
        <source src="/media/afterimage-loop.webm" type="video/webm" /><source src="/media/afterimage-loop.mp4" type="video/mp4" />
      </video>
    </div>
    <div className="afterimage-shade" aria-hidden="true" />
    <div className="hero-card-copy" aria-hidden="true">
      <div className="hero-card-side hero-card-front-copy"><small>07 · FRONT</small><strong>Möbius</strong><span>What has only one side?</span></div>
      <div className="hero-card-side hero-card-back-copy"><small>07 · BACK</small><strong>One surface.</strong><span>A continuous loop without an edge.</span></div>
    </div>
    <div className="afterimage-copy">
      <span className="chapter-label">{copy.eyebrow}</span>
      <h1><span>What you recall</span><span>becomes <em>yours.</em></span></h1>
      <p>{copy.body}</p>
      <div className="afterimage-actions"><Link className="afterimage-primary" href="/study/everyday-english-core">{copy.primary}<span aria-hidden="true">→</span></Link><Link className="afterimage-secondary" href="/app/decks/new">Create a deck</Link></div>
    </div>
    <a className="afterimage-scroll" href="#why"><span>Scroll to understand</span><i aria-hidden="true" /></a>
  </section>;
}

'use client';

export default function AppError({ reset }: { error: Error & { digest?: string }; reset: () => void }) {
  return <main className="workspace-page"><section className="workspace-error" role="alert"><span className="eyebrow">The loop paused</span><h1>We couldn’t load your library.</h1><p>Your decks are safe. Check the connection and try this view again.</p><button className="button button-teal" type="button" onClick={reset}>Try again</button></section></main>;
}

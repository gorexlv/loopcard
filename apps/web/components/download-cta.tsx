import Link from 'next/link';
import { codexPlugin, mobileDownloads } from '../lib/downloads';
import type { HomeCopy } from '../lib/home-copy';

function AppleMark() {
  return <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M16.7 12.8c0-2.3 1.9-3.4 2-3.5a4.4 4.4 0 0 0-3.5-1.9c-1.5-.1-2.9.9-3.6.9-.8 0-1.9-.9-3.1-.8a4.6 4.6 0 0 0-3.9 2.4c-1.7 2.9-.4 7.2 1.2 9.5.8 1.1 1.7 2.4 3 2.3 1.2 0 1.7-.7 3.2-.7 1.4 0 1.9.7 3.1.7 1.3 0 2.1-1.1 2.9-2.3.9-1.3 1.3-2.7 1.3-2.8-.1 0-2.6-1-2.6-3.8ZM14.2 5.9a4.2 4.2 0 0 0 1-3 4.3 4.3 0 0 0-2.8 1.5 4 4 0 0 0-1 2.9 3.6 3.6 0 0 0 2.8-1.4Z" /></svg>;
}

function AndroidMark() {
  return <svg viewBox="0 0 24 24" aria-hidden="true"><path d="m7.2 6.6-1.4-2.4.8-.5L8 6.2a9.8 9.8 0 0 1 8 0l1.4-2.5.8.5-1.4 2.4A7.2 7.2 0 0 1 20 12H4a7.2 7.2 0 0 1 3.2-5.4ZM8.1 9.8a1 1 0 1 0 0-2 1 1 0 0 0 0 2Zm7.8 0a1 1 0 1 0 0-2 1 1 0 0 0 0 2ZM4 13h16v6.5a2 2 0 0 1-2 2h-1V24h-2v-2.5H9V24H7v-2.5H6a2 2 0 0 1-2-2V13Z" /></svg>;
}

function CodexMark() {
  return <span className="codex-mark" aria-hidden="true">{Array.from({ length: 6 }, (_, index) => <i key={index} />)}</span>;
}

export function DownloadCta({ copy }: { copy: HomeCopy['download'] }) {
  return (
    <section className="download-cta" id="get-loopcard" aria-labelledby="get-loopcard-title">
      <header className="download-intro">
        <span className="eyebrow">{copy.eyebrow}</span>
        <h2 id="get-loopcard-title">{copy.title.split('\n').map((line, index) => <span key={line}>{index > 0 && <br />}{line}</span>)}</h2>
        <p>{copy.intro}</p>
      </header>

      <div className="download-options">
        <article className="download-panel mobile-panel">
          <div className="download-panel-head">
            <span className="panel-number">01</span>
            <div><small>{copy.mobileLabel}</small><h3>{copy.mobileTitle}</h3></div>
          </div>
          <p>{copy.mobileBody}</p>
          <div className="platform-list">
            {mobileDownloads.map((item) => (
              <Link className="platform-link" href={item.href} key={item.platform} aria-label={`${item.platform}, ${copy.coming}`}>
                <span className="platform-icon">{item.platform === 'iOS' ? <AppleMark /> : <AndroidMark />}</span>
                <span><strong>{item.platform}</strong><small>{item.detail}</small></span>
                <em>{copy.coming}</em>
              </Link>
            ))}
          </div>
        </article>

        <article className="download-panel plugin-panel">
          <div className="plugin-orbit"><CodexMark /></div>
          <div className="download-panel-head">
            <span className="panel-number">02</span>
            <div><small>{copy.pluginLabel}</small><h3>{copy.pluginTitle}</h3></div>
          </div>
          <p>{copy.pluginBody}</p>
          <a className="plugin-link" href={codexPlugin.href} target="_blank" rel="noreferrer">
            <span><small>{copy.available}</small><strong>{copy.marketplace}</strong></span>
            <b aria-hidden="true">↗</b>
          </a>
        </article>
      </div>
    </section>
  );
}

import Link from 'next/link';
import type { HomeCopy } from '../lib/home-copy';
import type { Locale, Theme } from '../lib/preferences';
import { AccountLink } from './account-link';

export function Logo({ homeLabel = 'LoopCard home' }: { homeLabel?: string }) {
  return <Link className="logo" href="/" aria-label={homeLabel}><img className="logo-mark" src="/brand/loopcard-logo-96.webp" alt="" width="35" height="35" /><span className="logo-wordmark" aria-hidden="true"><span>Loop</span><strong>Card</strong></span></Link>;
}

export function SiteHeader({ copy, locale, theme, onLocale, onTheme }: { copy?: HomeCopy; locale?: Locale; theme?: Theme; onLocale?: () => void; onTheme?: () => void }) {
  const nav = copy?.nav ?? ['Market', 'Tools', 'Journal'];
  return (
    <header className="site-header">
      <Logo homeLabel={copy?.home} />
      <nav aria-label={copy?.primaryNav ?? 'Primary navigation'}>
        <Link href="/market">{nav[0]}</Link><Link href="/tools">{nav[1]}</Link><Link href="/blog">{nav[2]}</Link>
      </nav>
      <div className="header-actions">
        {copy && locale && theme && <div className="preference-controls">
          <button className="language-toggle" type="button" onClick={onLocale} aria-label={copy.language}>{locale === 'en' ? '中文' : 'EN'}</button>
          <button className="theme-toggle" type="button" onClick={onTheme} aria-label={theme === 'dark' ? copy.themeLight : copy.themeDark}><span aria-hidden="true">{theme === 'dark' ? '☀' : '◐'}</span></button>
        </div>}
        <AccountLink />
        <details className="mobile-menu"><summary>{locale === 'zh' ? '菜单' : 'Menu'}</summary><nav aria-label={copy?.primaryNav ?? 'Mobile navigation'}><Link href="/market">{nav[0]}</Link><Link href="/tools">{nav[1]}</Link><Link href="/blog">{nav[2]}</Link><AccountLink compact /></nav></details>
      </div>
    </header>
  );
}

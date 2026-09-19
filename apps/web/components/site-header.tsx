'use client';

import { useEffect, useState } from 'react';
import { homeCopy } from '../lib/home-copy';
import Link from 'next/link';
import type { HomeCopy } from '../lib/home-copy';
import type { Locale, Theme } from '../lib/preferences';
import { AccountLink } from './account-link';

export function Logo({ homeLabel = 'LoopCard home' }: { homeLabel?: string }) {
  return <Link className="logo" href="/" aria-label={homeLabel}><img className="logo-mark" src="/brand/loopcard-logo-96.webp" alt="" width="35" height="35" /><span className="logo-wordmark" aria-hidden="true"><span>Loop</span><strong>Card</strong></span></Link>;
}

export function SiteHeader({ copy, locale, theme, onLocale, onTheme }: { copy?: HomeCopy; locale?: Locale; theme?: Theme; onLocale?: () => void; onTheme?: () => void }) {
  const [savedLocale, setSavedLocale] = useState<Locale>('en');
  const [savedTheme, setSavedTheme] = useState<Theme>('light');
  useEffect(() => { setSavedLocale(document.documentElement.dataset.locale === 'zh' ? 'zh' : 'en'); setSavedTheme(document.documentElement.dataset.theme === 'dark' ? 'dark' : 'light'); }, []);
  const currentLocale = locale ?? savedLocale;
  const currentTheme = theme ?? savedTheme;
  const currentCopy = copy ?? homeCopy[currentLocale];
  function toggleLocale() { if (onLocale) return onLocale(); const next = currentLocale === 'en' ? 'zh' : 'en'; localStorage.setItem('loopcard-locale', next); window.location.reload(); }
  function toggleTheme() { if (onTheme) return onTheme(); const next = currentTheme === 'light' ? 'dark' : 'light'; localStorage.setItem('loopcard-theme', next); document.documentElement.dataset.theme = next; setSavedTheme(next); }
  const nav = currentCopy.nav;
  return (
    <header className="site-header">
      <Logo homeLabel={copy?.home} />
      <nav aria-label={copy?.primaryNav ?? 'Primary navigation'}>
        <Link href="/market">{nav[0]}</Link><Link href="/tools">{nav[1]}</Link><Link href="/blog">{nav[2]}</Link>
      </nav>
      <div className="header-actions">
        {<div className="preference-controls">
          <button className="language-toggle" type="button" onClick={toggleLocale} aria-label={currentCopy.language}>{currentLocale === 'en' ? '中文' : 'EN'}</button>
          <button className="theme-toggle" type="button" onClick={toggleTheme} aria-label={currentTheme === 'dark' ? currentCopy.themeLight : currentCopy.themeDark}><svg aria-hidden="true" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><circle cx="12" cy="12" r="7"/><path d="M12 5a7 7 0 0 1 0 14Z" fill="currentColor" /></svg></button>
        </div>}
        <AccountLink chinese={currentLocale === 'zh'} />
        <details className="mobile-menu"><summary>{currentLocale === 'zh' ? '菜单' : 'Menu'}</summary><nav aria-label={copy?.primaryNav ?? 'Mobile navigation'}><Link href="/market">{nav[0]}</Link><Link href="/tools">{nav[1]}</Link><Link href="/blog">{nav[2]}</Link><AccountLink compact chinese={currentLocale === 'zh'} /></nav></details>
      </div>
    </header>
  );
}

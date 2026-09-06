import Link from 'next/link';
import { Logo } from './site-header';
import type { HomeCopy } from '../lib/home-copy';

export function SiteFooter({ copy }: { copy?: HomeCopy }) {
  const links = copy?.footerLinks ?? ['Flashcard decks', 'Memory guides', 'Free card maker', 'Web app', 'About LoopCard', 'Privacy'];
  return <footer className="site-footer"><div><Logo homeLabel={copy?.home} /><p>{copy?.footerTagline ?? 'Keep what matters in motion.'}</p></div><nav className="footer-links" aria-label={copy?.footerNav ?? 'Footer navigation'}><Link href="/market">{links[0]}</Link><Link href="/blog">{links[1]}</Link><Link href="/tools">{links[2]}</Link><Link href="/app">{links[3]}</Link><Link href="/about">{links[4]}</Link><Link href="/privacy">{links[5]}</Link></nav><small>© 2026 LoopCard Studio</small></footer>;
}

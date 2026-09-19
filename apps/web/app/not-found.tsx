import Link from 'next/link';
import { SiteHeader } from '../components/site-header';
import { SiteFooter } from '../components/site-footer';

export default function NotFound() {
  return <><SiteHeader /><main><section className="page-hero"><h1>This page is missing.</h1><p>The link may have changed.</p><div className="hero-actions"><Link className="button button-teal" href="/market">Browse decks</Link><Link className="button button-ghost" href="/">Home</Link></div></section></main><SiteFooter /></>;
}

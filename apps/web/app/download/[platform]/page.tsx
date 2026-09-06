import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { SiteFooter } from '../../../components/site-footer';
import { SiteHeader } from '../../../components/site-header';

const platforms = { ios: { name: 'iPhone and iPad', store: 'App Store' }, android: { name: 'Android', store: 'Google Play' } };
export function generateStaticParams() { return Object.keys(platforms).map((platform) => ({ platform })); }
export async function generateMetadata({ params }: { params: Promise<{ platform: string }> }): Promise<Metadata> { const item = platforms[(await params).platform as keyof typeof platforms]; return item ? { title: `LoopCard for ${item.name}`, description: `Install LoopCard from the ${item.store}.` } : {}; }
export default async function DownloadPage({ params }: { params: Promise<{ platform: string }> }) { const item = platforms[(await params).platform as keyof typeof platforms]; if (!item) notFound(); return <><SiteHeader /><main><section className="page-hero"><span className="eyebrow">Mobile beta</span><h1>LoopCard for<br />{item.name}.</h1><p>The public {item.store} release is being prepared. Use LoopCard on the web today, or join the mobile beta from this page when distribution opens.</p><div className="hero-actions"><Link className="button button-teal" href="/app">Use the web app →</Link><Link className="button button-ghost" href="/blog">Read the journal</Link></div></section></main><SiteFooter /></> }

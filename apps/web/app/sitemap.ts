import type { MetadataRoute } from 'next';
import { publicDecks } from '@loopcard/shared';
import { articles } from '../lib/articles';

export default function sitemap(): MetadataRoute.Sitemap { const base = process.env.NEXT_PUBLIC_SITE_URL ?? 'https://loopcard.dev'; const updated = new Date('2026-09-02'); const routes = ['', '/market', '/tools', '/blog', '/about', '/privacy'].map((route) => ({ url: `${base}${route}`, lastModified: updated, changeFrequency: (route === '/privacy' || route === '/about' ? 'yearly' : 'weekly') as 'yearly' | 'weekly', priority: route === '' ? 1 : .8 })); return [...routes, ...publicDecks.map((deck) => ({ url: `${base}/market/${deck.slug}`, lastModified: updated, changeFrequency: 'weekly' as const, priority: .7 })), ...articles.map((article) => ({ url: `${base}/blog/${article.slug}`, lastModified: new Date(article.isoDate), changeFrequency: 'monthly' as const, priority: .6 }))]; }

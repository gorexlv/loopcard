import type { MetadataRoute } from 'next';
export default function robots(): MetadataRoute.Robots { const base = process.env.NEXT_PUBLIC_SITE_URL ?? 'https://loopcard.dev'; return { rules: [{ userAgent: '*', allow: '/', disallow: ['/app'] }, { userAgent: ['GPTBot', 'ChatGPT-User', 'Google-Extended'], allow: '/' }], sitemap: `${base}/sitemap.xml`, host: base }; }

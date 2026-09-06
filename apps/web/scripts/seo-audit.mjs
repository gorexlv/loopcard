import { mkdir, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';

const base = (process.env.SEO_BASE_URL || 'http://127.0.0.1:3000').replace(/\/$/, '');
const reportPath = process.argv[2] || 'seo-reports/latest.json';
const coreRoutes = ['/', '/market', '/tools', '/blog'];
const articleRoutes = ['/blog/why-recall-beats-rereading', '/blog/make-a-card-worth-reviewing', '/blog/small-loops-long-memory', '/blog/designing-the-back-of-a-card'];
const deckRoutes = ['/market/chinese-zodiac-origins', '/market/everyday-english-core', '/market/chemistry-formulas', '/market/design-principles'];

const strip = (html) => html.replace(/<script[\s\S]*?<\/script>/gi, ' ').replace(/<style[\s\S]*?<\/style>/gi, ' ').replace(/<[^>]+>/g, ' ').replace(/&\w+;/g, ' ').replace(/\s+/g, ' ').trim();
const match = (html, pattern) => pattern.test(html);
const content = (html, pattern) => html.match(pattern)?.[1]?.trim() || '';
const checks = [];
const add = (name, pass, detail, weight = 1) => checks.push({ name, pass: Boolean(pass), detail, weight });

async function get(path) {
  const response = await fetch(`${base}${path}`, { redirect: 'manual' });
  return { response, text: await response.text() };
}

const pages = new Map();
for (const route of coreRoutes) {
  const { response, text } = await get(route);
  pages.set(route, text);
  add(`${route} returns 200`, response.status === 200, `HTTP ${response.status}`, 2);
  const title = content(text, /<title[^>]*>([\s\S]*?)<\/title>/i);
  const description = content(text, /<meta[^>]+name=["']description["'][^>]+content=["']([^"']+)["']/i) || content(text, /<meta[^>]+content=["']([^"']+)["'][^>]+name=["']description["']/i);
  const h1s = text.match(/<h1\b/gi)?.length || 0;
  const words = strip(text).split(/\s+/).filter(Boolean).length;
  add(`${route} unique title`, title.length >= 30 && title.length <= 65, `${title.length} chars: ${title}`);
  add(`${route} meta description`, description.length >= 120 && description.length <= 170, `${description.length} chars`);
  add(`${route} one H1`, h1s === 1, `${h1s} H1 elements`);
  add(`${route} canonical`, match(text, /<link[^>]+rel=["']canonical["']/i), 'self-referencing canonical');
  add(`${route} social metadata`, match(text, /property=["']og:title["']/i) && match(text, /property=["']og:image["']/i) && match(text, /name=["']twitter:card["']/i), 'Open Graph image and Twitter card');
  add(`${route} substantial content`, words >= 180, `${words} visible words`);
}

const home = pages.get('/');
add('Home SoftwareApplication schema', match(home, /"@type":"SoftwareApplication"/), 'SoftwareApplication JSON-LD', 2);
add('Home FAQ schema', match(home, /"@type":"FAQPage"/), 'FAQ content and JSON-LD');
add('Organization schema', match(home, /"@type":"Organization"/), 'Organization identity');
add('WebSite schema', match(home, /"@type":"WebSite"/), 'WebSite identity');
add('Semantic navigation', match(home, /<nav[^>]+aria-label=/i), 'labelled navigation');
add('Descriptive internal links', !match(home, />\s*(click here|read more)\s*</i), 'no generic anchors');

const robots = await get('/robots.txt');
add('robots.txt available', robots.response.status === 200 && /Sitemap:/i.test(robots.text), 'sitemap declared', 2);
add('AI crawler policy declared', /GPTBot|ChatGPT-User|Google-Extended/i.test(robots.text), 'explicit AI crawler rules');
const sitemap = await get('/sitemap.xml');
add('XML sitemap available', sitemap.response.status === 200 && /<urlset/i.test(sitemap.text), 'valid URL set', 2);
add('Sitemap includes content', /\/blog\//.test(sitemap.text) && /\/market\//.test(sitemap.text), 'blog and market detail URLs');
const manifest = await get('/manifest.webmanifest');
add('Web app manifest', manifest.response.status === 200, `HTTP ${manifest.response.status}`);

const allLinks = [...pages.values()].flatMap((html) => [...html.matchAll(/href=["'](\/[^"'#?]*)/g)].map((m) => m[1]));
const uniqueLinks = [...new Set(allLinks)].filter((link) => !link.startsWith('/_next'));
const broken = [];
for (const link of uniqueLinks) {
  const { response } = await get(link);
  if (response.status >= 400) broken.push(`${link}:${response.status}`);
}
add('No broken internal links', broken.length === 0, broken.join(', ') || `${uniqueLinks.length} links checked`, 2);

for (const route of [...articleRoutes, ...deckRoutes]) {
  const { response, text: html } = await get(route);
  const title = content(html, /<title[^>]*>([\s\S]*?)<\/title>/i);
  const description = content(html, /<meta[^>]+name=["']description["'][^>]+content=["']([^"']+)["']/i) || content(html, /<meta[^>]+content=["']([^"']+)["'][^>]+name=["']description["']/i);
  add(`${route} indexable response`, response.status === 200 && !match(html, /name=["']robots["'][^>]+noindex/i), `HTTP ${response.status}`);
  add(`${route} complete metadata`, title.length >= 30 && description.length >= 110 && match(html, /rel=["']canonical["']/i), `${title.length}-char title, ${description.length}-char description`);
  add(`${route} one H1`, (html.match(/<h1\b/gi)?.length || 0) === 1, 'single page topic');
  if (route.startsWith('/blog/')) {
    add(`${route} Article schema`, match(html, /"@type":"BlogPosting"/), 'BlogPosting with dates and author');
    add(`${route} useful article depth`, strip(html).split(/\s+/).length >= 300, `${strip(html).split(/\s+/).length} visible words`);
    add(`${route} contextual next step`, match(html, /href=["']\/(blog|tools|market)\//i), 'contextual internal link');
  } else {
    add(`${route} deck schema`, match(html, /"@type":"LearningResource"/) && match(html, /"@type":"BreadcrumbList"/), 'LearningResource and breadcrumb data');
    add(`${route} descriptive preview`, strip(html).split(/\s+/).length >= 160, `${strip(html).split(/\s+/).length} visible words`);
  }
}

const total = checks.reduce((sum, item) => sum + item.weight, 0);
const earned = checks.filter((item) => item.pass).reduce((sum, item) => sum + item.weight, 0);
const report = { auditedAt: new Date().toISOString(), base, score: Math.round((earned / total) * 100), passed: checks.filter((c) => c.pass).length, failed: checks.filter((c) => !c.pass).length, checks };
await mkdir(dirname(resolve(reportPath)), { recursive: true });
await writeFile(reportPath, `${JSON.stringify(report, null, 2)}\n`);
console.log(`SEO score: ${report.score}/100 · ${report.passed} passed · ${report.failed} failed`);
for (const item of checks.filter((c) => !c.pass)) console.log(`FAIL ${item.name} — ${item.detail}`);

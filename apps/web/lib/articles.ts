export const articles = [
  { slug: 'why-recall-beats-rereading', title: 'Why recall beats rereading', excerpt: 'The feeling of familiarity is not the same as memory. A practical guide to making review active.', date: 'August 28, 2026', isoDate: '2026-08-28', read: '6 min', featured: true },
  { slug: 'make-a-card-worth-reviewing', title: 'Make a card worth reviewing', excerpt: 'One prompt, one decision, and just enough context.', date: 'August 19, 2026', isoDate: '2026-08-19', read: '4 min' },
  { slug: 'small-loops-long-memory', title: 'Small loops, long memory', excerpt: 'Why a three-minute ritual can outlast a weekend of cramming.', date: 'August 07, 2026', isoDate: '2026-08-07', read: '5 min' },
  { slug: 'designing-the-back-of-a-card', title: 'Designing the back of a card', excerpt: 'Layer meaning without turning recall into reading.', date: 'July 26, 2026', isoDate: '2026-07-26', read: '7 min' },
];
export const getArticle = (slug: string) => articles.find((article) => article.slug === slug);

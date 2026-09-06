# LoopCard SEO optimization log

Audited locally on September 2, 2026. The repeatable audit command is:

```bash
npm --workspace @loopcard/web run seo:audit -- seo-reports/latest.json
```

| Stage | Score | Passed | Failed | Main change |
|---|---:|---:|---:|---|
| Baseline | 54 | 18 | 22 | Initial site audit |
| Round 1 | 85 | 33 | 7 | Canonicals, SERP metadata, social cards, manifest, stable sitemap |
| Round 2 | 94 | 37 | 3 | Organization, WebSite, SoftwareApplication and FAQ schema; trust pages |
| Round 3 | 100 | 40 | 0 | Search-intent copy, content depth and keyword mapping |
| Deep audit | 70 | 56 | 28 | Expanded coverage to eight dynamic detail pages |
| Round 4 | 100 | 84 | 0 | Unique articles, BlogPosting, LearningResource and breadcrumbs |
| Round 5 | 100 | 84 | 0 | Production headers, viewport, touch targets, motion and rendering stability |

## Production Lighthouse

- SEO: 100
- Performance: 98
- Accessibility: 95
- Best Practices: 100
- Largest Contentful Paint: 2.3 s
- Cumulative Layout Shift: 0
- Total Blocking Time: 20 ms

The JSON reports are retained in this directory. Search Console indexing, field Core Web Vitals, rankings and backlinks require a public production domain and real traffic, so they are outside this local audit.

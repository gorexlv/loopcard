import type { Metadata } from 'next';

export const siteUrl = process.env.NEXT_PUBLIC_SITE_URL ?? 'https://loopcard.dev';

export const site = {
  name: 'LoopCard',
  url: siteUrl,
  description: 'Create focused flashcards from notes, images, and ideas. Review with active recall, organize reusable decks, and remember what matters on web, iOS, and Android.',
  ogImage: '/opengraph-image',
};

export function pageMetadata({ title, description, path }: { title: string; description: string; path: string }): Metadata {
  return {
    title,
    description,
    alternates: { canonical: path },
    openGraph: {
      type: 'website',
      siteName: site.name,
      title,
      description,
      url: path,
      images: [{ url: site.ogImage, width: 1200, height: 630, alt: 'LoopCard memory cards in motion' }],
    },
    twitter: { card: 'summary_large_image', title, description, images: [site.ogImage] },
  };
}

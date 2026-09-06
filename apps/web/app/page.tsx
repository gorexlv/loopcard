import { publicDecks } from '@loopcard/shared';
import { HomePage } from '../components/home-page';
import { JsonLd } from '../components/json-ld';
import { site } from '../lib/seo';

const faqs = [
  ['What is LoopCard?', 'LoopCard is a focused flashcard maker for turning notes, images, formulas, questions, and ideas into reusable memory-card decks.'],
  ['Can I use LoopCard for any subject?', 'Yes. Cards are content-neutral, so a deck can hold vocabulary, chemistry formulas, cultural stories, professional concepts, or personal knowledge.'],
  ['How does a review loop work?', 'Read the prompt, recall the answer before flipping, then rate the memory as clear, fuzzy, or forgotten. The rating guides the next review loop.'],
  ['Can I try it without installing an app?', 'Yes. The web app and free note-to-flashcard tool work in a browser. Mobile apps are being prepared for iOS and Android.'],
];

export default function Home() {
  const jsonLd = [
    { '@context': 'https://schema.org', '@type': 'Organization', '@id': `${site.url}/#organization`, name: 'LoopCard Studio', url: site.url, logo: `${site.url}/brand/loopcard-app-icon.png` },
    { '@context': 'https://schema.org', '@type': 'WebSite', '@id': `${site.url}/#website`, name: 'LoopCard', url: site.url, publisher: { '@id': `${site.url}/#organization` } },
    { '@context': 'https://schema.org', '@type': 'SoftwareApplication', name: 'LoopCard', applicationCategory: 'ProductivityApplication', operatingSystem: 'Web, iOS, Android', description: 'Create and study focused memory cards from anything worth remembering.', url: site.url, offers: { '@type': 'Offer', price: '0', priceCurrency: 'USD' } },
    { '@context': 'https://schema.org', '@type': 'FAQPage', mainEntity: faqs.map(([name, text]) => ({ '@type': 'Question', name, acceptedAnswer: { '@type': 'Answer', text } })) },
  ];
  return <><HomePage decks={publicDecks} /><JsonLd data={jsonLd} /></>;
}

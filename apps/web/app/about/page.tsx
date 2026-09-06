import type { Metadata } from 'next';
import Link from 'next/link';
import { SiteHeader } from '../../components/site-header';
import { SiteFooter } from '../../components/site-footer';
import { pageMetadata } from '../../lib/seo';

export const metadata: Metadata = pageMetadata({ title: 'About LoopCard and Our Memory Method', description: 'Meet LoopCard Studio and learn why we build calm, content-neutral flashcards around active recall, clear prompts, layered answers, and honest review.', path: '/about' });

export default function AboutPage() {
  return <><SiteHeader /><main><section className="page-hero"><span className="eyebrow">About LoopCard Studio</span><h1>Memory tools<br />with less noise.</h1><p>LoopCard is an independent product for making and reviewing memory cards. It is designed for any person, topic, profession, or language—not a particular curriculum.</p></section><article className="prose"><h2>Why we built LoopCard</h2><p>Most information tools optimize for collecting more. We wanted a calmer place to decide what deserves to stay. LoopCard turns a source into small prompts, keeps supporting information in layers, and makes every review a clear act of recall.</p><h2>Our product principles</h2><p>One card should ask one meaningful question. The answer should correct memory without becoming another page to reread. People should control their material, understand what the product records, and be able to use the same card structure across subjects.</p><h2>How to reach us</h2><p>Product questions and feedback can be sent to <a href="mailto:hello@loopcard.app">hello@loopcard.app</a>. For data practices, read our <Link href="/privacy">privacy policy</Link>.</p></article></main><SiteFooter /></>;
}

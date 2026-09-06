import type { Metadata } from 'next';
import { SiteHeader } from '../../components/site-header';
import { SiteFooter } from '../../components/site-footer';
import { pageMetadata } from '../../lib/seo';

export const metadata: Metadata = pageMetadata({ title: 'Privacy Policy for LoopCard', description: 'Learn what account, deck, card, and usage data LoopCard processes, why it is needed, how it is protected, and how to request access or deletion.', path: '/privacy' });

export default function PrivacyPage() {
  return <><SiteHeader /><main><section className="page-hero"><span className="eyebrow">Last updated September 2, 2026</span><h1>Privacy,<br />in plain language.</h1><p>Your cards can be personal. This policy explains the information LoopCard processes and the choices available to you.</p></section><article className="prose"><h2>Information we process</h2><p>When you create an account, we process the account identifier and profile details provided by your chosen sign-in method. We store decks, cards, review outcomes, and settings so they remain available across your devices.</p><h2>Why we process it</h2><p>We use this information to authenticate you, synchronize your content, calculate review progress, prevent abuse, and improve reliability. We do not sell personal information or use private card content for advertising.</p><h2>Storage and control</h2><p>User records are isolated by account permissions. You may request a copy or deletion of your account data by emailing privacy@loopcard.app. Legal retention requirements may apply to limited operational records.</p><h2>Contact</h2><p>Questions about privacy can be sent to <a href="mailto:privacy@loopcard.app">privacy@loopcard.app</a>.</p></article></main><SiteFooter /></>;
}

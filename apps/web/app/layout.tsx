import type { Metadata, Viewport } from 'next';
import './globals.css';
import './afterimage.css';
import './fonts.css';
import './quiet.css';
import './system.css';
import { site } from '../lib/seo';

export const metadata: Metadata = {
  metadataBase: new URL(site.url),
  title: { default: 'Flashcard Maker for Lasting Recall | LoopCard', template: '%s | LoopCard' },
  description: site.description,
  applicationName: site.name,
  category: 'productivity',
  keywords: ['flashcard maker', 'memory cards', 'active recall', 'spaced repetition', 'study cards'],
  authors: [{ name: 'LoopCard Studio', url: site.url }],
  creator: 'LoopCard Studio',
  publisher: 'LoopCard Studio',
  alternates: { canonical: '/' },
  openGraph: { title: 'Flashcard Maker for Lasting Recall | LoopCard', description: site.description, type: 'website', siteName: site.name, url: '/', images: [{ url: site.ogImage, width: 1200, height: 630, alt: 'LoopCard memory cards in motion' }] },
  twitter: { card: 'summary_large_image', title: 'Flashcard Maker for Lasting Recall | LoopCard', description: site.description, images: [site.ogImage] },
};

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: '#f5f3ed' },
    { media: '(prefers-color-scheme: dark)', color: '#192720' },
  ],
  colorScheme: 'light dark',
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  const preferenceScript = `(function(){try{var t=localStorage.getItem('loopcard-theme');if(t!=='light'&&t!=='dark')t=matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light';var l=localStorage.getItem('loopcard-locale')==='zh'?'zh':'en';document.documentElement.dataset.theme=t;document.documentElement.dataset.locale=l;document.documentElement.lang=l==='zh'?'zh-CN':'en'}catch(e){}})()`;
  return (
    <html lang="en" suppressHydrationWarning>
      <head><link rel="preload" href="/fonts/loop-sans-latin.woff2" as="font" type="font/woff2" crossOrigin="anonymous" /><script dangerouslySetInnerHTML={{ __html: preferenceScript }} /></head>
      <body>{children}</body>
    </html>
  );
}

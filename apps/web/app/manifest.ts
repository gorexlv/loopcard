import type { MetadataRoute } from 'next';

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: 'LoopCard — Memory Card Maker',
    short_name: 'LoopCard',
    description: 'Create and review focused memory cards with active recall.',
    start_url: '/app',
    display: 'standalone',
    background_color: '#f3f0e9',
    theme_color: '#202334',
    icons: [{ src: '/icon.png', sizes: '512x512', type: 'image/png' }],
  };
}

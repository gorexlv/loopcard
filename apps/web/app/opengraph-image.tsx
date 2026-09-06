import { ImageResponse } from 'next/og';

export const alt = 'LoopCard — focused flashcards for lasting recall';
export const size = { width: 1200, height: 630 };
export const contentType = 'image/png';

export default function Image() {
  return new ImageResponse(
    <div style={{ width: '100%', height: '100%', display: 'flex', background: '#202334', color: '#faf8f3', padding: 72, alignItems: 'center', justifyContent: 'space-between', fontFamily: 'sans-serif' }}>
      <div style={{ display: 'flex', flexDirection: 'column', width: 660 }}><span style={{ color: '#23bfa5', fontSize: 28, letterSpacing: 6 }}>LOOPCARD</span><strong style={{ fontSize: 78, lineHeight: 1.03, marginTop: 34 }}>Make memory<br />visible.</strong><span style={{ color: '#b9bcc9', fontSize: 28, marginTop: 32 }}>Focused cards. Active recall. Your rhythm.</span></div>
      <div style={{ width: 300, height: 420, borderRadius: 38, display: 'flex', flexDirection: 'column', padding: 34, background: 'rgba(255,255,255,.08)', border: '2px solid rgba(255,255,255,.16)', transform: 'rotate(6deg)' }}><span style={{ color: '#f0a212', fontSize: 18 }}>CARD 08 / 20</span><span style={{ fontSize: 58, marginTop: 130 }}>retain</span><span style={{ color: '#b9bcc9', fontSize: 20, marginTop: 22 }}>keep in memory</span></div>
    </div>, size,
  );
}

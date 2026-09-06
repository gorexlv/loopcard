import { describe, expect, it } from 'vitest';
import { getPublicDeck, publicDecks } from '@loopcard/shared';
import { codexPlugin, mobileDownloads } from './downloads';
import { heroParticles } from './hero-motion';
import { resolveLocale, resolveTheme } from './preferences';

describe('public deck catalog', () => {
  it('provides unique indexable slugs and usable cards', () => { expect(new Set(publicDecks.map((deck) => deck.slug)).size).toBe(publicDecks.length); expect(publicDecks.every((deck) => deck.cards.length > 0)).toBe(true); });
  it('offers at least 50 decks across a broad set of filters', () => { expect(publicDecks.length).toBeGreaterThanOrEqual(50); expect(new Set(publicDecks.map((deck) => deck.category)).size).toBeGreaterThanOrEqual(8); });
  it('contains the complete zodiac CLI fixture', () => { const deck = getPublicDeck('chinese-zodiac-origins'); expect(deck?.cards).toHaveLength(12); expect(deck?.cards[0].prompt).toBe('子鼠'); expect(deck?.cards[11].prompt).toBe('亥猪'); });
});

describe('landing download destinations', () => {
  it('marks both mobile platforms as coming soon', () => {
    expect(mobileDownloads.map((item) => item.platform)).toEqual(['iOS', 'Android']);
    expect(mobileDownloads.every((item) => item.status === 'coming-soon')).toBe(true);
  });

  it('links the LoopCard Codex plugin to its marketplace slug', () => {
    expect(codexPlugin.href).toBe('https://www.codex-marketplace.com/plugins/loopcard');
    expect(codexPlugin.status).toBe('available');
  });
});

describe('hero motion system', () => {
  it('uses a bounded deterministic particle field', () => {
    expect(heroParticles).toHaveLength(24);
    expect(new Set(heroParticles.map((particle) => particle.id)).size).toBe(24);
    expect(heroParticles.every((particle) => particle.x >= 0 && particle.x <= 100)).toBe(true);
    expect(heroParticles.every((particle) => particle.duration >= 12)).toBe(true);
  });
});

describe('homepage preferences', () => {
  it('accepts supported locales and safely falls back to English', () => {
    expect(resolveLocale('zh')).toBe('zh');
    expect(resolveLocale('fr')).toBe('en');
    expect(resolveLocale(null)).toBe('en');
  });

  it('restores an explicit theme and otherwise follows the system', () => {
    expect(resolveTheme('dark', false)).toBe('dark');
    expect(resolveTheme('light', true)).toBe('light');
    expect(resolveTheme(null, true)).toBe('dark');
    expect(resolveTheme('sepia', false)).toBe('light');
  });
});

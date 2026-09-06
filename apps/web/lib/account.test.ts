import { describe, expect, it } from 'vitest';
import { parseCardDrafts, parseCardLines } from './decks';
import { safeNext } from './safe-next';

describe('account helpers', () => {
  it('accepts only same-origin redirect paths', () => {
    expect(safeNext('/app/decks/new')).toBe('/app/decks/new');
    expect(safeNext('https://attacker.test')).toBe('/app');
    expect(safeNext('//attacker.test')).toBe('/app');
  });

  it('parses compact front and back card lines', () => {
    expect(parseCardLines('borrow :: take temporarily\nserene :: calm\n\n')).toEqual([
      { prompt: 'borrow', answer: 'take temporarily' },
      { prompt: 'serene', answer: 'calm' },
    ]);
  });

  it('keeps a prompt without a back', () => {
    expect(parseCardLines('Unanswered prompt')).toEqual([{ prompt: 'Unanswered prompt', answer: '' }]);
  });

  it('sanitizes structured card drafts from the visual editor', () => {
    expect(parseCardDrafts(JSON.stringify([
      { prompt: '  What is recall?  ', answer: '  Retrieving a memory.  ' },
      { prompt: '', answer: 'ignored' },
      null,
    ]))).toEqual([{ prompt: 'What is recall?', answer: 'Retrieving a memory.' }]);
  });

  it('rejects malformed structured card drafts', () => {
    expect(parseCardDrafts('{not-json')).toEqual([]);
    expect(parseCardDrafts('{"prompt":"not an array"}')).toEqual([]);
  });
});

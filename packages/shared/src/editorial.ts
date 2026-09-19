import type { MemoryCard } from './index';

// Complete small collections. The same cards power discovery, preview and study.
const card = (id: string, prompt: string, heading: string, body: string, visual?: MemoryCard['visual']): MemoryCard => ({ id, prompt, visual, sections: [{ title: 'Answer', heading, body }] });
export const editorialCards: Record<string, MemoryCard[]> = {
  'arts-37-color-theory': [
    card('catalog-37-1', 'Why do blue and orange stand out together?', 'Opposites on the wheel.', 'Blue and orange are complementary colors on a traditional artist’s color wheel. Their contrast makes each easier to notice.', 'color'),
    card('catalog-37-2', 'A vivid red becomes muted. What changed?', 'Saturation.', 'Saturation describes color intensity. Lower it and a vivid color moves toward a neutral gray.'),
    card('catalog-37-3', 'Two colors look alike in a black-and-white photo. Why?', 'Similar value.', 'Value is how light or dark a color is. Different hues can have the same value.'),
  ],
  'arts-38-typography-anatomy': [
    card('catalog-38-1', 'Same font size. Why does one look bigger?', 'A taller x-height.', 'The height of a lowercase x varies between typefaces. A larger x-height can make text look bigger at the same point size.', 'type'),
    card('catalog-38-2', 'What are the small strokes at the ends of a letter called?', 'Serifs.', 'A serif extends from the end of a main stroke. A sans-serif typeface leaves these extensions out.'),
    card('catalog-38-3', 'What do you call the empty space inside an “o”?', 'A counter.', 'The enclosed space inside a letter is a counter. The white space is part of the letter’s design, too.'),
  ],
  'arts-40-photography-basics': [
    card('catalog-40-1', 'Which lets in more light: f/2 or f/8?', 'f/2, not f/8.', 'At the same focal length, a lower f-number means a wider opening. It admits more light when shutter speed stays the same.', 'aperture'),
    card('catalog-40-2', 'A moving cyclist looks blurred. Which setting could freeze them?', 'A faster shutter speed.', 'A shorter exposure records less movement. You may need a wider aperture or higher ISO to keep the image bright.'),
    card('catalog-40-3', 'Why place a road so it runs toward your subject?', 'It leads the eye.', 'A line can guide attention through a photograph. Roads, shadows and railings can all point toward the subject.'),
  ],
  'everyday-english-core': [
    card('borrow', 'May I ___ your pen: borrow or lend?', 'May I borrow your pen?', 'You borrow from someone. They lend to you. Same pen, opposite directions.', 'dialogue'),
    card('serene', 'The lake is calm and peaceful. One word?', 'Serene.', '“A serene morning.” Use serene for a quietly peaceful place, moment or expression.'),
    card('retain', 'You learn something today and still remember it next week. You…', 'Retain it.', 'To retain is to keep. “I retain more when I test myself.”'),
  ],
  'language-2-french-caf-phrases': [
    card('catalog-2-1', 'One coffee, politely.', 'Un café, s’il vous plaît.', '“A coffee, please.” Add s’il vous plaît to make the request polite.', 'cafe'),
    card('catalog-2-2', 'You have finished your coffee. Ask for the bill.', 'L’addition, s’il vous plaît.', 'L’addition is the bill in a café or restaurant.'),
    card('catalog-2-3', 'The pastry was delicious. Tell your host.', 'C’était délicieux.', '“It was delicious.” Use c’est délicieux while you are enjoying it; c’était délicieux afterward.'),
  ],
  'design-principles': [
    card('hierarchy', 'How can scale and contrast guide the eye?', 'Hierarchy directs attention.', 'Scale and contrast give one element priority. Decide what should be seen first before styling the rest.', 'hierarchy'),
    card('rhythm', 'What makes a row of uneven elements feel connected?', 'A repeated rhythm.', 'Consistent spacing or a shared alignment can connect elements even when their shapes differ.'),
    card('restraint', 'Two elements demand equal attention. What should you change?', 'Choose a lead.', 'Make the primary element clearer, then quiet the secondary one. Emphasis works because something else recedes.'),
  ],
};
export const editorialOrder = ['arts-37-color-theory', 'everyday-english-core', 'arts-40-photography-basics', 'arts-38-typography-anatomy', 'language-2-french-caf-phrases', 'design-principles'];

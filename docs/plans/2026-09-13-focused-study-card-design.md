# Focused study-card design

## Goal

Make the study screen feel like a single-purpose recall surface. The current
word card repeats category and context labels in its internal header and footer,
while the page header repeats the deck name. These elements compete with the
word without helping the user decide or act.

## Chosen direction

Use a focused mode that preserves interaction clarity:

- Keep only Back and the current card count in the page header.
- Remove the deck title from the study screen.
- Remove the word card's decorative eyebrow, trailing line, support caption,
  and underline.
- Hide the part of speech on the front. It remains available on the back with
  the pronunciation and definition.
- Set the word in one line with a calmer weight and tracking. Scale it down to
  fit the available width instead of wrapping or clipping.
- Place the hint directly below the word as a subtitle. Before reveal, reserve
  the same space with a quiet mask instead of showing a labeled button.
- Center the word and use the locally bundled Newsreader variable font at its
  semibold weight. Keep Inter for controls and lexical metadata.
- Build the mask from the real part-of-speech and IPA text. Blur and cover that
  text before reveal, then sharpen it in place after the user taps.
- Keep the two rating actions outside the card because they communicate the
  gesture model and provide an accessible tap fallback. Reduce their visual
  weight until a drag is active.

Formula and problem cards retain their subject-specific front compositions;
only the shared page header becomes quieter. The word-card back keeps lexical
metadata and pronunciation because these are learning content, not decoration.

## Acceptance criteria

- A word front contains no decorative category header, footer caption, or
  underline.
- The front never displays a part-of-speech label.
- The hidden hint appears as a mask below the word and reveals in place without
  moving the composition.
- A long word stays on one line and fits within the card at common phone widths.
- The study header contains no deck-title text.
- Back navigation, progress, rating taps, vertical swipes, hint reveal, card
  flip, and accessibility semantics continue to work.
- The front and back retain identical outer geometry.

## Verification

Run the focused widget tests, interaction tests, static analysis, and the visual
golden capture. Inspect the current-card screenshot at the phone viewport, make
one batched correction if needed, then confirm once.

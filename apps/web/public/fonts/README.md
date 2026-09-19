# Loopcard Web fonts

Locally hosted subsets of the font files already used by Loopcard mobile:

- Inter: UI text; source `apps/mobile/assets/fonts/Inter-Variable.ttf`.
- Newsreader: Latin card content and editorial headings; source `apps/mobile/assets/fonts/Newsreader-Variable.ttf`.
- Noto Sans SC: Chinese UI/content; source `apps/mobile/assets/fonts/NotoSansSC-Variable.ttf`.

All are SIL OFL 1.1; corresponding license files accompany these distributions.

The small Noto UI subset includes Chinese characters in Web/shared TypeScript source. `quiet.css` declares its precise unicode range after the full face, so ordinary interface text uses the small file; other Chinese card content can load the complete CJK fallback. Latin subsets include extended Latin and punctuation. Chemical subscript digits render as semantic `sub` elements in the same face rather than an unrelated fallback glyph.

Subset generation uses fontTools `pyftsubset --flavor=woff2 --layout-features='*'`; original mobile font files remain unchanged. Regenerate the UI subset and unicode range together when introducing Chinese interface copy.

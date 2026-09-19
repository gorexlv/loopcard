# Loopcard Web fonts

The active interface family is Noto Sans SC, served locally as `Loop Sans` for both Latin and Chinese. Source: `apps/mobile/assets/fonts/NotoSansSC-Variable.ttf`; complete WOFF2 retained as the uncommon-character fallback. License: SIL OFL 1.1 in `NotoSansSC-OFL.txt`.

- `loop-sans-latin.woff2`: Latin and common punctuation, about 55KB.
- `loop-sans-ui.woff2`: remaining characters in Web/shared TypeScript source, about 136KB.
- `noto-sans-sc.woff2`: full fallback. Rare user content can request this larger file.

Regenerate small subsets and `app/fonts.css` together with `python3 apps/web/scripts/build-fonts.py` (fontTools with WOFF2 support). Every subset comes from the same variable font; weights remain 100–900. Latin is preloaded; other subsets load by Unicode range.

Legacy Inter/Newsreader files are no longer declared as interface faces. Their OFL notices remain because `type-specimen.svg` contains two outlined glyphs from these typefaces, at equal em size, for the Typography Anatomy educational diagram. Original mobile font assets are unchanged.

Research: https://notofonts.github.io/noto-docs/website/use/ and https://github.com/notofonts/noto-cjk/blob/main/Sans/README.md . Noto Sans CJK shares the Source Han Sans design and uses Latin forms based on Source Sans Pro.

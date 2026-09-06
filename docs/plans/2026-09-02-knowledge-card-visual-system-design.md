# Loopcard Knowledge Card Visual System

## Product direction

Loopcard uses a restrained learning interface around editorial, collectible knowledge cards. Every card should feel like a small knowledge poster while remaining fast and comfortable to study.

The first release supports words, formulas, and problems through one brand shell and three content-specific visual grammars. Official themes provide a reliable quality floor. User imagery and generated imagery are represented through a replaceable background-source contract with deterministic fallback.

## Card anatomy

- The front creates one memorable visual anchor.
- The back reveals the answer first, then structured supporting material.
- Brand, palette, background motif, and decorative geometry persist across both faces.
- A visual safety layer controls contrast, content length, overflow, and reduced-motion behavior.

## Content grammars

- Word: oversized lexical display, pronunciation/category context, definition, example, distinction.
- Formula: typeset expression, scientific diagram motif, variable legend, constraints, worked example.
- Problem: editorial question composition, key-condition markers, breakthrough, progressive solution steps, transferable method.

## Creation experience

The default studio is constrained rather than canvas-based. Users choose theme, mood, density, emphasis, and background source. The layout engine owns typography, spacing, safe areas, and contrast. It generates deterministic recommendations and falls back to an official theme whenever custom media is unavailable or unsafe.

## Theme families

Aurora, Paper, Cosmos, Lab, Botanical, and Mono are tokenized art directions rather than wallpaper files. Each defines a palette, motif, surface treatment, typography mode, and foreground contrast.

## Interaction

The card reveals its back with a spatial fade/scale transition rather than a literal 3D flip. The core answer appears before supporting modules. Motion degrades to an immediate cross-fade when platform accessibility settings request reduced motion.

## Quality bar

- No text clipping at supported content densities.
- Minimum 44 logical-pixel touch targets.
- Deterministic fallback for failed backgrounds.
- Semantic labels for card faces and controls.
- Golden coverage for all three content grammars.
- Unit coverage for layout selection, density, theme fallback, and content-length behavior.


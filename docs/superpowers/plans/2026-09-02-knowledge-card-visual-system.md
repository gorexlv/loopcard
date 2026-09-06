# Knowledge Card Visual System Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a production-ready adaptive card renderer and constrained card studio for word, formula, and problem content.

**Architecture:** Extend the domain model with problem content and visual preferences, then isolate visual recommendation in a pure layout engine. Render both study and studio experiences through shared themed card widgets so appearance and behavior cannot drift.

**Tech Stack:** Flutter, Dart, Material 3, flutter_test golden and widget tests.

---

### Task 1: Domain and recommendation engine

**Files:**
- Modify: `apps/mobile/lib/models/card_models.dart`
- Create: `apps/mobile/lib/cards/card_visuals.dart`
- Test: `apps/mobile/test/card_visuals_test.dart`

- [ ] Write failing tests for kind-specific recommendations, theme fallback, density, and display-size selection.
- [ ] Run the focused test and verify expected failures.
- [ ] Implement immutable visual preferences, six official themes, and the pure recommendation engine.
- [ ] Run focused tests and refactor while green.

### Task 2: Shared editorial card renderer

**Files:**
- Create: `apps/mobile/lib/cards/editorial_card.dart`
- Create: `apps/mobile/lib/cards/card_background.dart`
- Test: `apps/mobile/test/editorial_card_test.dart`

- [ ] Write widget tests for word, formula, problem, front, back, long content, and semantics.
- [ ] Run the focused test and verify expected failures.
- [ ] Implement adaptive front/back compositions, theme motifs, answer-first back layout, and accessible motion.
- [ ] Run focused tests and refactor while green.

### Task 3: Study experience integration

**Files:**
- Modify: `apps/mobile/lib/screens/study_screen.dart`
- Modify: `apps/mobile/lib/data/demo_data.dart`
- Test: `apps/mobile/test/study_visual_system_test.dart`

- [ ] Write failing tests for reveal, progressive problem steps, navigation, and rating continuity.
- [ ] Add a problem deck and migrate study rendering to the shared card component.
- [ ] Run focused and existing interaction tests.

### Task 4: Constrained card studio

**Files:**
- Create: `apps/mobile/lib/screens/card_studio_screen.dart`
- Modify: `apps/mobile/lib/screens/deck_detail_screen.dart`
- Test: `apps/mobile/test/card_studio_screen_test.dart`

- [ ] Write failing tests for theme, mood, density, emphasis, preview, and reset/fallback behavior.
- [ ] Implement the live preview and finite controls with 44px targets and keyboard semantics.
- [ ] Add an entry point from deck detail and run focused tests.

### Task 5: Visual regression and final verification

**Files:**
- Modify: `apps/mobile/test/visual_golden_test.dart`
- Update: `apps/mobile/test/goldens/*.png`

- [ ] Add golden states for all three card grammars and studio preview.
- [ ] Run analyzer and complete Flutter suite.
- [ ] Inspect rendered goldens for clipping, weak hierarchy, accidental noise, and contrast regressions.
- [ ] Run a release Android build when the local toolchain permits it.


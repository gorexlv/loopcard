# Baidu OCR Camera Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Capture a photo from the system camera, recognize English words through Baidu Accurate OCR, and present a selectable confirmation list.

**Architecture:** Keep camera/OCR orchestration behind a `WordCaptureFlow` consumed by the UI. The temporary implementation reads development credentials from `.env`, calls Baidu directly, and can later be replaced by a backend implementation without changing screens.

**Tech Stack:** Flutter, `image_picker`, `http`, `flutter_dotenv`, `flutter_test`

---

### Task 1: Protect and load development configuration

**Files:**
- Modify: `.gitignore`
- Create: `.env.example`
- Modify: `pubspec.yaml`
- Modify: `lib/main.dart`

- [ ] Add `.env` ignore rules and a placeholder-only `.env.example`.
- [ ] Add `http`, `image_picker`, and `flutter_dotenv` dependencies, and register `.env` as a development asset.
- [ ] Load dotenv during startup and validate `apiKey` / `secretKey` without logging values.
- [ ] Run `flutter pub get` and verify dependency resolution succeeds.

### Task 2: Extract English words test-first

**Files:**
- Create: `test/ocr/english_word_extractor_test.dart`
- Create: `lib/ocr/english_word_extractor.dart`

- [ ] Write tests for ordinary text, apostrophes, hyphens, case-insensitive stable deduplication, and one-character filtering.
- [ ] Run `flutter test test/ocr/english_word_extractor_test.dart` and verify failure because the implementation is missing.
- [ ] Implement the minimal pure extractor.
- [ ] Re-run the focused test and verify it passes.

### Task 3: Implement Baidu OCR client test-first

**Files:**
- Create: `test/ocr/baidu_ocr_service_test.dart`
- Create: `lib/ocr/baidu_ocr_service.dart`

- [ ] Write HTTP-client tests for token acquisition, cached token reuse, OCR form encoding, recognized word output, and sanitized API errors.
- [ ] Run the focused test and verify the expected missing-implementation failure.
- [ ] Implement token caching and `accurate_basic` requests using an injected `http.Client`.
- [ ] Re-run focused tests and keep responses free of secret values.

### Task 4: Implement camera orchestration test-first

**Files:**
- Create: `test/ocr/direct_baidu_word_capture_flow_test.dart`
- Create: `lib/ocr/word_capture_flow.dart`
- Create: `lib/ocr/direct_baidu_word_capture_flow.dart`

- [ ] Test that camera cancellation returns no result and captured bytes are delegated to OCR.
- [ ] Verify the tests fail before implementation.
- [ ] Implement an injectable camera adapter backed by `ImagePicker` with camera-only source and bounded image quality/width.
- [ ] Re-run focused tests and verify green.

### Task 5: Build the selectable OCR result screen test-first

**Files:**
- Create: `test/ocr_result_screen_test.dart`
- Create: `lib/screens/ocr_result_screen.dart`

- [ ] Write widget tests proving all words start selected, rows can be toggled, and the selected count updates.
- [ ] Verify red, implement the minimal screen in the existing LoopCard visual language, then verify green.

### Task 6: Connect the homepage flow test-first

**Files:**
- Modify: `test/widget_test.dart`
- Modify: `lib/screens/home_screen.dart`
- Modify: `lib/main.dart`

- [ ] Add widget tests for loading, success navigation, cancellation, empty results, and errors using an injected `WordCaptureFlow`.
- [ ] Verify tests fail for the missing behavior.
- [ ] Convert the homepage to stateful capture handling and inject the production flow from `main.dart`.
- [ ] Re-run widget tests and preserve the existing deck-learning flow.

### Task 7: Platform configuration and full verification

**Files:**
- Modify: `ios/Runner/Info.plist`

- [ ] Add the iOS camera usage description.
- [ ] Run `dart format lib test`.
- [ ] Run `flutter test` and expect all tests to pass.
- [ ] Run `flutter analyze` and expect no issues.
- [ ] Confirm `.env` values are absent from source, tests, logs, and `.env.example`.

> This directory is not currently a Git repository, so the plan intentionally omits commit steps and worktree creation.

# Settings I18n and Theme Completion Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the ten-language interface and verify persisted system/light/dark appearance controls in Settings.

**Architecture:** Retain the existing map-based localization, `LoopPalette` ThemeExtension, and SharedPreferences settings store. Add a small localization completeness API for tests, fill every missing translation, and use the existing Profile settings pickers as the user-facing controls.

**Tech Stack:** Flutter Material 3, Flutter localizations, SharedPreferences, flutter_test

---

### Task 1: Enforce translation completeness test-first

**Files:**
- Modify: `test/localization_theme_test.dart`
- Modify: `lib/l10n/app_localizations.dart`

- [ ] Add a test that treats English regular keys as the baseline and reports missing keys for every supported locale.
- [ ] Run the focused test and confirm it fails for the seven locales currently missing 13 keys.
- [ ] Expose immutable diagnostic key sets from `AppLocalizations` without changing runtime lookup behavior.
- [ ] Re-run and confirm the test still fails on actual missing translations rather than test plumbing.

### Task 2: Fill seven locale dictionaries

**Files:**
- Modify: `lib/l10n/app_localizations.dart`
- Test: `test/localization_theme_test.dart`

- [ ] Add localized values for WeChat states, settings notices, result pagination, intervals, and feature placeholders in Japanese, Korean, Spanish, French, German, Portuguese, and Russian.
- [ ] Run the focused localization/theme test and confirm all locale key sets match the English baseline.
- [ ] Check placeholders `{count}` and `{feature}` are preserved in every translation.

### Task 3: Verify Settings integration and themes

**Files:**
- Verify: `lib/screens/profile_screen.dart`
- Verify: `lib/main.dart`
- Verify: `lib/settings/app_settings.dart`
- Test: `test/localization_theme_test.dart`

- [ ] Confirm “Language” and “Appearance” remain in the Profile settings card.
- [ ] Confirm language options include all ten retained locales plus system default.
- [ ] Confirm appearance options include system, light, and dark and persist through the settings store.
- [ ] Run `dart format lib test`, `flutter test`, and `flutter analyze`.
- [ ] Build an Android debug APK to ensure platform compilation succeeds.

> This directory is not currently a Git repository, so no worktree or commit steps are included.

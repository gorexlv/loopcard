import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopcard/l10n/app_localizations.dart';
import 'package:loopcard/main.dart';
import 'package:loopcard/settings/app_settings.dart';

void main() {
  test('ships ten supported interface languages', () {
    expect(AppLocalizations.supportedLocales, hasLength(10));
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = AppLocalizations(AppLocalizations.resolveLocaleKey(locale));
      expect(l10n.tr('navGenerate'), isNotEmpty);
      expect(l10n.tr('getStarted'), isNot('getStarted'));
    }
  });

  test(
    'every supported language provides the complete translation key set',
    () {
      final baseline = AppLocalizations.translationKeysFor(const Locale('en'));

      for (final locale in AppLocalizations.supportedLocales) {
        expect(
          AppLocalizations.translationKeysFor(locale),
          baseline,
          reason: '${locale.toLanguageTag()} must not fall back to English',
        );
      }
    },
  );

  test('translations preserve interpolation placeholders', () {
    final baseline = AppLocalizations.translationKeysFor(const Locale('en'));
    final placeholder = RegExp(r'\{[^}]+\}');
    const english = AppLocalizations('en');

    for (final locale in AppLocalizations.supportedLocales) {
      final localized = AppLocalizations(
        AppLocalizations.resolveLocaleKey(locale),
      );
      for (final key in baseline) {
        expect(
          placeholder.allMatches(localized.tr(key)).map((match) => match[0]),
          placeholder.allMatches(english.tr(key)).map((match) => match[0]),
          reason: '${locale.toLanguageTag()}.$key placeholders must match',
        );
      }
    }
  });

  test('resolves regional Chinese variants correctly', () {
    expect(
      AppLocalizations.resolvePreferredLocale(const [Locale('zh', 'TW')]),
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    );
    expect(
      AppLocalizations.resolvePreferredLocale(const [Locale('zh', 'CN')]),
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    );
  });

  testWidgets('switches language and theme and persists both choices', (
    tester,
  ) async {
    final store = MemoryAppSettingsStore(
      const AppSettings(
        locale: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
        themeMode: ThemeMode.dark,
      ),
    );
    await tester.pumpWidget(
      LoopCardApp(settingsStore: store, initialSettings: store.settings),
    );

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('界面语言'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(store.settings.locale, const Locale('en'));

    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();

    expect(store.settings.themeMode, ThemeMode.light);
    final context = tester.element(find.text('Settings'));
    expect(Theme.of(context).brightness, Brightness.light);
  });
}

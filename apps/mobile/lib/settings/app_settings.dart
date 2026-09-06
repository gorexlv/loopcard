import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({this.locale, this.themeMode = ThemeMode.system});

  final Locale? locale;
  final ThemeMode themeMode;
}

abstract interface class AppSettingsStore {
  Future<AppSettings> load();

  Future<void> saveLocale(Locale? locale);

  Future<void> saveThemeMode(ThemeMode mode);
}

class SharedPreferencesAppSettingsStore implements AppSettingsStore {
  SharedPreferencesAppSettingsStore([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _localeKey = 'settings.locale';
  static const _themeKey = 'settings.theme';

  final SharedPreferencesAsync _preferences;

  @override
  Future<AppSettings> load() async {
    final localeTag = await _preferences.getString(_localeKey);
    final themeName = await _preferences.getString(_themeKey);
    return AppSettings(
      locale: _localeFromTag(localeTag),
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == themeName,
        orElse: () => ThemeMode.system,
      ),
    );
  }

  @override
  Future<void> saveLocale(Locale? locale) async {
    if (locale == null) {
      await _preferences.remove(_localeKey);
      return;
    }
    await _preferences.setString(_localeKey, locale.toLanguageTag());
  }

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    await _preferences.setString(_themeKey, mode.name);
  }

  Locale? _localeFromTag(String? tag) {
    if (tag == null || tag.isEmpty) return null;
    final parts = tag.split('-');
    if (parts.length == 1) return Locale(parts.first);
    if (parts.length == 2 && parts.last.length == 4) {
      return Locale.fromSubtags(
        languageCode: parts.first,
        scriptCode: parts.last,
      );
    }
    return Locale.fromSubtags(
      languageCode: parts.first,
      countryCode: parts.last,
    );
  }
}

class MemoryAppSettingsStore implements AppSettingsStore {
  MemoryAppSettingsStore([this.settings = const AppSettings()]);

  AppSettings settings;

  @override
  Future<AppSettings> load() async => settings;

  @override
  Future<void> saveLocale(Locale? locale) async {
    settings = AppSettings(locale: locale, themeMode: settings.themeMode);
  }

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    settings = AppSettings(locale: settings.locale, themeMode: mode);
  }
}

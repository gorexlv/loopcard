import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/auth_service.dart';
import 'auth/test_auto_login.dart';
import 'data/deck_repository.dart';
import 'data/demo_data.dart';
import 'l10n/app_localizations.dart';
import 'ocr/on_device_word_capture_flow.dart';
import 'ocr/word_capture_flow.dart';
import 'onboarding/onboarding_store.dart';
import 'screens/app_entry.dart';
import 'settings/app_settings.dart';
import 'theme/loop_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  final wordCaptureFlow = OnDeviceWordCaptureFlow.standard();

  const configuredUrl = String.fromEnvironment('SUPABASE_URL');
  final supabaseUrl = configuredUrl.isNotEmpty
      ? configuredUrl
      : Platform.isAndroid
      ? 'http://10.0.2.2:8000'
      : 'http://127.0.0.1:8000';
  const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE',
  );
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  final client = Supabase.instance.client;
  final authService = SupabaseAuthService(client);
  await TestAutoLogin.run(authService);

  final onboardingStore = SharedPreferencesOnboardingStore();
  final onboardingCompleted = await onboardingStore.isCompleted();
  final settingsStore = SharedPreferencesAppSettingsStore();
  final settings = await settingsStore.load();
  runApp(
    LoopCardApp(
      wordCaptureFlow: wordCaptureFlow,
      onboardingStore: onboardingStore,
      initialOnboardingCompleted: onboardingCompleted,
      showSplash: true,
      settingsStore: settingsStore,
      initialSettings: settings,
      authService: authService,
      deckRepository: SupabaseDeckRepository(client),
    ),
  );
}

class LoopCardApp extends StatefulWidget {
  const LoopCardApp({
    super.key,
    this.wordCaptureFlow,
    this.onboardingStore,
    this.initialOnboardingCompleted = true,
    this.showSplash = false,
    this.settingsStore,
    this.authService,
    this.deckRepository,
    this.initialSettings = const AppSettings(
      locale: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      themeMode: ThemeMode.dark,
    ),
  });

  final WordCaptureFlow? wordCaptureFlow;
  final OnboardingStore? onboardingStore;
  final bool initialOnboardingCompleted;
  final bool showSplash;
  final AppSettingsStore? settingsStore;
  final AuthService? authService;
  final DeckRepository? deckRepository;
  final AppSettings initialSettings;

  @override
  State<LoopCardApp> createState() => _LoopCardAppState();
}

class _LoopCardAppState extends State<LoopCardApp> {
  late Locale? _locale = widget.initialSettings.locale;
  late ThemeMode _themeMode = widget.initialSettings.themeMode;

  Future<void> _setLocale(Locale? locale) async {
    setState(() => _locale = locale);
    await widget.settingsStore?.saveLocale(locale);
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    await widget.settingsStore?.saveThemeMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LoopCard',
      debugShowCheckedModeBanner: false,
      theme: LoopTheme.light,
      darkTheme: LoopTheme.dark,
      themeMode: _themeMode,
      locale: _locale,
      localeListResolutionCallback: (preferred, _) =>
          AppLocalizations.resolvePreferredLocale(preferred),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AppEntry(
        authService: widget.authService ?? MemoryAuthService.authenticated(),
        deckRepository:
            widget.deckRepository ?? MemoryDeckRepository(DemoData.decks),
        wordCaptureFlow: widget.wordCaptureFlow,
        onboardingStore:
            widget.onboardingStore ?? MemoryOnboardingStore(completed: true),
        initialOnboardingCompleted: widget.initialOnboardingCompleted,
        showSplash: widget.showSplash,
        locale: _locale,
        themeMode: _themeMode,
        onLocaleChanged: _setLocale,
        onThemeModeChanged: _setThemeMode,
      ),
    );
  }
}

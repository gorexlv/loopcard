import 'ocr/openrouter_text_recognizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/auth_service.dart';
import 'ai/word_card_generator.dart';
import 'auth/supabase_runtime_config.dart';
import 'auth/test_auto_login.dart';
import 'data/deck_repository.dart';
import 'data/demo_data.dart';
import 'l10n/app_localizations.dart';
import 'ocr/on_device_word_capture_flow.dart';
import 'ocr/word_capture_flow.dart';
import 'onboarding/onboarding_store.dart';
import 'reminders/practice_reminder.dart';
import 'screens/app_entry.dart';
import 'settings/app_settings.dart';
import 'theme/loop_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final authConfig = SupabaseRuntimeConfig.resolve(
    configuredUrl: const String.fromEnvironment('SUPABASE_URL'),
    configuredPublishableKey: const String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
    ),
    legacyAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
  await Supabase.initialize(
    url: authConfig.url,
    publishableKey: authConfig.publishableKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  final client = Supabase.instance.client;
  final wordCaptureFlow = OnDeviceWordCaptureFlow(
    camera: SystemCameraImagePathSource(),
    cropper: SystemCapturedImageCropper(),
    recognizer: OpenRouterTextRecognizer(client),
  );
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
      wordCardGenerator: SupabaseWordCardGenerator(client),
      reminderStore: SharedPreferencesPracticeReminderStore(),
      reminderScheduler: LocalPracticeReminderScheduler(),
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
    this.wordCardGenerator,
    this.reminderStore,
    this.reminderScheduler,
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
  final WordCardGenerator? wordCardGenerator;
  final PracticeReminderStore? reminderStore;
  final PracticeReminderScheduler? reminderScheduler;
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
        wordCardGenerator:
            widget.wordCardGenerator ?? const MemoryWordCardGenerator(),
        reminderStore: widget.reminderStore ?? MemoryPracticeReminderStore(),
        reminderScheduler: widget.reminderScheduler,
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

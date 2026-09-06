import 'dart:async';

import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../data/deck_repository.dart';
import '../ocr/word_capture_flow.dart';
import '../onboarding/onboarding_models.dart';
import '../onboarding/onboarding_store.dart';
import 'main_shell.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'splash_screen.dart';

class AppEntry extends StatefulWidget {
  const AppEntry({
    super.key,
    required this.authService,
    required this.deckRepository,
    required this.onboardingStore,
    required this.initialOnboardingCompleted,
    this.wordCaptureFlow,
    this.showSplash = true,
    required this.locale,
    required this.themeMode,
    required this.onLocaleChanged,
    required this.onThemeModeChanged,
  });

  final AuthService authService;
  final DeckRepository deckRepository;
  final OnboardingStore onboardingStore;
  final bool initialOnboardingCompleted;
  final WordCaptureFlow? wordCaptureFlow;
  final bool showSplash;
  final Locale? locale;
  final ThemeMode themeMode;
  final ValueChanged<Locale?> onLocaleChanged;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  late bool _splashFinished;
  late bool _onboardingCompleted;
  late AppUser? _user;
  StreamSubscription<AppUser?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _splashFinished = !widget.showSplash;
    _onboardingCompleted = widget.initialOnboardingCompleted;
    _user = widget.authService.currentUser;
    _authSubscription = widget.authService.userChanges.listen((user) {
      if (mounted) setState(() => _user = user);
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _completeOnboarding(OnboardingAnswers answers) async {
    await widget.onboardingStore.complete(answers);
    if (!mounted) return;
    setState(() {
      _onboardingCompleted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget page;
    if (!_splashFinished) {
      page = SplashScreen(
        key: const ValueKey('splash'),
        onFinished: () => setState(() => _splashFinished = true),
      );
    } else if (_user == null) {
      page = LoginScreen(
        key: const ValueKey('login'),
        authService: widget.authService,
      );
    } else if (!_onboardingCompleted) {
      page = OnboardingScreen(
        key: const ValueKey('onboarding'),
        onComplete: _completeOnboarding,
      );
    } else {
      page = MainShell(
        key: const ValueKey('main'),
        repository: widget.deckRepository,
        user: _user!,
        onSignOut: widget.authService.signOut,
        wordCaptureFlow: widget.wordCaptureFlow,
        locale: widget.locale,
        themeMode: widget.themeMode,
        onLocaleChanged: widget.onLocaleChanged,
        onThemeModeChanged: widget.onThemeModeChanged,
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: page,
    );
  }
}

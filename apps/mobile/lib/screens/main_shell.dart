import 'dart:async';

import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../ai/word_card_generator.dart';
import '../data/deck_repository.dart';
import '../data/demo_data.dart';
import '../l10n/app_localizations.dart';
import '../models/card_models.dart';
import '../ocr/word_capture_flow.dart';
import '../reminders/practice_reminder.dart';
import '../widgets/primary_navigation.dart';
import '../widgets/primary_page.dart';
import 'decks_screen.dart';
import 'home_screen.dart';
import 'market_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.repository,
    required this.wordCardGenerator,
    required this.user,
    required this.onSignOut,
    this.wordCaptureFlow,
    required this.locale,
    required this.themeMode,
    required this.onLocaleChanged,
    required this.onThemeModeChanged,
    required this.reminderStore,
    this.reminderScheduler,
  });

  final DeckRepository repository;
  final WordCardGenerator wordCardGenerator;
  final AppUser user;
  final Future<void> Function() onSignOut;
  final WordCaptureFlow? wordCaptureFlow;
  final Locale? locale;
  final ThemeMode themeMode;
  final ValueChanged<Locale?> onLocaleChanged;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final PracticeReminderStore reminderStore;
  final PracticeReminderScheduler? reminderScheduler;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  AppSection _current = AppSection.learn;
  late List<CardDeck> _decks = widget.repository.cachedDecks;
  bool _loading = true;
  String? _error;
  PracticeReminderSettings _reminderSettings = const PracticeReminderSettings();

  @override
  void initState() {
    super.initState();
    unawaited(_loadReminderSettings());
    _refresh();
  }

  Future<void> _loadReminderSettings() async {
    final settings = await widget.reminderStore.load();
    if (!mounted) return;
    setState(() => _reminderSettings = settings);
    await _syncReminder();
  }

  int get _dueCount => _decks.fold(0, (sum, deck) => sum + deck.dueCount());

  ({int count, DateTime? date}) get _nextReminder {
    final now = DateTime.now();
    final dueNow = _dueCount;
    if (dueNow > 0) return (count: dueNow, date: now);
    final scheduled =
        _decks
            .expand((deck) => deck.cards)
            .map((card) => card.dueAt)
            .whereType<DateTime>()
            .where((date) => date.isAfter(now))
            .toList()
          ..sort();
    if (scheduled.isEmpty) return (count: 0, date: null);
    final first = scheduled.first.toLocal();
    final count = scheduled.where((date) {
      final local = date.toLocal();
      return local.year == first.year &&
          local.month == first.month &&
          local.day == first.day;
    }).length;
    return (count: count, date: first);
  }

  Future<void> _syncReminder() async {
    final scheduler = widget.reminderScheduler;
    if (scheduler == null) return;
    final reminder = _nextReminder;
    await scheduler.schedule(
      settings: _reminderSettings,
      dueCount: reminder.count,
      dueDate: reminder.date,
      title: context.l10n.tr('practiceReminderTitle'),
      body: context.l10n.tr('practiceReminderBody', {'count': reminder.count}),
    );
  }

  Future<bool> _setReminderEnabled(bool enabled) async {
    final scheduler = widget.reminderScheduler;
    if (enabled && scheduler != null && !await scheduler.requestPermission()) {
      return false;
    }
    final settings = _reminderSettings.copyWith(enabled: enabled);
    await widget.reminderStore.save(settings);
    if (!mounted) return false;
    setState(() => _reminderSettings = settings);
    await _syncReminder();
    return true;
  }

  Future<void> _setReminderTime(TimeOfDay time) async {
    final settings = _reminderSettings.copyWith(
      hour: time.hour,
      minute: time.minute,
    );
    await widget.reminderStore.save(settings);
    if (!mounted) return;
    setState(() => _reminderSettings = settings);
    await _syncReminder();
  }

  Future<void> _refresh() async {
    try {
      await widget.repository.ensureStarterDecks(DemoData.decks);
      final decks = await widget.repository.listDecks();
      if (mounted) {
        setState(() => _decks = decks);
        await _syncReminder();
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createCapturedWordDeck(
    String title,
    List<String> sourceWords,
    List<WordCardDraft> cards,
  ) async {
    await widget.repository.createCapturedWordDeck(
      title: title,
      sourceWords: sourceWords,
      cards: cards,
    );
    await _refresh();
  }

  Future<List<CardScheduleUpdate>> _recordAttempts(
    CardDeck deck,
    List<CardAttempt> attempts,
  ) async {
    final updates = await widget.repository.recordAttempts(deck.id, attempts);
    unawaited(_refresh());
    return updates;
  }

  Future<void> _appendGeneratedCards(
    CardDeck deck,
    List<WordCardDraft> drafts,
  ) async {
    await widget.repository.appendGeneratedCards(deck.id, drafts);
    await _refresh();
  }

  Future<void> _openMarket() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MarketScreen(
          onAddDeck: (slug) async {
            final result = await widget.repository.addMarketDeck(slug);
            await _refresh();
            return result;
          },
        ),
      ),
    );
    await _refresh();
  }

  void _select(AppSection section) {
    if (section == _current) return;
    setState(() => _current = section);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _decks.isEmpty) {
      return const PrimaryPage(
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF33CFB4)),
        ),
      );
    }
    if (_error != null && _decks.isEmpty) {
      return PrimaryPage(
        child: Center(
          child: FilledButton(onPressed: _refresh, child: const Text('Retry')),
        ),
      );
    }
    return Stack(
      children: [
        IndexedStack(
          index: _current.index,
          children: [
            HomeScreen(
              decks: _decks,
              wordCaptureFlow: widget.wordCaptureFlow,
              wordCardGenerator: widget.wordCardGenerator,
              onCreateCapturedDeck: _createCapturedWordDeck,
              onAttemptsCompleted: _recordAttempts,
              onAppendGeneratedCards: _appendGeneratedCards,
            ),
            DecksScreen(
              decks: _decks,
              onAttemptsCompleted: _recordAttempts,
              wordCardGenerator: widget.wordCardGenerator,
              onAppendGeneratedCards: _appendGeneratedCards,
              onOpenMarket: _openMarket,
            ),
            ProfileScreen(
              decks: _decks,
              user: widget.user,
              onSignOut: widget.onSignOut,
              locale: widget.locale,
              themeMode: widget.themeMode,
              onLocaleChanged: widget.onLocaleChanged,
              onThemeModeChanged: widget.onThemeModeChanged,
              reminderSettings: _reminderSettings,
              onReminderEnabledChanged: _setReminderEnabled,
              onReminderTimeChanged: _setReminderTime,
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: PrimaryNavigationDock(current: _current, onSelected: _select),
        ),
      ],
    );
  }
}

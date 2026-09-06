import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../data/deck_repository.dart';
import '../data/demo_data.dart';
import '../models/card_models.dart';
import '../ocr/word_capture_flow.dart';
import '../widgets/primary_navigation.dart';
import 'decks_screen.dart';
import 'home_screen.dart';
import 'market_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.repository,
    required this.user,
    required this.onSignOut,
    this.wordCaptureFlow,
    required this.locale,
    required this.themeMode,
    required this.onLocaleChanged,
    required this.onThemeModeChanged,
  });

  final DeckRepository repository;
  final AppUser user;
  final Future<void> Function() onSignOut;
  final WordCaptureFlow? wordCaptureFlow;
  final Locale? locale;
  final ThemeMode themeMode;
  final ValueChanged<Locale?> onLocaleChanged;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  AppSection _current = AppSection.learn;
  late List<CardDeck> _decks = widget.repository.cachedDecks;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      await widget.repository.ensureStarterDecks(DemoData.decks);
      final decks = await widget.repository.listDecks();
      if (mounted) setState(() => _decks = decks);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createDeckFromWords(List<String> words) async {
    final cards = words
        .map(
          (word) => StudyCard(
            id: word,
            prompt: word,
            sections: const [
              CardBackSection(
                title: '核心释义',
                heading: 'Add a meaning',
                body: 'Created from on-device text recognition.',
              ),
            ],
          ),
        )
        .toList(growable: false);
    await widget.repository.createDeck(
      title: 'Captured words',
      subtitle: '${words.length} cards',
      kind: CardKind.word,
      cards: cards,
    );
    await _refresh();
  }

  Future<void> _recordAttempts(
    CardDeck deck,
    List<CardAttempt> attempts,
  ) async {
    await widget.repository.recordAttempts(deck.id, attempts);
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
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF33CFB4)),
        ),
      );
    }
    if (_error != null && _decks.isEmpty) {
      return Scaffold(
        body: Center(
          child: FilledButton(onPressed: _refresh, child: const Text('Retry')),
        ),
      );
    }
    return IndexedStack(
      index: _current.index,
      children: [
        HomeScreen(
          decks: _decks,
          wordCaptureFlow: widget.wordCaptureFlow,
          onCreateDeckFromWords: _createDeckFromWords,
          onAttemptsCompleted: _recordAttempts,
          onTabSelected: _select,
        ),
        DecksScreen(
          decks: _decks,
          onTabSelected: _select,
          onAttemptsCompleted: _recordAttempts,
          onOpenMarket: _openMarket,
        ),
        ProfileScreen(
          decks: _decks,
          user: widget.user,
          onSignOut: widget.onSignOut,
          onTabSelected: _select,
          locale: widget.locale,
          themeMode: widget.themeMode,
          onLocaleChanged: widget.onLocaleChanged,
          onThemeModeChanged: widget.onThemeModeChanged,
        ),
      ],
    );
  }
}

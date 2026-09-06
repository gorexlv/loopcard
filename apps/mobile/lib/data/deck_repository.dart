import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/card_models.dart';

enum MarketAddResult { added, alreadyAdded }

abstract interface class DeckRepository {
  List<CardDeck> get cachedDecks;
  Future<List<CardDeck>> listDecks();
  Future<void> ensureStarterDecks(List<CardDeck> decks);
  Future<CardDeck> createDeck({
    required String title,
    String subtitle,
    CardKind kind,
    List<StudyCard> cards,
  });
  Future<MarketAddResult> addMarketDeck(String slug);
  Future<void> recordAttempts(String deckId, List<CardAttempt> attempts);
}

class SupabaseDeckRepository implements DeckRepository {
  SupabaseDeckRepository(this._client);

  final SupabaseClient _client;
  List<CardDeck> _cache = const [];

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthException('Authentication required');
    return id;
  }

  @override
  List<CardDeck> get cachedDecks => _cache;

  @override
  Future<List<CardDeck>> listDecks() async {
    const selection =
        'id,title,subtitle,kind,updated_at,'
        'cards(id,prompt,position,card_sections(id,title,heading,body,position)),'
        'practice_attempts(card_id,familiarity,practiced_at)';
    final ownedRows = await _client
        .from('decks')
        .select(selection)
        .eq('user_id', _userId)
        .order('updated_at', ascending: false);
    final libraryRows = await _client
        .from('deck_library')
        .select('added_at,decks($selection)')
        .eq('user_id', _userId)
        .order('added_at', ascending: false);
    final rows = <Map<String, dynamic>>[
      ...(ownedRows as List).cast<Map<String, dynamic>>(),
      for (final row in (libraryRows as List).cast<Map<String, dynamic>>())
        if (row['decks'] case final Map<String, dynamic> deck) deck,
    ];
    _cache = rows.map(_deckFromJson).toList(growable: false);
    return _cache;
  }

  @override
  Future<MarketAddResult> addMarketDeck(String slug) async {
    final response = await _client.rpc(
      'add_market_deck',
      params: {'deck_slug': slug},
    );
    final rows = (response as List).cast<Map<String, dynamic>>();
    if (rows.isEmpty) {
      throw const PostgrestException(message: 'Empty import response');
    }
    return rows.single['status'] == 'already_added'
        ? MarketAddResult.alreadyAdded
        : MarketAddResult.added;
  }

  CardDeck _deckFromJson(Map<String, dynamic> json) {
    final rawCards =
        (json['cards'] as List? ?? const []).cast<Map<String, dynamic>>()..sort(
          (a, b) => (a['position'] as int).compareTo(b['position'] as int),
        );
    final cards = rawCards
        .map((card) {
          final rawSections =
              (card['card_sections'] as List? ?? const [])
                  .cast<Map<String, dynamic>>()
                ..sort(
                  (a, b) =>
                      (a['position'] as int).compareTo(b['position'] as int),
                );
          return StudyCard(
            id: card['id'] as String,
            prompt: card['prompt'] as String,
            sections: rawSections
                .map(
                  (section) => CardBackSection(
                    title: section['title'] as String,
                    heading: section['heading'] as String? ?? '',
                    body: section['body'] as String? ?? '',
                  ),
                )
                .toList(growable: false),
          );
        })
        .toList(growable: false);

    final latest = <String, Map<String, dynamic>>{};
    for (final attempt
        in (json['practice_attempts'] as List? ?? const [])
            .cast<Map<String, dynamic>>()) {
      final cardId = attempt['card_id'] as String;
      final existing = latest[cardId];
      if (existing == null ||
          (attempt['practiced_at'] as String).compareTo(
                existing['practiced_at'] as String,
              ) >
              0) {
        latest[cardId] = attempt;
      }
    }
    int count(String value) =>
        latest.values.where((row) => row['familiarity'] == value).length;
    final kindName = json['kind'] as String? ?? 'generic';
    final kind =
        CardKind.values.where((value) => value.name == kindName).firstOrNull ??
        CardKind.word;
    return CardDeck(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      kind: kind,
      cards: cards,
      mastered: count('mastered'),
      fuzzy: count('fuzzy'),
      forgotten: count('forgotten'),
    );
  }

  @override
  Future<void> ensureStarterDecks(List<CardDeck> decks) async {
    final existing = await _client
        .from('decks')
        .select('id')
        .eq('user_id', _userId)
        .limit(1);
    if ((existing as List).isNotEmpty) return;
    for (final deck in decks) {
      await createDeck(
        title: deck.title,
        subtitle: deck.subtitle,
        kind: deck.kind,
        cards: deck.cards,
      );
    }
  }

  @override
  Future<CardDeck> createDeck({
    required String title,
    String subtitle = '',
    CardKind kind = CardKind.word,
    List<StudyCard> cards = const [],
  }) async {
    final deck = await _client
        .from('decks')
        .insert({
          'user_id': _userId,
          'title': title,
          'subtitle': subtitle,
          'kind': kind.name,
        })
        .select('id')
        .single();
    final deckId = deck['id'] as String;
    if (cards.isNotEmpty) {
      final insertedCards = await _client
          .from('cards')
          .insert([
            for (var index = 0; index < cards.length; index++)
              {
                'user_id': _userId,
                'deck_id': deckId,
                'prompt': cards[index].prompt,
                'position': index,
              },
          ])
          .select('id,position');
      final idsByPosition = {
        for (final row in (insertedCards as List).cast<Map<String, dynamic>>())
          row['position'] as int: row['id'] as String,
      };
      final sections = <Map<String, dynamic>>[];
      for (var cardIndex = 0; cardIndex < cards.length; cardIndex++) {
        for (
          var sectionIndex = 0;
          sectionIndex < cards[cardIndex].sections.length;
          sectionIndex++
        ) {
          final section = cards[cardIndex].sections[sectionIndex];
          sections.add({
            'user_id': _userId,
            'card_id': idsByPosition[cardIndex],
            'title': section.title,
            'heading': section.heading,
            'body': section.body,
            'position': sectionIndex,
          });
        }
      }
      if (sections.isNotEmpty) {
        await _client.from('card_sections').insert(sections);
      }
    }
    final refreshed = await listDecks();
    return refreshed.firstWhere((value) => value.id == deckId);
  }

  @override
  Future<void> recordAttempts(String deckId, List<CardAttempt> attempts) async {
    if (attempts.isEmpty) return;
    await _client.from('practice_attempts').insert([
      for (final attempt in attempts)
        {
          'user_id': _userId,
          'deck_id': deckId,
          'card_id': attempt.cardId,
          'familiarity': attempt.familiarity.name,
        },
    ]);
  }
}

class MemoryDeckRepository implements DeckRepository {
  MemoryDeckRepository([List<CardDeck> decks = const []]) : _decks = [...decks];

  final List<CardDeck> _decks;
  final Set<String> _marketDecks = {};

  @override
  Future<MarketAddResult> addMarketDeck(String slug) async =>
      _marketDecks.add(slug)
      ? MarketAddResult.added
      : MarketAddResult.alreadyAdded;

  @override
  List<CardDeck> get cachedDecks => List.unmodifiable(_decks);

  @override
  Future<List<CardDeck>> listDecks() async => cachedDecks;

  @override
  Future<void> ensureStarterDecks(List<CardDeck> decks) async {
    if (_decks.isEmpty) _decks.addAll(decks);
  }

  @override
  Future<CardDeck> createDeck({
    required String title,
    String subtitle = '',
    CardKind kind = CardKind.word,
    List<StudyCard> cards = const [],
  }) async {
    final deck = CardDeck(
      id: 'memory-${_decks.length + 1}',
      title: title,
      subtitle: subtitle,
      kind: kind,
      cards: cards,
      mastered: 0,
      fuzzy: 0,
      forgotten: 0,
    );
    _decks.add(deck);
    return deck;
  }

  @override
  Future<void> recordAttempts(
    String deckId,
    List<CardAttempt> attempts,
  ) async {}
}

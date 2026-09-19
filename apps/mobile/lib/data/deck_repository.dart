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
  Future<CardDeck> createCapturedWordDeck({
    required String title,
    required List<String> sourceWords,
    required List<WordCardDraft> cards,
  });
  Future<int> appendGeneratedCards(String deckId, List<WordCardDraft> cards);
  Future<MarketAddResult> addMarketDeck(String slug);
  Future<List<CardScheduleUpdate>> recordAttempts(
    String deckId,
    List<CardAttempt> attempts,
  );
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
    try {
      return await _listDecks(includeWordData: true);
    } on PostgrestException catch (error) {
      final missingWordData =
          error.code == '42703' || error.message.contains('word_data');
      if (!missingWordData) rethrow;
      return _listDecks(includeWordData: false);
    }
  }

  Future<List<CardDeck>> _listDecks({required bool includeWordData}) async {
    final selection =
        'id,title,subtitle,kind,updated_at,'
        'cards(id,prompt,hint,position,source_type,'
        '${includeWordData ? 'word_data,presentation,' : ''}'
        'card_sections(id,title,heading,body,position),'
        'card_memory_states(due_at,interval_days,review_count,lapse_count,'
        'mastery_streak,last_familiarity,last_reviewed_at)),'
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
            hint: card['hint'] as String?,
            presentation: Map<String, dynamic>.from(
              card['presentation'] as Map? ?? {},
            ),
            wordContent: card['word_data'] is Map
                ? WordCardContent.fromJson(
                    (card['word_data'] as Map).cast<String, dynamic>(),
                  )
                : null,
            sections: rawSections
                .map(
                  (section) => CardBackSection(
                    title: section['title'] as String,
                    heading: section['heading'] as String? ?? '',
                    body: section['body'] as String? ?? '',
                  ),
                )
                .toList(growable: false),
            dueAt: _memoryRow(card)?['due_at'] == null
                ? null
                : DateTime.parse(_memoryRow(card)!['due_at'] as String),
            intervalDays: _memoryRow(card)?['interval_days'] as int? ?? 0,
            reviewCount: _memoryRow(card)?['review_count'] as int? ?? 0,
            lapseCount: _memoryRow(card)?['lapse_count'] as int? ?? 0,
            masteryStreak: _memoryRow(card)?['mastery_streak'] as int? ?? 0,
            lastFamiliarity: _familiarityFromName(
              _memoryRow(card)?['last_familiarity'] as String?,
            ),
            sourceType: card['source_type'] as String? ?? 'manual',
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

  Map<String, dynamic>? _memoryRow(Map<String, dynamic> card) {
    final rows = (card['card_memory_states'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    return rows.firstOrNull;
  }

  Familiarity? _familiarityFromName(String? name) => switch (name) {
    'mastered' => Familiarity.mastered,
    'fuzzy' => Familiarity.fuzzy,
    'forgotten' => Familiarity.forgotten,
    _ => null,
  };

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
      final cardRows = [
        for (var index = 0; index < cards.length; index++)
          {
            'user_id': _userId,
            'deck_id': deckId,
            'prompt': cards[index].prompt,
            'hint': cards[index].hint ?? '',
            if (cards[index].wordContent case final content?)
              'word_data': content.toJson(),
            'position': index,
          },
      ];
      dynamic insertedCards;
      try {
        insertedCards = await _client
            .from('cards')
            .insert(cardRows)
            .select('id,position');
      } on PostgrestException catch (error) {
        final missingWordData =
            error.code == '42703' || error.message.contains('word_data');
        if (!missingWordData) rethrow;
        insertedCards = await _client
            .from('cards')
            .insert([
              for (final row in cardRows)
                Map<String, dynamic>.from(row)..remove('word_data'),
            ])
            .select('id,position');
      }
      final idsByPosition = {
        for (final row in (insertedCards as List).cast<Map<String, dynamic>>())
          row['position'] as int: row['id'] as String,
      };
      final sections = <Map<String, dynamic>>[];
      for (var cardIndex = 0; cardIndex < cards.length; cardIndex++) {
        for (
          var sectionIndex = 0;
          sectionIndex < cards[cardIndex].learningSections.length;
          sectionIndex++
        ) {
          final section = cards[cardIndex].learningSections[sectionIndex];
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
  Future<CardDeck> createCapturedWordDeck({
    required String title,
    required List<String> sourceWords,
    required List<WordCardDraft> cards,
  }) async {
    final deckId =
        await _client.rpc(
              cards.isNotEmpty && cards.first.presentation.isNotEmpty
                  ? 'create_agent_deck'
                  : 'create_captured_word_deck',
              params: {
                'input_title': title,
                if (cards.isNotEmpty && cards.first.presentation.isNotEmpty)
                  'input_session_id': cards.first.presentation['session_id'],
                'input_source_excerpt': sourceWords.join(' '),
                'input_cards': [for (final card in cards) _draftJson(card)],
              },
            )
            as String;
    final refreshed = await listDecks();
    return refreshed.firstWhere((value) => value.id == deckId);
  }

  @override
  Future<int> appendGeneratedCards(
    String deckId,
    List<WordCardDraft> cards,
  ) async {
    if (cards.isEmpty) return 0;
    final result = await _client.rpc(
      'append_generated_cards',
      params: {
        'input_deck_id': deckId,
        'input_cards': [for (final card in cards) _draftJson(card)],
      },
    );
    await listDecks();
    return result as int;
  }

  Map<String, dynamic> _draftJson(WordCardDraft card) => {
    'prompt': card.prompt,
    'hint': card.hint,
    if (card.presentation.isNotEmpty) 'presentation': card.presentation,
    'sections': [
      for (final section in card.learningSections)
        {
          'title': section.title,
          'heading': section.heading,
          'body': section.body,
        },
    ],
    if (card.wordContent case final content?) 'word_data': content.toJson(),
    'parent_card_id': ?card.parentCardId,
    'relation_type': ?card.relationType?.name,
    if (card.reason.isNotEmpty) 'reason': card.reason,
  };

  @override
  Future<List<CardScheduleUpdate>> recordAttempts(
    String deckId,
    List<CardAttempt> attempts,
  ) async {
    if (attempts.isEmpty) return const [];
    final response = await _client.rpc(
      'record_practice_attempts',
      params: {
        'input_deck_id': deckId,
        'input_attempts': [
          for (final attempt in attempts)
            {
              'card_id': attempt.cardId,
              'familiarity': attempt.familiarity.name,
              'assistance_used': attempt.assistanceUsed,
            },
        ],
      },
    );
    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(
          (row) => CardScheduleUpdate(
            cardId: row['card_id'] as String,
            dueAt: DateTime.parse(row['due_at'] as String),
            intervalDays: row['interval_days'] as int,
          ),
        )
        .toList(growable: false);
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
  Future<CardDeck> createCapturedWordDeck({
    required String title,
    required List<String> sourceWords,
    required List<WordCardDraft> cards,
  }) async {
    final session = cards.isEmpty
        ? null
        : cards.first.presentation['session_id'];
    if (session != null) {
      for (final deck in _decks) {
        if (deck.cards.isNotEmpty &&
            deck.cards.first.presentation['session_id'] == session) {
          return deck;
        }
      }
    }
    return createDeck(
      title: title,
      subtitle: '${cards.length} AI-reviewed cards',
      kind: cardKindForGenerationSkill(
        cards.isEmpty ? null : cards.first.presentation['skill'] as String?,
      ),
      cards: [
        for (var index = 0; index < cards.length; index++)
          StudyCard(
            id: 'memory-card-${_decks.length + 1}-$index',
            prompt: cards[index].prompt,
            hint: cards[index].hint,
            sections: cards[index].sections,
            wordContent: cards[index].wordContent,
            presentation: cards[index].presentation,
            sourceType: 'capture',
          ),
      ],
    );
  }

  @override
  Future<int> appendGeneratedCards(
    String deckId,
    List<WordCardDraft> cards,
  ) async {
    final index = _decks.indexWhere((deck) => deck.id == deckId);
    if (index < 0) throw StateError('Deck not found');
    final deck = _decks[index];
    final appended = [
      ...deck.cards,
      for (var offset = 0; offset < cards.length; offset++)
        StudyCard(
          id: 'memory-extension-${deck.cards.length + offset}',
          prompt: cards[offset].prompt,
          hint: cards[offset].hint,
          sections: cards[offset].sections,
          wordContent: cards[offset].wordContent,
          sourceType: 'ai_extension',
        ),
    ];
    _decks[index] = deck.copyWith(cards: appended);
    return cards.length;
  }

  @override
  Future<List<CardScheduleUpdate>> recordAttempts(
    String deckId,
    List<CardAttempt> attempts,
  ) async {
    final deckIndex = _decks.indexWhere((deck) => deck.id == deckId);
    if (deckIndex < 0) return const [];
    final now = DateTime.now();
    final updates = <CardScheduleUpdate>[];
    final attemptsByCard = {
      for (final attempt in attempts) attempt.cardId: attempt,
    };
    final cards = [
      for (final card in _decks[deckIndex].cards)
        if (attemptsByCard[card.id] case final attempt?)
          () {
            final schedule = MemoryScheduler.next(
              familiarity: attempt.familiarity,
              now: now,
              previousIntervalDays: card.intervalDays,
            );
            updates.add(
              CardScheduleUpdate(
                cardId: card.id,
                dueAt: schedule.dueAt,
                intervalDays: schedule.intervalDays,
              ),
            );
            return card.copyWith(
              dueAt: schedule.dueAt,
              intervalDays: schedule.intervalDays,
              reviewCount: card.reviewCount + 1,
              lapseCount:
                  card.lapseCount +
                  (attempt.familiarity == Familiarity.forgotten ? 1 : 0),
              masteryStreak: attempt.familiarity == Familiarity.mastered
                  ? card.masteryStreak + 1
                  : 0,
              lastFamiliarity: attempt.familiarity,
            );
          }()
        else
          card,
    ];
    _decks[deckIndex] = _decks[deckIndex].copyWith(cards: cards);
    return updates;
  }
}

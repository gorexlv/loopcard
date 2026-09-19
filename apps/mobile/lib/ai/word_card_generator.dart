import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/card_models.dart';
import 'card_agent.dart';

class WordCardGenerationException implements Exception {
  const WordCardGenerationException(this.code, {this.retryable = true});

  final String code;
  final bool retryable;

  @override
  String toString() => 'WordCardGenerationException($code)';
}

abstract interface class WordCardGenerator {
  Future<List<WordCardDraft>> generateWords(
    List<String> words, {
    String outputLocale = 'en',
  });
  Future<List<WordCardDraft>> suggestExtensions(
    List<StudyCard> weakCards,
    Map<String, Familiarity> familiarities, {
    String outputLocale = 'en',
  });
}

class SupabaseWordCardGenerator implements WordCardGenerator {
  const SupabaseWordCardGenerator(this._client);

  final SupabaseClient _client;
  CardAgent get cardAgent => SupabaseCardAgent(_client);

  @override
  Future<List<WordCardDraft>> generateWords(
    List<String> words, {
    String outputLocale = 'en',
  }) => _invoke({
    'operation': 'generate_word_cards',
    'words': words,
    'output_locale': outputLocale,
  });

  @override
  Future<List<WordCardDraft>> suggestExtensions(
    List<StudyCard> weakCards,
    Map<String, Familiarity> familiarities, {
    String outputLocale = 'en',
  }) => _invoke({
    'operation': 'suggest_extensions',
    'output_locale': outputLocale,
    'weak_cards': [
      for (final card in weakCards.take(3))
        {
          'id': card.id,
          'prompt': card.prompt,
          'familiarity': familiarities[card.id]?.name ?? 'fuzzy',
          'sections': [
            for (final section in card.learningSections)
              {
                'title': section.title,
                'heading': section.heading,
                'body': section.body,
              },
          ],
          if (card.wordContent case final content?)
            'word_data': content.toJson(),
        },
    ],
  });

  Future<List<WordCardDraft>> _invoke(Map<String, dynamic> body) async {
    try {
      final response = await _client.functions.invoke(
        'generate-word-cards',
        body: body,
      );
      if (response.status != 200 || response.data is! Map) {
        throw WordCardGenerationException(
          'provider_error',
          retryable: response.status != 503,
        );
      }
      final payload = (response.data as Map).cast<String, dynamic>();
      final rows = (payload['cards'] as List? ?? const [])
          .cast<Map<String, dynamic>>();
      if (rows.isEmpty) {
        throw const WordCardGenerationException('empty_generation');
      }
      return rows.map(_draftFromJson).toList(growable: false);
    } on WordCardGenerationException {
      rethrow;
    } on FunctionException catch (error) {
      final details = error.details;
      final code = details is Map ? details['error'] as String? : null;
      final retryable = details is Map ? details['retryable'] != false : true;
      throw WordCardGenerationException(
        code ?? 'generation_failed',
        retryable: retryable,
      );
    } catch (_) {
      throw const WordCardGenerationException('generation_failed');
    }
  }

  WordCardDraft _draftFromJson(Map<String, dynamic> json) {
    final relationName = json['relation_type'] as String?;
    final rawWordData = json['word_data'];
    return WordCardDraft(
      prompt: json['prompt'] as String,
      hint: json['hint'] as String? ?? '',
      sections: (json['sections'] as List)
          .cast<Map<String, dynamic>>()
          .map(
            (section) => CardBackSection(
              title: section['title'] as String,
              heading: section['heading'] as String,
              body: section['body'] as String,
            ),
          )
          .toList(growable: false),
      wordContent: rawWordData is Map
          ? WordCardContent.fromJson(rawWordData.cast<String, dynamic>())
          : null,
      parentCardId: (json['parent_card_id'] as String?)?.isEmpty ?? true
          ? null
          : json['parent_card_id'] as String,
      relationType: relationName == null || relationName == 'none'
          ? null
          : CardRelationType.values.firstWhere(
              (value) => value.name == relationName,
            ),
      reason: json['reason'] as String? ?? '',
    );
  }
}

class MemoryWordCardGenerator implements WordCardGenerator {
  const MemoryWordCardGenerator();

  static const _known = <String, List<CardBackSection>>{
    'borrow': [
      CardBackSection(
        title: 'Meaning',
        heading: 'v. take and use temporarily',
        body: 'Use something with the intention of returning it.',
      ),
      CardBackSection(
        title: 'Example & collocation',
        heading: 'borrow a book',
        body: 'May I borrow this book for the weekend?',
      ),
      CardBackSection(
        title: 'Common confusion',
        heading: 'borrow vs. lend',
        body: 'You borrow from someone; they lend something to you.',
      ),
    ],
    'retain': [
      CardBackSection(
        title: 'Meaning',
        heading: 'v. continue to have',
        body: 'Keep possession, memory, or control of something.',
      ),
      CardBackSection(
        title: 'Example & collocation',
        heading: 'retain information',
        body: 'Short reviews help you retain new information.',
      ),
    ],
    'lend': [
      CardBackSection(
        title: 'Meaning',
        heading: 'v. give temporarily',
        body: 'Let someone use something that you expect to get back.',
      ),
      CardBackSection(
        title: 'Example & collocation',
        heading: 'lend a hand',
        body: 'Could you lend me a hand with these boxes?',
      ),
      CardBackSection(
        title: 'Common confusion',
        heading: 'lend vs. borrow',
        body: 'You lend to someone; they borrow from you.',
      ),
    ],
  };

  static const _knownContent = <String, WordCardContent>{
    'borrow': WordCardContent(
      partOfSpeech: 'v.',
      pronunciations: [
        WordPronunciation(region: 'UK', ipa: '/ˈbɒrəʊ/'),
        WordPronunciation(region: 'US', ipa: '/ˈbɔːroʊ/'),
      ],
      definition: '借入；借用',
      englishDefinition: 'to take and use something that you will return',
      usagePatterns: ['borrow something from someone'],
      example: WordExample(
        sentence: 'May I borrow this book for the weekend?',
        translation: '这本书我可以借一个周末吗？',
      ),
      collocations: ['borrow a book', 'borrow money'],
      confusion: WordNote(
        heading: 'borrow vs. lend',
        body: 'You borrow from someone; they lend something to you.',
      ),
    ),
    'retain': WordCardContent(
      partOfSpeech: 'v.',
      pronunciations: [WordPronunciation(ipa: '/rɪˈteɪn/')],
      definition: '保留；保持',
      englishDefinition: 'to continue to have or keep something',
      usagePatterns: ['retain information'],
      example: WordExample(
        sentence: 'Short reviews help you retain new information.',
        translation: '短时复习有助于保留新信息。',
      ),
      collocations: ['retain control', 'retain information'],
    ),
    'lend': WordCardContent(
      partOfSpeech: 'v.',
      pronunciations: [WordPronunciation(ipa: '/lend/')],
      forms: ['past / past participle: lent'],
      definition: '借给；借出',
      englishDefinition: 'to give something temporarily to someone',
      usagePatterns: ['lend something to someone', 'lend someone something'],
      example: WordExample(
        sentence: 'Could you lend me a pen?',
        translation: '你能借给我一支笔吗？',
      ),
      collocations: ['lend a hand', 'lend money'],
      confusion: WordNote(
        heading: 'lend vs. borrow',
        body: 'You lend to someone; they borrow from you.',
      ),
    ),
  };

  @override
  Future<List<WordCardDraft>> generateWords(
    List<String> words, {
    String outputLocale = 'en',
  }) async {
    if (words.any((word) => !_known.containsKey(word.toLowerCase()))) {
      throw const WordCardGenerationException(
        'demo_dictionary_missing',
        retryable: false,
      );
    }
    return [
      for (final word in words)
        WordCardDraft(
          prompt: word,
          hint:
              'Starts with ${word.substring(0, 1).toUpperCase()} · '
              '${word.length} letters',
          sections: _known[word.toLowerCase()]!,
          wordContent: _knownContent[word.toLowerCase()],
        ),
    ];
  }

  @override
  Future<List<WordCardDraft>> suggestExtensions(
    List<StudyCard> weakCards,
    Map<String, Familiarity> familiarities, {
    String outputLocale = 'en',
  }) async => const [];
}

enum CardKind { word, formula, problem }

CardKind cardKindForGenerationSkill(String? skill) => switch (skill) {
  'knowledge' || 'poetry' || 'classical' => CardKind.problem,
  _ => CardKind.word,
};

enum Familiarity { mastered, fuzzy, forgotten }

enum MemoryStability { unseen, building, stable, consolidated }

enum DeckLearningStage { notStarted, learning, reinforcing, mastered, fluent }

extension DeckLearningStageKey on DeckLearningStage {
  String get localizationKey => switch (this) {
    DeckLearningStage.notStarted => 'deckStageNotStarted',
    DeckLearningStage.learning => 'deckStageLearning',
    DeckLearningStage.reinforcing => 'deckStageReinforcing',
    DeckLearningStage.mastered => 'deckStageMastered',
    DeckLearningStage.fluent => 'deckStageFluent',
  };
}

enum CardRelationType {
  prerequisite,
  contrast,
  application,
  collocation,
  synonym,
}

class CardBackSection {
  const CardBackSection({
    required this.title,
    required this.heading,
    required this.body,
  });

  final String title;
  final String heading;
  final String body;
}

class WordPronunciation {
  const WordPronunciation({required this.ipa, this.region = ''});

  final String ipa;
  final String region;

  factory WordPronunciation.fromJson(Map<String, dynamic> json) =>
      WordPronunciation(
        ipa: json['ipa'] as String? ?? '',
        region: json['region'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'ipa': ipa,
    if (region.isNotEmpty) 'region': region,
  };
}

class WordExample {
  const WordExample({required this.sentence, required this.translation});

  final String sentence;
  final String translation;

  factory WordExample.fromJson(Map<String, dynamic> json) => WordExample(
    sentence: json['sentence'] as String? ?? '',
    translation: json['translation'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'sentence': sentence,
    'translation': translation,
  };
}

class WordNote {
  const WordNote({required this.heading, required this.body});

  final String heading;
  final String body;

  factory WordNote.fromJson(Map<String, dynamic> json) => WordNote(
    heading: json['heading'] as String? ?? '',
    body: json['body'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {'heading': heading, 'body': body};
}

/// Structured learning content for one lemma, one part of speech, and one
/// target sense. Generic [CardBackSection] data remains available as a legacy
/// fallback for cards created before this schema existed.
class WordCardContent {
  const WordCardContent({
    required this.partOfSpeech,
    required this.definition,
    required this.example,
    this.pronunciations = const [],
    this.forms = const [],
    this.englishDefinition = '',
    this.usagePatterns = const [],
    this.collocations = const [],
    this.confusion,
    this.extension,
  });

  final String partOfSpeech;
  final List<WordPronunciation> pronunciations;
  final List<String> forms;
  final String definition;
  final String englishDefinition;
  final List<String> usagePatterns;
  final WordExample example;
  final List<String> collocations;
  final WordNote? confusion;
  final WordNote? extension;

  factory WordCardContent.fromJson(Map<String, dynamic> json) {
    List<String> strings(String key) => (json[key] as List? ?? const [])
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    WordNote? note(String key) {
      final value = json[key];
      if (value is! Map) return null;
      final parsed = WordNote.fromJson(value.cast<String, dynamic>());
      return parsed.heading.trim().isEmpty || parsed.body.trim().isEmpty
          ? null
          : parsed;
    }

    final rawExample = json['example'];
    return WordCardContent(
      partOfSpeech: json['part_of_speech'] as String? ?? '',
      pronunciations: (json['pronunciations'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (value) =>
                WordPronunciation.fromJson(value.cast<String, dynamic>()),
          )
          .where((value) => value.ipa.trim().isNotEmpty)
          .toList(growable: false),
      forms: strings('forms'),
      definition: json['definition'] as String? ?? '',
      englishDefinition: json['english_definition'] as String? ?? '',
      usagePatterns: strings('usage_patterns'),
      example: rawExample is Map
          ? WordExample.fromJson(rawExample.cast<String, dynamic>())
          : const WordExample(sentence: '', translation: ''),
      collocations: strings('collocations'),
      confusion: note('confusion'),
      extension: note('extension'),
    );
  }

  Map<String, dynamic> toJson() => {
    'part_of_speech': partOfSpeech,
    'pronunciations': [for (final value in pronunciations) value.toJson()],
    'forms': forms,
    'definition': definition,
    'english_definition': englishDefinition,
    'usage_patterns': usagePatterns,
    'example': example.toJson(),
    'collocations': collocations,
    if (confusion case final value?) 'confusion': value.toJson(),
    if (extension case final value?) 'extension': value.toJson(),
  };

  List<CardBackSection> get sections => [
    CardBackSection(
      title: 'Meaning',
      heading: definition,
      body: [
        if (englishDefinition.isNotEmpty) englishDefinition,
        ...usagePatterns,
      ].join('\n'),
    ),
    CardBackSection(
      title: 'Example & collocation',
      heading: example.sentence,
      body: [example.translation, ...collocations].join('\n'),
    ),
    if (confusion case final value?)
      CardBackSection(
        title: 'Common confusion',
        heading: value.heading,
        body: value.body,
      ),
    if (extension case final value?)
      CardBackSection(
        title: 'Extension',
        heading: value.heading,
        body: value.body,
      ),
  ];

  /// Reading pages are separate from the persisted/exported sections contract.
  List<CardBackSection> get reviewSections => [
    CardBackSection(
      title: 'Word overview',
      heading: definition,
      body: [
        englishDefinition,
        example.sentence,
        example.translation,
        ...usagePatterns,
      ].where((s) => s.isNotEmpty).join('\n'),
    ),
    if (collocations.isNotEmpty || forms.isNotEmpty)
      CardBackSection(
        title: 'Word usage',
        heading: '',
        body: [...collocations, ...forms].join('\n'),
      ),
    if (confusion case final value?)
      CardBackSection(
        title: 'Common confusion',
        heading: value.heading,
        body: value.body,
      ),
    if (extension case final value?)
      CardBackSection(
        title: 'Extension',
        heading: value.heading,
        body: value.body,
      ),
  ];

  WordCardContent copyWith({
    String? partOfSpeech,
    List<WordPronunciation>? pronunciations,
    List<String>? forms,
    String? definition,
    String? englishDefinition,
    List<String>? usagePatterns,
    WordExample? example,
    List<String>? collocations,
    WordNote? confusion,
    WordNote? extension,
  }) => WordCardContent(
    partOfSpeech: partOfSpeech ?? this.partOfSpeech,
    pronunciations: pronunciations ?? this.pronunciations,
    forms: forms ?? this.forms,
    definition: definition ?? this.definition,
    englishDefinition: englishDefinition ?? this.englishDefinition,
    usagePatterns: usagePatterns ?? this.usagePatterns,
    example: example ?? this.example,
    collocations: collocations ?? this.collocations,
    confusion: confusion ?? this.confusion,
    extension: extension ?? this.extension,
  );
}

class StudyCard {
  const StudyCard({
    required this.id,
    required this.prompt,
    required this.sections,
    this.eyebrow,
    this.supportingText,
    this.hint,
    this.wordContent,
    this.dueAt,
    this.intervalDays = 0,
    this.reviewCount = 0,
    this.lapseCount = 0,
    this.masteryStreak = 0,
    this.lastFamiliarity,
    this.sourceType = 'manual',
    this.presentation = const {},
  });

  final String id;
  final String prompt;
  final List<CardBackSection> sections;
  final String? eyebrow;
  final String? supportingText;
  final String? hint;
  final WordCardContent? wordContent;
  final DateTime? dueAt;
  final int intervalDays;
  final int reviewCount;
  final int lapseCount;
  final int masteryStreak;
  final Familiarity? lastFamiliarity;
  final String sourceType;
  final Map<String, dynamic> presentation;

  bool isDueAt(DateTime now) => dueAt == null || !dueAt!.isAfter(now);

  bool get isUnseen => lastFamiliarity == null;

  MemoryStability get stability {
    if (isUnseen) return MemoryStability.unseen;
    if (lastFamiliarity != Familiarity.mastered) {
      return MemoryStability.building;
    }
    if (masteryStreak >= 3 && intervalDays >= 30) {
      return MemoryStability.consolidated;
    }
    if (masteryStreak >= 2 && intervalDays >= 7) {
      return MemoryStability.stable;
    }
    return MemoryStability.building;
  }

  /// Older generated vocabulary stores only sections. Adapt recognized fields
  /// without inventing content or dropping unfamiliar/custom sections.
  WordCardContent? get reviewWordContent {
    // Custom back instructions are represented by the generated sections;
    // lexical metadata can contain facts the user explicitly excluded.
    final backRule = presentation['back'];
    if (presentation['skill'] == 'word' &&
        backRule is String &&
        !const {
          '释义在上，例句在下',
          '释义、双语例句与常用句型同页，搭配与词形按需查看',
          '释义、例句与搭配、易混淆点分区排列',
        }.contains(backRule.trim())) {
      return null;
    }
    if (wordContent != null) return wordContent;
    if (presentation['skill'] != 'word') return null;
    CardBackSection? meaning;
    CardBackSection? example;
    for (final section in sections) {
      if (const ['Meaning', '核心释义', '释义'].contains(section.title)) {
        if (meaning != null) return null;
        meaning = section;
      } else if (const [
        'Example & collocation',
        '例句',
        '例句搭配',
      ].contains(section.title)) {
        if (example != null) return null;
        example = section;
      } else {
        return null;
      }
    }
    if (meaning == null || example == null) return null;
    var sentence = example.heading;
    var translation = example.body;
    if (sentence.isEmpty) {
      final chinese = RegExp(r'[\u3400-\u9fff]').firstMatch(example.body);
      final boundary = chinese?.start ?? example.body.length;
      sentence = example.body.substring(0, boundary).trim();
      translation = example.body.substring(boundary).trim();
    }
    return WordCardContent(
      partOfSpeech: '',
      definition: meaning.heading.isEmpty ? meaning.body : meaning.heading,
      englishDefinition: meaning.heading.isEmpty ? '' : meaning.body,
      example: WordExample(sentence: sentence, translation: translation),
    );
  }

  List<CardBackSection> get learningSections =>
      presentation.isNotEmpty ? sections : wordContent?.sections ?? sections;

  /// UI grouping does not change the persisted/exported section structure.
  List<CardBackSection> get reviewSections =>
      reviewWordContent?.reviewSections ?? sections;

  StudyCard copyWith({
    DateTime? dueAt,
    int? intervalDays,
    int? reviewCount,
    int? lapseCount,
    int? masteryStreak,
    Familiarity? lastFamiliarity,
  }) => StudyCard(
    id: id,
    prompt: prompt,
    sections: sections,
    eyebrow: eyebrow,
    supportingText: supportingText,
    hint: hint,
    wordContent: wordContent,
    dueAt: dueAt ?? this.dueAt,
    intervalDays: intervalDays ?? this.intervalDays,
    reviewCount: reviewCount ?? this.reviewCount,
    lapseCount: lapseCount ?? this.lapseCount,
    masteryStreak: masteryStreak ?? this.masteryStreak,
    lastFamiliarity: lastFamiliarity ?? this.lastFamiliarity,
    sourceType: sourceType,
    presentation: presentation,
  );
}

class WordCardDraft {
  const WordCardDraft({
    required this.prompt,
    required this.sections,
    this.hint = '',
    this.wordContent,
    this.parentCardId,
    this.relationType,
    this.reason = '',
    this.presentation = const {},
  });

  final String prompt;
  final List<CardBackSection> sections;
  final String hint;
  final WordCardContent? wordContent;
  final String? parentCardId;
  final CardRelationType? relationType;
  final String reason;
  final Map<String, dynamic> presentation;

  List<CardBackSection> get learningSections =>
      presentation.isNotEmpty ? sections : wordContent?.sections ?? sections;

  WordCardDraft copyWith({
    String? prompt,
    String? hint,
    List<CardBackSection>? sections,
    WordCardContent? wordContent,
  }) => WordCardDraft(
    prompt: prompt ?? this.prompt,
    hint: hint ?? this.hint,
    sections: sections ?? this.sections,
    wordContent: wordContent ?? this.wordContent,
    parentCardId: parentCardId,
    relationType: relationType,
    reason: reason,
    presentation: presentation,
  );
}

class CardDeck {
  const CardDeck({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.cards,
    required this.mastered,
    required this.fuzzy,
    required this.forgotten,
  });

  final String id;
  final String title;
  final String subtitle;
  final CardKind kind;
  final List<StudyCard> cards;
  final int mastered;
  final int fuzzy;
  final int forgotten;

  int get reviewedCount {
    final count = mastered + fuzzy + forgotten;
    return count > cards.length ? cards.length : count;
  }

  int get unseenCount => cards.length - reviewedCount;

  double get coverage => cards.isEmpty ? 0 : reviewedCount / cards.length;

  double get masteryProgress =>
      cards.isEmpty ? 0 : (mastered + fuzzy * 0.5) / cards.length;

  int get stableCount => cards
      .where(
        (card) =>
            card.stability == MemoryStability.stable ||
            card.stability == MemoryStability.consolidated,
      )
      .length;

  double get stableRate => cards.isEmpty ? 0 : stableCount / cards.length;

  DeckLearningStage get learningStage {
    if (reviewedCount == 0) return DeckLearningStage.notStarted;
    if (coverage < 1) return DeckLearningStage.learning;
    if (masteryProgress < 0.7) return DeckLearningStage.reinforcing;
    if (masteryProgress >= 0.85 && stableRate >= 0.6) {
      return DeckLearningStage.fluent;
    }
    return DeckLearningStage.mastered;
  }

  List<StudyCard> dueCards([DateTime? now]) {
    final current = now ?? DateTime.now();
    return cards.where((card) => card.isDueAt(current)).toList(growable: false);
  }

  int dueCount([DateTime? now]) => dueCards(now).length;

  CardDeck copyWith({List<StudyCard>? cards}) {
    final nextCards = cards ?? this.cards;
    int count(Familiarity familiarity) =>
        nextCards.where((card) => card.lastFamiliarity == familiarity).length;
    return CardDeck(
      id: id,
      title: title,
      subtitle: subtitle,
      kind: kind,
      cards: nextCards,
      mastered: count(Familiarity.mastered),
      fuzzy: count(Familiarity.fuzzy),
      forgotten: count(Familiarity.forgotten),
    );
  }
}

class CardAttempt {
  const CardAttempt({
    required this.cardId,
    required this.prompt,
    required this.familiarity,
    this.assistanceUsed = false,
  });

  final String cardId;
  final String prompt;
  final Familiarity familiarity;
  final bool assistanceUsed;
}

class CardScheduleUpdate {
  const CardScheduleUpdate({
    required this.cardId,
    required this.dueAt,
    required this.intervalDays,
  });

  final String cardId;
  final DateTime dueAt;
  final int intervalDays;
}

class MemorySchedule {
  const MemorySchedule({required this.dueAt, required this.intervalDays});

  final DateTime dueAt;
  final int intervalDays;
}

abstract final class MemoryScheduler {
  static MemorySchedule next({
    required Familiarity familiarity,
    required DateTime now,
    int previousIntervalDays = 0,
  }) {
    return switch (familiarity) {
      Familiarity.forgotten => MemorySchedule(
        dueAt: now.add(const Duration(minutes: 10)),
        intervalDays: 0,
      ),
      Familiarity.fuzzy => MemorySchedule(
        dueAt: now.add(
          Duration(
            days: previousIntervalDays <= 0
                ? 1
                : ((previousIntervalDays * 1.25).ceil()).clamp(1, 30),
          ),
        ),
        intervalDays: previousIntervalDays <= 0
            ? 1
            : ((previousIntervalDays * 1.25).ceil()).clamp(1, 30),
      ),
      Familiarity.mastered => MemorySchedule(
        dueAt: now.add(
          Duration(
            days: previousIntervalDays <= 0
                ? 3
                : (previousIntervalDays * 2).clamp(3, 90),
          ),
        ),
        intervalDays: previousIntervalDays <= 0
            ? 3
            : (previousIntervalDays * 2).clamp(3, 90),
      ),
    };
  }
}

extension FamiliarityLabel on Familiarity {
  String get label => switch (this) {
    Familiarity.mastered => '熟悉',
    Familiarity.fuzzy => '记不牢',
    Familiarity.forgotten => '不熟悉',
  };

  String get interval => switch (this) {
    Familiarity.mastered => '+3 天',
    Familiarity.fuzzy => '+1 天',
    Familiarity.forgotten => '今天再练',
  };
}

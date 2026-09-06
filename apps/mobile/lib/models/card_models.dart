enum CardKind { word, formula, problem }

enum Familiarity { mastered, fuzzy, forgotten }

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

class StudyCard {
  const StudyCard({
    required this.id,
    required this.prompt,
    required this.sections,
    this.eyebrow,
    this.supportingText,
  });

  final String id;
  final String prompt;
  final List<CardBackSection> sections;
  final String? eyebrow;
  final String? supportingText;
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
}

class CardAttempt {
  const CardAttempt({
    required this.cardId,
    required this.prompt,
    required this.familiarity,
  });

  final String cardId;
  final String prompt;
  final Familiarity familiarity;
}

extension FamiliarityLabel on Familiarity {
  String get label => switch (this) {
    Familiarity.mastered => '门清儿',
    Familiarity.fuzzy => '搂一眼',
    Familiarity.forgotten => '忘记了',
  };

  String get interval => switch (this) {
    Familiarity.mastered => '+3 天',
    Familiarity.fuzzy => '+1 天',
    Familiarity.forgotten => '今天再练',
  };
}

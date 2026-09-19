import 'package:flutter_test/flutter_test.dart';
import 'package:loopcard/models/card_models.dart';

void main() {
  final now = DateTime.utc(2026, 9, 13, 8);

  test('forgotten cards return in ten minutes', () {
    final schedule = MemoryScheduler.next(
      familiarity: Familiarity.forgotten,
      now: now,
      previousIntervalDays: 20,
    );
    expect(schedule.intervalDays, 0);
    expect(schedule.dueAt, now.add(const Duration(minutes: 10)));
  });

  test('mastered cards start at three days and grow to a cap', () {
    expect(
      MemoryScheduler.next(
        familiarity: Familiarity.mastered,
        now: now,
      ).intervalDays,
      3,
    );
    expect(
      MemoryScheduler.next(
        familiarity: Familiarity.mastered,
        now: now,
        previousIntervalDays: 60,
      ).intervalDays,
      90,
    );
  });

  test('deck due queue includes unseen and expired cards only', () {
    final deck = CardDeck(
      id: 'deck',
      title: 'Words',
      subtitle: '',
      kind: CardKind.word,
      cards: [
        const StudyCard(id: 'unseen', prompt: 'unseen', sections: []),
        StudyCard(
          id: 'due',
          prompt: 'due',
          sections: const [],
          dueAt: now.subtract(const Duration(minutes: 1)),
        ),
        StudyCard(
          id: 'later',
          prompt: 'later',
          sections: const [],
          dueAt: now.add(const Duration(days: 1)),
        ),
      ],
      mastered: 0,
      fuzzy: 0,
      forgotten: 0,
    );
    expect(deck.dueCards(now).map((card) => card.id), ['unseen', 'due']);
  });

  test(
    'deck progress includes fuzzy weight and unseen cards in denominator',
    () {
      final deck = CardDeck(
        id: 'progress',
        title: 'Progress',
        subtitle: '',
        kind: CardKind.word,
        cards: const [
          StudyCard(id: '1', prompt: 'one', sections: []),
          StudyCard(id: '2', prompt: 'two', sections: []),
          StudyCard(id: '3', prompt: 'three', sections: []),
          StudyCard(id: '4', prompt: 'four', sections: []),
        ],
        mastered: 1,
        fuzzy: 1,
        forgotten: 1,
      );

      expect(deck.reviewedCount, 3);
      expect(deck.unseenCount, 1);
      expect(deck.coverage, 0.75);
      expect(deck.masteryProgress, 0.375);
      expect(deck.learningStage, DeckLearningStage.learning);
    },
  );

  test('card stability needs repeated recall and a long enough interval', () {
    const building = StudyCard(
      id: 'building',
      prompt: 'building',
      sections: [],
      lastFamiliarity: Familiarity.mastered,
      masteryStreak: 1,
      intervalDays: 3,
    );
    const stable = StudyCard(
      id: 'stable',
      prompt: 'stable',
      sections: [],
      lastFamiliarity: Familiarity.mastered,
      masteryStreak: 2,
      intervalDays: 7,
    );

    expect(building.stability, MemoryStability.building);
    expect(stable.stability, MemoryStability.stable);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:loopcard/data/demo_data.dart';

void main() {
  test('ships three unique demos covering every knowledge grammar', () {
    expect(DemoData.decks, hasLength(3));
    for (final deck in DemoData.decks) {
      expect(deck.cards, isNotEmpty);
      expect(
        deck.cards.map((card) => card.id).toSet(),
        hasLength(deck.cards.length),
      );
      expect(deck.cards.every((card) => card.sections.length == 3), isTrue);
    }
  });

  test('word demos include editorial metadata instead of generic filler', () {
    final card = DemoData.wordDeck.cards.first;
    expect(card.eyebrow, contains('ENGLISH'));
    expect(card.supportingText, contains('borrow'));
  });
}

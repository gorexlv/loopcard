import 'package:flutter_test/flutter_test.dart';
import 'package:loopcard/models/card_models.dart';

void main() {
  test('word content round-trips and creates learning pages', () {
    const content = WordCardContent(
      partOfSpeech: 'v.',
      pronunciations: [WordPronunciation(region: 'US', ipa: '/lend/')],
      forms: ['past / past participle: lent'],
      definition: '借给；借出',
      englishDefinition: 'to give something temporarily to someone',
      usagePatterns: ['lend something to someone'],
      example: WordExample(
        sentence: 'Could you lend me a pen?',
        translation: '你能借给我一支笔吗？',
      ),
      collocations: ['lend money', 'lend a hand'],
      confusion: WordNote(
        heading: 'lend vs. borrow',
        body: 'lend 是借出，borrow 是借入。',
      ),
    );

    final restored = WordCardContent.fromJson(content.toJson());

    expect(restored.partOfSpeech, 'v.');
    expect(restored.forms, ['past / past participle: lent']);
    expect(restored.pronunciations.single.ipa, '/lend/');
    expect(restored.sections, hasLength(3));
    expect(restored.sections[0].title, 'Meaning');
    expect(restored.sections[1].heading, 'Could you lend me a pen?');
    expect(restored.sections[2].title, 'Common confusion');
  });

  test('generic sections remain the fallback for legacy cards', () {
    const legacy = StudyCard(
      id: 'legacy',
      prompt: 'legacy',
      sections: [
        CardBackSection(title: 'Meaning', heading: '旧释义', body: '旧卡仍然可读。'),
      ],
    );

    expect(legacy.learningSections, same(legacy.sections));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:loopcard/ocr/english_word_extractor.dart';

void main() {
  group('EnglishWordExtractor', () {
    test('extracts words and keeps apostrophes and hyphens', () {
      final words = EnglishWordExtractor.extract([
        "Borrow a well-known book; don't lose it.",
      ]);

      expect(words, ['Borrow', 'well-known', 'book', "don't", 'lose', 'it']);
    });

    test('deduplicates case-insensitively while preserving first spelling', () {
      final words = EnglishWordExtractor.extract([
        'Apple banana APPLE Banana cherry',
      ]);

      expect(words, ['Apple', 'banana', 'cherry']);
    });

    test('filters one-character fragments and pure numbers', () {
      final words = EnglishWordExtractor.extract([
        'A I x 123 B2 useful 42words',
      ]);

      expect(words, ['useful', 'words']);
    });

    test('normalizes curly apostrophes', () {
      final words = EnglishWordExtractor.extract(["we’re WE'RE"]);

      expect(words, ["we're"]);
    });
  });
}

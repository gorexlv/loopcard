class EnglishWordExtractor {
  const EnglishWordExtractor._();

  static final RegExp _wordPattern = RegExp(r"[A-Za-z]+(?:['\-][A-Za-z]+)*");

  static List<String> extract(Iterable<String> lines) {
    final words = <String>[];
    final seen = <String>{};

    for (final line in lines) {
      final normalizedLine = line.replaceAll('’', "'");
      for (final match in _wordPattern.allMatches(normalizedLine)) {
        final word = match.group(0)!;
        if (word.length < 2) continue;

        final key = word.toLowerCase();
        if (seen.add(key)) words.add(word);
      }
    }

    return words;
  }
}

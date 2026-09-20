import '../models/card_models.dart';

String literaryText(String text) => text
    .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
    .replaceAll('\r\n', '\n')
    .trim();

/// Break only at supplied line breaks or Chinese sentence punctuation.
/// Punctuation and original characters remain intact.
List<String> literaryLines(String text, {bool verse = true}) {
  final clean = literaryText(text);
  if (clean.isEmpty) return const [];
  if (clean.contains('\n') || !verse) {
    return clean
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
  return RegExp(r'[^，。！？；]+[，。！？；]*[”」』]?|[，。！？；]+')
      .allMatches(clean)
      .map((m) => m.group(0)!.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

class LiteraryPage {
  const LiteraryPage({
    required this.label,
    required this.heading,
    required this.lines,
    this.translations = const [],
    this.verse = false,
  });
  final String label;
  final String heading;
  final List<String> lines;
  final List<String> translations;
  final bool verse;
}

bool _translation(String title) =>
    RegExp('译|譯|释义|釋義|翻译|translation', caseSensitive: false).hasMatch(title);
String? _stanza(String title) {
  if (RegExp('上[阕闋片]').hasMatch(title)) return '上阕';
  if (RegExp('下[阕闋片]').hasMatch(title)) return '下阕';
  return null;
}

/// Pair only explicitly line-aligned translations. If counts differ, retain
/// a separate translation page; never silently zip, truncate, or guess a stanza.
List<LiteraryPage> literaryPages(StudyCard card) {
  final sections = card.sections;
  final poetry = card.presentation['skill'] == 'poetry';
  final consumed = <int>{};
  final pages = <LiteraryPage>[];
  for (var i = 0; i < sections.length; i++) {
    if (consumed.contains(i)) continue;
    final section = sections[i];
    final stanza = _stanza(section.title);
    final source =
        !_translation(section.title) &&
        (stanza != null ||
            RegExp('原文|原诗|原詩|原句|下一句|答案').hasMatch(section.title));
    final lines = literaryLines(section.body, verse: poetry && source);
    var translations = <String>[];
    if (source) {
      final candidates = <int>[
        for (var j = 0; j < sections.length; j++)
          if (j > i &&
              !consumed.contains(j) &&
              _translation(sections[j].title) &&
              _stanza(sections[j].title) == stanza)
            j,
      ];
      if (candidates.length == 1) {
        final j = candidates.single;
        // Explicit newline alignment is required for multi-line translations.
        final translated = literaryLines(sections[j].body, verse: false);
        if (lines.length == translated.length && sections[j].heading.isEmpty) {
          translations = translated;
          consumed.add(j);
        }
      }
    }
    var bodyLines = lines;
    if (!source && RegExp('注释|注釋|字词|字詞').hasMatch(section.title)) {
      bodyLines = literaryText(section.body)
          .split(RegExp(r'\n+|(?=【)'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    pages.add(
      LiteraryPage(
        label: stanza != null && source ? stanza : section.title,
        heading: section.heading,
        lines: bodyLines,
        translations: translations,
        verse: poetry && source,
      ),
    );
  }
  return pages;
}

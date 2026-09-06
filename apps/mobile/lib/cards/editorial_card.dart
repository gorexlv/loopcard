import 'package:flutter/material.dart';

import '../models/card_models.dart';
import 'card_background.dart';
import 'card_visuals.dart';

enum CardFace { front, back }

class EditorialCard extends StatelessWidget {
  const EditorialCard({
    super.key,
    required this.card,
    required this.kind,
    this.face = CardFace.front,
    this.sectionIndex = 0,
    this.preferences = const CardVisualPreferences(),
    this.onTap,
  });

  final StudyCard card;
  final CardKind kind;
  final CardFace face;
  final int sectionIndex;
  final CardVisualPreferences preferences;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final contentLength =
        card.prompt.length +
        card.sections.fold<int>(
          0,
          (sum, section) => sum + section.heading.length + section.body.length,
        );
    final visuals = const CardVisualEngine().resolve(
      kind: kind,
      preferences: preferences,
      contentLength: contentLength,
    );
    final tokens = CardThemeTokens.forFamily(visuals.theme);
    final section =
        card.sections[sectionIndex.clamp(0, card.sections.length - 1)];
    final label = face == CardFace.front
        ? '卡片正面：${card.prompt}'
        : '卡片背面：${section.heading}';

    return Semantics(
      label: label,
      excludeSemantics: true,
      button: onTap != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: CardBackground(
              family: visuals.theme,
              mood: visuals.mood,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: tokens.foreground.withValues(alpha: 0.12),
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x52000000),
                      blurRadius: 34,
                      offset: Offset(0, 18),
                    ),
                  ],
                ),
                child: face == CardFace.front
                    ? _Front(
                        card: card,
                        kind: kind,
                        visuals: visuals,
                        tokens: tokens,
                      )
                    : _Back(
                        section: section,
                        kind: kind,
                        visuals: visuals,
                        tokens: tokens,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Front extends StatelessWidget {
  const _Front({
    required this.card,
    required this.kind,
    required this.visuals,
    required this.tokens,
  });

  final StudyCard card;
  final CardKind kind;
  final ResolvedCardVisuals visuals;
  final CardThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(visuals.density == CardDensity.compact ? 28 : 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow(text: card.eyebrow ?? _defaultEyebrow(kind), tokens: tokens),
          Expanded(child: _composition()),
          Row(
            children: [
              Expanded(
                child: Text(
                  card.supportingText ?? _defaultSupport(kind),
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 0.8,
                    color: tokens.muted,
                  ),
                ),
              ),
              Container(width: 28, height: 2, color: tokens.accent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _composition() => switch (kind) {
    CardKind.word => _WordFront(card: card, visuals: visuals, tokens: tokens),
    CardKind.formula => _FormulaFront(
      card: card,
      visuals: visuals,
      tokens: tokens,
    ),
    CardKind.problem => _ProblemFront(
      card: card,
      visuals: visuals,
      tokens: tokens,
    ),
  };
}

class _WordFront extends StatelessWidget {
  const _WordFront({
    required this.card,
    required this.visuals,
    required this.tokens,
  });
  final StudyCard card;
  final ResolvedCardVisuals visuals;
  final CardThemeTokens tokens;

  @override
  Widget build(BuildContext context) => Stack(
    key: const ValueKey('word-composition'),
    alignment: Alignment.centerLeft,
    children: [
      Positioned(
        right: -18,
        top: 42,
        child: Text(
          card.prompt.characters.first.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 220,
            height: 1,
            fontWeight: FontWeight.w800,
            color: tokens.foreground.withValues(alpha: 0.055),
          ),
        ),
      ),
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            key: const ValueKey('word-classification'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: tokens.accent.withValues(alpha: 0.12),
              border: Border.all(color: tokens.accent.withValues(alpha: 0.38)),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              _wordClass(card),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 9,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: tokens.accent,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            card.prompt,
            maxLines: 2,
            overflow: TextOverflow.fade,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 58 * visuals.displayScale,
              height: 0.96,
              letterSpacing: -2.8,
              fontWeight: FontWeight.w700,
              color: tokens.foreground,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            key: const ValueKey('lexical-rule'),
            width: 68,
            height: 3,
            decoration: BoxDecoration(
              color: tokens.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    ],
  );
}

class _FormulaFront extends StatelessWidget {
  const _FormulaFront({
    required this.card,
    required this.visuals,
    required this.tokens,
  });
  final StudyCard card;
  final ResolvedCardVisuals visuals;
  final CardThemeTokens tokens;

  @override
  Widget build(BuildContext context) => Stack(
    key: const ValueKey('formula-composition'),
    alignment: Alignment.center,
    children: [
      SizedBox(
        key: const ValueKey('formula-atom-system'),
        width: 228,
        height: 228,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: tokens.accent.withValues(alpha: 0.35),
                ),
              ),
            ),
            Container(
              width: 148,
              height: 148,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: tokens.foreground.withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              top: 5,
              left: 105,
              child: _AtomDot(color: tokens.accent, size: 11),
            ),
            Positioned(
              right: 22,
              bottom: 43,
              child: _AtomDot(color: tokens.foreground, size: 7),
            ),
            Positioned(
              left: 29,
              bottom: 50,
              child: _AtomDot(color: tokens.accent, size: 6),
            ),
          ],
        ),
      ),
      Text(
        card.sections.first.title == '化学式'
            ? card.sections.first.heading
            : card.prompt,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.fade,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 66 * visuals.displayScale,
          fontWeight: FontWeight.w600,
          letterSpacing: -2,
          color: tokens.foreground,
        ),
      ),
    ],
  );
}

class _ProblemFront extends StatelessWidget {
  const _ProblemFront({
    required this.card,
    required this.visuals,
    required this.tokens,
  });
  final StudyCard card;
  final ResolvedCardVisuals visuals;
  final CardThemeTokens tokens;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('problem-composition'),
    alignment: Alignment.centerLeft,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          key: const ValueKey('condition-markers'),
          spacing: 7,
          runSpacing: 7,
          children: _problemMarkers(card).map((marker) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(
                  color: tokens.foreground.withValues(alpha: 0.16),
                ),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                marker,
                style: TextStyle(fontSize: 10, color: tokens.muted),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 22),
        Text(
          'Q.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 66,
            height: 0.8,
            fontWeight: FontWeight.w800,
            color: tokens.accent,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          card.prompt,
          maxLines: visuals.density == CardDensity.compact ? 8 : 6,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 25 * visuals.displayScale,
            height: 1.5,
            fontWeight: FontWeight.w600,
            color: tokens.foreground,
          ),
        ),
      ],
    ),
  );
}

class _Back extends StatelessWidget {
  const _Back({
    required this.section,
    required this.kind,
    required this.visuals,
    required this.tokens,
  });
  final CardBackSection section;
  final CardKind kind;
  final ResolvedCardVisuals visuals;
  final CardThemeTokens tokens;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(34, 32, 30, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Eyebrow(text: section.title.toUpperCase(), tokens: tokens),
        const SizedBox(height: 28),
        Text(
          section.heading,
          key: const ValueKey('answer-heading'),
          style: TextStyle(
            fontFamily: kind == CardKind.formula ? 'Inter' : null,
            fontSize: kind == CardKind.formula ? 44 : 25,
            height: 1.3,
            fontWeight: FontWeight.w700,
            color: tokens.foreground,
          ),
        ),
        const SizedBox(height: 20),
        Container(width: 48, height: 3, color: tokens.accent),
        const SizedBox(height: 22),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: _StructuredBody(
              key: const ValueKey('answer-body'),
              body: section.body,
              kind: kind,
              tokens: tokens,
              compact: visuals.density == CardDensity.compact,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'LOOPCARD  /  TAP TO RETURN',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 9,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
            color: tokens.muted.withValues(alpha: 0.72),
          ),
        ),
      ],
    ),
  );
}

class _StructuredBody extends StatelessWidget {
  const _StructuredBody({
    super.key,
    required this.body,
    required this.kind,
    required this.tokens,
    required this.compact,
  });

  final String body;
  final CardKind kind;
  final CardThemeTokens tokens;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final blocks = body
        .split(RegExp(r'\n\s*\n|\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < blocks.length; index++) ...[
          _AnswerBlock(
            key: ValueKey('answer-step-$index'),
            text: blocks[index],
            index: index,
            kind: kind,
            tokens: tokens,
            compact: compact,
          ),
          if (index != blocks.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _AnswerBlock extends StatelessWidget {
  const _AnswerBlock({
    super.key,
    required this.text,
    required this.index,
    required this.kind,
    required this.tokens,
    required this.compact,
  });

  final String text;
  final int index;
  final CardKind kind;
  final CardThemeTokens tokens;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isEquation = RegExp(r'[=÷×+−]|\d+\s*[-+*/]').hasMatch(text);
    final isStep =
        kind == CardKind.problem && RegExp(r'^\d{1,2}\s{2,}').hasMatch(text);
    if (isStep) {
      final match = RegExp(r'^(\d+)\s*(.*)$').firstMatch(text);
      final number = match?.group(1) ?? '${index + 1}';
      final content = match?.group(2) ?? text;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 25,
            height: 25,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tokens.accent,
            ),
            child: Text(
              number.padLeft(2, '0'),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: tokens.background,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _AnswerText(text: content, tokens: tokens, compact: compact),
          ),
        ],
      );
    }
    if (isEquation) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border(left: BorderSide(color: tokens.accent, width: 2)),
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(12),
          ),
        ),
        child: _AnswerText(
          text: text,
          tokens: tokens,
          compact: compact,
          strong: true,
        ),
      );
    }
    return _AnswerText(text: text, tokens: tokens, compact: compact);
  }
}

class _AnswerText extends StatelessWidget {
  const _AnswerText({
    required this.text,
    required this.tokens,
    required this.compact,
    this.strong = false,
  });

  final String text;
  final CardThemeTokens tokens;
  final bool compact;
  final bool strong;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: compact ? 13 : (strong ? 16 : 15),
      height: 1.65,
      fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
      color: strong ? tokens.foreground : tokens.muted,
    ),
  );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.text, required this.tokens});
  final String text;
  final CardThemeTokens tokens;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(shape: BoxShape.circle, color: tokens.accent),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: _containsCjk(text) ? 'NotoSansSC' : 'Inter',
            fontSize: 10,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
            color: tokens.muted,
          ),
        ),
      ),
      Text('∞', style: TextStyle(fontSize: 18, color: tokens.muted)),
    ],
  );
}

String _defaultEyebrow(CardKind kind) => switch (kind) {
  CardKind.word => 'LANGUAGE / LEXICON',
  CardKind.formula => 'SCIENCE / FORMULA',
  CardKind.problem => 'PROBLEM / REASONING',
};

String _defaultSupport(CardKind kind) => switch (kind) {
  CardKind.word => 'WORD · MEANING · CONTEXT',
  CardKind.formula => 'FORM · VARIABLES · CONDITIONS',
  CardKind.problem => 'CLUE · METHOD · TRANSFER',
};

bool _containsCjk(String value) => RegExp(r'[\u3400-\u9fff]').hasMatch(value);

String _wordClass(StudyCard card) {
  final heading = card.sections.first.heading.trim();
  final token = heading.split(RegExp(r'\s+')).first;
  if (token.length <= 6 && RegExp(r'[a-zA-Z]').hasMatch(token)) {
    return token.toUpperCase();
  }
  return 'LEXICON';
}

List<String> _problemMarkers(StudyCard card) {
  final support = card.supportingText;
  if (support == null || support.trim().isEmpty) return const ['READ', 'SOLVE'];
  return support
      .split('·')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .take(2)
      .toList();
}

class _AtomDot extends StatelessWidget {
  const _AtomDot({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 8),
      ],
    ),
  );
}

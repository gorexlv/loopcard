import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/card_models.dart';
import '../widgets/figma_icon.dart';
import 'card_background.dart';
import 'card_visuals.dart';
import 'card_reading_layout.dart';
import 'generated_card_face.dart';

enum CardFace { front, back }

class EditorialCard extends StatefulWidget {
  const EditorialCard({
    super.key,
    required this.card,
    required this.kind,
    this.face = CardFace.front,
    this.sectionIndex = 0,
    this.hintRevealed = false,
    this.preferences = const CardVisualPreferences(),
    this.onTap,
    this.onHintTap,
    this.onSectionChanged,
    this.onBackScrollabilityChanged,
    this.onPronounce,
  });

  final StudyCard card;
  final CardKind kind;
  final CardFace face;
  final int sectionIndex;
  final bool hintRevealed;
  final CardVisualPreferences preferences;
  final VoidCallback? onTap;
  final VoidCallback? onHintTap;
  final ValueChanged<int>? onSectionChanged;
  final ValueChanged<bool>? onBackScrollabilityChanged;
  final VoidCallback? onPronounce;

  @override
  State<EditorialCard> createState() => _EditorialCardState();
}

class _EditorialCardState extends State<EditorialCard> {
  int _localSection = 0;
  StudyCard get card => widget.card;
  CardKind get kind => widget.kind;
  CardFace get face => widget.face;
  int get sectionIndex =>
      widget.onSectionChanged == null ? _localSection : widget.sectionIndex;
  bool get hintRevealed => widget.hintRevealed;
  CardVisualPreferences get preferences => widget.preferences;
  VoidCallback? get onTap => widget.onTap;
  VoidCallback? get onHintTap => widget.onHintTap;
  VoidCallback? get onPronounce => widget.onPronounce;
  ValueChanged<bool>? get onBackScrollabilityChanged =>
      widget.onBackScrollabilityChanged;
  void onSectionChanged(int index) {
    setState(() => _localSection = index);
    widget.onSectionChanged?.call(index);
  }

  @override
  void didUpdateWidget(covariant EditorialCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.id != card.id ||
        oldWidget.card.prompt != card.prompt ||
        oldWidget.face != face) {
      _localSection = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (card.presentation.isNotEmpty &&
        (face == CardFace.front ||
            card.presentation['skill'] == 'poetry' ||
            card.presentation['skill'] == 'classical')) {
      return GeneratedCardFace(
        card: card,
        back: face == CardFace.back,
        onTap: onTap,
        onScrollabilityChanged: onBackScrollabilityChanged,
      );
    }
    final sections = card.reviewSections.isEmpty
        ? const [CardBackSection(title: '', heading: '', body: '')]
        : card.reviewSections;
    final contentLength =
        card.prompt.length +
        sections.fold<int>(
          0,
          (sum, section) => sum + section.heading.length + section.body.length,
        );
    final visuals = const CardVisualEngine().resolve(
      kind: kind,
      preferences: preferences,
      contentLength: contentLength,
    );
    final tokens = CardThemeTokens.forContext(context);
    final section = sections[sectionIndex.clamp(0, sections.length - 1)];
    final label = context.l10n.tr(
      face == CardFace.front ? 'cardFrontSemantic' : 'cardBackSemantic',
      {'content': face == CardFace.front ? card.prompt : section.heading},
    );

    return Semantics(
      label: label,
      hint: face == CardFace.back && onTap != null
          ? context.l10n.tr('tapToReturnFront')
          : null,
      container: true,
      explicitChildNodes: face == CardFace.back,
      excludeSemantics: face == CardFace.front,
      button: onTap != null,
      onTap: onTap,
      child: _PressableCardSurface(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: CardBackground(
            family: visuals.theme,
            mood: visuals.mood,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.transparent),
                borderRadius: BorderRadius.circular(28),
              ),
              child: face == CardFace.front
                  ? _Front(
                      card: card,
                      kind: kind,
                      visuals: visuals,
                      tokens: tokens,
                      hintRevealed: hintRevealed,
                      onHintTap: onHintTap,
                    )
                  : kind == CardKind.word && card.reviewWordContent != null
                  ? _WordBack(
                      card: card,
                      sectionIndex: sectionIndex,
                      visuals: visuals,
                      tokens: tokens,
                      onSectionChanged: onSectionChanged,
                      onScrollabilityChanged: onBackScrollabilityChanged,
                      onPronounce: onPronounce,
                    )
                  : _Back(
                      card: card,
                      sectionIndex: sectionIndex,
                      kind: kind,
                      visuals: visuals,
                      tokens: tokens,
                      onSectionChanged: onSectionChanged,
                      onScrollabilityChanged: onBackScrollabilityChanged,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PressableCardSurface extends StatefulWidget {
  const _PressableCardSurface({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_PressableCardSurface> createState() => _PressableCardSurfaceState();
}

class _PressableCardSurfaceState extends State<_PressableCardSurface> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 100);
    return AnimatedScale(
      key: const ValueKey('editorial-card-press-motion'),
      scale: _pressed ? 0.992 : 1,
      duration: duration,
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? (_pressed ? 0.18 : 0.26)
                    : (_pressed ? 0.05 : 0.08),
              ),
              blurRadius: _pressed ? 18 : 24,
              offset: Offset(0, _pressed ? 6 : 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (pressed) {
              if (_pressed == pressed) return;
              setState(() => _pressed = pressed);
            },
            excludeFromSemantics: true,
            borderRadius: BorderRadius.circular(28),
            child: widget.child,
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
    required this.hintRevealed,
    required this.onHintTap,
  });

  final StudyCard card;
  final CardKind kind;
  final ResolvedCardVisuals visuals;
  final CardThemeTokens tokens;
  final bool hintRevealed;
  final VoidCallback? onHintTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(visuals.density == CardDensity.compact ? 28 : 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _composition()),
          if (kind != CardKind.word &&
              card.hint?.trim().isNotEmpty == true) ...[
            _HintDisclosure(
              hint: card.hint!.trim(),
              revealed: hintRevealed,
              tokens: tokens,
              onTap: onHintTap,
            ),
            const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }

  Widget _composition() => switch (kind) {
    CardKind.word => _WordFront(
      card: card,
      tokens: tokens,
      hintRevealed: hintRevealed,
      onHintTap: onHintTap,
    ),
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

class _HintDisclosure extends StatelessWidget {
  const _HintDisclosure({
    required this.hint,
    required this.revealed,
    required this.tokens,
    required this.onTap,
  });

  final String hint;
  final bool revealed;
  final CardThemeTokens tokens;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: !revealed,
      label: revealed
          ? '${context.l10n.tr('hintRevealed')}: $hint'
          : context.l10n.tr('revealHint'),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('card-hint-action'),
          onTap: revealed ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: revealed
                  ? Row(
                      key: const ValueKey('revealed-hint'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FigmaIcon('hint', size: 18, color: tokens.accent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            hint,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              fontWeight: FontWeight.w600,
                              color: tokens.foreground,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      key: const ValueKey('hidden-hint'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FigmaIcon('hint', size: 18, color: tokens.muted),
                        const SizedBox(width: 9),
                        Text(
                          context.l10n.tr('revealHint'),
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                            color: tokens.muted,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WordFront extends StatelessWidget {
  const _WordFront({
    required this.card,
    required this.tokens,
    required this.hintRevealed,
    required this.onHintTap,
  });
  final StudyCard card;
  final CardThemeTokens tokens;
  final bool hintRevealed;
  final VoidCallback? onHintTap;

  @override
  Widget build(BuildContext context) {
    final cue = _wordFrontCue(card);
    return Column(
      key: const ValueKey('word-composition'),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            key: const ValueKey('word-prompt-fit'),
            alignment: Alignment.center,
            fit: BoxFit.scaleDown,
            child: Text(
              card.prompt,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontFamily: 'Inter',
                fontFamilyFallback: const ['NotoSansSC'],
                fontSize: 62,
                height: 1.02,
                letterSpacing: -0.8,
                fontWeight: FontWeight.w600,
                fontVariations: const [ui.FontVariation('wght', 600)],
                color: tokens.foreground,
              ),
            ),
          ),
        ),
        if (cue.isNotEmpty) ...[
          const SizedBox(height: 16),
          _WordHintMask(
            cue: cue,
            revealed: hintRevealed,
            tokens: tokens,
            onTap: onHintTap,
          ),
        ],
      ],
    );
  }
}

class _WordHintMask extends StatelessWidget {
  const _WordHintMask({
    required this.cue,
    required this.revealed,
    required this.tokens,
    required this.onTap,
  });

  final String cue;
  final bool revealed;
  final CardThemeTokens tokens;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      excludeSemantics: true,
      button: !revealed,
      label: revealed
          ? '${context.l10n.tr('hintRevealed')}: $cue'
          : context.l10n.tr('revealHint'),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('card-hint-action'),
          onTap: revealed ? null : onTap,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            key: const ValueKey('word-cue-surface'),
            width: double.infinity,
            height: 48,
            child: Center(
              child: AnimatedSwitcher(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                child: revealed
                    ? Padding(
                        key: const ValueKey('revealed-word-cue'),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _WordCueText(cue: cue, tokens: tokens),
                      )
                    : Row(
                        key: const ValueKey('word-cue-mask'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FigmaIcon('hint', size: 16, color: tokens.muted),
                          const SizedBox(width: 8),
                          Text(
                            context.l10n.tr('revealHint'),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: tokens.muted,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WordCueText extends StatelessWidget {
  const _WordCueText({required this.cue, required this.tokens});

  final String cue;
  final CardThemeTokens tokens;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(
      cue,
      key: const ValueKey('word-cue-content'),
      maxLines: 1,
      softWrap: false,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        height: 1.2,
        letterSpacing: 0.15,
        fontWeight: FontWeight.w500,
        color: tokens.muted,
      ),
    ),
  );
}

String _wordFrontCue(StudyCard card) {
  final content = card.wordContent;
  if (content != null) {
    final parts = <String>[
      if (content.partOfSpeech.trim().isNotEmpty) content.partOfSpeech.trim(),
      for (final pronunciation in content.pronunciations)
        [
          if (pronunciation.region.trim().isNotEmpty)
            pronunciation.region.trim(),
          pronunciation.ipa.trim(),
        ].where((value) => value.isNotEmpty).join(' '),
    ].where((value) => value.isNotEmpty).toList(growable: false);
    if (parts.isNotEmpty) return parts.join('   ');
  }
  return card.hint?.trim() ?? '';
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
                border: Border.all(color: Colors.transparent),
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

class _WordBack extends StatelessWidget {
  const _WordBack({
    required this.card,
    required this.sectionIndex,
    required this.visuals,
    required this.tokens,
    required this.onSectionChanged,
    required this.onScrollabilityChanged,
    required this.onPronounce,
  });
  final StudyCard card;
  final int sectionIndex;
  final ResolvedCardVisuals visuals;
  final CardThemeTokens tokens;
  final ValueChanged<int>? onSectionChanged;
  final ValueChanged<bool>? onScrollabilityChanged;
  final VoidCallback? onPronounce;

  @override
  Widget build(BuildContext context) {
    final content = card.reviewWordContent!;
    final sections = content.reviewSections;
    final index = sectionIndex.clamp(0, sections.length - 1);
    final previous = index > 0 ? () => onSectionChanged?.call(index - 1) : null;
    final next = index + 1 < sections.length
        ? () => onSectionChanged?.call(index + 1)
        : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardSectionTabs(
            labels: [
              for (final s in sections) context.l10n.sectionTitle(s.title),
            ],
            index: index,
            onSelected: (i) => onSectionChanged?.call(i),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _HorizontalSectionPager(
              key: const ValueKey('back-content'),
              index: index,
              onPrevious: previous,
              onNext: next,
              child: _AdaptiveBackSection(
                key: ValueKey('word-back-section-$index'),
                onScrollabilityChanged: onScrollabilityChanged,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                card.prompt,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 22,
                                  height: 1.25,
                                  fontWeight: FontWeight.w600,
                                  color: tokens.foreground,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 10,
                                runSpacing: 4,
                                children: [
                                  if (content.partOfSpeech.isNotEmpty)
                                    Text(
                                      content.partOfSpeech,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: tokens.accent,
                                      ),
                                    ),
                                  for (final p in content.pronunciations)
                                    Text(
                                      [
                                        if (p.region.isNotEmpty) p.region,
                                        p.ipa,
                                      ].join(' '),
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontFamilyFallback: const [
                                          'NotoSansSC',
                                        ],
                                        fontSize: 13,
                                        height: 1.4,
                                        color: tokens.muted,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (onPronounce != null)
                          IconButton(
                            key: const ValueKey('play-word-pronunciation'),
                            tooltip: context.l10n.tr('playPronunciation'),
                            constraints: const BoxConstraints.tightFor(
                              width: 48,
                              height: 48,
                            ),
                            onPressed: onPronounce,
                            icon: FigmaIcon(
                              'volume',
                              size: 22,
                              color: tokens.foreground,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _WordBackPage(
                      index: index,
                      content: content,
                      tokens: tokens,
                      compact: visuals.density == CardDensity.compact,
                    ),
                  ],
                ),
              ),
            ),
          ),
          _BackFooter(
            index: index,
            count: sections.length,
            tokens: tokens,
            onPrevious: previous,
            onNext: next,
          ),
        ],
      ),
    );
  }
}

class _WordBackPage extends StatelessWidget {
  const _WordBackPage({
    required this.index,
    required this.content,
    required this.tokens,
    required this.compact,
  });

  final int index;
  final WordCardContent content;
  final CardThemeTokens tokens;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (index == 0) return _meaning(context);
    final section = content.reviewSections[index];
    if (section.title == 'Word usage') return _usage(context);
    final note = WordNote(heading: section.heading, body: section.body);
    final isConfusion = section.title == 'Common confusion';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WordSectionLabel(
          text: context.l10n.tr(
            isConfusion ? 'sectionDistinction' : 'wordExtension',
          ),
          tokens: tokens,
        ),
        const SizedBox(height: 18),
        Text(
          note.heading,
          style: TextStyle(
            fontFamily: _metadataFontFamily(note.heading),
            fontFamilyFallback: const ['NotoSansSC'],
            fontSize: compact ? 21 : 24,
            height: 1.25,
            fontWeight: FontWeight.w700,
            color: tokens.foreground,
          ),
        ),
        const SizedBox(height: 15),
        _StructuredBody(
          body: note.body,
          kind: CardKind.word,
          tokens: tokens,
          compact: compact,
        ),
      ],
    );
  }

  Widget _meaning(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        content.definition,
        key: const ValueKey('answer-heading'),
        style: TextStyle(
          fontFamily: _metadataFontFamily(content.definition),
          fontFamilyFallback: const ['NotoSansSC'],
          fontSize: compact ? 25 : 28,
          height: 1.24,
          fontWeight: FontWeight.w700,
          color: tokens.foreground,
        ),
      ),
      if (content.englishDefinition.isNotEmpty) ...[
        const SizedBox(height: 11),
        Text(
          content.englishDefinition,
          key: const ValueKey('answer-body'),
          style: TextStyle(
            fontFamily: _metadataFontFamily(content.englishDefinition),
            fontFamilyFallback: const ['NotoSansSC'],
            fontSize: 15,
            height: 1.5,
            color: tokens.muted,
          ),
        ),
      ],
      if (content.example.sentence.isNotEmpty) ...[
        const SizedBox(height: 24),
        _WordMetadataLabel(
          text: context.l10n.tr('sectionExamples'),
          tokens: tokens,
        ),
        const SizedBox(height: 8),
        Text(
          content.example.sentence,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            height: 1.5,
            fontWeight: FontWeight.w600,
            color: tokens.foreground,
          ),
        ),
        if (content.example.translation.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            content.example.translation,
            style: TextStyle(fontSize: 15, height: 1.5, color: tokens.muted),
          ),
        ],
      ],
      if (content.usagePatterns.isNotEmpty) ...[
        const SizedBox(height: 26),
        _WordMetadataLabel(
          text: context.l10n.tr('usagePattern'),
          tokens: tokens,
        ),
        const SizedBox(height: 10),
        for (final pattern in content.usagePatterns) ...[
          _WordLine(text: pattern, tokens: tokens),
          const SizedBox(height: 8),
        ],
      ],
    ],
  );

  Widget _usage(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (content.collocations.isNotEmpty) ...[
        _WordMetadataLabel(
          text: context.l10n.tr('commonCollocations'),
          tokens: tokens,
        ),
        const SizedBox(height: 12),
        for (final line in content.collocations) ...[
          _WordLine(text: line, tokens: tokens),
          const SizedBox(height: 12),
        ],
      ],
      if (content.forms.isNotEmpty) ...[
        const SizedBox(height: 20),
        _WordMetadataLabel(text: context.l10n.tr('wordForms'), tokens: tokens),
        const SizedBox(height: 12),
        for (final form in content.forms) ...[
          Text(
            form,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: tokens.foreground,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    ],
  );
}

class _WordSectionLabel extends StatelessWidget {
  const _WordSectionLabel({required this.text, required this.tokens});

  final String text;
  final CardThemeTokens tokens;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(width: 22, height: 2, color: tokens.accent),
      const SizedBox(width: 9),
      Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w800,
          color: tokens.muted,
        ),
      ),
    ],
  );
}

class _WordMetadataLabel extends StatelessWidget {
  const _WordMetadataLabel({required this.text, required this.tokens});

  final String text;
  final CardThemeTokens tokens;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 11,
      letterSpacing: 0.7,
      fontWeight: FontWeight.w700,
      color: tokens.muted,
    ),
  );
}

class _WordLine extends StatelessWidget {
  const _WordLine({required this.text, required this.tokens});

  final String text;
  final CardThemeTokens tokens;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: tokens.accent,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            height: 1.45,
            fontWeight: FontWeight.w600,
            color: tokens.foreground,
          ),
        ),
      ),
    ],
  );
}

class _Back extends StatelessWidget {
  const _Back({
    required this.card,
    required this.sectionIndex,
    required this.kind,
    required this.visuals,
    required this.tokens,
    required this.onSectionChanged,
    required this.onScrollabilityChanged,
  });
  final StudyCard card;
  final int sectionIndex;
  final CardKind kind;
  final ResolvedCardVisuals visuals;
  final CardThemeTokens tokens;
  final ValueChanged<int>? onSectionChanged;
  final ValueChanged<bool>? onScrollabilityChanged;
  @override
  Widget build(BuildContext context) {
    final sections = card.reviewSections.isEmpty
        ? const [CardBackSection(title: '', heading: '', body: '')]
        : card.reviewSections;
    final index = sectionIndex.clamp(0, sections.length - 1);
    final section = sections[index];
    final previous = index > 0 ? () => onSectionChanged?.call(index - 1) : null;
    final next = index + 1 < sections.length
        ? () => onSectionChanged?.call(index + 1)
        : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardSectionTabs(
            labels: [
              for (final s in sections) context.l10n.sectionTitle(s.title),
            ],
            index: index,
            onSelected: (i) => onSectionChanged?.call(i),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _HorizontalSectionPager(
              key: const ValueKey('back-content'),
              index: index,
              onPrevious: previous,
              onNext: next,
              child: _AdaptiveBackSection(
                key: ValueKey('back-section-$index'),
                onScrollabilityChanged: onScrollabilityChanged,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.prompt,
                      style: TextStyle(
                        fontSize: kind == CardKind.word ? 22 : 15,
                        height: 1.5,
                        color: tokens.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (sections.length == 1 && section.title.isNotEmpty) ...[
                      Text(
                        context.l10n.sectionTitle(section.title),
                        style: TextStyle(fontSize: 13, color: tokens.accent),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (section.heading.isNotEmpty) ...[
                      Text(
                        section.heading,
                        key: const ValueKey('answer-heading'),
                        style: TextStyle(
                          fontSize: kind == CardKind.formula ? 30 : 26,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                          color: tokens.foreground,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _StructuredBody(
                      key: const ValueKey('answer-body'),
                      body: section.body,
                      kind: kind,
                      tokens: tokens,
                      compact: visuals.density == CardDensity.compact,
                    ),
                  ],
                ),
              ),
            ),
          ),
          _BackFooter(
            index: index,
            count: sections.length,
            tokens: tokens,
            onPrevious: previous,
            onNext: next,
          ),
        ],
      ),
    );
  }
}

class _AdaptiveBackSection extends StatelessWidget {
  const _AdaptiveBackSection({
    super.key,
    required this.child,
    required this.onScrollabilityChanged,
  });
  final Widget child;
  final ValueChanged<bool>? onScrollabilityChanged;
  @override
  Widget build(BuildContext context) => CardReadingScroll(
    onScrollabilityChanged: onScrollabilityChanged,
    child: child,
  );
}

class _HorizontalSectionPager extends StatefulWidget {
  const _HorizontalSectionPager({
    super.key,
    required this.index,
    required this.child,
    required this.onPrevious,
    required this.onNext,
  });

  final int index;
  final Widget child;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  State<_HorizontalSectionPager> createState() =>
      _HorizontalSectionPagerState();
}

class _HorizontalSectionPagerState extends State<_HorizontalSectionPager> {
  static const _distanceThreshold = 64.0;
  static const _flickDistanceFloor = 28.0;
  static const _velocityThreshold = 700.0;
  static const _horizontalIntentRatio = 1.35;
  static const _intentSlop = 14.0;
  static const _maximumFollowDistance = 42.0;

  Offset? _origin;
  Offset? _lastPosition;
  bool _horizontalIntentAccepted = false;
  double _dragOffset = 0;
  int _pageDirection = 1;

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void didUpdateWidget(covariant _HorizontalSectionPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _pageDirection = widget.index > oldWidget.index ? 1 : -1;
      _dragOffset = 0;
    }
  }

  double _followOffset(double rawOffset) {
    final movingPastStart = rawOffset > 0 && widget.onPrevious == null;
    final movingPastEnd = rawOffset < 0 && widget.onNext == null;
    final resisted = movingPastStart || movingPastEnd
        ? rawOffset * 0.28
        : rawOffset;
    return resisted.clamp(-_maximumFollowDistance, _maximumFollowDistance);
  }

  void _updateHorizontalDrag(Offset position) {
    _lastPosition = position;
    final origin = _origin;
    if (origin == null) return;
    final displacement = position - origin;
    if (!_horizontalIntentAccepted) {
      final hasClearIntent =
          displacement.dx.abs() >= _intentSlop &&
          displacement.dx.abs() >=
              displacement.dy.abs() * _horizontalIntentRatio;
      if (!hasClearIntent) return;
      _horizontalIntentAccepted = true;
    }
    setState(() => _dragOffset = _followOffset(displacement.dx));
  }

  void _resetGesture() {
    _origin = null;
    _lastPosition = null;
    _horizontalIntentAccepted = false;
    if (_dragOffset != 0 && mounted) setState(() => _dragOffset = 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragDown: (details) {
        _origin = details.globalPosition;
        _lastPosition = details.globalPosition;
        _horizontalIntentAccepted = false;
      },
      onHorizontalDragStart: (details) {
        _origin ??= details.globalPosition;
        _horizontalIntentAccepted = false;
        _updateHorizontalDrag(details.globalPosition);
      },
      onHorizontalDragUpdate: (details) =>
          _updateHorizontalDrag(details.globalPosition),
      onHorizontalDragEnd: (details) {
        final origin = _origin;
        final lastPosition = _lastPosition;
        if (origin == null || lastPosition == null) {
          _resetGesture();
          return;
        }
        final displacement = lastPosition - origin;
        final velocity = details.primaryVelocity ?? 0;
        final hasHorizontalIntent =
            _horizontalIntentAccepted &&
            displacement.dx.abs() >=
                displacement.dy.abs() * _horizontalIntentRatio;
        final hasEnoughTravel =
            displacement.dx.abs() >= _distanceThreshold ||
            (displacement.dx.abs() >= _flickDistanceFloor &&
                velocity.abs() >= _velocityThreshold);
        if (!hasHorizontalIntent || !hasEnoughTravel) {
          _resetGesture();
          return;
        }
        if (displacement.dx < 0 && widget.onNext != null) {
          _pageDirection = 1;
          _resetGesture();
          widget.onNext!();
        } else if (displacement.dx > 0 && widget.onPrevious != null) {
          _pageDirection = -1;
          _resetGesture();
          widget.onPrevious!();
        } else {
          _resetGesture();
        }
      },
      onHorizontalDragCancel: _resetGesture,
      child: ClipRect(
        clipBehavior: Clip.hardEdge,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: _dragOffset),
          duration: _horizontalIntentAccepted || _reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          builder: (context, offset, child) => Transform.translate(
            key: const ValueKey('back-content-motion'),
            offset: Offset(offset, 0),
            child: child,
          ),
          child: AnimatedSwitcher(
            duration: _reduceMotion
                ? const Duration(milliseconds: 100)
                : const Duration(milliseconds: 220),
            reverseDuration: _reduceMotion
                ? const Duration(milliseconds: 100)
                : const Duration(milliseconds: 160),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            // Dense text becomes unreadable when two explanations crossfade.
            // Paint only the incoming page during the section transition.
            layoutBuilder: (currentChild, _) =>
                currentChild ?? const SizedBox.shrink(),
            transitionBuilder: (child, animation) {
              if (_reduceMotion) {
                return FadeTransition(opacity: animation, child: child);
              }
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.15, 1, curve: Curves.easeOut),
                ),
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: Offset(0.06 * _pageDirection, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                  child: child,
                ),
              );
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _BackFooter extends StatelessWidget {
  const _BackFooter({
    required this.index,
    required this.count,
    required this.tokens,
    required this.onPrevious,
    required this.onNext,
  });

  final int index;
  final int count;
  final CardThemeTokens tokens;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final progress = count == 1
        ? context.l10n.tr('answerDetail')
        : context.l10n.tr('explanationProgress', {
            'current': index + 1,
            'count': count,
          });
    if (count == 1) {
      return Semantics(label: progress, child: const SizedBox.shrink());
    }
    return Semantics(
      container: true,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              label: progress,
              liveRegion: true,
              child: ExcludeSemantics(
                child: Text(
                  '${index + 1} / $count',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: tokens.muted,
                  ),
                ),
              ),
            ),
          ),
          if (count > 1) ...[
            IconButton(
              key: const ValueKey('previous-back-section'),
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              padding: EdgeInsets.zero,
              tooltip: context.l10n.tr('previousExplanation'),
              onPressed: onPrevious,
              icon: FigmaIcon(
                'back',
                size: 20,
                color: onPrevious == null
                    ? tokens.muted.withValues(alpha: 0.38)
                    : tokens.foreground,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              key: const ValueKey('next-back-section'),
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              padding: EdgeInsets.zero,
              tooltip: context.l10n.tr('nextExplanation'),
              onPressed: onNext,
              icon: FigmaIcon(
                'forward',
                size: 20,
                color: onNext == null
                    ? tokens.muted.withValues(alpha: 0.38)
                    : tokens.foreground,
              ),
            ),
          ],
        ],
      ),
    );
  }
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
      fontSize: strong ? 17 : 16,
      height: 1.58,
      fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
      color: strong ? tokens.foreground : tokens.muted,
    ),
  );
}

String? _metadataFontFamily(String value) =>
    RegExp(r'^[\u0000-\u024f\s·/—–_-]+$').hasMatch(value) ? 'Inter' : null;

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

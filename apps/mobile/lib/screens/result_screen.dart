import 'package:flutter/material.dart';

import '../ai/word_card_generator.dart';
import '../l10n/app_localizations.dart';
import '../models/card_models.dart';
import '../theme/loop_theme.dart';
import '../widgets/app_page.dart';
import '../widgets/figma_icon.dart';
import 'study_screen.dart';
import 'word_draft_review_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.deck,
    required this.attempts,
    this.schedules = const [],
    this.saveAttempts,
    this.wordCardGenerator,
    this.onAppendGeneratedCards,
  });

  final CardDeck deck;
  final List<CardAttempt> attempts;
  final List<CardScheduleUpdate> schedules;
  final Future<List<CardScheduleUpdate>> Function()? saveAttempts;
  final WordCardGenerator? wordCardGenerator;
  final Future<void> Function(List<WordCardDraft> drafts)?
  onAppendGeneratedCards;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late List<CardScheduleUpdate> _schedules = widget.schedules;
  bool _syncing = false;
  Object? _syncError;

  CardDeck get deck => widget.deck;
  List<CardAttempt> get attempts => widget.attempts;
  List<CardScheduleUpdate> get schedules => _schedules;
  WordCardGenerator? get wordCardGenerator => widget.wordCardGenerator;
  Future<void> Function(List<WordCardDraft> drafts)?
  get onAppendGeneratedCards => widget.onAppendGeneratedCards;

  @override
  void initState() {
    super.initState();
    if (widget.saveAttempts != null) _syncAttempts();
  }

  Future<void> _syncAttempts() async {
    final save = widget.saveAttempts;
    if (save == null || _syncing) return;
    setState(() {
      _syncing = true;
      _syncError = null;
    });
    try {
      final schedules = await save();
      if (!mounted) return;
      setState(() {
        _schedules = schedules;
        _syncing = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _syncing = false;
        _syncError = error;
      });
    }
  }

  List<StudyCard> get _weakCards {
    final weakIds = attempts
        .where((attempt) => attempt.familiarity != Familiarity.mastered)
        .map((attempt) => attempt.cardId)
        .toSet();
    return deck.cards
        .where((card) => weakIds.contains(card.id))
        .take(3)
        .toList(growable: false);
  }

  Future<void> _extend(BuildContext context) async {
    final generator = wordCardGenerator;
    final append = onAppendGeneratedCards;
    if (generator == null || append == null || _weakCards.isEmpty) return;
    final familiarities = {
      for (final attempt in attempts) attempt.cardId: attempt.familiarity,
    };
    var addedCount = 0;
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WordDraftReviewScreen(
          extensionMode: true,
          initialDeckTitle: deck.title,
          loadDrafts: () => generator.suggestExtensions(
            _weakCards,
            familiarities,
            outputLocale: AppLocalizations.resolveLocaleKey(
              Localizations.localeOf(context),
            ),
          ),
          onSave: (_, drafts) async {
            addedCount = drafts.length;
            await append(drafts);
          },
        ),
      ),
    );
    if (added == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.tr('extensionsAdded', {'count': addedCount}),
          ),
        ),
      );
    }
  }

  String _nextLabel(BuildContext context, CardAttempt attempt) {
    final schedule = schedules
        .where((value) => value.cardId == attempt.cardId)
        .firstOrNull;
    final days =
        schedule?.intervalDays ??
        switch (attempt.familiarity) {
          Familiarity.mastered => 3,
          Familiarity.fuzzy => 1,
          Familiarity.forgotten => 0,
        };
    return days == 0
        ? context.l10n.tr('nextTenMinutes')
        : context.l10n.tr('nextDays', {'count': days});
  }

  int _count(Familiarity familiarity) =>
      attempts.where((attempt) => attempt.familiarity == familiarity).length;

  void _reviewCards(BuildContext context, Familiarity familiarity) {
    final cardIds = attempts
        .where((attempt) => attempt.familiarity == familiarity)
        .map((attempt) => attempt.cardId)
        .toSet();
    final cards = deck.cards
        .where((card) => cardIds.contains(card.id))
        .toList(growable: false);
    if (cards.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StudyScreen(
          deck: CardDeck(
            id: '${deck.id}-result-${familiarity.name}',
            title: deck.title,
            subtitle: deck.subtitle,
            kind: deck.kind,
            cards: cards,
            mastered: familiarity == Familiarity.mastered ? cards.length : 0,
            fuzzy: familiarity == Familiarity.fuzzy ? cards.length : 0,
            forgotten: familiarity == Familiarity.forgotten ? cards.length : 0,
          ),
          readOnly: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      minimum: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) => _body(
          context,
          compact: constraints.maxHeight < 720,
          maxWidth: constraints.maxWidth,
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context, {
    required bool compact,
    required double maxWidth,
  }) {
    final canExtend =
        deck.kind == CardKind.word &&
        _weakCards.isNotEmpty &&
        wordCardGenerator != null &&
        onAppendGeneratedCards != null;
    final contentWidth = (maxWidth - (compact ? 40 : 48))
        .clamp(0.0, 430.0)
        .toDouble();
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: contentWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: compact ? 2 : 8),
            Text(
              context.l10n.tr('practiceResults'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.loopColors.muted,
              ),
            ),
            SizedBox(height: compact ? 14 : 20),
            _hero(context, compact: compact),
            SizedBox(height: compact ? 18 : 24),
            _summary(context),
            if (_syncing || _syncError != null) ...[
              SizedBox(height: compact ? 10 : 14),
              _syncStatus(context),
            ],
            SizedBox(height: compact ? 18 : 24),
            Row(
              children: [
                Text(
                  context.l10n.tr('cardResults'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: context.loopColors.ink,
                  ),
                ),
                const Spacer(),
                Text(
                  '${attempts.length} / ${deck.cards.length}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.loopColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: attempts.isEmpty
                  ? const SizedBox.shrink()
                  : ListView.separated(
                      key: const ValueKey('result-card-list'),
                      padding: EdgeInsets.zero,
                      itemCount: attempts.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        thickness: 1,
                        color: context.loopColors.divider,
                      ),
                      itemBuilder: (_, index) => _ResultRow(
                        attempt: attempts[index],
                        nextLabel: _nextLabel(context, attempts[index]),
                      ),
                    ),
            ),
            if (attempts.length > 4) ...[
              const SizedBox(height: 6),
              Text(
                context.l10n.tr('swipeMore', {'count': attempts.length}),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: context.loopColors.subtle,
                ),
              ),
            ],
            if (canExtend) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: () => _extend(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.loopColors.ink,
                    side: BorderSide(color: context.loopColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(context.l10n.tr('extendWeakCards')),
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              height: 58,
              child: FilledButton(
                key: const ValueKey('finish-results'),
                style: FilledButton.styleFrom(
                  backgroundColor: LoopTheme.teal,
                  foregroundColor: const Color(0xFF091413),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(21),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  context.l10n.tr('finishReturn'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            SizedBox(height: compact ? 4 : 10),
          ],
        ),
      ),
    );
  }

  Widget _syncStatus(BuildContext context) {
    if (_syncing) {
      return Center(
        child: SizedBox(
          key: const ValueKey('result-syncing'),
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.loopColors.muted,
          ),
        ),
      );
    }
    return Container(
      key: const ValueKey('result-sync-failed'),
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: LoopTheme.coral.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.tr('saveAttemptsFailed'),
              style: TextStyle(fontSize: 12, color: context.loopColors.muted),
            ),
          ),
          TextButton(
            onPressed: _syncAttempts,
            child: Text(context.l10n.tr('retrySave')),
          ),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context, {required bool compact}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FigmaIcon('success', size: compact ? 54 : 60),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.tr('sessionComplete'),
                style: TextStyle(
                  fontSize: compact ? 25 : 28,
                  height: 1.18,
                  fontWeight: FontWeight.w800,
                  color: context.loopColors.ink,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                context.l10n.deckTitle(deck.id, deck.title),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: context.loopColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summary(BuildContext context) {
    final mastered = _count(Familiarity.mastered);
    final fuzzy = _count(Familiarity.fuzzy);
    final forgotten = _count(Familiarity.forgotten);
    return Semantics(
      container: true,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ResultMetric(
                  key: const ValueKey('result-mastered-count'),
                  value: mastered,
                  label: context.l10n.tr('mastered'),
                  color: LoopTheme.teal,
                  onTap: mastered == 0
                      ? null
                      : () => _reviewCards(context, Familiarity.mastered),
                ),
              ),
              Expanded(
                child: _ResultMetric(
                  key: const ValueKey('result-fuzzy-count'),
                  value: fuzzy,
                  label: context.l10n.tr('fuzzy'),
                  color: LoopTheme.amber,
                  onTap: fuzzy == 0
                      ? null
                      : () => _reviewCards(context, Familiarity.fuzzy),
                ),
              ),
              Expanded(
                child: _ResultMetric(
                  key: const ValueKey('result-forgotten-count'),
                  value: forgotten,
                  label: context.l10n.tr('forgotten'),
                  color: LoopTheme.coral,
                  onTap: forgotten == 0
                      ? null
                      : () => _reviewCards(context, Familiarity.forgotten),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          _DistributionBar(
            key: const ValueKey('result-distribution'),
            mastered: mastered,
            fuzzy: fuzzy,
            forgotten: forgotten,
          ),
        ],
      ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  const _ResultMetric({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  final int value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      enabled: onTap != null,
      label: '$label $value',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 28,
                height: 1,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.loopColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DistributionBar extends StatelessWidget {
  const _DistributionBar({
    super.key,
    required this.mastered,
    required this.fuzzy,
    required this.forgotten,
  });

  final int mastered;
  final int fuzzy;
  final int forgotten;

  @override
  Widget build(BuildContext context) {
    final total = mastered + fuzzy + forgotten;
    if (total == 0) {
      return Container(
        height: 8,
        decoration: BoxDecoration(
          color: context.loopColors.divider,
          borderRadius: BorderRadius.circular(99),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: 8,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (mastered > 0)
              Expanded(
                flex: mastered,
                child: const ColoredBox(color: LoopTheme.teal),
              ),
            if (fuzzy > 0)
              Expanded(
                flex: fuzzy,
                child: const ColoredBox(color: LoopTheme.amber),
              ),
            if (forgotten > 0)
              Expanded(
                flex: forgotten,
                child: const ColoredBox(color: LoopTheme.coral),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.attempt, required this.nextLabel});

  final CardAttempt attempt;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    final (labelKey, color) = switch (attempt.familiarity) {
      Familiarity.mastered => ('mastered', LoopTheme.teal),
      Familiarity.fuzzy => ('fuzzy', LoopTheme.amber),
      Familiarity.forgotten => ('forgotten', LoopTheme.coral),
    };
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              attempt.prompt,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.loopColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 66,
            child: Text(
              context.l10n.tr(labelKey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(
              nextLabel,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: context.loopColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

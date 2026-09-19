import 'package:flutter/material.dart';

import '../ai/word_card_generator.dart';
import '../l10n/app_localizations.dart';
import '../models/card_models.dart';
import '../theme/loop_theme.dart';
import '../widgets/app_page.dart';
import '../widgets/glass_surface.dart';
import 'study_screen.dart';

class DeckDetailScreen extends StatelessWidget {
  const DeckDetailScreen({
    super.key,
    required this.deck,
    this.onAttemptsCompleted,
    this.wordCardGenerator,
    this.onAppendGeneratedCards,
  });

  final CardDeck deck;
  final Future<List<CardScheduleUpdate>> Function(List<CardAttempt> attempts)?
  onAttemptsCompleted;
  final WordCardGenerator? wordCardGenerator;
  final Future<void> Function(List<WordCardDraft> drafts)?
  onAppendGeneratedCards;

  @override
  Widget build(BuildContext context) {
    final completion = (deck.masteryProgress * 100).round();
    final dueCards = deck.dueCards();
    final practiceCards = dueCards.isEmpty ? deck.cards : dueCards;
    final practiceDeck = deck.copyWith(cards: practiceCards);
    return AppPage(
      title: context.l10n.tr('deckDetail'),
      footer: SizedBox(
        height: 60,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: LoopTheme.teal.withValues(alpha: 0.96),
            foregroundColor: const Color(0xFF091413),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          onPressed: practiceCards.isEmpty
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => StudyScreen(
                      deck: practiceDeck,
                      onAttemptsCompleted: onAttemptsCompleted,
                      wordCardGenerator: wordCardGenerator,
                      onAppendGeneratedCards: onAppendGeneratedCards,
                    ),
                  ),
                ),
          child: Text(
            dueCards.isEmpty
                ? context.l10n.tr('practiceAllCards')
                : context.l10n.tr('reviewDueCards', {'count': dueCards.length}),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.deckSubtitle(deck.id, deck.subtitle),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: LoopTheme.teal,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.deckTitle(deck.id, deck.title),
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: context.loopColors.ink,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                '${context.l10n.tr('dueNow', {'count': dueCards.length})} · '
                '${context.l10n.tr('scheduledLater', {'count': deck.cards.length - dueCards.length})}',
                style: TextStyle(fontSize: 14, color: context.loopColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 28),
          GlassSurface(
            radius: 30,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 23, 24, 21),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.tr('thisSession'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: context.loopColors.muted,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${practiceCards.length}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 54,
                          height: 1.05,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.5,
                          color: context.loopColors.ink,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 7, bottom: 7),
                        child: Text(
                          context.l10n.tr('cardUnit'),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: context.loopColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    dueCards.isEmpty
                        ? context.l10n.tr('practiceAllCards')
                        : context.l10n.tr('reviewDueCards', {
                            'count': dueCards.length,
                          }),
                    style: TextStyle(
                      fontSize: 13,
                      color: context.loopColors.muted,
                    ),
                  ),
                  const SizedBox(height: 25),
                  _DistributionBar(deck: deck),
                  const SizedBox(height: 17),
                  Row(
                    children: [
                      Expanded(
                        child: _StatusValue(
                          label: context.l10n.tr('mastered'),
                          value: deck.mastered,
                          color: LoopTheme.teal,
                        ),
                      ),
                      Expanded(
                        child: _StatusValue(
                          label: context.l10n.tr('fuzzy'),
                          value: deck.fuzzy,
                          color: LoopTheme.amber,
                        ),
                      ),
                      Expanded(
                        child: _StatusValue(
                          label: context.l10n.tr('forgotten'),
                          value: deck.forgotten,
                          color: LoopTheme.coral,
                        ),
                      ),
                      Expanded(
                        child: _StatusValue(
                          label: context.l10n.tr('unseen'),
                          value: deck.unseenCount,
                          color: context.loopColors.inactive,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: context.loopColors.divider,
                  ),
                  const SizedBox(height: 17),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.tr(deck.learningStage.localizationKey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.loopColors.subtle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        flex: 2,
                        child: Text(
                          '${context.l10n.tr('masteryProgress', {'rate': completion})} · '
                          '${context.l10n.tr('coverageSummary', {'reviewed': deck.reviewedCount, 'total': deck.cards.length})}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: context.loopColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DistributionBar extends StatelessWidget {
  const _DistributionBar({required this.deck});

  final CardDeck deck;

  @override
  Widget build(BuildContext context) {
    final segments = <(int, Color)>[
      (deck.mastered, LoopTheme.teal),
      (deck.fuzzy, LoopTheme.amber),
      (deck.forgotten, LoopTheme.coral),
      (deck.unseenCount, context.loopColors.inactive),
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: double.infinity,
        height: 7,
        child: Row(
          children: [
            for (final segment in segments)
              if (segment.$1 > 0)
                Expanded(
                  flex: segment.$1,
                  child: SizedBox.expand(child: ColoredBox(color: segment.$2)),
                ),
            if (segments.every((segment) => segment.$1 == 0))
              Expanded(child: ColoredBox(color: context.loopColors.inactive)),
          ],
        ),
      ),
    );
  }
}

class _StatusValue extends StatelessWidget {
  const _StatusValue({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: context.loopColors.subtle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          '$value',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 21,
            fontWeight: FontWeight.w600,
            color: context.loopColors.ink,
          ),
        ),
      ],
    );
  }
}

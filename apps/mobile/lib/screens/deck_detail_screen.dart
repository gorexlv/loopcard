import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/card_models.dart';
import '../theme/loop_theme.dart';
import '../widgets/design_canvas.dart';
import '../widgets/figma_icon.dart';
import '../widgets/glass_surface.dart';
import 'card_studio_screen.dart';
import 'study_screen.dart';

class DeckDetailScreen extends StatelessWidget {
  const DeckDetailScreen({
    super.key,
    required this.deck,
    this.onAttemptsCompleted,
  });

  final CardDeck deck;
  final Future<void> Function(List<CardAttempt> attempts)? onAttemptsCompleted;

  @override
  Widget build(BuildContext context) {
    final completion = ((deck.mastered + deck.fuzzy) / deck.cards.length * 100)
        .round();
    return DesignCanvas(
      child: GradientPage(
        children: [
          Positioned(
            left: 32,
            top: 650,
            width: 326,
            height: 54,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: context.loopColors.ink,
                side: BorderSide(color: context.loopColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      CardStudioScreen(card: deck.cards.first, kind: deck.kind),
                ),
              ),
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: const Text('设计卡片'),
            ),
          ),
          Positioned(
            left: 32,
            top: 48,
            width: 326,
            height: 44,
            child: Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                  child: const FigmaIcon('back', size: 28),
                ),
                const SizedBox(width: 14),
                Text(
                  context.l10n.tr('deckDetail'),
                  style: TextStyle(
                    fontSize: 14,
                    color: context.loopColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 32,
            top: 132,
            width: 326,
            child: Column(
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
                  context.l10n.tr('recentPractice', {
                    'count': deck.cards.length,
                  }),
                  style: TextStyle(
                    fontSize: 14,
                    color: context.loopColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 32,
            top: 270,
            width: 326,
            height: 330,
            child: GlassSurface(
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
                          '${deck.cards.length}',
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
                      context.l10n.tr('sessionEstimate'),
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
                      ],
                    ),
                    const Spacer(),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: context.loopColors.divider,
                    ),
                    const SizedBox(height: 17),
                    Row(
                      children: [
                        Text(
                          context.l10n.tr('totalSessions'),
                          style: TextStyle(
                            fontSize: 13,
                            color: context.loopColors.subtle,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          context.l10n.tr('completion', {'rate': completion}),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: context.loopColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 32,
            top: 724,
            width: 326,
            height: 60,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: LoopTheme.teal.withValues(alpha: 0.96),
                foregroundColor: const Color(0xFF091413),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => StudyScreen(
                    deck: deck,
                    onAttemptsCompleted: onAttemptsCompleted,
                  ),
                ),
              ),
              child: Text(
                context.l10n.tr('startPractice'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
    int safeFlex(int value) => value == 0 ? 1 : value;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: double.infinity,
        height: 7,
        child: Row(
          children: [
            Expanded(
              flex: safeFlex(deck.mastered),
              child: const SizedBox.expand(
                child: ColoredBox(color: LoopTheme.teal),
              ),
            ),
            Expanded(
              flex: safeFlex(deck.fuzzy),
              child: const SizedBox.expand(
                child: ColoredBox(color: LoopTheme.amber),
              ),
            ),
            Expanded(
              flex: safeFlex(deck.forgotten),
              child: const SizedBox.expand(
                child: ColoredBox(color: LoopTheme.coral),
              ),
            ),
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
            Text(
              label,
              style: TextStyle(fontSize: 12, color: context.loopColors.subtle),
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

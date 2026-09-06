import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/card_models.dart';
import '../theme/loop_theme.dart';
import '../widgets/design_canvas.dart';
import '../widgets/figma_icon.dart';
import '../widgets/glass_surface.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.deck, required this.attempts});

  final CardDeck deck;
  final List<CardAttempt> attempts;

  @override
  Widget build(BuildContext context) {
    return DesignCanvas(
      child: GradientPage(
        children: [
          Positioned(
            left: 32,
            top: 58,
            child: Text(
              context.l10n.tr('practiceResults'),
              style: TextStyle(fontSize: 14, color: context.loopColors.muted),
            ),
          ),
          Positioned(
            left: 159,
            top: 132,
            child: FigmaIcon('success', size: 72),
          ),
          Positioned(
            left: 32,
            top: 230,
            width: 326,
            child: Text(
              context.l10n.tr('sessionComplete'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: context.loopColors.ink,
              ),
            ),
          ),
          Positioned(
            left: 32,
            top: 278,
            width: 326,
            child: Text(
              '${context.l10n.deckTitle(deck.id, deck.title)} · ${attempts.length} / ${deck.cards.length}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: context.loopColors.muted),
            ),
          ),
          Positioned(
            left: 32,
            top: 342,
            width: 326,
            height: 250,
            child: GlassSurface(
              radius: 30,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(23, 25, 18, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.tr('cardResults'),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: context.loopColors.ink,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: attempts.length,
                        itemExtent: 27,
                        itemBuilder: (_, index) {
                          final attempt = attempts[index];
                          return Row(
                            children: [
                              SizedBox(
                                width: 116,
                                child: Text(
                                  attempt.prompt,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    color: context.loopColors.ink,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 68,
                                child: Text(
                                  context.l10n.tr(switch (attempt.familiarity) {
                                    Familiarity.mastered => 'mastered',
                                    Familiarity.fuzzy => 'fuzzy',
                                    Familiarity.forgotten => 'forgotten',
                                  }),
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: context.loopColors.ink,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  attempt.familiarity == Familiarity.forgotten
                                      ? context.l10n.tr('todayAgain')
                                      : context.l10n.tr('plusDays', {
                                          'count':
                                              attempt.familiarity ==
                                                  Familiarity.mastered
                                              ? 3
                                              : 1,
                                        }),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: context.loopColors.muted,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 32,
            top: 610,
            width: 326,
            child: Text(
              context.l10n.tr('swipeMore', {'count': attempts.length}),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: context.loopColors.subtle),
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
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                context.l10n.tr('finishReturn'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

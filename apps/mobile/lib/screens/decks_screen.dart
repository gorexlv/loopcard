import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/card_models.dart';
import '../theme/loop_theme.dart';
import '../widgets/brand_lockup.dart';
import '../widgets/design_canvas.dart';
import '../widgets/glass_surface.dart';
import '../widgets/primary_navigation.dart';
import 'deck_detail_screen.dart';

class DecksScreen extends StatelessWidget {
  const DecksScreen({
    super.key,
    required this.decks,
    this.onTabSelected,
    this.onAttemptsCompleted,
    this.onOpenMarket,
  });

  final List<CardDeck> decks;
  final ValueChanged<AppSection>? onTabSelected;
  final Future<void> Function(CardDeck deck, List<CardAttempt> attempts)?
  onAttemptsCompleted;
  final VoidCallback? onOpenMarket;

  void _openDeck(BuildContext context, CardDeck deck) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: DeckDetailScreen(
            deck: deck,
            onAttemptsCompleted: onAttemptsCompleted == null
                ? null
                : (attempts) => onAttemptsCompleted!(deck, attempts),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalCards = decks.fold<int>(
      0,
      (sum, deck) => sum + deck.cards.length,
    );
    final dueCards = decks.fold<int>(
      0,
      (sum, deck) => sum + deck.fuzzy + deck.forgotten,
    );
    return DesignCanvas(
      child: GradientPage(
        children: [
          Positioned(
            left: 32,
            top: 58,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BrandLockup(),
                const SizedBox(height: 10),
                Text(
                  context.l10n.tr('decksTitle'),
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: context.loopColors.ink,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 32,
            top: 58,
            child: TextButton.icon(
              key: const ValueKey('open-market'),
              onPressed: onOpenMarket,
              icon: const Icon(Icons.storefront_outlined, size: 20),
              label: Text(context.l10n.tr('market')),
              style: TextButton.styleFrom(
                foregroundColor: context.loopColors.ink,
                backgroundColor: context.loopColors.glassStrong,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                shape: const StadiumBorder(),
              ),
            ),
          ),
          Positioned(
            left: 32,
            top: 142,
            width: 326,
            height: 104,
            child: GlassSurface(
              radius: 28,
              child: Row(
                children: [
                  _OverviewValue(
                    value: '${decks.length}',
                    label: context.l10n.tr('navDecks'),
                  ),
                  const _Divider(),
                  _OverviewValue(
                    value: '$totalCards',
                    label: context.l10n.tr('cards'),
                  ),
                  const _Divider(),
                  _OverviewValue(
                    value: '$dueCards',
                    label: context.l10n.tr('due'),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 32,
            top: 282,
            child: Text(
              context.l10n.tr('allDecks'),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: context.loopColors.ink,
              ),
            ),
          ),
          ...List.generate(decks.length, (index) {
            final deck = decks[index];
            return Positioned(
              left: 32,
              top: 318 + index * 154,
              width: 326,
              height: 136,
              child: _DeckRow(
                deck: deck,
                onTap: () => _openDeck(context, deck),
              ),
            );
          }),
          Positioned(
            left: 32,
            top: 744,
            width: 326,
            height: 72,
            child: PrimaryNavigation(
              current: AppSection.decks,
              onSelected: onTabSelected,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewValue extends StatelessWidget {
  const _OverviewValue({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: context.loopColors.ink,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: context.loopColors.muted),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 34, color: context.loopColors.divider);
  }
}

class _DeckRow extends StatelessWidget {
  const _DeckRow({required this.deck, required this.onTap});

  final CardDeck deck;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = deck.mastered / deck.cards.length;
    final subject = deck.kind == CardKind.word
        ? context.l10n.tr('wordVocabulary')
        : context.l10n.tr('chemicalFormulas');
    return GestureDetector(
      onTap: onTap,
      child: GlassSurface(
        radius: 26,
        blur: 10,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.deckTitle(deck.id, deck.title),
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: context.loopColors.ink,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '$subject · ${context.l10n.tr('cardsCount', {'count': deck.cards.length})}',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.loopColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '›',
                    style: TextStyle(
                      fontSize: 28,
                      height: 1,
                      color: context.loopColors.muted,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: context.loopColors.divider,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    LoopTheme.teal,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.tr('progressSummary', {
                  'mastered': deck.mastered,
                  'due': deck.fuzzy + deck.forgotten,
                }),
                style: TextStyle(
                  fontSize: 12,
                  color: context.loopColors.subtle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

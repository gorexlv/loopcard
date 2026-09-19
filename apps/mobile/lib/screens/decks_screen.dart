import 'package:flutter/material.dart';

import '../ai/word_card_generator.dart';
import '../l10n/app_localizations.dart';
import '../models/card_models.dart';
import '../theme/loop_theme.dart';
import '../widgets/primary_page.dart';
import '../widgets/glass_surface.dart';
import 'deck_detail_screen.dart';

class DecksScreen extends StatelessWidget {
  const DecksScreen({
    super.key,
    required this.decks,
    this.onAttemptsCompleted,
    this.onOpenMarket,
    this.wordCardGenerator,
    this.onAppendGeneratedCards,
  });

  final List<CardDeck> decks;
  final Future<List<CardScheduleUpdate>> Function(
    CardDeck deck,
    List<CardAttempt> attempts,
  )?
  onAttemptsCompleted;
  final VoidCallback? onOpenMarket;
  final WordCardGenerator? wordCardGenerator;
  final Future<void> Function(CardDeck deck, List<WordCardDraft> drafts)?
  onAppendGeneratedCards;

  void _openDeck(BuildContext context, CardDeck deck) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: DeckDetailScreen(
            deck: deck,
            wordCardGenerator: wordCardGenerator,
            onAttemptsCompleted: onAttemptsCompleted == null
                ? null
                : (attempts) => onAttemptsCompleted!(deck, attempts),
            onAppendGeneratedCards: onAppendGeneratedCards == null
                ? null
                : (drafts) => onAppendGeneratedCards!(deck, drafts),
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
    final dueCards = decks.fold<int>(0, (sum, deck) => sum + deck.dueCount());
    return PrimaryPage(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tablet = constraints.maxWidth >= 600;
          return CustomScrollView(
            key: ValueKey(tablet ? 'deck-grid' : 'deck-list'),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(onOpenMarket: onOpenMarket),
                    SizedBox(height: tablet ? 28 : 22),
                    SizedBox(
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
                    SizedBox(height: tablet ? 30 : 28),
                    Text(
                      context.l10n.tr('allDecks'),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: context.loopColors.ink,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
              SliverList.separated(
                itemCount: tablet ? (decks.length / 2).ceil() : decks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 18),
                itemBuilder: (context, index) {
                  Widget card(int i) => _DeckRow(
                    deck: decks[i],
                    onTap: () => _openDeck(context, decks[i]),
                  );
                  if (!tablet) return card(index);
                  final left = index * 2;
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: card(left)),
                        const SizedBox(width: 18),
                        Expanded(
                          child: left + 1 < decks.length
                              ? card(left + 1)
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onOpenMarket});

  final VoidCallback? onOpenMarket;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
        const Spacer(),
        TextButton.icon(
          key: const ValueKey('open-market'),
          onPressed: onOpenMarket,
          icon: const Icon(Icons.storefront_outlined, size: 20),
          label: Text(context.l10n.tr('market')),
          style: TextButton.styleFrom(
            foregroundColor: context.loopColors.ink,
            backgroundColor: context.loopColors.glassStrong,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            shape: const StadiumBorder(),
          ),
        ),
      ],
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
    final progress = deck.masteryProgress;
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
              const SizedBox(height: 18),
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
                context.l10n.tr('deckProgressSummary', {
                  'rate': (deck.masteryProgress * 100).round(),
                  'due': deck.dueCount(),
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

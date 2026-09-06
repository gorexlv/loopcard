import 'package:flutter/material.dart';

import '../cards/editorial_card.dart';
import '../l10n/app_localizations.dart';
import '../models/card_models.dart';
import '../theme/loop_theme.dart';
import '../widgets/design_canvas.dart';
import '../widgets/figma_icon.dart';
import 'result_screen.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key, required this.deck, this.onAttemptsCompleted});
  final CardDeck deck;
  final Future<void> Function(List<CardAttempt> attempts)? onAttemptsCompleted;

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  int _cardIndex = 0;
  int _sectionIndex = 0;
  bool _showBack = false;
  final List<CardAttempt> _attempts = [];

  StudyCard get _card => widget.deck.cards[_cardIndex];

  @override
  void didUpdateWidget(covariant StudyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deck.id != widget.deck.id) {
      _cardIndex = 0;
      _sectionIndex = 0;
      _showBack = false;
      _attempts.clear();
    }
  }

  void _toggleFace() => setState(() => _showBack = !_showBack);

  void _selectSection(int index) => setState(() {
    _sectionIndex = index;
    _showBack = true;
  });

  Future<void> _rate(Familiarity familiarity) async {
    _attempts.add(
      CardAttempt(
        cardId: _card.id,
        prompt: _card.prompt,
        familiarity: familiarity,
      ),
    );
    if (_cardIndex == widget.deck.cards.length - 1) {
      await widget.onAttemptsCompleted?.call(List.unmodifiable(_attempts));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ResultScreen(
            deck: widget.deck,
            attempts: List.unmodifiable(_attempts),
          ),
        ),
      );
      return;
    }
    setState(() {
      _cardIndex += 1;
      _sectionIndex = 0;
      _showBack = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return DesignCanvas(
      child: GradientPage(
        children: [
          Positioned(
            left: 32,
            top: 48,
            width: 326,
            height: 44,
            child: _header(),
          ),
          Positioned(
            left: 18,
            top: 112,
            width: 354,
            height: 500,
            child: AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 360),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final scale = Tween<double>(
                  begin: 0.975,
                  end: 1,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: scale, child: child),
                );
              },
              child: EditorialCard(
                key: ValueKey(
                  '${_card.id}-${_showBack ? 'back-$_sectionIndex' : 'front'}',
                ),
                card: _card,
                kind: widget.deck.kind,
                face: _showBack ? CardFace.back : CardFace.front,
                sectionIndex: _sectionIndex,
                onTap: _toggleFace,
              ),
            ),
          ),
          if (_showBack)
            Positioned(
              left: 22,
              top: 624,
              width: 346,
              height: 48,
              child: _sectionPicker(),
            ),
          Positioned(
            left: 65,
            top: _showBack ? 680 : 628,
            width: 260,
            child: Text(
              _showBack
                  ? context.l10n.tr('backHint')
                  : context.l10n.tr('frontHint'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: context.loopColors.subtle,
              ),
            ),
          ),
          if (_showBack)
            Positioned(
              left: 20,
              top: 724,
              width: 350,
              height: 68,
              child: _ratingButtons(),
            ),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Semantics(
          label: '返回',
          button: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Center(child: FigmaIcon('back', size: 28)),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '${_cardIndex + 1} / ${widget.deck.cards.length}',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.loopColors.muted,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            context.l10n.deckTitle(widget.deck.id, widget.deck.title),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: context.loopColors.muted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionPicker() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      itemCount: _card.sections.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final selected = index == _sectionIndex;
        return Semantics(
          selected: selected,
          button: true,
          child: InkWell(
            onTap: () => _selectSection(index),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              constraints: const BoxConstraints(minWidth: 88, minHeight: 44),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected
                    ? context.loopColors.glassStrong
                    : context.loopColors.glass,
                border: Border.all(
                  color: selected
                      ? LoopTheme.teal.withValues(alpha: 0.55)
                      : context.loopColors.border,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                context.l10n.sectionTitle(_card.sections[index].title),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? context.loopColors.ink
                      : context.loopColors.subtle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _ratingButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _RatingButton(
          label: context.l10n.tr('mastered'),
          color: LoopTheme.teal,
          onTap: () => _rate(Familiarity.mastered),
        ),
        _RatingButton(
          label: context.l10n.tr('fuzzy'),
          color: LoopTheme.amber,
          onTap: () => _rate(Familiarity.fuzzy),
        ),
        _RatingButton(
          label: context.l10n.tr('forgotten'),
          color: LoopTheme.coral,
          onTap: () => _rate(Familiarity.forgotten),
        ),
      ],
    );
  }
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({
    required this.label,
    required this.color,
    required this.onTap,
  });
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 104,
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 17, color: context.loopColors.ink),
              ),
              const SizedBox(height: 9),
              Container(
                width: 26,
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

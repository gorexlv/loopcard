import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/card_models.dart';
import '../ocr/word_capture_flow.dart';
import '../theme/loop_theme.dart';
import '../widgets/brand_lockup.dart';
import '../widgets/design_canvas.dart';
import '../widgets/figma_icon.dart';
import '../widgets/glass_surface.dart';
import '../widgets/primary_navigation.dart';
import 'deck_detail_screen.dart';
import 'ocr_result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.decks,
    this.wordCaptureFlow,
    this.onCreateDeckFromWords,
    this.onAttemptsCompleted,
    this.onTabSelected,
  });

  final List<CardDeck> decks;
  final WordCaptureFlow? wordCaptureFlow;
  final Future<void> Function(List<String> words)? onCreateDeckFromWords;
  final Future<void> Function(CardDeck deck, List<CardAttempt> attempts)?
  onAttemptsCompleted;
  final ValueChanged<AppSection>? onTabSelected;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isRecognizing = false;

  void _openDeck(BuildContext context, CardDeck deck) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: DeckDetailScreen(
            deck: deck,
            onAttemptsCompleted: widget.onAttemptsCompleted == null
                ? null
                : (attempts) => widget.onAttemptsCompleted!(deck, attempts),
          ),
        ),
      ),
    );
  }

  Future<void> _captureWords() async {
    final flow = widget.wordCaptureFlow;
    if (flow == null) {
      _showMessage(context.l10n.tr('ocrMissing'));
      return;
    }

    setState(() => _isRecognizing = true);
    try {
      final words = await flow.captureWords();
      if (!mounted || words == null) return;
      if (words.isEmpty) {
        _showMessage(context.l10n.tr('ocrEmpty'));
        return;
      }

      Navigator.of(context).push(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 280),
          pageBuilder: (context, animation, secondaryAnimation) =>
              FadeTransition(
                opacity: animation,
                child: OcrResultScreen(
                  words: words,
                  onConfirm: (selected) async {
                    await widget.onCreateDeckFromWords?.call(selected);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              ),
        ),
      );
    } on OcrException {
      if (mounted) _showMessage(context.l10n.tr('ocrFailed'));
    } catch (_) {
      if (mounted) _showMessage(context.l10n.tr('ocrFailed'));
    } finally {
      if (mounted) setState(() => _isRecognizing = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
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
                  context.l10n.tr('homeHeadline'),
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    color: context.loopColors.ink,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 32,
            top: 178,
            width: 326,
            height: 214,
            child: GestureDetector(
              onTap: _isRecognizing ? null : _captureWords,
              child: GlassSurface(
                radius: 32,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isRecognizing)
                      const SizedBox(
                        width: 42,
                        height: 42,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: LoopTheme.teal,
                        ),
                      )
                    else
                      FigmaIcon(
                        'camera',
                        size: 48,
                        color: context.loopColors.ink,
                      ),
                    const SizedBox(height: 14),
                    Text(
                      _isRecognizing
                          ? context.l10n.tr('recognizing')
                          : context.l10n.tr('captureCards'),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: context.loopColors.ink,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      context.l10n.tr('captureHint'),
                      style: TextStyle(
                        fontSize: 14,
                        color: context.loopColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 32,
            top: 474,
            child: Text(
              context.l10n.tr('myDecks'),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: context.loopColors.ink,
              ),
            ),
          ),
          Positioned(
            left: 32,
            top: 506,
            width: 326,
            height: 132,
            child: Row(
              children: [
                Expanded(
                  child: _PackCard(
                    deck: widget.decks[0],
                    onTap: () => _openDeck(context, widget.decks[0]),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _PackCard(
                    deck: widget.decks[1],
                    onTap: () => _openDeck(context, widget.decks[1]),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 32,
            top: 744,
            width: 326,
            height: 72,
            child: PrimaryNavigation(
              current: AppSection.learn,
              onSelected: widget.onTabSelected,
            ),
          ),
        ],
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  const _PackCard({required this.deck, required this.onTap});

  final CardDeck deck;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassSurface(
        radius: 24,
        blur: 10,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 12, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.deckTitle(deck.id, deck.title),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: context.loopColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.tr('cardsCount', {'count': deck.cards.length}),
                style: const TextStyle(
                  fontFamily: 'NotoSansSC',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF2A614),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

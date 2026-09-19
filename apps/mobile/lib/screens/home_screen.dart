import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../ai/word_card_generator.dart';
import '../ai/card_agent.dart';
import '../ocr/photo_batch.dart';
import 'photo_batch_screen.dart';
import 'card_agent_screen.dart';
import '../models/card_models.dart';
import '../ocr/word_capture_flow.dart';
import '../theme/loop_theme.dart';
import '../widgets/primary_page.dart';
import '../widgets/figma_icon.dart';
import '../widgets/glass_surface.dart';
import 'deck_detail_screen.dart';
import 'ocr_result_screen.dart';
import 'word_draft_review_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.decks,
    this.wordCaptureFlow,
    this.wordCardGenerator = const MemoryWordCardGenerator(),
    this.onCreateCapturedDeck,
    this.cardAgent,
    this.onAttemptsCompleted,
    this.onAppendGeneratedCards,
  });

  final List<CardDeck> decks;
  final CardAgent? cardAgent;
  final WordCaptureFlow? wordCaptureFlow;
  final WordCardGenerator wordCardGenerator;
  final Future<void> Function(
    String title,
    List<String> sourceWords,
    List<WordCardDraft> drafts,
  )?
  onCreateCapturedDeck;
  final Future<List<CardScheduleUpdate>> Function(
    CardDeck deck,
    List<CardAttempt> attempts,
  )?
  onAttemptsCompleted;
  final Future<void> Function(CardDeck deck, List<WordCardDraft> drafts)?
  onAppendGeneratedCards;

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
            wordCardGenerator: widget.wordCardGenerator,
            onAttemptsCompleted: widget.onAttemptsCompleted == null
                ? null
                : (attempts) => widget.onAttemptsCompleted!(deck, attempts),
            onAppendGeneratedCards: widget.onAppendGeneratedCards == null
                ? null
                : (drafts) => widget.onAppendGeneratedCards!(deck, drafts),
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

    if (flow is PhotoCaptureFlow) {
      await _openAgentCapture(flow);
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
                    final saved = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => WordDraftReviewScreen(
                          initialDeckTitle: 'Captured words',
                          loadDrafts: () =>
                              widget.wordCardGenerator.generateWords(
                                selected,
                                outputLocale: AppLocalizations.resolveLocaleKey(
                                  Localizations.localeOf(context),
                                ),
                              ),
                          onSave: (title, drafts) async {
                            await widget.onCreateCapturedDeck?.call(
                              title,
                              selected,
                              drafts,
                            );
                          },
                        ),
                      ),
                    );
                    if (saved == true && context.mounted) {
                      Navigator.of(context).pop();
                    }
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

  Future<void> _openAgentCapture(PhotoCaptureFlow flow) async {
    final generator = widget.wordCardGenerator;
    final agent =
        widget.cardAgent ??
        (generator is SupabaseWordCardGenerator ? generator.cardAgent : null);
    if (agent == null || widget.onCreateCapturedDeck == null) {
      _showMessage('请连接 Card Agent 服务后生成卡片。');
      return;
    }
    setState(() => _isRecognizing = true);
    try {
      final store = AgentSessionStore(agent.owner);
      var restored = await store.load();
      if (!mounted) return;
      if (restored != null && restored['saved'] != true) {
        final choice = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('继续生成卡片'),
            content: const Text('有尚未完成的生成对话，可以继续或拍摄新素材。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'new'),
                child: const Text('新拍摄'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, 'resume'),
                child: const Text('继续对话'),
              ),
            ],
          ),
        );
        if (choice == null || !mounted) return;
        if (choice == 'new') restored = null;
      } else {
        restored = null;
      }
      List<Map<String, dynamic>> sources;
      if (restored == null) {
        final captured = await Navigator.push<List<Map<String, dynamic>>>(
          context,
          MaterialPageRoute(builder: (_) => PhotoBatchScreen(flow: flow)),
        );
        if (captured == null || !mounted) return;
        sources = captured;
      } else {
        sources = [
          for (final source in restored['sources'])
            Map<String, dynamic>.from(source),
        ];
      }
      if (!mounted) return;
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => CardAgentScreen(
            agent: agent,
            store: store,
            sources: sources,
            restored: restored,
            onSave: widget.onCreateCapturedDeck!,
          ),
        ),
      );
    } catch (_) {
      if (mounted) _showMessage('暂时无法打开生成会话，请重试。');
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
    return PrimaryPage(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
          const SizedBox(height: 16),
          SizedBox(
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
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.only(bottom: 0),
            child: Text(
              context.l10n.tr('myDecks'),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: context.loopColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: widget.decks.isEmpty
                ? Center(
                    child: Text(
                      context.l10n.tr('captureHint'),
                      style: TextStyle(color: context.loopColors.muted),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (
                        var index = 0;
                        index < widget.decks.length.clamp(0, 2);
                        index++
                      ) ...[
                        if (index > 0) const SizedBox(width: 16),
                        Expanded(
                          child: _PackCard(
                            deck: widget.decks[index],
                            onTap: () =>
                                _openDeck(context, widget.decks[index]),
                          ),
                        ),
                      ],
                    ],
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 132),
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
      ),
    );
  }
}

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../ai/word_card_generator.dart';
import '../audio/word_pronunciation_service.dart';
import '../cards/editorial_card.dart';
import '../cards/literary_layout.dart';
import '../l10n/app_localizations.dart';
import '../models/card_models.dart';
import '../theme/loop_theme.dart';
import '../widgets/app_page.dart';
import '../widgets/figma_icon.dart';
import 'result_screen.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({
    super.key,
    required this.deck,
    this.onAttemptsCompleted,
    this.wordCardGenerator,
    this.onAppendGeneratedCards,
    this.readOnly = false,
  });

  final CardDeck deck;
  final Future<List<CardScheduleUpdate>> Function(List<CardAttempt> attempts)?
  onAttemptsCompleted;
  final WordCardGenerator? wordCardGenerator;
  final Future<void> Function(List<WordCardDraft> drafts)?
  onAppendGeneratedCards;
  final bool readOnly;

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen>
    with SingleTickerProviderStateMixin {
  static const _dragThreshold = 108.0;
  static const _velocityThreshold = 800.0;
  static const _verticalIntentSlop = 18.0;
  static const _verticalIntentRatio = 1.4;

  int _cardIndex = 0;
  int _sectionIndex = 0;
  bool _showBack = false;
  bool _hintRevealed = false;
  bool _assistanceUsed = false;
  bool _inputLocked = false;
  bool _awaitingCompletion = false;
  bool _canUndoRating = false;
  bool _backContentScrollable = false;
  bool _finishing = false;
  bool _thresholdFeedbackSent = false;
  bool _disableAnimations = false;
  bool _faceTransitioning = false;
  Object? _finishError;
  double _dragOffset = 0;
  Offset? _verticalDragOrigin;
  bool _verticalDragAccepted = false;
  Timer? _completionTimer;
  Timer? _ratingUndoTimer;
  Timer? _faceTransitionTimer;
  late final AnimationController _settleController;
  final List<CardAttempt> _attempts = [];
  final WordPronunciationService _pronunciationService =
      const WordPronunciationService();
  _CardStudySnapshot? _lastSnapshot;

  StudyCard get _card => widget.deck.cards[_cardIndex];
  bool get _reduceMotion => _disableAnimations;
  Familiarity get _upFamiliarity =>
      _assistanceUsed ? Familiarity.fuzzy : Familiarity.mastered;

  @override
  void initState() {
    super.initState();
    _settleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  @override
  void didUpdateWidget(covariant StudyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deck.id != widget.deck.id) {
      _completionTimer?.cancel();
      _ratingUndoTimer?.cancel();
      _faceTransitionTimer?.cancel();
      _cardIndex = 0;
      _sectionIndex = 0;
      _showBack = false;
      _hintRevealed = false;
      _assistanceUsed = false;
      _inputLocked = false;
      _awaitingCompletion = false;
      _canUndoRating = false;
      _backContentScrollable = false;
      _finishing = false;
      _faceTransitioning = false;
      _finishError = null;
      _dragOffset = 0;
      _attempts.clear();
      _lastSnapshot = null;
    }
  }

  @override
  void dispose() {
    _completionTimer?.cancel();
    _ratingUndoTimer?.cancel();
    _faceTransitionTimer?.cancel();
    _settleController.dispose();
    super.dispose();
  }

  void _revealHint() {
    if (_inputLocked || _faceTransitioning || _hintRevealed) return;
    HapticFeedback.selectionClick();
    setState(() {
      _hintRevealed = true;
      _assistanceUsed = true;
    });
    SemanticsService.sendAnnouncement(
      View.of(context),
      context.l10n.tr('hintRevealed'),
      TextDirection.ltr,
    );
  }

  void _revealBack() {
    if (_inputLocked || _showBack) return;
    HapticFeedback.selectionClick();
    setState(() {
      _beginFaceTransition();
      _showBack = true;
      _assistanceUsed = true;
      _sectionIndex = 0;
      _backContentScrollable = false;
    });
    SemanticsService.sendAnnouncement(
      View.of(context),
      context.l10n.tr('backSectionAnnouncement', {
        'current': 1,
        'count':
            const ['poetry', 'classical'].contains(_card.presentation['skill'])
            ? literaryPages(_card).length
            : _card.reviewSections.length,
      }),
      TextDirection.ltr,
    );
  }

  void _returnToFront() {
    if (_inputLocked || !_showBack) return;
    HapticFeedback.selectionClick();
    setState(() {
      _beginFaceTransition();
      _showBack = false;
      _sectionIndex = 0;
      _backContentScrollable = false;
    });
    SemanticsService.sendAnnouncement(
      View.of(context),
      context.l10n.tr('cardFrontAnnouncement'),
      TextDirection.ltr,
    );
  }

  void _toggleCardFace() => _showBack ? _returnToFront() : _revealBack();

  void _beginFaceTransition() {
    _faceTransitionTimer?.cancel();
    _faceTransitioning = true;
    _faceTransitionTimer = Timer(
      _reduceMotion
          ? const Duration(milliseconds: 100)
          : const Duration(milliseconds: 280),
      () {
        if (!mounted) return;
        setState(() => _faceTransitioning = false);
      },
    );
  }

  Future<void> _pronounceWord() async {
    final pronunciations = _card.wordContent?.pronunciations ?? const [];
    final region = pronunciations.isEmpty ? '' : pronunciations.first.region;
    await _pronunciationService.speak(_card.prompt, region: region);
  }

  void _selectSection(int index) {
    if (_inputLocked || _faceTransitioning || index == _sectionIndex) return;
    HapticFeedback.selectionClick();
    setState(() {
      _sectionIndex = index;
      _backContentScrollable = false;
    });
    SemanticsService.sendAnnouncement(
      View.of(context),
      context.l10n.tr('backSectionAnnouncement', {
        'current': index + 1,
        'count':
            const ['poetry', 'classical'].contains(_card.presentation['skill'])
            ? literaryPages(_card).length
            : _card.reviewSections.length,
      }),
      TextDirection.ltr,
    );
  }

  void _onVerticalDragStart(DragStartDetails details) {
    if (_inputLocked || _faceTransitioning || _awaitingCompletion) return;
    _settleController.stop();
    _thresholdFeedbackSent = false;
    _verticalDragOrigin = details.globalPosition;
    _verticalDragAccepted = false;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_inputLocked || _faceTransitioning || _awaitingCompletion) return;
    final origin = _verticalDragOrigin;
    if (origin == null) return;
    final displacement = details.globalPosition - origin;
    if (!_verticalDragAccepted) {
      final isClearVerticalIntent =
          displacement.dy.abs() >= _verticalIntentSlop &&
          displacement.dy.abs() >= displacement.dx.abs() * _verticalIntentRatio;
      if (!isClearVerticalIntent) return;
      _verticalDragAccepted = true;
    }
    final intentOffset =
        displacement.dy - displacement.dy.sign * _verticalIntentSlop;
    setState(() {
      _dragOffset = intentOffset.clamp(-240, 240);
    });
    if (!_thresholdFeedbackSent && _dragOffset.abs() >= _dragThreshold) {
      _thresholdFeedbackSent = true;
      HapticFeedback.selectionClick();
    } else if (_thresholdFeedbackSent &&
        _dragOffset.abs() < _dragThreshold * 0.8) {
      _thresholdFeedbackSent = false;
    }
  }

  Future<void> _onVerticalDragEnd(DragEndDetails details) async {
    if (_inputLocked || _faceTransitioning || _awaitingCompletion) return;
    _verticalDragOrigin = null;
    if (!_verticalDragAccepted) {
      await _animateDragTo(0);
      return;
    }
    final velocity = details.primaryVelocity ?? 0;
    final shouldSubmit =
        _dragOffset.abs() >= _dragThreshold ||
        velocity.abs() >= _velocityThreshold;
    if (!shouldSubmit) {
      await _animateDragTo(0);
      return;
    }
    final upward = velocity.abs() >= _velocityThreshold
        ? velocity < 0
        : _dragOffset < 0;
    await _submitRating(
      upward ? _upFamiliarity : Familiarity.forgotten,
      upward: upward,
    );
  }

  void _onVerticalDragCancel() {
    _verticalDragOrigin = null;
    _verticalDragAccepted = false;
    _thresholdFeedbackSent = false;
    unawaited(_animateDragTo(0));
  }

  Future<void> _submitRating(
    Familiarity familiarity, {
    required bool upward,
  }) async {
    if (_inputLocked || _faceTransitioning || _awaitingCompletion) return;
    setState(() => _inputLocked = true);
    HapticFeedback.mediumImpact();
    await _animateDragTo(upward ? -650 : 650);
    if (!mounted) return;
    if (widget.readOnly) {
      _advanceReadOnlyReview();
      return;
    }
    _recordRating(familiarity);
  }

  void _advanceReadOnlyReview() {
    if (_cardIndex == widget.deck.cards.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _cardIndex += 1;
      _resetCardState();
    });
  }

  Future<void> _animateDragTo(double target) async {
    if (_reduceMotion) {
      if (mounted) setState(() => _dragOffset = target);
      return;
    }
    final start = _dragOffset;
    final animation = Tween<double>(begin: start, end: target).animate(
      CurvedAnimation(parent: _settleController, curve: Curves.easeOutCubic),
    );
    void tick() {
      if (mounted) setState(() => _dragOffset = animation.value);
    }

    animation.addListener(tick);
    try {
      await _settleController.forward(from: 0).orCancel;
    } on TickerCanceled {
      // A new gesture took ownership of the controller.
    } finally {
      animation.removeListener(tick);
    }
  }

  void _recordRating(Familiarity familiarity) {
    final snapshot = _CardStudySnapshot(
      cardIndex: _cardIndex,
      sectionIndex: _sectionIndex,
      showBack: _showBack,
      hintRevealed: _hintRevealed,
      assistanceUsed: _assistanceUsed,
    );
    _attempts.add(
      CardAttempt(
        cardId: _card.id,
        prompt: _card.prompt,
        familiarity: familiarity,
        assistanceUsed: _assistanceUsed,
      ),
    );
    _lastSnapshot = snapshot;

    if (_cardIndex == widget.deck.cards.length - 1) {
      _ratingUndoTimer?.cancel();
      setState(() {
        _dragOffset = 0;
        _awaitingCompletion = true;
        _canUndoRating = false;
        _inputLocked = false;
        _finishError = null;
      });
      _completionTimer?.cancel();
      _completionTimer = Timer(const Duration(seconds: 1), _finishSession);
      return;
    }

    setState(() {
      _cardIndex += 1;
      _resetCardState();
      _canUndoRating = true;
    });
    _ratingUndoTimer?.cancel();
    _ratingUndoTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || _awaitingCompletion) return;
      setState(() {
        _canUndoRating = false;
        _lastSnapshot = null;
      });
    });
  }

  void _resetCardState() {
    _faceTransitionTimer?.cancel();
    _sectionIndex = 0;
    _showBack = false;
    _hintRevealed = false;
    _assistanceUsed = false;
    _inputLocked = false;
    _thresholdFeedbackSent = false;
    _verticalDragOrigin = null;
    _verticalDragAccepted = false;
    _dragOffset = 0;
    _backContentScrollable = false;
    _faceTransitioning = false;
  }

  void _undoLastRating() {
    final snapshot = _lastSnapshot;
    if (snapshot == null || _attempts.isEmpty || _finishing) return;
    _completionTimer?.cancel();
    _ratingUndoTimer?.cancel();
    _faceTransitionTimer?.cancel();
    _attempts.removeLast();
    setState(() {
      _cardIndex = snapshot.cardIndex;
      _sectionIndex = snapshot.sectionIndex;
      _showBack = snapshot.showBack;
      _hintRevealed = snapshot.hintRevealed;
      _assistanceUsed = snapshot.assistanceUsed;
      _awaitingCompletion = false;
      _canUndoRating = false;
      _backContentScrollable = false;
      _inputLocked = false;
      _faceTransitioning = false;
      _finishError = null;
      _dragOffset = 0;
      _lastSnapshot = null;
    });
  }

  Future<void> _finishSession() async {
    if (_finishing || !_awaitingCompletion || _attempts.isEmpty) return;
    _completionTimer?.cancel();
    setState(() {
      _finishing = true;
      _finishError = null;
    });
    final attempts = List<CardAttempt>.unmodifiable(_attempts);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ResultScreen(
          deck: widget.deck,
          attempts: attempts,
          saveAttempts: widget.onAttemptsCompleted == null
              ? null
              : () => widget.onAttemptsCompleted!(attempts),
          wordCardGenerator: widget.wordCardGenerator,
          onAppendGeneratedCards: widget.onAppendGeneratedCards,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      minimum: const EdgeInsets.symmetric(vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) => _awaitingCompletion
            ? _completionBody(constraints)
            : _studyBody(constraints),
      ),
    );
  }

  Widget _studyBody(BoxConstraints constraints) {
    final compact = constraints.maxWidth < 360 || constraints.maxHeight < 700;
    final sideInset = compact ? 14.0 : 18.0;
    final contentWidth = (constraints.maxWidth - sideInset * 2)
        .clamp(0.0, 430.0)
        .toDouble();
    // Guidance lives in the controls themselves. Keeping one small fixed slot
    // preserves identical geometry on both faces without persistent copy.
    const helpHeight = 6.0;
    final actionHeight = widget.readOnly ? 0.0 : 52.0;
    final reservedHeight =
        (compact ? 2.0 : 8.0) +
        48 +
        (compact ? 6.0 : 10.0) +
        8 +
        actionHeight +
        helpHeight;
    final availableCardHeight = (constraints.maxHeight - reservedHeight)
        .clamp(260.0, double.infinity)
        .toDouble();
    final naturalCardHeight = contentWidth * 1.74;
    final cardHeight = naturalCardHeight
        .clamp(260.0, availableCardHeight)
        .toDouble();

    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: contentWidth,
        child: Column(
          children: [
            SizedBox(height: compact ? 2 : 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 14),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: _header(),
              ),
            ),
            SizedBox(height: compact ? 6 : 10),
            SizedBox(height: cardHeight, child: _cardSurface()),
            const SizedBox(height: 8),
            if (!widget.readOnly)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 14),
                child: SizedBox(height: actionHeight, child: _gestureGuide()),
              ),
            const SizedBox(height: helpHeight),
          ],
        ),
      ),
    );
  }

  Widget _cardSurface() {
    final verticalRatingEnabled = !_showBack || !_backContentScrollable;
    final hasNextCard = _cardIndex + 1 < widget.deck.cards.length;
    final travelProgress = (_dragOffset.abs() / 650).clamp(0.0, 1.0);
    final dragProgress = (_dragOffset.abs() / _dragThreshold).clamp(0.0, 1.0);
    return Semantics(
      customSemanticsActions: widget.readOnly
          ? const {}
          : {
              CustomSemanticsAction(
                label: context.l10n.tr(
                  _upFamiliarity == Familiarity.mastered
                      ? 'markMastered'
                      : 'markFuzzy',
                ),
              ): () =>
                  _submitRating(_upFamiliarity, upward: true),
              CustomSemanticsAction(
                label: context.l10n.tr('markForgotten'),
              ): () =>
                  _submitRating(Familiarity.forgotten, upward: false),
            },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: verticalRatingEnabled
            ? _onVerticalDragStart
            : null,
        onVerticalDragUpdate: verticalRatingEnabled
            ? _onVerticalDragUpdate
            : null,
        onVerticalDragEnd: verticalRatingEnabled ? _onVerticalDragEnd : null,
        onVerticalDragCancel: verticalRatingEnabled
            ? _onVerticalDragCancel
            : null,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            if (hasNextCard && (_dragOffset != 0 || _inputLocked))
              _nextCardPreview(travelProgress),
            Transform.translate(
              offset: Offset(0, _dragOffset),
              child: Transform.scale(
                key: const ValueKey('active-study-card-motion'),
                scale: 1 - dragProgress * 0.008,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedSwitcher(
                      key: const ValueKey('card-face-switcher'),
                      duration: _reduceMotion
                          ? const Duration(milliseconds: 100)
                          : const Duration(milliseconds: 280),
                      reverseDuration: _reduceMotion
                          ? const Duration(milliseconds: 100)
                          : const Duration(milliseconds: 240),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      layoutBuilder: (currentChild, previousChildren) => Stack(
                        fit: StackFit.expand,
                        children: [...previousChildren, ?currentChild],
                      ),
                      transitionBuilder: (child, animation) {
                        if (_reduceMotion) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        }
                        final isBack = child.key == const ValueKey('card-back');
                        return _CardFaceFlipTransition(
                          animation: animation,
                          isBack: isBack,
                          child: child,
                        );
                      },
                      child: EditorialCard(
                        key: ValueKey(_showBack ? 'card-back' : 'card-front'),
                        card: _card,
                        kind: widget.deck.kind,
                        face: _showBack ? CardFace.back : CardFace.front,
                        sectionIndex: _sectionIndex,
                        hintRevealed: _hintRevealed,
                        onHintTap: _revealHint,
                        onSectionChanged: _selectSection,
                        onPronounce: widget.deck.kind == CardKind.word
                            ? _pronounceWord
                            : null,
                        onBackScrollabilityChanged: (scrollable) {
                          if (!mounted || !_showBack) return;
                          if (_backContentScrollable == scrollable) return;
                          setState(() => _backContentScrollable = scrollable);
                        },
                        onTap: _toggleCardFace,
                      ),
                    ),
                    if (_dragOffset.abs() > 12) _dragFeedback(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nextCardPreview(double progress) {
    final eased = Curves.easeOutCubic.transform(progress);
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Opacity(
          key: const ValueKey('next-study-card-opacity'),
          opacity: 0.72 + eased * 0.28,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - eased)),
            child: Transform.scale(
              scale: 0.97 + eased * 0.03,
              child: EditorialCard(
                key: const ValueKey('next-study-card-preview'),
                card: widget.deck.cards[_cardIndex + 1],
                kind: widget.deck.kind,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 0,
          child: Semantics(
            label: context.l10n.tr('back'),
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Center(child: FigmaIcon('back', size: 26)),
              ),
            ),
          ),
        ),
        Text(
          '${_cardIndex + 1} / ${widget.deck.cards.length}',
          key: const ValueKey('study-progress'),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            letterSpacing: 0.35,
            fontWeight: FontWeight.w600,
            color: context.loopColors.muted,
          ),
        ),
        if (_canUndoRating)
          Positioned(
            right: 0,
            child: TextButton(
              key: const ValueKey('undo-last-rating'),
              onPressed: _undoLastRating,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: LoopTheme.teal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                context.l10n.tr('undoRating'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _gestureGuide() {
    final upKey = _upFamiliarity == Familiarity.mastered ? 'mastered' : 'fuzzy';
    return Row(
      children: [
        Expanded(
          child: _GestureAction(
            key: const ValueKey('rate-forgotten'),
            iconName: 'arrow-down',
            label: context.l10n.tr('forgotten'),
            color: LoopTheme.coral,
            onTap: () => _submitRating(Familiarity.forgotten, upward: false),
          ),
        ),
        Container(width: 1, height: 16, color: context.loopColors.divider),
        Expanded(
          child: _GestureAction(
            key: const ValueKey('rate-up'),
            iconName: 'arrow-up',
            label: context.l10n.tr(upKey),
            color: _upFamiliarity == Familiarity.mastered
                ? LoopTheme.teal
                : LoopTheme.amber,
            onTap: () => _submitRating(_upFamiliarity, upward: true),
          ),
        ),
      ],
    );
  }

  Widget _dragFeedback() {
    final upward = _dragOffset < 0;
    final familiarity = upward ? _upFamiliarity : Familiarity.forgotten;
    final color = switch (familiarity) {
      Familiarity.mastered => LoopTheme.teal,
      Familiarity.fuzzy => LoopTheme.amber,
      Familiarity.forgotten => LoopTheme.coral,
    };
    final labelKey = switch (familiarity) {
      Familiarity.mastered => 'mastered',
      Familiarity.fuzzy => 'fuzzy',
      Familiarity.forgotten => 'forgotten',
    };
    final progress = (_dragOffset.abs() / _dragThreshold).clamp(0.0, 1.0);
    return IgnorePointer(
      child: Align(
        alignment: upward ? Alignment.topCenter : Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Opacity(
            opacity: 0.45 + progress * 0.55,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(99),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                child: Text(
                  context.l10n.tr(labelKey),
                  style: const TextStyle(
                    color: Color(0xFF091413),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _completionBody(BoxConstraints constraints) {
    final horizontalInset = constraints.maxWidth < 360 ? 22.0 : 32.0;
    final width = (constraints.maxWidth - horizontalInset * 2)
        .clamp(0.0, 430.0)
        .toDouble();
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: width,
        child: Column(
          children: [
            SizedBox(height: constraints.maxHeight < 700 ? 4 : 10),
            SizedBox(height: 48, child: _header()),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FigmaIcon('success', size: 72),
                    const SizedBox(height: 28),
                    Text(
                      context.l10n.tr('sessionComplete'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: context.loopColors.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _finishError == null
                          ? context.l10n.tr('undoWindow')
                          : context.l10n.tr('saveAttemptsFailed'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: _finishError == null
                            ? context.loopColors.muted
                            : LoopTheme.coral,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 54,
              width: double.infinity,
              child: OutlinedButton(
                key: const ValueKey('undo-final-rating'),
                onPressed: _finishing ? null : _undoLastRating,
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.loopColors.ink,
                  side: BorderSide(color: context.loopColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(context.l10n.tr('undoRating')),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 60,
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('show-study-results'),
                onPressed: _finishing ? null : _finishSession,
                style: FilledButton.styleFrom(
                  backgroundColor: LoopTheme.teal,
                  foregroundColor: const Color(0xFF091413),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: _finishing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Color(0xFF091413),
                        ),
                      )
                    : Text(
                        _finishError == null
                            ? context.l10n.tr('showResults')
                            : context.l10n.tr('retrySave'),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            SizedBox(height: constraints.maxHeight < 700 ? 8 : 18),
          ],
        ),
      ),
    );
  }
}

class _GestureAction extends StatefulWidget {
  const _GestureAction({
    super.key,
    required this.iconName,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String iconName;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_GestureAction> createState() => _GestureActionState();
}

class _GestureActionState extends State<_GestureAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      button: true,
      label: widget.label,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (pressed) {
            if (_pressed == pressed) return;
            setState(() => _pressed = pressed);
          },
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FigmaIcon(
                  widget.iconName,
                  size: 16,
                  color: widget.color.withValues(alpha: 0.82),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: context.loopColors.muted,
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

class _CardFaceFlipTransition extends StatelessWidget {
  const _CardFaceFlipTransition({
    required this.animation,
    required this.isBack,
    required this.child,
  });

  final Animation<double> animation;
  final bool isBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final progress = animation.value.clamp(0.0, 1.0);
        final angle = (1 - progress) * (isBack ? math.pi / 2 : -math.pi / 2);
        final visibleProgress = ((progress - 0.46) / 0.54).clamp(0.0, 1.0);
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateY(angle);
        return Opacity(
          opacity: Curves.easeOut.transform(visibleProgress),
          child: Transform(
            key: const ValueKey('card-face-flip'),
            alignment: Alignment.center,
            transform: transform,
            child: child,
          ),
        );
      },
    );
  }
}

class _CardStudySnapshot {
  const _CardStudySnapshot({
    required this.cardIndex,
    required this.sectionIndex,
    required this.showBack,
    required this.hintRevealed,
    required this.assistanceUsed,
  });

  final int cardIndex;
  final int sectionIndex;
  final bool showBack;
  final bool hintRevealed;
  final bool assistanceUsed;
}

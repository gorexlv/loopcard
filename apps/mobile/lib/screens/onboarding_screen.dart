import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../onboarding/onboarding_models.dart';
import '../theme/loop_theme.dart';
import '../widgets/brand_lockup.dart';
import '../widgets/app_page.dart';
import '../widgets/glass_surface.dart';

typedef OnboardingComplete = Future<void> Function(OnboardingAnswers answers);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final OnboardingComplete onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  String _source = 'camera';
  String _pace = 'steady';
  int _dailyGoal = 20;

  OnboardingAnswers get _answers =>
      OnboardingAnswers(source: _source, pace: _pace, dailyGoal: _dailyGoal);

  void _next() {
    if (_step >= 3) return;
    setState(() => _step += 1);
  }

  Future<void> _finish() => widget.onComplete(_answers);

  @override
  Widget build(BuildContext context) {
    return AppPage(
      branded: true,
      actions: [
        Row(
          children: List.generate(
            4,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: index == _step ? 22 : 6,
              height: 6,
              margin: const EdgeInsets.only(left: 6),
              decoration: BoxDecoration(
                color: index == _step
                    ? LoopTheme.teal
                    : context.loopColors.divider,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: switch (_step) {
            0 => _QuestionStep<String>(
              key: const ValueKey('source-step'),
              eyebrow: context.l10n.tr('sourceEyebrow'),
              title: context.l10n.tr('sourceTitle'),
              options: const ['camera', 'text', 'manual'],
              selected: _source,
              labelFor: (value) => context.l10n.tr(switch (value) {
                'camera' => 'sourceCamera',
                'text' => 'sourceText',
                _ => 'sourceManual',
              }),
              onSelected: (value) => setState(() => _source = value),
              onNext: _next,
            ),
            1 => _QuestionStep<String>(
              key: const ValueKey('pace-step'),
              eyebrow: context.l10n.tr('paceEyebrow'),
              title: context.l10n.tr('paceTitle'),
              options: const ['light', 'steady', 'focus'],
              selected: _pace,
              labelFor: (value) => context.l10n.tr(switch (value) {
                'light' => 'paceLight',
                'steady' => 'paceSteady',
                _ => 'paceFocus',
              }),
              onSelected: (value) => setState(() => _pace = value),
              onNext: _next,
            ),
            2 => _QuestionStep<int>(
              key: const ValueKey('goal-step'),
              eyebrow: context.l10n.tr('goalEyebrow'),
              title: context.l10n.tr('goalTitle'),
              options: const [10, 20, 30],
              selected: _dailyGoal,
              labelFor: (value) =>
                  context.l10n.tr('countUnit', {'count': value}),
              onSelected: (value) => setState(() => _dailyGoal = value),
              onNext: _next,
            ),
            _ => _ReadyStep(
              key: const ValueKey('ready-step'),
              answers: _answers,
              onStart: _finish,
            ),
          },
        ),
      ),
    );
  }
}

class _QuestionStep<T> extends StatelessWidget {
  const _QuestionStep({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.options,
    required this.selected,
    required this.labelFor,
    required this.onSelected,
    required this.onNext,
  });

  final String eyebrow;
  final String title;
  final List<T> options;
  final T selected;
  final String Function(T value) labelFor;
  final ValueChanged<T> onSelected;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: LoopTheme.teal,
          ),
        ),
        const SizedBox(height: 17),
        Text(
          title,
          style: TextStyle(
            fontSize: 31,
            height: 1.28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: context.loopColors.ink,
          ),
        ),
        const SizedBox(height: 42),
        ...options.map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 13),
            child: _ChoiceRow(
              label: labelFor(option),
              selected: option == selected,
              onTap: () => onSelected(option),
            ),
          ),
        ),
        const SizedBox(height: 32),
        _PrimaryButton(label: context.l10n.tr('continue'), onTap: onNext),
      ],
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 21),
        decoration: BoxDecoration(
          color: selected
              ? LoopTheme.teal.withValues(alpha: 0.16)
              : context.loopColors.glass,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(
            color: selected ? LoopTheme.teal : context.loopColors.border,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: context.loopColors.ink,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? LoopTheme.teal : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? LoopTheme.teal
                      : context.loopColors.inactive,
                ),
              ),
              alignment: Alignment.center,
              child: selected
                  ? Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF07130F),
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadyStep extends StatelessWidget {
  const _ReadyStep({super.key, required this.answers, required this.onStart});

  final OnboardingAnswers answers;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.tr('readyEyebrow'),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: LoopTheme.teal,
          ),
        ),
        const SizedBox(height: 17),
        Text(
          context.l10n.tr('readyTitle'),
          style: TextStyle(
            fontSize: 31,
            height: 1.28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: context.loopColors.ink,
          ),
        ),
        const SizedBox(height: 38),
        GlassSurface(
          radius: 24,
          color: context.loopColors.glass,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 19),
            child: Row(
              children: [
                const BrandMark(size: 48, radius: 14),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${context.l10n.tr(switch (answers.source) {
                          'camera' => 'sourceCamera',
                          'text' => 'sourceText',
                          _ => 'sourceManual',
                        })} · ${context.l10n.tr(switch (answers.pace) {
                          'light' => 'paceLight',
                          'steady' => 'paceSteady',
                          _ => 'paceFocus',
                        })}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.loopColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.l10n.tr('dailyGoal', {
                          'count': answers.dailyGoal,
                        }),
                        style: TextStyle(
                          fontSize: 13,
                          color: context.loopColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        _PrimaryButton(label: context.l10n.tr('getStarted'), onTap: onStart),
        const SizedBox(height: 16),
        Center(
          child: Text(
            context.l10n.tr('localFirstHint'),
            style: TextStyle(fontSize: 13, color: context.loopColors.subtle),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 62,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: LoopTheme.teal,
          disabledBackgroundColor: const Color(0x7533CDB2),
          foregroundColor: const Color(0xFF07130F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(21),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

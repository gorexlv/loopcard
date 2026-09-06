import 'package:flutter/material.dart';

import '../cards/card_visuals.dart';
import '../cards/editorial_card.dart';
import '../models/card_models.dart';
import '../theme/loop_theme.dart';
import '../widgets/figma_icon.dart';

class CardStudioScreen extends StatefulWidget {
  const CardStudioScreen({super.key, required this.card, required this.kind});

  final StudyCard card;
  final CardKind kind;

  @override
  State<CardStudioScreen> createState() => _CardStudioScreenState();
}

class _CardStudioScreenState extends State<CardStudioScreen> {
  late CardVisualPreferences _preferences;
  CardFace _face = CardFace.front;
  bool _backgroundFallback = false;

  @override
  void initState() {
    super.initState();
    final recommended = const CardVisualEngine().recommend(widget.kind);
    _preferences = CardVisualPreferences(
      theme: recommended.theme,
      density: recommended.density,
    );
  }

  void _setTheme(CardThemeFamily value) {
    setState(() => _preferences = _preferences.copyWith(theme: value));
  }

  void _setMood(CardMood value) {
    setState(() => _preferences = _preferences.copyWith(mood: value));
  }

  void _setDensity(CardDensity value) {
    setState(() => _preferences = _preferences.copyWith(density: value));
  }

  void _setBackground(CardBackgroundSource value) {
    setState(() {
      _backgroundFallback = value != CardBackgroundSource.official;
      _preferences = _preferences.copyWith(
        backgroundSource: _backgroundFallback
            ? CardBackgroundSource.official
            : value,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('design-canvas'),
      backgroundColor: context.loopColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
              child: SizedBox(
                height: 390,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: FittedBox(
                    key: ValueKey(
                      '${_face.name}-${_preferences.theme?.name}-${_preferences.density?.name}',
                    ),
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: 354,
                      height: 500,
                      child: EditorialCard(
                        card: widget.card,
                        kind: widget.kind,
                        face: _face,
                        preferences: _preferences,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.loopColors.glassStrong,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  border: Border(
                    top: BorderSide(color: context.loopColors.border),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _controlLabel('主题家族'),
                      _choiceWrap<CardThemeFamily>(
                        values: CardThemeFamily.values,
                        selected: _preferences.theme!,
                        label: _themeLabel,
                        onSelected: _setTheme,
                      ),
                      const SizedBox(height: 18),
                      _controlLabel('视觉情绪'),
                      _choiceWrap<CardMood>(
                        values: CardMood.values,
                        selected: _preferences.mood,
                        label: _moodLabel,
                        onSelected: _setMood,
                      ),
                      const SizedBox(height: 18),
                      _controlLabel('信息密度'),
                      _choiceWrap<CardDensity>(
                        values: CardDensity.values,
                        selected: _preferences.density!,
                        label: _densityLabel,
                        onSelected: _setDensity,
                      ),
                      const SizedBox(height: 18),
                      _controlLabel('背景来源'),
                      _choiceWrap<CardBackgroundSource>(
                        values: CardBackgroundSource.values,
                        selected: _backgroundFallback
                            ? CardBackgroundSource.generated
                            : CardBackgroundSource.official,
                        label: _backgroundLabel,
                        onSelected: _setBackground,
                      ),
                      if (_backgroundFallback) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: LoopTheme.amber.withValues(alpha: 0.1),
                            border: Border.all(
                              color: LoopTheme.amber.withValues(alpha: 0.32),
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            '背景服务尚未配置，已回退官方主题；卡片内容与设计不会丢失。',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: LoopTheme.amber,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return SizedBox(
      height: 58,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            Semantics(
              label: '返回',
              button: true,
              child: InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(18),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(child: FigmaIcon('back', size: 24)),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CARD STUDIO',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w700,
                      color: context.loopColors.subtle,
                    ),
                  ),
                  Text(
                    '让系统完成专业设计',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.loopColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => setState(
                () => _face = _face == CardFace.front
                    ? CardFace.back
                    : CardFace.front,
              ),
              child: Text(_face == CardFace.front ? '查看背面' : '查看正面'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controlLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: context.loopColors.muted,
      ),
    ),
  );

  Widget _choiceWrap<T>({
    required List<T> values,
    required T selected,
    required String Function(T) label,
    required ValueChanged<T> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((value) {
        final active = value == selected;
        return Semantics(
          selected: active,
          button: true,
          child: InkWell(
            onTap: () => onSelected(value),
            borderRadius: BorderRadius.circular(15),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 100,
              constraints: const BoxConstraints(minHeight: 44),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: active
                    ? LoopTheme.teal.withValues(alpha: 0.16)
                    : context.loopColors.glass,
                border: Border.all(
                  color: active
                      ? LoopTheme.teal.withValues(alpha: 0.52)
                      : context.loopColors.border,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                label(value),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? LoopTheme.teal : context.loopColors.muted,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

String _themeLabel(CardThemeFamily value) => switch (value) {
  CardThemeFamily.aurora => '极光',
  CardThemeFamily.paper => '纸刊',
  CardThemeFamily.cosmos => '宇宙',
  CardThemeFamily.lab => '实验室',
  CardThemeFamily.botanical => '植物',
  CardThemeFamily.mono => '黑白',
};

String _moodLabel(CardMood value) => switch (value) {
  CardMood.quiet => '安静',
  CardMood.editorial => '编辑感',
  CardMood.vivid => '鲜明',
};

String _densityLabel(CardDensity value) => switch (value) {
  CardDensity.airy => '舒展',
  CardDensity.balanced => '平衡',
  CardDensity.compact => '紧凑',
};

String _backgroundLabel(CardBackgroundSource value) => switch (value) {
  CardBackgroundSource.official => '官方精选',
  CardBackgroundSource.userImage => '我的图片',
  CardBackgroundSource.generated => 'AI 生成',
};

import 'package:flutter/material.dart';

import '../cards/card_visuals.dart';
import '../cards/editorial_card.dart';
import '../models/card_models.dart';
import '../theme/loop_theme.dart';
import '../widgets/app_page.dart';

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

  @override
  void initState() {
    super.initState();
    final recommended = const CardVisualEngine().recommend(widget.kind);
    _preferences = CardVisualPreferences(
      theme: recommended.theme,
      density: recommended.density,
    );
  }

  void _setDensity(CardDensity value) {
    setState(() => _preferences = _preferences.copyWith(density: value));
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: '卡片排版',
      actions: [
        TextButton(
          onPressed: () => setState(
            () => _face = _face == CardFace.front
                ? CardFace.back
                : CardFace.front,
          ),
          child: Text(_face == CardFace.front ? '查看背面' : '查看正面'),
        ),
      ],
      contentGutters: false,
      child: ListView(
        children: [
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
          SizedBox(
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
                    Text(
                      '渐变玻璃',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: context.loopColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('统一卡片外观，让注意力回到内容。'),
                    const SizedBox(height: 24),
                    _controlLabel('信息密度'),
                    _choiceWrap<CardDensity>(
                      values: CardDensity.values,
                      selected: _preferences.density!,
                      label: _densityLabel,
                      onSelected: _setDensity,
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
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

String _densityLabel(CardDensity value) => switch (value) {
  CardDensity.airy => '舒展',
  CardDensity.balanced => '平衡',
  CardDensity.compact => '紧凑',
};

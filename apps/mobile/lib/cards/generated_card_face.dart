import 'package:flutter/material.dart';
import '../models/card_models.dart';
import 'card_background.dart';
import 'card_visuals.dart';

/// Used by both chat previews and saved cards, with identical presentation data.
class GeneratedCardFace extends StatelessWidget {
  const GeneratedCardFace({
    super.key,
    required this.card,
    required this.back,
    this.onTap,
    this.onScrollabilityChanged,
  });
  final StudyCard card;
  final bool back;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onScrollabilityChanged;
  @override
  Widget build(BuildContext context) {
    final centered = card.presentation['layout'] == 'centered';
    final colors = CardThemeTokens.forContext(context);
    return Semantics(
      label: back ? '卡片背面' : '卡片正面',
      child: CardBackground(
        family: CardThemeFamily.aurora,
        mood: CardMood.quiet,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: LayoutBuilder(
                builder: (context, constraints) =>
                    NotificationListener<ScrollMetricsNotification>(
                      onNotification: (n) {
                        onScrollabilityChanged?.call(
                          n.metrics.maxScrollExtent > 0,
                        );
                        return false;
                      },
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight.isFinite
                                ? constraints.maxHeight
                                : 0,
                          ),
                          child: Column(
                            mainAxisAlignment: !back && centered
                                ? MainAxisAlignment.center
                                : MainAxisAlignment.start,
                            crossAxisAlignment: !back && centered
                                ? CrossAxisAlignment.center
                                : CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                back ? '背面' : '正面',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.muted,
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (!back) ...[
                                Text(
                                  card.prompt,
                                  textAlign: centered
                                      ? TextAlign.center
                                      : TextAlign.left,
                                  style: TextStyle(
                                    color: colors.foreground,
                                    fontSize: 30,
                                    height: 1.25,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (card.hint?.isNotEmpty == true) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    card.hint!,
                                    textAlign: centered
                                        ? TextAlign.center
                                        : TextAlign.left,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontFamilyFallback: const ['NotoSansSC'],
                                      fontSize: 15,
                                      color: colors.muted,
                                    ),
                                  ),
                                ],
                              ] else
                                for (final section in card.sections) ...[
                                  Text(
                                    section.title,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: colors.accent,
                                    ),
                                  ),
                                  if (section.heading.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      section.heading,
                                      style: TextStyle(
                                        color: colors.foreground,
                                        fontSize: 19,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    section.body,
                                    style: TextStyle(
                                      color: colors.foreground,
                                      fontSize: 16,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                            ],
                          ),
                        ),
                      ),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

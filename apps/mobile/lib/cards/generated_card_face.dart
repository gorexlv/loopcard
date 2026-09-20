import 'package:flutter/material.dart';
import '../models/card_models.dart';
import 'card_background.dart';
import 'card_visuals.dart';
import 'card_reading_layout.dart';
import 'literary_layout.dart';

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
    final skill = card.presentation['skill'];
    if (skill == 'poetry' || skill == 'classical') {
      return _LiteraryFace(
        key: ValueKey('${card.id}:${card.prompt}:$back'),
        card: card,
        back: back,
        onTap: onTap,
        onScrollabilityChanged: onScrollabilityChanged,
      );
    }
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

class _LiteraryFace extends StatefulWidget {
  const _LiteraryFace({
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
  State<_LiteraryFace> createState() => _LiteraryFaceState();
}

class _LiteraryFaceState extends State<_LiteraryFace> {
  final _controller = PageController();
  int _page = 0;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _LiteraryFace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.sections != widget.card.sections) {
      _page = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) _controller.jumpToPage(0);
      });
    }
  }

  void _go(int index) {
    if (MediaQuery.of(context).disableAnimations) {
      _controller.jumpToPage(index);
    } else {
      _controller.animateToPage(
        index,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Widget _scroll(Widget child, {Key? key}) =>
      NotificationListener<ScrollMetricsNotification>(
        onNotification: (n) {
          if (n.metrics.axis == Axis.vertical) {
            widget.onScrollabilityChanged?.call(n.metrics.maxScrollExtent > 0);
          }
          return false;
        },
        child: SingleChildScrollView(key: key, primary: false, child: child),
      );

  @override
  Widget build(BuildContext context) {
    final colors = CardThemeTokens.forContext(context);
    final data = widget.card.presentation['literary'];
    final metadata = data is Map ? data : const {};
    // Legacy cards stay readable without inventing missing author/dynasty data.
    final parts = widget.card.prompt.split(RegExp(r'\s+[·—]\s*'));
    final prompt = metadata.isNotEmpty ? widget.card.prompt : parts.first;
    final author =
        metadata['author'] as String? ??
        (parts.length == 2 ? parts.last : widget.card.hint ?? '');
    final dynasty = metadata['dynasty'] as String? ?? '';
    final pages = literaryPages(widget.card);
    return Semantics(
      label: widget.back ? '卡片背面' : '卡片正面',
      child: CardBackground(
        family: CardThemeFamily.aurora,
        mood: CardMood.quiet,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: !widget.back
                  ? LayoutBuilder(
                      builder: (context, constraints) => _scroll(
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                prompt,
                                key: const ValueKey('literary-title'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 30,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                  color: colors.foreground,
                                ),
                              ),
                              if (author.isNotEmpty) ...[
                                const SizedBox(height: 22),
                                Text(
                                  author,
                                  key: const ValueKey('literary-author'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    height: 1.5,
                                    color: colors.foreground,
                                  ),
                                ),
                              ],
                              if (dynasty.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  dynasty,
                                  key: const ValueKey('literary-dynasty'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: colors.muted,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CardSectionTabs(
                          labels: [for (final page in pages) page.label],
                          index: _page,
                          onSelected: _go,
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: PageView.builder(
                            key: const ValueKey('literary-back-pages'),
                            controller: _controller,
                            itemCount: pages.length,
                            onPageChanged: (index) =>
                                setState(() => _page = index),
                            itemBuilder: (context, index) {
                              final page = pages[index];
                              return CardReadingScroll(
                                key: ValueKey('literary-reading-$index'),
                                scrollKey: PageStorageKey(
                                  'literary-page-$index',
                                ),
                                active: index == _page,
                                onScrollabilityChanged:
                                    widget.onScrollabilityChanged,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      prompt,
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.4,
                                        color: colors.muted,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    if (page.heading.isNotEmpty) ...[
                                      Text(
                                        page.heading,
                                        style: TextStyle(
                                          fontSize: 22,
                                          height: 1.4,
                                          fontWeight: FontWeight.w600,
                                          color: colors.foreground,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    for (
                                      var line = 0;
                                      line < page.lines.length;
                                      line++
                                    ) ...[
                                      Text(
                                        page.lines[line],
                                        key: ValueKey(
                                          'literary-line-$index-$line',
                                        ),
                                        style: TextStyle(
                                          fontSize: page.verse ? 20 : 17,
                                          height: page.verse ? 1.6 : 1.65,
                                          fontWeight: page.verse
                                              ? FontWeight.w500
                                              : FontWeight.w400,
                                          color: colors.foreground,
                                        ),
                                      ),
                                      if (page.translations.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          page.translations[line],
                                          key: ValueKey(
                                            'literary-translation-$index-$line',
                                          ),
                                          style: TextStyle(
                                            fontSize: 15,
                                            height: 1.55,
                                            color: colors.muted,
                                          ),
                                        ),
                                      ],
                                      SizedBox(
                                        height: page.translations.isNotEmpty
                                            ? 20
                                            : 10,
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        if (pages.length > 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                tooltip: '上一页',
                                onPressed: _page > 0
                                    ? () => _go(_page - 1)
                                    : null,
                                color: colors.muted,
                                icon: const Icon(Icons.chevron_left),
                              ),
                              Semantics(
                                liveRegion: true,
                                label:
                                    '${pages[_page].label}，第 ${_page + 1} 页，共 ${pages.length} 页',
                                child: Text(
                                  '${_page + 1} / ${pages.length}',
                                  key: const ValueKey('literary-page-count'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colors.muted,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: '下一页',
                                onPressed: _page + 1 < pages.length
                                    ? () => _go(_page + 1)
                                    : null,
                                color: colors.muted,
                                icon: const Icon(Icons.chevron_right),
                              ),
                            ],
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

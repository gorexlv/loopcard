import 'package:flutter/material.dart';

import 'card_visuals.dart';

/// Named sections share one navigation pattern across every kind of card.
class CardSectionTabs extends StatefulWidget {
  const CardSectionTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onSelected,
  });
  final List<String> labels;
  final int index;
  final ValueChanged<int> onSelected;

  @override
  State<CardSectionTabs> createState() => _CardSectionTabsState();
}

class _CardSectionTabsState extends State<CardSectionTabs> {
  final _keys = <GlobalKey>[];
  List<String> get labels => widget.labels;
  int get index => widget.index;
  ValueChanged<int> get onSelected => widget.onSelected;
  @override
  void didUpdateWidget(covariant CardSectionTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != index) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || index >= _keys.length) return;
        final target = _keys[index].currentContext;
        if (target != null) {
          Scrollable.ensureVisible(
            target,
            alignment: 0.5,
            duration: Duration.zero,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (labels.length < 2) return const SizedBox.shrink();
    while (_keys.length < labels.length) {
      _keys.add(GlobalKey());
    }
    final colors = CardThemeTokens.forContext(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Semantics(
              key: _keys[i],
              selected: i == index,
              child: TextButton(
                key: ValueKey('card-section-tab-$i'),
                onPressed: () => onSelected(i),
                style: TextButton.styleFrom(
                  foregroundColor: i == index ? colors.accent : colors.muted,
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: const RoundedRectangleBorder(),
                  side: BorderSide.none,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: i == index ? colors.accent : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: i == index
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Scrolls the entire reading area, including long headings and metadata.
/// Native scroll indicators communicate overflow without instructional copy.
class CardReadingScroll extends StatefulWidget {
  const CardReadingScroll({
    super.key,
    required this.child,
    this.onScrollabilityChanged,
    this.scrollKey,
    this.active = true,
  });
  final Widget child;
  final ValueChanged<bool>? onScrollabilityChanged;
  final Key? scrollKey;
  final bool active;
  @override
  State<CardReadingScroll> createState() => _CardReadingScrollState();
}

class _CardReadingScrollState extends State<CardReadingScroll> {
  final _controller = ScrollController();
  bool? _scrollable;
  @override
  void initState() {
    super.initState();
    _controller.addListener(_scheduleMeasure);
  }

  @override
  void didUpdateWidget(covariant CardReadingScroll oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) _scrollable = null;
  }

  void _scheduleMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      final position = _controller.position;
      final scrollable = position.maxScrollExtent > 1;
      if (_scrollable != scrollable) {
        setState(() => _scrollable = scrollable);
        if (widget.active) widget.onScrollabilityChanged?.call(scrollable);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scheduleMeasure();
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (_) {
        _scheduleMeasure();
        return false;
      },
      child: Scrollbar(
        controller: _controller,
        thumbVisibility: _scrollable == true,
        child: SingleChildScrollView(
          key: widget.scrollKey,
          controller: _controller,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(right: 8, bottom: 8),
          child: widget.child,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/loop_theme.dart';
import 'brand_lockup.dart';
import 'design_canvas.dart';
import 'figma_icon.dart';
import 'app_layout.dart';

/// Common viewport, background and system-inset handling for app screens.
class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.minimum = const EdgeInsets.symmetric(vertical: 16),
    this.gradient = true,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget child;
  final EdgeInsets minimum;
  final bool gradient;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(minimum: minimum, child: child);
    return DesignCanvas(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      child: gradient
          ? GradientPage(children: [Positioned.fill(child: content)])
          : content,
    );
  }
}

/// Page chrome stays fixed; each feature owns only its scrollable content.
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.child,
    this.title,
    this.actions = const [],
    this.branded = false,
    this.footer,
    this.bottomClearance = 0,
    this.maxWidth = AppLayout.maxContentWidth,
    this.contentGutters = true,
  });

  final Widget child;
  final String? title;
  final List<Widget> actions;
  final bool branded;
  final Widget? footer;
  final double bottomClearance;
  final double maxWidth;
  final bool contentGutters;

  @override
  Widget build(BuildContext context) => AppSurface(
    minimum: EdgeInsets.only(
      top: branded ? AppLayout.brandTop : AppLayout.bottomGap,
      bottom: AppLayout.bottomGap,
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final gutter = AppLayout.horizontalPadding(constraints.maxWidth);
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth + gutter * 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: branded
                      ? Row(
                          children: [
                            const BrandLockup(),
                            if (actions.isNotEmpty)
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: actions,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : AppPageHeader(title: title, actions: actions),
                ),
                const SizedBox(height: AppLayout.headerGap),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: contentGutters ? gutter : 0,
                    ),
                    child: child,
                  ),
                ),
                if (footer != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 0),
                    child: footer!,
                  ),
                if (bottomClearance > 0) SizedBox(height: bottomClearance),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class AppPageHeader extends StatelessWidget {
  const AppPageHeader({super.key, this.title, this.actions = const []});
  final String? title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        key: const ValueKey('page-back'),
        tooltip: context.l10n.tr('back'),
        onPressed: () => Navigator.of(context).maybePop(),
        icon: FigmaIcon('back', size: 24, color: context.loopColors.ink),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          title ?? '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: context.loopColors.ink,
          ),
        ),
      ),
      ...actions,
    ],
  );
}

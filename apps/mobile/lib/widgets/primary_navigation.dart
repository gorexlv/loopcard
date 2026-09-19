import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/loop_theme.dart';
import 'figma_icon.dart';
import 'app_layout.dart';

enum AppSection { learn, decks, profile }

class PrimaryNavigationDock extends StatelessWidget {
  const PrimaryNavigationDock({
    super.key,
    required this.current,
    required this.onSelected,
  });

  final AppSection current;
  final ValueChanged<AppSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final gutter = AppLayout.horizontalPadding(viewportWidth);
    return SafeArea(
      top: false,
      minimum: EdgeInsets.fromLTRB(gutter, 0, gutter, AppLayout.bottomGap),
      child: LayoutBuilder(
        builder: (context, constraints) => Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: viewportWidth >= AppLayout.tabletBreakpoint
                  ? AppLayout.maxContentWidth
                  : 326,
            ),
            child: SizedBox(
              key: const ValueKey('primary-navigation-dock'),
              height: AppLayout.dockHeight,
              child: PrimaryNavigation(
                current: current,
                onSelected: onSelected,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PrimaryNavigation extends StatelessWidget {
  const PrimaryNavigation({super.key, required this.current, this.onSelected});

  final AppSection current;
  final ValueChanged<AppSection>? onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _NavItem(
          icon: 'nav-learn',
          label: context.l10n.tr('navGenerate'),
          section: AppSection.learn,
          current: current,
          onSelected: onSelected,
        ),
        _NavItem(
          icon: 'nav-decks',
          label: context.l10n.tr('navDecks'),
          section: AppSection.decks,
          current: current,
          onSelected: onSelected,
        ),
        _NavItem(
          icon: 'nav-profile',
          label: context.l10n.tr('navProfile'),
          section: AppSection.profile,
          current: current,
          onSelected: onSelected,
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.section,
    required this.current,
    required this.onSelected,
  });

  final String icon;
  final String label;
  final AppSection section;
  final AppSection current;
  final ValueChanged<AppSection>? onSelected;

  @override
  Widget build(BuildContext context) {
    final active = section == current;
    final color = active ? LoopTheme.teal : context.loopColors.inactive;
    return Semantics(
      selected: active,
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onSelected == null ? null : () => onSelected!(section),
        child: SizedBox(
          key: ValueKey('primary-nav-${section.name}'),
          width: 72,
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FigmaIcon(icon, size: 24, color: color),
              const SizedBox(height: 5),
              Text(label, style: TextStyle(fontSize: 12, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

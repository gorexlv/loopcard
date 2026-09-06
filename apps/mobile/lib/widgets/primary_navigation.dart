import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/loop_theme.dart';
import 'figma_icon.dart';

enum AppSection { learn, decks, profile }

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

import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../l10n/app_localizations.dart';
import '../models/card_models.dart';
import '../theme/loop_theme.dart';
import '../widgets/brand_lockup.dart';
import '../widgets/design_canvas.dart';
import '../widgets/glass_surface.dart';
import '../widgets/primary_navigation.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.decks,
    required this.user,
    required this.onSignOut,
    this.onTabSelected,
    required this.locale,
    required this.themeMode,
    required this.onLocaleChanged,
    required this.onThemeModeChanged,
  });

  final List<CardDeck> decks;
  final AppUser user;
  final Future<void> Function() onSignOut;
  final ValueChanged<AppSection>? onTabSelected;
  final Locale? locale;
  final ThemeMode themeMode;
  final ValueChanged<Locale?> onLocaleChanged;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showLanguagePicker(BuildContext context) {
    final locales = <Locale?>[null, ...AppLocalizations.supportedLocales];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: 540,
          child: Column(
            children: [
              Text(
                context.l10n.tr('languageTitle'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: context.loopColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: locales.length,
                  itemBuilder: (_, index) {
                    final option = locales[index];
                    final selected =
                        option?.toLanguageTag() == locale?.toLanguageTag();
                    return ListTile(
                      onTap: () {
                        onLocaleChanged(option);
                        Navigator.of(sheetContext).pop();
                      },
                      title: Text(context.l10n.languageName(option)),
                      trailing: selected
                          ? const Icon(
                              Icons.check_rounded,
                              color: LoopTheme.teal,
                            )
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
    final options = <(ThemeMode, String)>[
      (ThemeMode.system, 'themeSystem'),
      (ThemeMode.light, 'themeLight'),
      (ThemeMode.dark, 'themeDark'),
    ];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.tr('themeTitle'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: context.loopColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              ...options.map(
                (option) => ListTile(
                  onTap: () {
                    onThemeModeChanged(option.$1);
                    Navigator.of(sheetContext).pop();
                  },
                  title: Text(context.l10n.tr(option.$2)),
                  trailing: themeMode == option.$1
                      ? const Icon(Icons.check_rounded, color: LoopTheme.teal)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = decks.fold<int>(0, (sum, deck) => sum + deck.cards.length);
    final mastered = decks.fold<int>(0, (sum, deck) => sum + deck.mastered);
    final rate = total == 0 ? 0 : (mastered / total * 100).round();
    final l10n = context.l10n;
    final palette = context.loopColors;
    return DesignCanvas(
      child: GradientPage(
        children: [
          const Positioned(left: 32, top: 58, child: BrandLockup()),
          Positioned(
            left: 32,
            top: 118,
            child: Row(
              children: [
                const _Avatar(),
                const SizedBox(width: 18),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ??
                          user.email?.split('@').first ??
                          l10n.tr('myCards'),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text(
                        user.email ?? l10n.tr('accountConnected'),
                        style: TextStyle(fontSize: 14, color: palette.muted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: 32,
            top: 228,
            width: 326,
            height: 126,
            child: GlassSurface(
              radius: 28,
              color: palette.glass,
              child: Row(
                children: [
                  _ProfileStat(value: '7', label: l10n.tr('streak')),
                  const _ProfileDivider(),
                  _ProfileStat(value: '$total', label: l10n.tr('totalCards')),
                  const _ProfileDivider(),
                  _ProfileStat(value: '$rate%', label: l10n.tr('masteryRate')),
                ],
              ),
            ),
          ),
          Positioned(
            left: 32,
            top: 398,
            child: Text(
              l10n.tr('settings'),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: palette.ink,
              ),
            ),
          ),
          Positioned(
            left: 32,
            top: 434,
            width: 326,
            height: 300,
            child: GlassSurface(
              radius: 28,
              blur: 10,
              color: palette.glass,
              child: Column(
                children: [
                  _SettingRow(
                    label: l10n.tr('language'),
                    value: l10n.languageName(locale),
                    onTap: () => _showLanguagePicker(context),
                  ),
                  const _SettingDivider(),
                  _SettingRow(
                    label: l10n.tr('appearance'),
                    value: l10n.tr(switch (themeMode) {
                      ThemeMode.system => 'themeSystem',
                      ThemeMode.light => 'themeLight',
                      ThemeMode.dark => 'themeDark',
                    }),
                    onTap: () => _showThemePicker(context),
                  ),
                  const _SettingDivider(),
                  _SettingRow(label: l10n.tr('signOut'), onTap: onSignOut),
                  const _SettingDivider(),
                  _SettingRow(
                    label: l10n.tr('memoryPreferences'),
                    onTap: () =>
                        _showMessage(context, l10n.tr('defaultPreferences')),
                  ),
                  const _SettingDivider(),
                  _SettingRow(
                    label: l10n.tr('about'),
                    onTap: () =>
                        _showMessage(context, l10n.tr('localPrototype')),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 32,
            top: 744,
            width: 326,
            height: 72,
            child: PrimaryNavigation(
              current: AppSection.profile,
              onSelected: onTabSelected,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: context.loopColors.glass,
        shape: BoxShape.circle,
        border: Border.all(color: context.loopColors.border),
      ),
      alignment: Alignment.center,
      child: Text(
        'L',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: context.loopColors.ink,
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 25,
              fontWeight: FontWeight.w700,
              color: context.loopColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: context.loopColors.muted),
          ),
        ],
      ),
    );
  }
}

class _ProfileDivider extends StatelessWidget {
  const _ProfileDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 38, color: context.loopColors.divider);
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.onTap, this.value});

  final String label;
  final VoidCallback onTap;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 15, color: context.loopColors.ink),
                ),
              ),
              if (value != null)
                Flexible(
                  child: Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.loopColors.muted,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                '›',
                style: TextStyle(
                  fontSize: 26,
                  height: 1,
                  color: context.loopColors.inactive,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingDivider extends StatelessWidget {
  const _SettingDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 22),
      color: context.loopColors.divider,
    );
  }
}

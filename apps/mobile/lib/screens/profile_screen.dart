import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../l10n/app_localizations.dart';
import '../models/card_models.dart';
import '../reminders/practice_reminder.dart';
import '../theme/loop_theme.dart';
import '../widgets/primary_page.dart';
import '../widgets/glass_surface.dart';
import '../widgets/user_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.decks,
    required this.user,
    required this.onSignOut,
    required this.locale,
    required this.themeMode,
    required this.onLocaleChanged,
    required this.onThemeModeChanged,
    this.reminderSettings = const PracticeReminderSettings(),
    this.onReminderEnabledChanged,
    this.onReminderTimeChanged,
  });

  final List<CardDeck> decks;
  final AppUser user;
  final Future<void> Function() onSignOut;
  final Locale? locale;
  final ThemeMode themeMode;
  final ValueChanged<Locale?> onLocaleChanged;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final PracticeReminderSettings reminderSettings;
  final Future<bool> Function(bool enabled)? onReminderEnabledChanged;
  final Future<void> Function(TimeOfDay time)? onReminderTimeChanged;

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

  void _showReminderSettings(BuildContext context) {
    var settings = reminderSettings;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.tr('practiceReminder'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: context.loopColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  key: const ValueKey('practice-reminder-toggle'),
                  title: Text(context.l10n.tr('dailyReminder')),
                  subtitle: Text(context.l10n.tr('dailyReminderHint')),
                  value: settings.enabled,
                  onChanged: (enabled) async {
                    final accepted =
                        await onReminderEnabledChanged?.call(enabled) ?? false;
                    if (!context.mounted) return;
                    if (!accepted && enabled) {
                      _showMessage(
                        context,
                        context.l10n.tr('permissionDenied'),
                      );
                      return;
                    }
                    setSheetState(
                      () => settings = settings.copyWith(enabled: enabled),
                    );
                  },
                ),
                ListTile(
                  key: const ValueKey('practice-reminder-time'),
                  enabled: settings.enabled,
                  title: Text(context.l10n.tr('reminderTime')),
                  trailing: Text(settings.timeLabel),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: settings.hour,
                        minute: settings.minute,
                      ),
                    );
                    if (time == null) return;
                    await onReminderTimeChanged?.call(time);
                    if (!context.mounted) return;
                    setSheetState(
                      () => settings = settings.copyWith(
                        hour: time.hour,
                        minute: time.minute,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = decks.fold<int>(0, (sum, deck) => sum + deck.cards.length);
    final mastered = decks.fold<int>(0, (sum, deck) => sum + deck.mastered);
    final fuzzy = decks.fold<int>(0, (sum, deck) => sum + deck.fuzzy);
    final rate = total == 0
        ? 0
        : ((mastered + fuzzy * 0.5) / total * 100).round();
    final l10n = context.l10n;
    final palette = context.loopColors;
    return PrimaryPage(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              children: [
                UserAvatar(user: user),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
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
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
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
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.only(bottom: 0),
            child: Text(
              l10n.tr('settings'),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: palette.ink,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
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
                    label: l10n.tr('practiceReminder'),
                    value: reminderSettings.enabled
                        ? reminderSettings.timeLabel
                        : l10n.tr('reminderOff'),
                    onTap: () => _showReminderSettings(context),
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
        ],
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

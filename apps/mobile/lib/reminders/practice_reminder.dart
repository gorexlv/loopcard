import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class PracticeReminderSettings {
  const PracticeReminderSettings({
    this.enabled = false,
    this.hour = 20,
    this.minute = 0,
  });

  final bool enabled;
  final int hour;
  final int minute;

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  PracticeReminderSettings copyWith({bool? enabled, int? hour, int? minute}) =>
      PracticeReminderSettings(
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );
}

abstract interface class PracticeReminderStore {
  Future<PracticeReminderSettings> load();
  Future<void> save(PracticeReminderSettings settings);
}

class SharedPreferencesPracticeReminderStore implements PracticeReminderStore {
  SharedPreferencesPracticeReminderStore([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _enabledKey = 'practice_reminder.enabled';
  static const _hourKey = 'practice_reminder.hour';
  static const _minuteKey = 'practice_reminder.minute';
  final SharedPreferencesAsync _preferences;

  @override
  Future<PracticeReminderSettings> load() async => PracticeReminderSettings(
    enabled: await _preferences.getBool(_enabledKey) ?? false,
    hour: await _preferences.getInt(_hourKey) ?? 20,
    minute: await _preferences.getInt(_minuteKey) ?? 0,
  );

  @override
  Future<void> save(PracticeReminderSettings settings) async {
    await _preferences.setBool(_enabledKey, settings.enabled);
    await _preferences.setInt(_hourKey, settings.hour);
    await _preferences.setInt(_minuteKey, settings.minute);
  }
}

class MemoryPracticeReminderStore implements PracticeReminderStore {
  MemoryPracticeReminderStore([
    this.settings = const PracticeReminderSettings(),
  ]);

  PracticeReminderSettings settings;

  @override
  Future<PracticeReminderSettings> load() async => settings;

  @override
  Future<void> save(PracticeReminderSettings value) async => settings = value;
}

abstract interface class PracticeReminderScheduler {
  Future<bool> requestPermission();
  Future<void> schedule({
    required PracticeReminderSettings settings,
    required int dueCount,
    DateTime? dueDate,
    required String title,
    required String body,
  });
  Future<void> cancel();
}

class LocalPracticeReminderScheduler implements PracticeReminderScheduler {
  LocalPracticeReminderScheduler([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _notificationIds = [1101, 1102, 1103];
  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> _initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    await _initialize();
    final android = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    final ios = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return android ?? ios ?? true;
  }

  @override
  Future<void> schedule({
    required PracticeReminderSettings settings,
    required int dueCount,
    DateTime? dueDate,
    required String title,
    required String body,
  }) async {
    await _initialize();
    if (!settings.enabled || dueCount <= 0) return cancel();
    final now = tz.TZDateTime.now(tz.local);
    final target = dueDate?.toLocal() ?? now;
    var next = tz.TZDateTime(
      tz.local,
      target.year,
      target.month,
      target.day,
      settings.hour,
      settings.minute,
    );
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    await cancel();
    for (var day = 0; day < _notificationIds.length; day++) {
      await _plugin.zonedSchedule(
        id: _notificationIds[day],
        title: title,
        body: body,
        scheduledDate: next.add(Duration(days: day)),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'practice_reminders',
            'Practice reminders',
            channelDescription: 'A daily reminder when cards are due',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'practice',
      );
    }
  }

  @override
  Future<void> cancel() async {
    await _initialize();
    for (final id in _notificationIds) {
      await _plugin.cancel(id: id);
    }
  }
}

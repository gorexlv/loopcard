import 'package:flutter_test/flutter_test.dart';
import 'package:loopcard/reminders/practice_reminder.dart';

void main() {
  test('reminder settings default to off at 20:00', () async {
    final store = MemoryPracticeReminderStore();

    final settings = await store.load();

    expect(settings.enabled, isFalse);
    expect(settings.timeLabel, '20:00');
  });

  test('memory store persists enabled state and reminder time', () async {
    final store = MemoryPracticeReminderStore();
    const settings = PracticeReminderSettings(
      enabled: true,
      hour: 8,
      minute: 5,
    );

    await store.save(settings);

    final loaded = await store.load();
    expect(loaded.enabled, isTrue);
    expect(loaded.hour, 8);
    expect(loaded.minute, 5);
    expect(loaded.timeLabel, '08:05');
  });

  test('copyWith preserves reminder fields that were not changed', () {
    const settings = PracticeReminderSettings(
      enabled: true,
      hour: 21,
      minute: 30,
    );

    final disabled = settings.copyWith(enabled: false);

    expect(disabled.enabled, isFalse);
    expect(disabled.timeLabel, '21:30');
  });
}

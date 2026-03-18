import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/core/localization/app_strings.dart';
import 'package:quran/models/prayer_time_model.dart';
import 'package:quran/models/zikir_reminder_models.dart';
import 'package:quran/services/notification_service.dart';
import 'package:quran/state/zikir_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loads bundled adhkar presets from asset data', () async {
    final controller = ZikirController();
    await controller.bootstrap();

    final presetIds = controller.presetSets.map((set) => set.id).toSet();
    expect(
      presetIds,
      containsAll(<String>[
        'after_salah',
        'morning',
        'evening',
        'sleep',
        'istighfar',
      ]),
    );
  });

  test(
    'after salah preset advances automatically between dhikr steps',
    () async {
      final controller = ZikirController();
      await controller.bootstrap();
      await controller.setVibrationEnabled(false);

      for (int i = 0; i < 33; i++) {
        await controller.incrementPresetSet('after_salah');
      }

      expect(controller.currentDhikrForSet('after_salah')?.id, 'alhamdulillah');
      expect(controller.currentCountForSet('after_salah'), 0);
    },
  );

  test('custom dhikr persists locally after bootstrap reload', () async {
    final controller = ZikirController();
    await controller.bootstrap();
    await controller.setVibrationEnabled(false);

    await controller.addCustomDhikr(
      arabicText: 'اللهم صل على محمد',
      transliteration: 'Allahumma salli ala Muhammad',
      meaning: 'O Allah, send prayers upon Muhammad',
      targetCount: 50,
    );

    final restored = ZikirController();
    await restored.bootstrap();
    await restored.setVibrationEnabled(false);

    expect(restored.customDhikrs, isNotEmpty);
    expect(restored.customDhikrs.first.arabicText, 'اللهم صل على محمد');
    expect(restored.targetForDhikr(restored.customDhikrs.first.id), 50);
  });

  test('deleting a custom dhikr removes saved state', () async {
    final controller = ZikirController();
    await controller.bootstrap();
    await controller.setVibrationEnabled(false);

    await controller.addCustomDhikr(
      arabicText: 'سبحان الله وبحمده',
      targetCount: 25,
    );

    final customId = controller.customDhikrs.first.id;
    await controller.incrementDhikr(customId);
    await controller.deleteCustomDhikr(customId);

    final restored = ZikirController();
    await restored.bootstrap();
    await restored.setVibrationEnabled(false);

    expect(
      restored.customDhikrs.where((dhikr) => dhikr.id == customId),
      isEmpty,
    );
    expect(restored.countForDhikr(customId), 0);
    expect(restored.findDhikr(customId), isNull);
  });

  test(
    'legacy single reminder migrates into one daily reminder rule',
    () async {
      SharedPreferences.setMockInitialValues({
        'zikir_reminder_enabled': true,
        'zikir_reminder_dhikr_id': 'alhamdulillah',
        'zikir_reminder_hour': 6,
        'zikir_reminder_minute': 15,
      });

      final controller = ZikirController();
      await controller.bootstrap();

      expect(controller.reminderRules, hasLength(1));
      final rule = controller.reminderRules.first;
      expect(rule.enabled, isTrue);
      expect(rule.targetType, ZikirReminderTargetType.singleDhikr);
      expect(rule.targetId, 'alhamdulillah');
      expect(rule.scheduleType, ZikirReminderScheduleType.dailyTime);
      expect(rule.time, const TimeOfDay(hour: 6, minute: 15));
      expect(rule.weekdays, {
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
        DateTime.saturday,
        DateTime.sunday,
      });
    },
  );

  test(
    'after-prayer reminder schedules notifications with prayer offset',
    () async {
      final notificationService = _FakeNotificationService();
      final controller = ZikirController(
        notificationService: notificationService,
      );
      await controller.bootstrap();

      final now = DateTime.now();
      final today = PrayerDaySchedule(
        date: now,
        prayers: [
          PrayerTimeEntry(
            name: PrayerName.fajr,
            time: now.add(const Duration(minutes: 30)),
          ),
          PrayerTimeEntry(
            name: PrayerName.dhuhr,
            time: now.add(const Duration(hours: 6)),
          ),
          PrayerTimeEntry(
            name: PrayerName.asr,
            time: now.add(const Duration(hours: 9)),
          ),
          PrayerTimeEntry(
            name: PrayerName.maghrib,
            time: now.add(const Duration(hours: 12)),
          ),
          PrayerTimeEntry(
            name: PrayerName.isha,
            time: now.add(const Duration(hours: 14)),
          ),
        ],
      );
      final tomorrow = PrayerDaySchedule(
        date: now.add(const Duration(days: 1)),
        prayers: [
          PrayerTimeEntry(
            name: PrayerName.fajr,
            time: now.add(const Duration(days: 1, minutes: 35)),
          ),
          PrayerTimeEntry(
            name: PrayerName.dhuhr,
            time: now.add(const Duration(days: 1, hours: 6)),
          ),
          PrayerTimeEntry(
            name: PrayerName.asr,
            time: now.add(const Duration(days: 1, hours: 9)),
          ),
          PrayerTimeEntry(
            name: PrayerName.maghrib,
            time: now.add(const Duration(days: 1, hours: 12)),
          ),
          PrayerTimeEntry(
            name: PrayerName.isha,
            time: now.add(const Duration(days: 1, hours: 14)),
          ),
        ],
      );

      await controller.syncExternalContext(
        language: AppLanguage.english,
        todaySchedule: today,
        tomorrowSchedule: tomorrow,
      );
      await controller.addReminder(
        ZikirReminderRule(
          id: 'after_prayer_rule',
          enabled: true,
          targetType: ZikirReminderTargetType.presetSet,
          targetId: 'after_salah',
          scheduleType: ZikirReminderScheduleType.afterPrayer,
          weekdays: {today.date.weekday, tomorrow.date.weekday},
          prayers: const [PrayerName.fajr, PrayerName.maghrib],
          minutesAfterPrayer: 10,
        ),
      );

      expect(notificationService.scheduled, isNotEmpty);
      expect(
        notificationService.scheduled.first.dateTime,
        today.prayers.first.time.add(const Duration(minutes: 10)),
      );
    },
  );
}

class _FakeNotificationService extends NotificationService {
  List<ScheduledZikirNotification> scheduled = const [];

  @override
  Future<void> cancelZikirReminders() async {
    scheduled = const [];
  }

  @override
  Future<bool> scheduleZikirNotifications(
    List<ScheduledZikirNotification> notifications,
  ) async {
    scheduled = notifications;
    return true;
  }
}

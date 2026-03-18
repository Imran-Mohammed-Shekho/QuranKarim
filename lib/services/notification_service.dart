import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/prayer_time_model.dart';
import '../models/zikir_reminder_models.dart';

class NotificationService {
  NotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const String _channelId = 'prayer_times_channel';
  static const String _channelName = 'Prayer Times';
  static const String _channelDescription =
      'Notifications for daily prayer times';
  static const String _zikirChannelId = 'zikir_reminders_channel';
  static const String _zikirChannelName = 'Zikir Reminders';
  static const String _zikirChannelDescription =
      'Daily reminders for tasbih and remembrance';
  static const String pushChannelId = 'push_notifications_channel';
  static const String _pushChannelName = 'Push Notifications';
  static const String _pushChannelDescription =
      'General push notifications from Firebase Cloud Messaging';
  static const int _notificationBaseId = 1200;
  static const String _scheduledZikirIdsKey =
      'scheduled_zikir_notification_ids';

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await _configureTimeZone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings: settings);
    await _createAndroidChannels();
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    return ensurePermissions();
  }

  Future<bool> ensurePermissions() async {
    await initialize();

    if (kIsWeb) {
      return false;
    }

    if (Platform.isIOS || Platform.isMacOS) {
      final iosGranted = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      final macGranted = await _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return iosGranted ?? macGranted ?? false;
    }

    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android == null) {
        return false;
      }

      final enabled = await android.areNotificationsEnabled() ?? true;
      if (!enabled) {
        final granted = await android.requestNotificationsPermission() ?? false;
        if (!granted) {
          return false;
        }
      }

      final canExact = await android.canScheduleExactNotifications() ?? false;
      if (!canExact) {
        await android.requestExactAlarmsPermission();
      }
      return true;
    }

    return true;
  }

  Future<void> cancelPrayerNotifications() async {
    await initialize();
    for (int i = 0; i < PrayerName.values.length; i++) {
      await _plugin.cancel(id: _notificationBaseId + i);
    }
  }

  Future<void> schedulePrayerNotifications({
    required PrayerDaySchedule today,
    required PrayerDaySchedule tomorrow,
  }) async {
    await initialize();
    await cancelPrayerNotifications();

    final now = DateTime.now();
    AndroidScheduleMode scheduleMode =
        AndroidScheduleMode.inexactAllowWhileIdle;

    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final canExact = await android?.canScheduleExactNotifications() ?? false;
      scheduleMode = canExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
    }

    for (int index = 0; index < PrayerName.values.length; index++) {
      final prayerName = PrayerName.values[index];
      final todayEntry = today.prayers.firstWhere(
        (item) => item.name == prayerName,
      );
      final tomorrowEntry = tomorrow.prayers.firstWhere(
        (item) => item.name == prayerName,
      );
      final scheduledTime = todayEntry.time.isAfter(now)
          ? todayEntry.time
          : tomorrowEntry.time;

      await _plugin.zonedSchedule(
        id: _notificationBaseId + index,
        title: '${prayerName.label} Prayer Time',
        body: 'It\'s time to pray ${prayerName.label}',
        scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: scheduleMode,
      );
    }
  }

  Future<void> cancelZikirReminders() async {
    await initialize();
    final prefs = await SharedPreferences.getInstance();
    final scheduledIds = prefs.getStringList(_scheduledZikirIdsKey) ?? const [];
    for (final rawId in scheduledIds) {
      final id = int.tryParse(rawId);
      if (id != null) {
        await _plugin.cancel(id: id);
      }
    }
    await prefs.remove(_scheduledZikirIdsKey);
  }

  Future<void> showPushNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          pushChannelId,
          _pushChannelName,
          channelDescription: _pushChannelDescription,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  Future<bool> scheduleZikirNotifications(
    List<ScheduledZikirNotification> notifications,
  ) async {
    await initialize();
    await cancelZikirReminders();
    if (notifications.isEmpty) {
      return true;
    }

    final granted = await ensurePermissions();
    if (!granted) {
      return false;
    }

    AndroidScheduleMode scheduleMode =
        AndroidScheduleMode.inexactAllowWhileIdle;
    if (!kIsWeb && Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final canExact = await android?.canScheduleExactNotifications() ?? false;
      scheduleMode = canExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
    }

    final prefs = await SharedPreferences.getInstance();
    final scheduledIds = <String>[];
    for (final notification in notifications) {
      await _plugin.zonedSchedule(
        id: notification.id,
        title: notification.title,
        body: notification.body,
        scheduledDate: tz.TZDateTime.from(notification.dateTime, tz.local),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _zikirChannelId,
            _zikirChannelName,
            channelDescription: _zikirChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: scheduleMode,
      );
      scheduledIds.add(notification.id.toString());
    }
    await prefs.setStringList(_scheduledZikirIdsKey, scheduledIds);
    return true;
  }

  Future<void> _configureTimeZone() async {
    if (kIsWeb || Platform.isLinux) {
      return;
    }

    tz_data.initializeTimeZones();
    if (Platform.isWindows) {
      return;
    }

    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  Future<void> _createAndroidChannels() async {
    if (kIsWeb || !Platform.isAndroid) {
      return;
    }

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) {
      return;
    }

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
      ),
    );
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        _zikirChannelId,
        _zikirChannelName,
        description: _zikirChannelDescription,
        importance: Importance.high,
      ),
    );
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        pushChannelId,
        _pushChannelName,
        description: _pushChannelDescription,
        importance: Importance.max,
      ),
    );
  }
}

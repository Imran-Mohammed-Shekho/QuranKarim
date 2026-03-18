import 'package:flutter/material.dart';

import 'prayer_time_model.dart';

enum ZikirReminderTargetType { singleDhikr, presetSet }

enum ZikirReminderScheduleType { dailyTime, afterPrayer }

class ZikirReminderRule {
  const ZikirReminderRule({
    required this.id,
    required this.enabled,
    required this.targetType,
    required this.targetId,
    required this.scheduleType,
    required this.weekdays,
    this.time,
    this.prayers = const <PrayerName>[],
    this.minutesAfterPrayer = 0,
  });

  final String id;
  final bool enabled;
  final ZikirReminderTargetType targetType;
  final String targetId;
  final ZikirReminderScheduleType scheduleType;
  final Set<int> weekdays;
  final TimeOfDay? time;
  final List<PrayerName> prayers;
  final int minutesAfterPrayer;

  factory ZikirReminderRule.fromJson(Map<String, dynamic> json) {
    final weekdays = (json['weekdays'] as List<dynamic>? ?? const <dynamic>[])
        .map((value) => (value as num?)?.toInt())
        .whereType<int>()
        .where((value) => value >= DateTime.monday && value <= DateTime.sunday)
        .toSet();
    final prayers = (json['prayers'] as List<dynamic>? ?? const <dynamic>[])
        .map((value) => value as String?)
        .whereType<String>()
        .map(
          (value) => PrayerName.values.firstWhere(
            (prayer) => prayer.name == value,
            orElse: () => PrayerName.fajr,
          ),
        )
        .toList(growable: false);
    final timeJson = json['time'] as Map<String, dynamic>?;
    return ZikirReminderRule(
      id: (json['id'] as String? ?? '').trim(),
      enabled: json['enabled'] as bool? ?? false,
      targetType: ZikirReminderTargetType.values.firstWhere(
        (value) => value.name == json['targetType'],
        orElse: () => ZikirReminderTargetType.singleDhikr,
      ),
      targetId: (json['targetId'] as String? ?? '').trim(),
      scheduleType: ZikirReminderScheduleType.values.firstWhere(
        (value) => value.name == json['scheduleType'],
        orElse: () => ZikirReminderScheduleType.dailyTime,
      ),
      weekdays: weekdays,
      time: timeJson == null
          ? null
          : TimeOfDay(
              hour: (timeJson['hour'] as num?)?.toInt() ?? 0,
              minute: (timeJson['minute'] as num?)?.toInt() ?? 0,
            ),
      prayers: prayers,
      minutesAfterPrayer: (json['minutesAfterPrayer'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    final sortedWeekdays = weekdays.toList()..sort();
    return <String, dynamic>{
      'id': id,
      'enabled': enabled,
      'targetType': targetType.name,
      'targetId': targetId,
      'scheduleType': scheduleType.name,
      'weekdays': sortedWeekdays,
      'time': time == null
          ? null
          : <String, dynamic>{'hour': time!.hour, 'minute': time!.minute},
      'prayers': prayers.map((value) => value.name).toList(growable: false),
      'minutesAfterPrayer': minutesAfterPrayer,
    };
  }

  ZikirReminderRule copyWith({
    String? id,
    bool? enabled,
    ZikirReminderTargetType? targetType,
    String? targetId,
    ZikirReminderScheduleType? scheduleType,
    Set<int>? weekdays,
    TimeOfDay? time,
    bool clearTime = false,
    List<PrayerName>? prayers,
    int? minutesAfterPrayer,
  }) {
    return ZikirReminderRule(
      id: id ?? this.id,
      enabled: enabled ?? this.enabled,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      scheduleType: scheduleType ?? this.scheduleType,
      weekdays: weekdays ?? this.weekdays,
      time: clearTime ? null : (time ?? this.time),
      prayers: prayers ?? this.prayers,
      minutesAfterPrayer: minutesAfterPrayer ?? this.minutesAfterPrayer,
    );
  }
}

class ScheduledZikirNotification {
  const ScheduledZikirNotification({
    required this.id,
    required this.dateTime,
    required this.title,
    required this.body,
  });

  final int id;
  final DateTime dateTime;
  final String title;
  final String body;
}

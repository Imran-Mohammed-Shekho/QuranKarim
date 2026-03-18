import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/localization/app_strings.dart';
import '../models/dhikr_models.dart';
import '../models/prayer_time_model.dart';
import '../models/zikir_reminder_models.dart';
import '../services/dhikr_library_service.dart';
import '../services/notification_service.dart';

class ZikirController extends ChangeNotifier {
  ZikirController({
    NotificationService? notificationService,
    DhikrLibraryService? libraryService,
  }) : _notificationService = notificationService,
       _libraryService = libraryService ?? DhikrLibraryService();

  static const String _customDhikrsKey = 'zikir_custom_dhikrs';
  static const String _singleCountsKey = 'zikir_single_counts';
  static const String _singleTargetsKey = 'zikir_single_targets';
  static const String _setProgressKey = 'zikir_set_progress';
  static const String _vibrationEnabledKey = 'zikir_vibration_enabled';
  static const String _languageKey = 'app_language';
  static const String _reminderRulesKey = 'zikir_reminder_rules_v2';

  static const String _legacyReminderEnabledKey = 'zikir_reminder_enabled';
  static const String _legacyReminderDhikrIdKey = 'zikir_reminder_dhikr_id';
  static const String _legacyReminderHourKey = 'zikir_reminder_hour';
  static const String _legacyReminderMinuteKey = 'zikir_reminder_minute';
  static const String _defaultReminderDhikrId = 'alhamdulillah';
  static const int _reminderScheduleHorizonDays = 14;
  static const int _maxReminderSlotsPerRule = 32;
  static const Set<int> _allWeekdays = <int>{
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
    DateTime.sunday,
  };

  static const List<DhikrDefinition> _fallbackBuiltInDhikrs = [
    DhikrDefinition(
      id: 'subhanallah',
      arabicText: 'سبحان الله',
      transliteration: 'SubhanAllah',
      meaning: 'Glory be to Allah',
      defaultTarget: 33,
    ),
    DhikrDefinition(
      id: 'alhamdulillah',
      arabicText: 'الحمد لله',
      transliteration: 'Alhamdulillah',
      meaning: 'All praise is for Allah',
      defaultTarget: 33,
    ),
    DhikrDefinition(
      id: 'allahu_akbar',
      arabicText: 'الله أكبر',
      transliteration: 'Allahu Akbar',
      meaning: 'Allah is the Greatest',
      defaultTarget: 34,
    ),
    DhikrDefinition(
      id: 'astaghfirullah',
      arabicText: 'أستغفر الله',
      transliteration: 'Astaghfirullah',
      meaning: 'I seek forgiveness from Allah',
      defaultTarget: 100,
    ),
    DhikrDefinition(
      id: 'la_ilaha_illallah',
      arabicText: 'لا إله إلا الله',
      transliteration: 'La ilaha illallah',
      meaning: 'There is no god but Allah',
      defaultTarget: 100,
    ),
  ];

  static const List<DhikrSetDefinition> _fallbackPresetSets = [
    DhikrSetDefinition(
      id: 'after_salah',
      title: 'After Salah Tasbih',
      subtitle: 'Move through the well-known post-prayer remembrance set.',
      steps: [
        DhikrSetStep(dhikrId: 'subhanallah', targetCount: 33),
        DhikrSetStep(dhikrId: 'alhamdulillah', targetCount: 33),
        DhikrSetStep(dhikrId: 'allahu_akbar', targetCount: 34),
      ],
    ),
  ];

  final NotificationService? _notificationService;
  final DhikrLibraryService _libraryService;

  SharedPreferences? _prefs;
  AppLanguage _language = AppLanguage.kurdish;
  PrayerDaySchedule? _todayPrayerSchedule;
  PrayerDaySchedule? _tomorrowPrayerSchedule;

  List<DhikrDefinition> _builtInDhikrs = _fallbackBuiltInDhikrs;
  List<DhikrSetDefinition> _presetSets = _fallbackPresetSets;
  List<DhikrDefinition> _customDhikrs = const [];
  List<ZikirReminderRule> _reminderRules = const [];
  Map<String, int> _singleCounts = <String, int>{};
  Map<String, int> _singleTargets = <String, int>{};
  Map<String, DhikrSetProgress> _setProgress = <String, DhikrSetProgress>{};

  bool vibrationEnabled = true;
  String? reminderError;
  bool isReady = false;

  AppStrings get strings => AppStrings(_language);
  List<DhikrDefinition> get builtInDhikrs => List.unmodifiable(_builtInDhikrs);
  List<DhikrDefinition> get customDhikrs => List.unmodifiable(_customDhikrs);
  List<DhikrDefinition> get allDhikrs =>
      List.unmodifiable([..._builtInDhikrs, ..._customDhikrs]);
  List<DhikrSetDefinition> get presetSets => List.unmodifiable(_presetSets);
  List<ZikirReminderRule> get reminderRules =>
      List.unmodifiable(_reminderRules);

  Future<void> bootstrap() async {
    _prefs = await SharedPreferences.getInstance();
    final savedLanguage = _prefs?.getString(_languageKey);
    if (savedLanguage != null) {
      _language = AppLanguage.values.firstWhere(
        (value) => value.name == savedLanguage,
        orElse: () => AppLanguage.english,
      );
    }

    try {
      final library = await _libraryService.loadLibrary();
      _builtInDhikrs = library.builtInDhikrs;
      _presetSets = library.presetSets;
    } catch (_) {
      _builtInDhikrs = _fallbackBuiltInDhikrs;
      _presetSets = _fallbackPresetSets;
    }

    _customDhikrs = _loadCustomDhikrs();
    _singleCounts = _loadIntMap(_singleCountsKey);
    _singleTargets = _loadIntMap(_singleTargetsKey);
    _setProgress = _loadSetProgress();
    vibrationEnabled = _prefs?.getBool(_vibrationEnabledKey) ?? true;
    _reminderRules = _loadReminderRules();
    if (_reminderRules.isEmpty) {
      _reminderRules = _migrateLegacyReminderRules();
      await _persistReminderRules();
    }
    _reminderRules = _normalizedReminderRules(_reminderRules);
    isReady = true;
    notifyListeners();
    await _rescheduleReminders();
  }

  Future<void> syncExternalContext({
    required AppLanguage language,
    PrayerDaySchedule? todaySchedule,
    PrayerDaySchedule? tomorrowSchedule,
  }) async {
    final languageChanged = _language != language;
    final todayChanged =
        _scheduleSignature(_todayPrayerSchedule) !=
        _scheduleSignature(todaySchedule);
    final tomorrowChanged =
        _scheduleSignature(_tomorrowPrayerSchedule) !=
        _scheduleSignature(tomorrowSchedule);
    if (!languageChanged && !todayChanged && !tomorrowChanged) {
      return;
    }

    _language = language;
    _todayPrayerSchedule = todaySchedule;
    _tomorrowPrayerSchedule = tomorrowSchedule;
    if (isReady) {
      await _rescheduleReminders();
    }
    notifyListeners();
  }

  DhikrDefinition? findDhikr(String id) {
    for (final dhikr in allDhikrs) {
      if (dhikr.id == id) {
        return dhikr;
      }
    }
    return null;
  }

  DhikrSetDefinition? findPresetSet(String id) {
    for (final set in _presetSets) {
      if (set.id == id) {
        return set;
      }
    }
    return null;
  }

  int countForDhikr(String id) => _singleCounts[id] ?? 0;

  int targetForDhikr(String id) {
    final saved = _singleTargets[id];
    if (saved != null && saved > 0) {
      return saved;
    }
    return findDhikr(id)?.defaultTarget ?? 33;
  }

  double progressForDhikr(String id) {
    final target = targetForDhikr(id);
    if (target <= 0) {
      return 0;
    }
    return (countForDhikr(id) / target).clamp(0.0, 1.0);
  }

  DhikrSetProgress progressForSet(String setId) {
    final definition = findPresetSet(setId);
    if (definition == null) {
      return const DhikrSetProgress(currentStepIndex: 0, stepCounts: []);
    }

    final progress = _setProgress[setId];
    if (progress == null ||
        progress.stepCounts.length != definition.steps.length) {
      return DhikrSetProgress.empty(definition);
    }

    final maxIndex = definition.steps.isEmpty ? 0 : definition.steps.length - 1;
    final clampedIndex = progress.currentStepIndex.clamp(0, maxIndex);
    return progress.copyWith(currentStepIndex: clampedIndex);
  }

  DhikrDefinition? currentDhikrForSet(String setId) {
    final definition = findPresetSet(setId);
    if (definition == null || definition.steps.isEmpty) {
      return null;
    }
    final progress = progressForSet(setId);
    return findDhikr(definition.steps[progress.currentStepIndex].dhikrId);
  }

  int currentCountForSet(String setId) {
    final definition = findPresetSet(setId);
    if (definition == null || definition.steps.isEmpty) {
      return 0;
    }
    final progress = progressForSet(setId);
    return progress.stepCounts[progress.currentStepIndex];
  }

  int currentTargetForSet(String setId) {
    final definition = findPresetSet(setId);
    if (definition == null || definition.steps.isEmpty) {
      return 0;
    }
    final progress = progressForSet(setId);
    return definition.steps[progress.currentStepIndex].targetCount;
  }

  double currentProgressForSet(String setId) {
    final target = currentTargetForSet(setId);
    if (target <= 0) {
      return 0;
    }
    return (currentCountForSet(setId) / target).clamp(0.0, 1.0);
  }

  double overallProgressForSet(String setId) {
    final definition = findPresetSet(setId);
    if (definition == null || definition.steps.isEmpty) {
      return 0;
    }

    final progress = progressForSet(setId);
    final total = definition.steps.fold<int>(
      0,
      (sum, step) => sum + step.targetCount,
    );
    final completed = progress.stepCounts.fold<int>(
      0,
      (sum, count) => sum + count,
    );
    if (total <= 0) {
      return 0;
    }
    return (completed / total).clamp(0.0, 1.0);
  }

  bool hasProgressForDhikr(String id) => countForDhikr(id) > 0;

  bool hasProgressForSet(String setId) {
    final progress = progressForSet(setId);
    return progress.stepCounts.any((count) => count > 0);
  }

  Future<void> setVibrationEnabled(bool value) async {
    vibrationEnabled = value;
    await _prefs?.setBool(_vibrationEnabledKey, value);
    notifyListeners();
  }

  Future<void> addReminder(ZikirReminderRule rule) async {
    _reminderRules = [..._reminderRules, rule];
    await _persistReminderRules();
    await _rescheduleReminders();
    notifyListeners();
  }

  Future<void> updateReminder(ZikirReminderRule rule) async {
    final index = _reminderRules.indexWhere((item) => item.id == rule.id);
    if (index < 0) {
      return;
    }
    final next = [..._reminderRules];
    next[index] = rule;
    _reminderRules = _normalizedReminderRules(next);
    await _persistReminderRules();
    await _rescheduleReminders();
    notifyListeners();
  }

  Future<void> setReminderEnabled(String id, bool value) async {
    final reminder = _reminderRules.where((item) => item.id == id).firstOrNull;
    if (reminder == null) {
      return;
    }
    await updateReminder(reminder.copyWith(enabled: value));
  }

  Future<void> deleteReminder(String id) async {
    final next = _reminderRules.where((item) => item.id != id).toList();
    if (next.length == _reminderRules.length) {
      return;
    }
    _reminderRules = next;
    await _persistReminderRules();
    await _rescheduleReminders();
    notifyListeners();
  }

  bool reminderCanSchedule(ZikirReminderRule rule) {
    if (!rule.enabled || !_hasValidReminderTarget(rule)) {
      return false;
    }
    if (rule.scheduleType == ZikirReminderScheduleType.dailyTime) {
      return rule.time != null && rule.weekdays.isNotEmpty;
    }
    return rule.prayers.isNotEmpty &&
        rule.weekdays.isNotEmpty &&
        _todayPrayerSchedule != null &&
        _tomorrowPrayerSchedule != null;
  }

  bool reminderHasFutureOccurrence(ZikirReminderRule rule) {
    return _nextOccurrencePreview(rule).isNotEmpty;
  }

  Future<void> addCustomDhikr({
    required String arabicText,
    required int targetCount,
    String transliteration = '',
    String? meaning,
  }) async {
    final now = DateTime.now().microsecondsSinceEpoch;
    final dhikr = DhikrDefinition(
      id: 'custom_$now',
      arabicText: arabicText.trim(),
      transliteration: transliteration.trim(),
      meaning: (meaning == null || meaning.trim().isEmpty)
          ? null
          : meaning.trim(),
      defaultTarget: targetCount,
      isCustom: true,
    );
    _customDhikrs = [..._customDhikrs, dhikr];
    _singleTargets[dhikr.id] = targetCount;
    await _persistCustomDhikrs();
    await _persistIntMap(_singleTargetsKey, _singleTargets);
    await _rescheduleReminders();
    notifyListeners();
  }

  Future<void> deleteCustomDhikr(String id) async {
    final exists = _customDhikrs.any((dhikr) => dhikr.id == id);
    if (!exists) {
      return;
    }

    _customDhikrs = _customDhikrs
        .where((dhikr) => dhikr.id != id)
        .toList(growable: false);
    _singleCounts = {..._singleCounts}..remove(id);
    _singleTargets = {..._singleTargets}..remove(id);
    _reminderRules = _reminderRules
        .where(
          (rule) =>
              !(rule.targetType == ZikirReminderTargetType.singleDhikr &&
                  rule.targetId == id),
        )
        .toList(growable: false);
    await _persistCustomDhikrs();
    await _persistIntMap(_singleCountsKey, _singleCounts);
    await _persistIntMap(_singleTargetsKey, _singleTargets);
    await _persistReminderRules();
    await _rescheduleReminders();
    notifyListeners();
  }

  Future<void> incrementDhikr(String id) async {
    final next = countForDhikr(id) + 1;
    _singleCounts = {..._singleCounts, id: next};
    await _persistIntMap(_singleCountsKey, _singleCounts);
    await _triggerTapFeedback(completed: next >= targetForDhikr(id));
    notifyListeners();
  }

  Future<void> decrementDhikr(String id) async {
    final next = countForDhikr(id) - 1;
    _singleCounts = {..._singleCounts, id: next < 0 ? 0 : next};
    await _persistIntMap(_singleCountsKey, _singleCounts);
    notifyListeners();
  }

  Future<void> resetDhikr(String id) async {
    _singleCounts = {..._singleCounts, id: 0};
    await _persistIntMap(_singleCountsKey, _singleCounts);
    notifyListeners();
  }

  Future<DhikrTapOutcome> incrementPresetSet(String setId) async {
    final definition = findPresetSet(setId);
    if (definition == null || definition.steps.isEmpty) {
      return DhikrTapOutcome.incremented;
    }

    final progress = progressForSet(setId);
    final counts = [...progress.stepCounts];
    final stepIndex = progress.currentStepIndex;
    final target = definition.steps[stepIndex].targetCount;
    final nextCount = counts[stepIndex] + 1;
    counts[stepIndex] = nextCount > target ? target : nextCount;

    DhikrTapOutcome outcome = DhikrTapOutcome.incremented;
    var nextIndex = stepIndex;
    if (counts[stepIndex] >= target) {
      if (stepIndex < definition.steps.length - 1) {
        nextIndex = stepIndex + 1;
        outcome = DhikrTapOutcome.advanced;
      } else {
        outcome = DhikrTapOutcome.completed;
      }
    }

    _setProgress = {
      ..._setProgress,
      setId: DhikrSetProgress(currentStepIndex: nextIndex, stepCounts: counts),
    };
    await _persistSetProgress();
    await _triggerTapFeedback(
      completed: outcome != DhikrTapOutcome.incremented,
    );
    notifyListeners();
    return outcome;
  }

  Future<void> decrementPresetSet(String setId) async {
    final definition = findPresetSet(setId);
    if (definition == null || definition.steps.isEmpty) {
      return;
    }

    final progress = progressForSet(setId);
    final counts = [...progress.stepCounts];
    var stepIndex = progress.currentStepIndex;

    if (counts[stepIndex] > 0) {
      counts[stepIndex]--;
    } else if (stepIndex > 0) {
      stepIndex--;
      if (counts[stepIndex] > 0) {
        counts[stepIndex]--;
      }
    }

    _setProgress = {
      ..._setProgress,
      setId: DhikrSetProgress(currentStepIndex: stepIndex, stepCounts: counts),
    };
    await _persistSetProgress();
    notifyListeners();
  }

  Future<void> resetPresetSet(String setId) async {
    final definition = findPresetSet(setId);
    if (definition == null) {
      return;
    }

    _setProgress = {..._setProgress, setId: DhikrSetProgress.empty(definition)};
    await _persistSetProgress();
    notifyListeners();
  }

  List<DhikrDefinition> _loadCustomDhikrs() {
    final raw = _prefs?.getString(_customDhikrsKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .map(DhikrDefinition.fromJson)
        .where((dhikr) => dhikr.id.isNotEmpty && dhikr.arabicText.isNotEmpty)
        .toList(growable: false);
  }

  Map<String, int> _loadIntMap(String key) {
    final raw = _prefs?.getString(key);
    if (raw == null || raw.isEmpty) {
      return <String, int>{};
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (mapKey, value) => MapEntry(mapKey, (value as num).toInt()),
    );
  }

  Map<String, DhikrSetProgress> _loadSetProgress() {
    final raw = _prefs?.getString(_setProgressKey);
    if (raw == null || raw.isEmpty) {
      return <String, DhikrSetProgress>{};
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(
        key,
        DhikrSetProgress.fromJson(value as Map<String, dynamic>),
      ),
    );
  }

  List<ZikirReminderRule> _loadReminderRules() {
    final raw = _prefs?.getString(_reminderRulesKey);
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .map(ZikirReminderRule.fromJson)
        .where((rule) => rule.id.isNotEmpty && rule.targetId.isNotEmpty)
        .toList(growable: false);
  }

  List<ZikirReminderRule> _migrateLegacyReminderRules() {
    final hasLegacyValues =
        (_prefs?.containsKey(_legacyReminderEnabledKey) ?? false) ||
        (_prefs?.containsKey(_legacyReminderDhikrIdKey) ?? false) ||
        (_prefs?.containsKey(_legacyReminderHourKey) ?? false) ||
        (_prefs?.containsKey(_legacyReminderMinuteKey) ?? false);
    if (!hasLegacyValues) {
      return const [];
    }

    final targetId =
        _prefs?.getString(_legacyReminderDhikrIdKey) ?? _defaultReminderDhikrId;
    if (findDhikr(targetId) == null) {
      return const [];
    }

    return <ZikirReminderRule>[
      ZikirReminderRule(
        id: 'legacy_daily_$targetId',
        enabled: _prefs?.getBool(_legacyReminderEnabledKey) ?? false,
        targetType: ZikirReminderTargetType.singleDhikr,
        targetId: targetId,
        scheduleType: ZikirReminderScheduleType.dailyTime,
        weekdays: _allWeekdays,
        time: TimeOfDay(
          hour: _prefs?.getInt(_legacyReminderHourKey) ?? 20,
          minute: _prefs?.getInt(_legacyReminderMinuteKey) ?? 0,
        ),
      ),
    ];
  }

  List<ZikirReminderRule> _normalizedReminderRules(
    List<ZikirReminderRule> rules,
  ) {
    return rules
        .where(_hasValidReminderTarget)
        .map((rule) {
          final normalizedWeekdays = rule.weekdays.isEmpty
              ? _allWeekdays
              : rule.weekdays
                    .where(
                      (value) =>
                          value >= DateTime.monday && value <= DateTime.sunday,
                    )
                    .toSet();
          return rule.copyWith(
            weekdays: normalizedWeekdays,
            prayers: rule.prayers.toSet().toList(growable: false),
          );
        })
        .toList(growable: false);
  }

  bool _hasValidReminderTarget(ZikirReminderRule rule) {
    return switch (rule.targetType) {
      ZikirReminderTargetType.singleDhikr => findDhikr(rule.targetId) != null,
      ZikirReminderTargetType.presetSet => findPresetSet(rule.targetId) != null,
    };
  }

  Future<void> _persistCustomDhikrs() async {
    final encoded = jsonEncode(
      _customDhikrs.map((item) => item.toJson()).toList(),
    );
    await _prefs?.setString(_customDhikrsKey, encoded);
  }

  Future<void> _persistIntMap(String key, Map<String, int> values) async {
    await _prefs?.setString(key, jsonEncode(values));
  }

  Future<void> _persistSetProgress() async {
    final encoded = jsonEncode(
      _setProgress.map((key, value) => MapEntry(key, value.toJson())),
    );
    await _prefs?.setString(_setProgressKey, encoded);
  }

  Future<void> _persistReminderRules() async {
    final encoded = jsonEncode(
      _reminderRules.map((rule) => rule.toJson()).toList(growable: false),
    );
    await _prefs?.setString(_reminderRulesKey, encoded);
  }

  Future<void> _triggerTapFeedback({required bool completed}) async {
    if (!vibrationEnabled) {
      return;
    }

    if (completed) {
      await HapticFeedback.mediumImpact();
      return;
    }

    await HapticFeedback.selectionClick();
  }

  Future<void> _rescheduleReminders() async {
    final service = _notificationService;
    final enabledRules = _reminderRules.where((rule) => rule.enabled).toList();
    if (service == null) {
      reminderError = enabledRules.isEmpty
          ? null
          : strings.zikirReminderUnavailable;
      return;
    }

    final notifications = _buildScheduledNotifications(enabledRules);
    final scheduled = await service.scheduleZikirNotifications(notifications);
    reminderError = scheduled ? null : strings.reminderPermissionDenied;
  }

  List<ScheduledZikirNotification> _buildScheduledNotifications(
    List<ZikirReminderRule> rules,
  ) {
    final notifications = <ScheduledZikirNotification>[];
    for (final rule in rules) {
      final occurrences = _nextOccurrencePreview(rule);
      for (
        var index = 0;
        index < occurrences.length && index < _maxReminderSlotsPerRule;
        index++
      ) {
        notifications.add(
          ScheduledZikirNotification(
            id: _notificationIdFor(rule.id, index),
            dateTime: occurrences[index],
            title: strings.zikirReminderNotificationTitle,
            body: _reminderBodyForRule(rule),
          ),
        );
      }
    }

    notifications.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return notifications;
  }

  List<DateTime> _nextOccurrencePreview(ZikirReminderRule rule) {
    final now = DateTime.now();
    if (!rule.enabled || !_hasValidReminderTarget(rule)) {
      return const [];
    }
    return switch (rule.scheduleType) {
      ZikirReminderScheduleType.dailyTime => _dailyOccurrences(rule, now),
      ZikirReminderScheduleType.afterPrayer => _afterPrayerOccurrences(
        rule,
        now,
      ),
    };
  }

  List<DateTime> _dailyOccurrences(ZikirReminderRule rule, DateTime now) {
    final time = rule.time;
    if (time == null || rule.weekdays.isEmpty) {
      return const [];
    }

    final occurrences = <DateTime>[];
    for (
      var dayOffset = 0;
      dayOffset < _reminderScheduleHorizonDays;
      dayOffset++
    ) {
      final date = DateTime(now.year, now.month, now.day + dayOffset);
      if (!rule.weekdays.contains(date.weekday)) {
        continue;
      }
      final scheduled = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      if (scheduled.isAfter(now)) {
        occurrences.add(scheduled);
      }
    }
    return occurrences;
  }

  List<DateTime> _afterPrayerOccurrences(ZikirReminderRule rule, DateTime now) {
    if (_todayPrayerSchedule == null ||
        _tomorrowPrayerSchedule == null ||
        rule.prayers.isEmpty ||
        rule.weekdays.isEmpty) {
      return const [];
    }

    final occurrences = <DateTime>[];
    for (final schedule in <PrayerDaySchedule>[
      _todayPrayerSchedule!,
      _tomorrowPrayerSchedule!,
    ]) {
      if (!rule.weekdays.contains(schedule.date.weekday)) {
        continue;
      }
      for (final prayer in rule.prayers) {
        final prayerEntry = schedule.prayers
            .where((item) => item.name == prayer)
            .firstOrNull;
        if (prayerEntry == null) {
          continue;
        }
        final scheduled = prayerEntry.time.add(
          Duration(minutes: rule.minutesAfterPrayer),
        );
        if (scheduled.isAfter(now)) {
          occurrences.add(scheduled);
        }
      }
    }
    occurrences.sort();
    return occurrences;
  }

  int _notificationIdFor(String reminderId, int slotIndex) {
    const baseId = 220000;
    final hash = _stableHash(reminderId) % 30000;
    return baseId + (hash * _maxReminderSlotsPerRule) + slotIndex;
  }

  int _stableHash(String input) {
    var hash = 2166136261;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash;
  }

  String _reminderBodyForRule(ZikirReminderRule rule) {
    if (rule.targetType == ZikirReminderTargetType.singleDhikr) {
      final dhikr = findDhikr(rule.targetId);
      if (dhikr == null) {
        return strings.zikirReminderUnavailable;
      }
      final spoken = dhikr.labelFor(_language);
      return strings.zikirReminderNotificationBody(spoken, dhikr.arabicText);
    }

    final preset = findPresetSet(rule.targetId);
    if (preset == null) {
      return strings.zikirReminderUnavailable;
    }
    return strings.zikirPresetReminderNotificationBody(
      preset.titleFor(_language),
    );
  }

  String _scheduleSignature(PrayerDaySchedule? schedule) {
    if (schedule == null) {
      return '';
    }
    final buffer = StringBuffer()..write(schedule.date.toIso8601String());
    for (final prayer in schedule.prayers) {
      buffer
        ..write('|')
        ..write(prayer.name.name)
        ..write(':')
        ..write(prayer.time.toIso8601String());
    }
    return buffer.toString();
  }
}

extension on Iterable<PrayerTimeEntry> {
  PrayerTimeEntry? get firstOrNull => isEmpty ? null : first;
}

extension on Iterable<ZikirReminderRule> {
  ZikirReminderRule? get firstOrNull => isEmpty ? null : first;
}

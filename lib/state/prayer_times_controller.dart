import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/prayer_time_model.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/prayer_time_service.dart';

class PrayerTimesController extends ChangeNotifier {
  PrayerTimesController({
    required LocationService locationService,
    required PrayerTimeService prayerTimeService,
    required NotificationService notificationService,
  }) : _locationService = locationService,
       _prayerTimeService = prayerTimeService,
       _notificationService = notificationService;

  static const String _madhabKey = 'prayer_madhab';
  static const String _notificationsEnabledKey = 'prayer_notifications_enabled';
  static const String _useDeviceLocationKey = 'prayer_use_device_location';
  static const String _selectedCitySlugKey = 'prayer_selected_city_slug';
  static const String _defaultCitySlug = 'هەولێر';

  final LocationService _locationService;
  final PrayerTimeService _prayerTimeService;
  final NotificationService _notificationService;

  PrayerTimesModel? schedule;
  PrayerDaySchedule? _todaySchedule;
  PrayerDaySchedule? _tomorrowSchedule;
  String? errorMessage;
  LocationFailureType? locationFailureType;
  PrayerMadhab madhab = PrayerMadhab.shafi;
  bool notificationsEnabled = false;
  bool useDeviceLocation = false;
  String? selectedCitySlug;
  bool isLoading = false;

  DateTime _now = DateTime.now();
  Timer? _ticker;

  Duration get remainingUntilNextPrayer =>
      schedule?.nextPrayer.time.difference(_now) ?? Duration.zero;
  PrayerDaySchedule? get todaySchedule => _todaySchedule;
  PrayerDaySchedule? get tomorrowSchedule => _tomorrowSchedule;

  String get countdownLabel {
    final remaining = remainingUntilNextPrayer;
    if (remaining.isNegative) {
      return '00:00:00';
    }

    final hours = remaining.inHours.toString().padLeft(2, '0');
    final minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  List<BangCityOption> get availableBangCities =>
      _prayerTimeService.supportedBangCities;

  BangCityOption? get selectedBangCity =>
      _prayerTimeService.findBangCityBySlug(selectedCitySlug);

  BangCityOption? get defaultBangCity =>
      availableBangCities.isEmpty ? null : availableBangCities.first;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMadhab = prefs.getString(_madhabKey);
    final savedNotifications = prefs.getBool(_notificationsEnabledKey) ?? false;
    useDeviceLocation = prefs.getBool(_useDeviceLocationKey) ?? false;
    selectedCitySlug =
        prefs.getString(_selectedCitySlugKey) ??
        _prayerTimeService.findBangCityBySlug(_defaultCitySlug)?.slug ??
        defaultBangCity?.slug;

    if (savedMadhab == PrayerMadhab.hanafi.name) {
      madhab = PrayerMadhab.hanafi;
    }
    notificationsEnabled = savedNotifications;
    if (selectedCitySlug != null &&
        selectedCitySlug != prefs.getString(_selectedCitySlugKey)) {
      await prefs.setString(_selectedCitySlugKey, selectedCitySlug!);
    }
    notifyListeners();
  }

  Future<void> refreshPrayerTimes() async {
    if (isLoading) {
      return;
    }
    try {
      isLoading = true;
      errorMessage = null;
      locationFailureType = null;
      notifyListeners();

      final location = await _resolveLocation();
      if (location == null) {
        return;
      }

      final now = DateTime.now();
      final nextSchedule = await _prayerTimeService.buildPrayerTimesModel(
        location: location,
        now: now,
        madhab: madhab,
      );

      schedule = nextSchedule;
      _todaySchedule = PrayerDaySchedule(
        date: now,
        prayers: nextSchedule.prayers,
      );
      _tomorrowSchedule = await _prayerTimeService.buildTomorrowSchedule(
        location: location,
        now: now,
        madhab: madhab,
      );
      unawaited(
        _prayerTimeService.warmBangCacheForKurdistan(referenceDate: now),
      );
      _now = now;

      _startTicker();

      if (notificationsEnabled &&
          _todaySchedule != null &&
          _tomorrowSchedule != null) {
        final granted = await _notificationService.ensurePermissions();
        if (!granted) {
          errorMessage =
              'Notification permission was not granted. Enable notifications in system settings.';
        } else {
          await _notificationService.schedulePrayerNotifications(
            today: _todaySchedule!,
            tomorrow: _tomorrowSchedule!,
          );
        }
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setMadhab(PrayerMadhab value) async {
    if (madhab == value) {
      return;
    }
    madhab = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_madhabKey, value.name);
    notifyListeners();
    await refreshPrayerTimes();
  }

  Future<void> setSelectedCity(String slug) async {
    if (selectedCitySlug == slug) {
      return;
    }
    selectedCitySlug = slug;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedCitySlugKey, slug);
    notifyListeners();
    await refreshPrayerTimes();
  }

  Future<void> setUseDeviceLocation(bool value) async {
    if (useDeviceLocation == value) {
      return;
    }
    useDeviceLocation = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useDeviceLocationKey, value);
    if (!value && selectedCitySlug == null && defaultBangCity != null) {
      selectedCitySlug = defaultBangCity!.slug;
      await prefs.setString(_selectedCitySlugKey, selectedCitySlug!);
    }
    notifyListeners();
    await refreshPrayerTimes();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    if (value) {
      final granted = await _notificationService.requestPermissions();
      if (!granted) {
        errorMessage =
            'Notification permission was not granted. Enable notifications in system settings.';
        notifyListeners();
        return;
      }
    }

    notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, value);

    if (!value) {
      await _notificationService.cancelPrayerNotifications();
    } else if (_todaySchedule != null && _tomorrowSchedule != null) {
      await _notificationService.schedulePrayerNotifications(
        today: _todaySchedule!,
        tomorrow: _tomorrowSchedule!,
      );
    }

    notifyListeners();
  }

  Future<void> rescheduleNotificationsForCurrentLanguage() async {
    if (!notificationsEnabled ||
        _todaySchedule == null ||
        _tomorrowSchedule == null) {
      return;
    }

    final granted = await _notificationService.ensurePermissions();
    if (!granted) {
      return;
    }

    await _notificationService.schedulePrayerNotifications(
      today: _todaySchedule!,
      tomorrow: _tomorrowSchedule!,
    );
  }

  Future<void> openLocationSettings() =>
      _locationService.openLocationSettings();

  Future<void> openAppSettings() => _locationService.openAppSettings();

  Future<DeviceLocation?> _resolveLocation() async {
    if (useDeviceLocation) {
      final locationResult = await _locationService.getCurrentLocation();
      if (!locationResult.isSuccess) {
        schedule = null;
        _todaySchedule = null;
        _tomorrowSchedule = null;
        errorMessage = locationResult.message;
        locationFailureType = locationResult.failureType;
        return null;
      }

      locationFailureType = null;
      errorMessage = null;
      return locationResult.location!;
    }

    final city = selectedBangCity ?? defaultBangCity;
    if (city == null) {
      schedule = null;
      _todaySchedule = null;
      _tomorrowSchedule = null;
      errorMessage = 'Prayer city could not be resolved.';
      locationFailureType = LocationFailureType.unavailable;
      return null;
    }

    selectedCitySlug = city.slug;
    locationFailureType = null;
    errorMessage = null;
    return city.deviceLocation;
  }

  bool isEntryNextPrayer(PrayerTimeEntry entry) {
    final nextPrayer = schedule?.nextPrayer;
    if (nextPrayer == null) {
      return false;
    }
    return nextPrayer.name == entry.name;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _now = DateTime.now();
      final nextPrayerTime = schedule?.nextPrayer.time;
      if (nextPrayerTime != null && !_now.isBefore(nextPrayerTime)) {
        unawaited(refreshPrayerTimes());
        return;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

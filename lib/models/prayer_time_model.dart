import 'package:flutter/material.dart';

enum PrayerName { fajr, sunrise, dhuhr, asr, maghrib, isha }

enum PrayerMadhab { shafi, hanafi }

enum LocationFailureType {
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

class DeviceLocation {
  const DeviceLocation({
    required this.latitude,
    required this.longitude,
    required this.city,
  });

  final double latitude;
  final double longitude;
  final String city;
}

class BangCityOption {
  const BangCityOption({
    required this.slug,
    required this.englishName,
    required this.arabicName,
    required this.kurdishName,
    required this.latitude,
    required this.longitude,
    required this.aliases,
  });

  final String slug;
  final String englishName;
  final String arabicName;
  final String kurdishName;
  final double latitude;
  final double longitude;
  final List<String> aliases;

  DeviceLocation get deviceLocation => DeviceLocation(
    latitude: latitude,
    longitude: longitude,
    city: englishName,
  );
}

class LocationFetchResult {
  const LocationFetchResult.success(this.location)
    : failureType = null,
      message = null;

  const LocationFetchResult.failure({
    required this.failureType,
    required this.message,
  }) : location = null;

  final DeviceLocation? location;
  final LocationFailureType? failureType;
  final String? message;

  bool get isSuccess => location != null;
}

class PrayerTimeEntry {
  const PrayerTimeEntry({required this.name, required this.time});

  final PrayerName name;
  final DateTime time;
}

class PrayerDaySchedule {
  const PrayerDaySchedule({required this.date, required this.prayers});

  final DateTime date;
  final List<PrayerTimeEntry> prayers;
}

class PrayerTimesModel {
  const PrayerTimesModel({
    required this.location,
    required this.date,
    this.bangCity,
    required this.prayers,
    required this.nextPrayer,
    required this.timeUntilNextPrayer,
    required this.madhab,
  });

  final DeviceLocation location;
  final DateTime date;
  final BangCityOption? bangCity;
  final List<PrayerTimeEntry> prayers;
  final PrayerTimeEntry nextPrayer;
  final Duration timeUntilNextPrayer;
  final PrayerMadhab madhab;
}

extension PrayerNameX on PrayerName {
  bool get isFardPrayer => this != PrayerName.sunrise;

  static List<PrayerName> get fardPrayers => PrayerName.values
      .where((prayer) => prayer.isFardPrayer)
      .toList(growable: false);

  String get label {
    switch (this) {
      case PrayerName.fajr:
        return 'Fajr';
      case PrayerName.sunrise:
        return 'Sunrise';
      case PrayerName.dhuhr:
        return 'Dhuhr';
      case PrayerName.asr:
        return 'Asr';
      case PrayerName.maghrib:
        return 'Maghrib';
      case PrayerName.isha:
        return 'Isha';
    }
  }

  IconData get icon {
    switch (this) {
      case PrayerName.fajr:
        return Icons.wb_twilight_rounded;
      case PrayerName.sunrise:
        return Icons.wb_sunny_outlined;
      case PrayerName.dhuhr:
        return Icons.light_mode_rounded;
      case PrayerName.asr:
        return Icons.brightness_5_rounded;
      case PrayerName.maghrib:
        return Icons.wb_twilight;
      case PrayerName.isha:
        return Icons.nightlight_round;
    }
  }
}

extension PrayerMadhabX on PrayerMadhab {
  String get label => this == PrayerMadhab.shafi ? 'Shafi' : 'Hanafi';
}

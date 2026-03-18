import 'dart:async';
import 'dart:convert';

import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/prayer_time_model.dart';

class PrayerTimeService {
  PrayerTimeService({
    http.Client? client,
    Future<SharedPreferences> Function()? preferencesProvider,
  }) : _client = client ?? http.Client(),
       _preferencesProvider =
           preferencesProvider ?? SharedPreferences.getInstance;

  static const _scheduleCachePrefix = 'bang_month_schedule';
  static const _warmMarkerPrefix = 'bang_month_warm';
  static const int offlineMonthWindow = 2;

  final http.Client _client;
  final Future<SharedPreferences> Function() _preferencesProvider;
  final Map<String, Map<String, dynamic>> _monthScheduleCache = {};

  List<BangCityOption> get supportedBangCities =>
      List.unmodifiable(_bangCities);

  BangCityOption? findBangCityBySlug(String? slug) {
    if (slug == null || slug.isEmpty) {
      return null;
    }

    for (final bangCity in _bangCities) {
      if (bangCity.slug == slug) {
        return bangCity;
      }
    }

    return null;
  }

  Future<PrayerDaySchedule> buildDaySchedule({
    required DeviceLocation location,
    required DateTime date,
    required PrayerMadhab madhab,
  }) async {
    final bangSchedule = await _fetchBangScheduleForDate(
      location: location,
      date: date,
    );
    if (bangSchedule != null) {
      return bangSchedule;
    }

    return _buildCalculatedDaySchedule(
      location: location,
      date: date,
      madhab: madhab,
    );
  }

  Future<PrayerTimesModel> buildPrayerTimesModel({
    required DeviceLocation location,
    required DateTime now,
    required PrayerMadhab madhab,
  }) async {
    final today = await buildDaySchedule(
      location: location,
      date: now,
      madhab: madhab,
    );
    final tomorrow = await buildDaySchedule(
      location: location,
      date: now.add(const Duration(days: 1)),
      madhab: madhab,
    );
    final nextPrayer = _resolveNextPrayer(
      today: today,
      tomorrow: tomorrow,
      now: now,
    );
    final bangCity = _resolveBangCity(location.city);

    return PrayerTimesModel(
      location: location,
      date: DateTime(now.year, now.month, now.day),
      bangCity: bangCity,
      prayers: today.prayers,
      nextPrayer: nextPrayer,
      timeUntilNextPrayer: nextPrayer.time.difference(now),
      madhab: madhab,
    );
  }

  Future<PrayerDaySchedule> buildTomorrowSchedule({
    required DeviceLocation location,
    required DateTime now,
    required PrayerMadhab madhab,
  }) {
    return buildDaySchedule(
      location: location,
      date: now.add(const Duration(days: 1)),
      madhab: madhab,
    );
  }

  Future<void> warmBangCacheForKurdistan({
    required DateTime referenceDate,
  }) async {
    final prefs = await _preferencesProvider();
    final months = <DateTime>{
      DateTime(referenceDate.year, referenceDate.month),
      DateTime(referenceDate.year, referenceDate.month + 1),
    };

    for (final monthDate in months) {
      final markerKey = _warmMarkerKey(monthDate);
      if (prefs.getBool(markerKey) ?? false) {
        continue;
      }

      var successCount = 0;
      for (final bangCity in _bangCities) {
        final schedule = await _ensureMonthScheduleCached(
          slug: bangCity.slug,
          year: monthDate.year,
          month: monthDate.month,
          prefs: prefs,
          allowNetwork: true,
        );
        if (schedule != null) {
          successCount++;
        }
      }

      if (successCount == _bangCities.length) {
        await prefs.setBool(markerKey, true);
      }
    }
  }

  Future<int> cacheBangCityForOffline({
    required String slug,
    required DateTime referenceDate,
  }) async {
    final prefs = await _preferencesProvider();
    var cachedMonths = 0;
    for (final monthDate in _offlineMonthDates(referenceDate)) {
      final schedule = await _ensureMonthScheduleCached(
        slug: slug,
        year: monthDate.year,
        month: monthDate.month,
        prefs: prefs,
        allowNetwork: true,
      );
      if (schedule != null) {
        cachedMonths++;
      }
    }
    return cachedMonths;
  }

  Future<int> countCachedBangCityMonths({
    required String slug,
    required DateTime referenceDate,
  }) async {
    final prefs = await _preferencesProvider();
    var cachedMonths = 0;
    for (final monthDate in _offlineMonthDates(referenceDate)) {
      final schedule = await _ensureMonthScheduleCached(
        slug: slug,
        year: monthDate.year,
        month: monthDate.month,
        prefs: prefs,
        allowNetwork: false,
      );
      if (schedule != null) {
        cachedMonths++;
      }
    }
    return cachedMonths;
  }

  Future<PrayerDaySchedule?> _fetchBangScheduleForDate({
    required DeviceLocation location,
    required DateTime date,
  }) async {
    final bangCity = _resolveBangCity(location.city);
    if (bangCity == null) {
      return null;
    }

    final prefs = await _preferencesProvider();
    final monthSchedule = await _ensureMonthScheduleCached(
      slug: bangCity.slug,
      year: date.year,
      month: date.month,
      prefs: prefs,
      allowNetwork: true,
    );
    if (monthSchedule == null) {
      return null;
    }

    final dayKey = date.day.toString().padLeft(2, '0');
    final daySchedule = monthSchedule[dayKey];
    if (daySchedule is! Map<String, dynamic>) {
      return null;
    }

    return PrayerDaySchedule(
      date: DateTime(date.year, date.month, date.day),
      prayers: [
        PrayerTimeEntry(
          name: PrayerName.fajr,
          time: _timeForPrayer(
            date,
            daySchedule['fajr'] as String?,
            PrayerName.fajr,
          ),
        ),
        PrayerTimeEntry(
          name: PrayerName.sunrise,
          time: _timeForPrayer(
            date,
            daySchedule['sunrise'] as String?,
            PrayerName.sunrise,
          ),
        ),
        PrayerTimeEntry(
          name: PrayerName.dhuhr,
          time: _timeForPrayer(
            date,
            daySchedule['dhuhr'] as String?,
            PrayerName.dhuhr,
          ),
        ),
        PrayerTimeEntry(
          name: PrayerName.asr,
          time: _timeForPrayer(
            date,
            daySchedule['asr'] as String?,
            PrayerName.asr,
          ),
        ),
        PrayerTimeEntry(
          name: PrayerName.maghrib,
          time: _timeForPrayer(
            date,
            daySchedule['maghrib'] as String?,
            PrayerName.maghrib,
          ),
        ),
        PrayerTimeEntry(
          name: PrayerName.isha,
          time: _timeForPrayer(
            date,
            daySchedule['isha'] as String?,
            PrayerName.isha,
          ),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>?> _ensureMonthScheduleCached({
    required String slug,
    required int year,
    required int month,
    required SharedPreferences prefs,
    required bool allowNetwork,
  }) async {
    final monthKey = _monthKey(slug: slug, year: year, month: month);
    final memoryCached = _monthScheduleCache[monthKey];
    if (memoryCached != null) {
      return memoryCached;
    }

    final prefsKey = _schedulePrefsKey(monthKey);
    final storedJson = prefs.getString(prefsKey);
    if (storedJson != null && storedJson.isNotEmpty) {
      final decoded = jsonDecode(storedJson) as Map<String, dynamic>;
      _monthScheduleCache[monthKey] = decoded;
      return decoded;
    }

    if (!allowNetwork) {
      return null;
    }

    final html = await _fetchMonthHtml(slug: slug, month: month);
    if (html == null) {
      return null;
    }

    final parsedSchedule = _parseMonthSchedule(html, year: year);
    if (parsedSchedule.isEmpty) {
      return null;
    }

    _monthScheduleCache[monthKey] = parsedSchedule;
    await prefs.setString(prefsKey, jsonEncode(parsedSchedule));
    return parsedSchedule;
  }

  Future<String?> _fetchMonthHtml({
    required String slug,
    required int month,
  }) async {
    try {
      final uri = Uri.parse(
        'https://www.amozhgary.tv/bang/${Uri.encodeComponent(slug)}'
        '?month=${month.toString().padLeft(2, '0')}',
      );
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 6));
      if (response.statusCode != 200 || response.body.isEmpty) {
        return null;
      }

      return response.body;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _parseMonthSchedule(String html, {required int year}) {
    final schedule = <String, dynamic>{};
    final rowPattern = RegExp(
      r'(\d{2})\s*-\s*.*?\s*-\s*(\d{4}).*?'
      r'(\d{2}:\d{2}).*?'
      r'(\d{2}:\d{2}).*?'
      r'(\d{2}:\d{2}).*?'
      r'(\d{2}:\d{2}).*?'
      r'(\d{2}:\d{2}).*?'
      r'(\d{2}:\d{2})',
      dotAll: true,
    );

    for (final match in rowPattern.allMatches(html)) {
      if (match.group(2) != '$year') {
        continue;
      }

      final day = match.group(1);
      if (day == null) {
        continue;
      }

      schedule[day] = {
        'fajr': match.group(3),
        'sunrise': match.group(4),
        'dhuhr': match.group(5),
        'asr': match.group(6),
        'maghrib': match.group(7),
        'isha': match.group(8),
      };
    }

    return schedule;
  }

  PrayerDaySchedule _buildCalculatedDaySchedule({
    required DeviceLocation location,
    required DateTime date,
    required PrayerMadhab madhab,
  }) {
    final parameters = _calculationParametersFor(madhab: madhab);
    final times = adhan.PrayerTimes(
      date: date,
      coordinates: adhan.Coordinates(location.latitude, location.longitude),
      calculationParameters: parameters,
    );

    return PrayerDaySchedule(
      date: DateTime(date.year, date.month, date.day),
      prayers: [
        PrayerTimeEntry(name: PrayerName.fajr, time: times.fajr.toLocal()),
        PrayerTimeEntry(
          name: PrayerName.sunrise,
          time: times.sunrise.toLocal(),
        ),
        PrayerTimeEntry(name: PrayerName.dhuhr, time: times.dhuhr.toLocal()),
        PrayerTimeEntry(name: PrayerName.asr, time: times.asr.toLocal()),
        PrayerTimeEntry(
          name: PrayerName.maghrib,
          time: times.maghrib.toLocal(),
        ),
        PrayerTimeEntry(name: PrayerName.isha, time: times.isha.toLocal()),
      ],
    );
  }

  adhan.CalculationParameters _calculationParametersFor({
    required PrayerMadhab madhab,
  }) {
    final parameters = adhan.CalculationMethodParameters.muslimWorldLeague();
    parameters.madhab = madhab == PrayerMadhab.hanafi
        ? adhan.Madhab.hanafi
        : adhan.Madhab.shafi;
    return parameters;
  }

  BangCityOption? _resolveBangCity(String city) {
    final normalizedCity = _normalizeCity(city);
    if (normalizedCity.isEmpty) {
      return null;
    }

    for (final bangCity in _bangCities) {
      for (final alias in bangCity.aliases) {
        if (normalizedCity.contains(alias)) {
          return bangCity;
        }
      }
    }

    return null;
  }

  String _normalizeCity(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('ە', 'ه')
        .replaceAll('ێ', 'ی')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ا')
        .replaceAll('ى', 'ی')
        .replaceAll('ک', 'ك')
        .replaceAll('ڕ', 'ر')
        .replaceAll('ڵ', 'ل')
        .replaceAll('چ', 'ج')
        .replaceAll('ۆ', 'و')
        .replaceAll('å', 'a')
        .replaceAll('ê', 'e')
        .replaceAll('î', 'i')
        .replaceAll('û', 'u')
        .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF]+'), '');
  }

  DateTime _timeForPrayer(DateTime date, String? raw, PrayerName prayer) {
    if (raw == null) {
      return DateTime(date.year, date.month, date.day);
    }

    final parts = raw.split(':');
    var hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    switch (prayer) {
      case PrayerName.fajr:
      case PrayerName.sunrise:
        break;
      case PrayerName.dhuhr:
        if (hour < 11) {
          hour += 12;
        }
        break;
      case PrayerName.asr:
      case PrayerName.maghrib:
      case PrayerName.isha:
        if (hour < 12) {
          hour += 12;
        }
        break;
    }

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  PrayerTimeEntry _resolveNextPrayer({
    required PrayerDaySchedule today,
    required PrayerDaySchedule tomorrow,
    required DateTime now,
  }) {
    for (final prayer in today.prayers) {
      if (!prayer.name.isFardPrayer) {
        continue;
      }
      if (prayer.time.isAfter(now)) {
        return prayer;
      }
    }

    return tomorrow.prayers.firstWhere((prayer) => prayer.name.isFardPrayer);
  }

  String _monthKey({
    required String slug,
    required int year,
    required int month,
  }) => '$slug:$year:${month.toString().padLeft(2, '0')}';

  String _schedulePrefsKey(String monthKey) =>
      '$_scheduleCachePrefix:$monthKey';

  Iterable<DateTime> _offlineMonthDates(DateTime referenceDate) sync* {
    for (var offset = 0; offset < offlineMonthWindow; offset++) {
      yield DateTime(referenceDate.year, referenceDate.month + offset);
    }
  }

  String _warmMarkerKey(DateTime date) =>
      '$_warmMarkerPrefix:${date.year}:${date.month.toString().padLeft(2, '0')}';
}

const List<BangCityOption> _bangCities = [
  BangCityOption(
    slug: 'هەولێر',
    englishName: 'Erbil',
    arabicName: 'أربيل',
    kurdishName: 'هەولێر',
    latitude: 36.1911,
    longitude: 44.0092,
    aliases: ['erbil', 'hawler', 'hewler', 'اربيل', 'أربيل', 'هولير', 'هەولێر'],
  ),
  BangCityOption(
    slug: 'سلێمانی',
    englishName: 'Sulaymaniyah',
    arabicName: 'السليمانية',
    kurdishName: 'سلێمانی',
    latitude: 35.5613,
    longitude: 45.4304,
    aliases: [
      'sulaimani',
      'sulaymani',
      'sulaymaniyah',
      'sulaymaniyya',
      'slemani',
      'slimani',
      'سليمانية',
      'السليمانية',
      'سلێمانی',
    ],
  ),
  BangCityOption(
    slug: 'دهۆک',
    englishName: 'Duhok',
    arabicName: 'دهوك',
    kurdishName: 'دهۆک',
    latitude: 36.8671,
    longitude: 42.9885,
    aliases: ['duhok', 'dohuk', 'دهوك', 'دهۆك'],
  ),
  BangCityOption(
    slug: 'کەرکوک',
    englishName: 'Kirkuk',
    arabicName: 'كركوك',
    kurdishName: 'کەرکوک',
    latitude: 35.4681,
    longitude: 44.3922,
    aliases: ['kirkuk', 'kerkuk', 'كركوك', 'کەرکوک'],
  ),
  BangCityOption(
    slug: 'هەڵەبجە',
    englishName: 'Halabja',
    arabicName: 'حلبجة',
    kurdishName: 'هەڵەبجە',
    latitude: 35.1778,
    longitude: 45.9861,
    aliases: ['halabja', 'halabcha', 'حلبجة', 'هەڵەبجە'],
  ),
  BangCityOption(
    slug: 'کفری',
    englishName: 'Kifri',
    arabicName: 'كفري',
    kurdishName: 'کفری',
    latitude: 34.6896,
    longitude: 44.9606,
    aliases: ['kifri', 'kefri', 'كفري', 'کفری'],
  ),
  BangCityOption(
    slug: 'ڕانیە',
    englishName: 'Ranya',
    arabicName: 'رانية',
    kurdishName: 'ڕانیە',
    latitude: 36.2550,
    longitude: 44.8828,
    aliases: ['ranya', 'rania', 'رانية', 'ڕانیە'],
  ),
  BangCityOption(
    slug: 'کۆیە',
    englishName: 'Koya',
    arabicName: 'كوية',
    kurdishName: 'کۆیە',
    latitude: 36.0820,
    longitude: 44.6287,
    aliases: ['koya', 'كوية', 'کۆیە'],
  ),
  BangCityOption(
    slug: 'قەڵادزێ',
    englishName: 'Qaladze',
    arabicName: 'قلادزة',
    kurdishName: 'قەڵادزێ',
    latitude: 36.1844,
    longitude: 45.1411,
    aliases: ['qaladze', 'qaladza', 'قلادزة', 'قەڵادزێ'],
  ),
  BangCityOption(
    slug: 'زاخۆ',
    englishName: 'Zakho',
    arabicName: 'زاخو',
    kurdishName: 'زاخۆ',
    latitude: 37.1445,
    longitude: 42.6853,
    aliases: ['zakho', 'zaxo', 'زاخو', 'زاخۆ'],
  ),
  BangCityOption(
    slug: 'بەردەڕەش',
    englishName: 'Bardarash',
    arabicName: 'بردرش',
    kurdishName: 'بەردەڕەش',
    latitude: 36.0746,
    longitude: 43.5657,
    aliases: ['bardarash', 'بەردەڕەش'],
  ),
  BangCityOption(
    slug: 'موسڵ',
    englishName: 'Mosul',
    arabicName: 'الموصل',
    kurdishName: 'موسڵ',
    latitude: 36.3450,
    longitude: 43.1575,
    aliases: ['mosul', 'mousl', 'موصل', 'الموصل', 'موسڵ'],
  ),
  BangCityOption(
    slug: 'دەربەندیخان',
    englishName: 'Darbandikhan',
    arabicName: 'دربنديخان',
    kurdishName: 'دەربەندیخان',
    latitude: 35.1134,
    longitude: 45.7081,
    aliases: ['darbandikhan', 'darbandixan', 'دربنديخان', 'دەربەندیخان'],
  ),
  BangCityOption(
    slug: 'کەلار',
    englishName: 'Kalar',
    arabicName: 'كلار',
    kurdishName: 'کەلار',
    latitude: 34.6279,
    longitude: 45.3210,
    aliases: ['kalar', 'كلار', 'کەلار'],
  ),
  BangCityOption(
    slug: 'ئاکرێ',
    englishName: 'Akre',
    arabicName: 'عقرة',
    kurdishName: 'ئاکرێ',
    latitude: 36.7570,
    longitude: 43.8939,
    aliases: ['aqrah', 'akre', 'عقرة', 'ئاکرێ'],
  ),
  BangCityOption(
    slug: 'داقوق',
    englishName: 'Daquq',
    arabicName: 'داقوق',
    kurdishName: 'داقوق',
    latitude: 35.1061,
    longitude: 44.4517,
    aliases: ['daqoq', 'dakuk', 'داقوق'],
  ),
  BangCityOption(
    slug: 'مەخمور',
    englishName: 'Makhmur',
    arabicName: 'مخمور',
    kurdishName: 'مەخمور',
    latitude: 35.7767,
    longitude: 43.5794,
    aliases: ['makhmur', 'makhmour', 'مخمور', 'مەخمور'],
  ),
  BangCityOption(
    slug: 'مەندەلی',
    englishName: 'Mandali',
    arabicName: 'مندلي',
    kurdishName: 'مەندەلی',
    latitude: 33.7483,
    longitude: 45.5550,
    aliases: ['mandali', 'مندلي', 'مەندەلی'],
  ),
  BangCityOption(
    slug: 'قەرەهەنجیر',
    englishName: 'Qarahanjir',
    arabicName: 'قرةهنجير',
    kurdishName: 'قەرەهەنجیر',
    latitude: 35.3160,
    longitude: 44.3000,
    aliases: ['qarahanjir', 'قەرەهەنجیر'],
  ),
  BangCityOption(
    slug: 'سنجار',
    englishName: 'Sinjar',
    arabicName: 'سنجار',
    kurdishName: 'سنجار',
    latitude: 36.3209,
    longitude: 41.8758,
    aliases: ['sinjar', 'سنجار'],
  ),
  BangCityOption(
    slug: 'دوز خورماتوو',
    englishName: 'Tuz Khurmatu',
    arabicName: 'طوز خورماتو',
    kurdishName: 'دوز خورماتوو',
    latitude: 34.8881,
    longitude: 44.6326,
    aliases: ['tuzkhurmatu', 'tuzkhormato', 'دوزخورماتوو', 'دوز خورماتوو'],
  ),
];

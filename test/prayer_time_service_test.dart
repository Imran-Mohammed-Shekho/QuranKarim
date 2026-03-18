import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quran/models/prayer_time_model.dart';
import 'package:quran/services/prayer_time_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Bang-supported cities use exact Bang timetable rows', () async {
    final service = PrayerTimeService(
      client: MockClient((request) async {
        return http.Response.bytes(
          utf8.encode(_sampleBangHtml),
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      }),
    );

    final bangCitySchedule = await service.buildDaySchedule(
      location: const DeviceLocation(
        latitude: 36.1911,
        longitude: 44.0092,
        city: 'Erbil',
      ),
      date: DateTime(2026, 3, 10),
      madhab: PrayerMadhab.shafi,
    );

    expect(bangCitySchedule.prayers[0].time.hour, 4);
    expect(bangCitySchedule.prayers[0].time.minute, 59);
    expect(bangCitySchedule.prayers[1].time.hour, 12);
    expect(bangCitySchedule.prayers[1].time.minute, 23);
    expect(bangCitySchedule.prayers[2].time.hour, 15);
    expect(bangCitySchedule.prayers[2].time.minute, 36);
    expect(bangCitySchedule.prayers[3].time.hour, 18);
    expect(bangCitySchedule.prayers[3].time.minute, 10);
    expect(bangCitySchedule.prayers[4].time.hour, 19);
    expect(bangCitySchedule.prayers[4].time.minute, 25);
  });

  test('Bang timetable stays exact offline after it is cached', () async {
    final onlineService = PrayerTimeService(
      client: MockClient((request) async {
        return http.Response.bytes(
          utf8.encode(_sampleBangHtml),
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      }),
    );

    final onlineSchedule = await onlineService.buildDaySchedule(
      location: const DeviceLocation(
        latitude: 36.1911,
        longitude: 44.0092,
        city: 'Erbil',
      ),
      date: DateTime(2026, 3, 10),
      madhab: PrayerMadhab.shafi,
    );

    final offlineService = PrayerTimeService(
      client: MockClient((request) async {
        throw Exception('offline');
      }),
    );

    final offlineSchedule = await offlineService.buildDaySchedule(
      location: const DeviceLocation(
        latitude: 36.1911,
        longitude: 44.0092,
        city: 'Erbil',
      ),
      date: DateTime(2026, 3, 10),
      madhab: PrayerMadhab.shafi,
    );

    expect(
      offlineSchedule.prayers.map((entry) => entry.time).toList(),
      equals(onlineSchedule.prayers.map((entry) => entry.time).toList()),
    );
  });

  test('warm cache preloads current and next month for Kurdistan cities', () async {
    final requestedUrls = <String>[];
    final service = PrayerTimeService(
      client: MockClient((request) async {
        requestedUrls.add(request.url.toString());
        return http.Response.bytes(
          utf8.encode(_sampleBangHtml),
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      }),
    );

    await service.warmBangCacheForKurdistan(
      referenceDate: DateTime(2026, 3, 10),
    );

    final firstPassCount = requestedUrls.length;
    expect(firstPassCount, greaterThan(10));
    expect(
      requestedUrls.any(
        (url) => url.contains(
          'https://www.amozhgary.tv/bang/%D9%87%DB%95%D9%88%D9%84%DB%8E%D8%B1?month=03',
        ),
      ),
      isTrue,
    );
    expect(
      requestedUrls.any(
        (url) => url.contains(
          'https://www.amozhgary.tv/bang/%D8%B3%D9%84%DB%8E%D9%85%D8%A7%D9%86%DB%8C?month=04',
        ),
      ),
      isTrue,
    );
    expect(
      requestedUrls.any(
        (url) => url.contains(
          'https://www.amozhgary.tv/bang/%D8%AF%D9%87%DB%86%DA%A9?month=03',
        ),
      ),
      isTrue,
    );

    await service.warmBangCacheForKurdistan(
      referenceDate: DateTime(2026, 3, 10),
    );

    expect(requestedUrls.length, firstPassCount);
  });

  test(
    'Bang-supported city matching works with Arabic and Kurdish aliases',
    () async {
      final service = PrayerTimeService(
        client: MockClient((request) async {
          return http.Response.bytes(
            utf8.encode(_sampleBangHtml),
            200,
            headers: {'content-type': 'text/html; charset=utf-8'},
          );
        }),
      );

      final englishSchedule = await service.buildDaySchedule(
        location: const DeviceLocation(
          latitude: 35.5613,
          longitude: 45.4304,
          city: 'Sulaymaniyah',
        ),
        date: DateTime(2026, 3, 10),
        madhab: PrayerMadhab.shafi,
      );

      final arabicSchedule = await service.buildDaySchedule(
        location: const DeviceLocation(
          latitude: 35.5613,
          longitude: 45.4304,
          city: 'السليمانية',
        ),
        date: DateTime(2026, 3, 10),
        madhab: PrayerMadhab.shafi,
      );

      expect(
        arabicSchedule.prayers.map((entry) => entry.time).toList(),
        equals(englishSchedule.prayers.map((entry) => entry.time).toList()),
      );
    },
  );
}

const String _sampleBangHtml =
    r'children\":\"09 - ئازار - 2026\"'
    r' children\":\"05:01\"'
    r' children\":\"06:29\"'
    r' children\":\"12:23\"'
    r' children\":\"03:35\"'
    r' children\":\"06:09\"'
    r' children\":\"07:24\"'
    r' children\":\"10 - ئازار - 2026\"'
    r' children\":\"04:59\"'
    r' children\":\"06:28\"'
    r' children\":\"12:23\"'
    r' children\":\"03:36\"'
    r' children\":\"06:10\"'
    r' children\":\"07:25\"'
    r' children\":\"11 - ئازار - 2026\"'
    r' children\":\"04:57\"'
    r' children\":\"06:26\"'
    r' children\":\"12:23\"'
    r' children\":\"03:36\"'
    r' children\":\"06:11\"'
    r' children\":\"07:26\"';

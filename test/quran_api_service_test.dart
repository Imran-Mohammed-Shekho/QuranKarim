import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quran/data/services/quran_api_service.dart';

void main() {
  test('fetchAyahsForSurah returns Kurdish translation only', () async {
    final service = QuranApiService(
      client: MockClient((request) async {
        expect(request.url.toString(), contains('/surah/1/ku.asan'));
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'data': {
                'ayahs': [
                  {'numberInSurah': 1, 'text': 'بە ناوی خوای'},
                  {'numberInSurah': 2, 'text': 'سوپاس بۆ خوا'},
                ],
              },
            }),
          ),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final ayahs = await service.fetchAyahsForSurah(1);

    expect(ayahs, hasLength(2));
    expect(ayahs.first.arabicText, isEmpty);
    expect(ayahs.first.kurdishText, 'بە ناوی خوای');
    expect(ayahs.first.audioUrl, isEmpty);
    expect(ayahs[1].ayahNumber, 2);
    expect(ayahs[1].kurdishText, 'سوپاس بۆ خوا');
  });

  test('fetchAyah returns a single Kurdish translation ayah', () async {
    final service = QuranApiService(
      client: MockClient((request) async {
        expect(request.url.toString(), contains('/ayah/1:1/ku.asan'));
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'data': {'numberInSurah': 1, 'text': 'بە ناوی خوای'},
            }),
          ),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final ayah = await service.fetchAyah(1, 1);

    expect(ayah.ayahNumber, 1);
    expect(ayah.arabicText, isEmpty);
    expect(ayah.kurdishText, 'بە ناوی خوای');
    expect(ayah.audioUrl, isEmpty);
  });
}

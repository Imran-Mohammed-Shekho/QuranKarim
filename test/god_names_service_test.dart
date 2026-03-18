import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quran/services/god_names_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _sampleGodNamesJson = '''
{
  "standalone": {
    "arabic": "الله",
    "kurdish": "پەرستراو",
    "english": "Allah"
  },
  "meta": {
    "total": 99,
    "title_en": "The Beautiful Names of Allah",
    "title_ar": "أسماء الله الحسنى",
    "title_ku": "ناوە جوانەکانی خوای گەورە"
  },
  "names": [
    {
      "id": 1,
      "arabic": {
        "name": "الرَّحْمَنُ",
        "plain": "الرحمن",
        "meaning": "كثير الرحمة"
      },
      "english": {
        "transliteration": "Ar Rahmaan",
        "translation": "The Most Merciful",
        "meaning": "The One who has plenty of mercy."
      },
      "kurdish": {
        "translation": "بەبەزەیی"
      },
      "audio": "/audio/asma-ul-husna/rahman.mp3"
    }
  ]
}
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fetchAndCacheCollection parses and stores the names JSON', () async {
    SharedPreferences.setMockInitialValues({});
    final service = GodNamesService(
      client: MockClient((request) async {
        return http.Response.bytes(
          utf8.encode(_sampleGodNamesJson),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final collection = await service.fetchAndCacheCollection();
    final cached = await service.loadCachedCollection();

    expect(collection.meta.total, 99);
    expect(collection.names, hasLength(1));
    expect(collection.names.first.english.translation, 'The Most Merciful');
    expect(cached, isNotNull);
    expect(cached!.standalone.english, 'Allah');

    service.dispose();
  });

  test('loadCachedCollection returns null when no cache exists', () async {
    SharedPreferences.setMockInitialValues({});
    final service = GodNamesService(
      client: MockClient((request) async => http.Response('', 500)),
    );

    final cached = await service.loadCachedCollection();

    expect(cached, isNull);
    service.dispose();
  });
}

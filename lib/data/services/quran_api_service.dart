import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ayah.dart';
import '../models/surah.dart';

class QuranApiService {
  QuranApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl = 'https://api.alquran.cloud/v1';
  static const String _kurdishEdition = 'ku.asan';

  Future<List<Surah>> fetchSurahs() async {
    final response = await _client.get(Uri.parse('$_baseUrl/surah'));
    if (response.statusCode != 200) {
      throw Exception('Unable to fetch surah list (${response.statusCode}).');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>;
    return data
        .map((rawSurah) => Surah.fromApi(rawSurah as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<Ayah>> fetchAyahsForSurah(int surahNumber) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/surah/$surahNumber/$_kurdishEdition'),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Unable to fetch Kurdish ayahs for surah $surahNumber (${response.statusCode}).',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final surah = body['data'] as Map<String, dynamic>;
    final ayahs = surah['ayahs'] as List<dynamic>? ?? const [];
    return _mapKurdishAyahs(surahNumber: surahNumber, ayahs: ayahs);
  }

  Future<Ayah> fetchAyah(int surahNumber, int ayahNumber) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/ayah/$surahNumber:$ayahNumber/$_kurdishEdition'),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Unable to fetch Kurdish ayah $surahNumber:$ayahNumber (${response.statusCode}).',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final ayah = body['data'] as Map<String, dynamic>;
    final ayahs = _mapKurdishAyahs(surahNumber: surahNumber, ayahs: [ayah]);
    final match = ayahs.where((ayah) => ayah.ayahNumber == ayahNumber);
    if (match.isEmpty) {
      throw Exception(
        'Kurdish ayah data missing for $surahNumber:$ayahNumber.',
      );
    }
    return match.first;
  }

  List<Ayah> _mapKurdishAyahs({
    required int surahNumber,
    required List<dynamic> ayahs,
  }) {
    final mappedAyahs = ayahs
        .whereType<Map<String, dynamic>>()
        .map((rawAyah) {
          final numberInSurah = (rawAyah['numberInSurah'] as num?)?.toInt();
          final text = (rawAyah['text'] as String?)?.trim();
          if (numberInSurah == null || text == null || text.isEmpty) {
            return null;
          }
          return Ayah.fromApi(
            surahNumber: surahNumber,
            ayahNumber: numberInSurah,
            arabicText: '',
            kurdishText: text,
            audioUrl: '',
          );
        })
        .whereType<Ayah>()
        .toList(growable: false);

    if (mappedAyahs.isEmpty) {
      throw Exception('No Kurdish ayahs were returned from AlQuran Cloud.');
    }

    mappedAyahs.sort((a, b) => a.ayahNumber.compareTo(b.ayahNumber));
    return mappedAyahs;
  }

  void dispose() {
    _client.close();
  }
}

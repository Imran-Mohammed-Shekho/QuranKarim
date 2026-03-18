import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/ayah.dart';

class QuranTranslationCacheService {
  QuranTranslationCacheService({
    Future<SharedPreferences> Function()? preferencesProvider,
  }) : _preferencesProvider =
           preferencesProvider ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _preferencesProvider;

  Future<Map<int, String>> loadSurahTranslations(int surahNumber) async {
    final prefs = await _preferencesProvider();
    final raw = prefs.getString(_surahKey(surahNumber));
    return _decodeTranslations(raw);
  }

  Future<String?> loadAyahTranslation(int surahNumber, int ayahNumber) async {
    final translations = await loadSurahTranslations(surahNumber);
    return translations[ayahNumber];
  }

  Future<void> saveSurahTranslations(
    int surahNumber,
    Iterable<Ayah> ayahs,
  ) async {
    final translations = <String, String>{};
    for (final ayah in ayahs) {
      final text = ayah.kurdishText?.trim();
      if (text == null || text.isEmpty) {
        continue;
      }
      translations[ayah.ayahNumber.toString()] = text;
    }

    if (translations.isEmpty) {
      return;
    }

    final prefs = await _preferencesProvider();
    await prefs.setString(_surahKey(surahNumber), jsonEncode(translations));
  }

  Future<void> saveAyahTranslation(
    int surahNumber,
    int ayahNumber,
    String translation,
  ) async {
    final text = translation.trim();
    if (text.isEmpty) {
      return;
    }

    final prefs = await _preferencesProvider();
    final translations = _decodeTranslations(
      prefs.getString(_surahKey(surahNumber)),
    );
    translations[ayahNumber] = text;
    await prefs.setString(
      _surahKey(surahNumber),
      jsonEncode(
        translations.map((key, value) => MapEntry(key.toString(), value)),
      ),
    );
  }

  Map<int, String> _decodeTranslations(String? raw) {
    if (raw == null || raw.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return {};
      }

      final translations = <int, String>{};
      for (final entry in decoded.entries) {
        final ayahNumber = int.tryParse(entry.key);
        final text = (entry.value as String?)?.trim();
        if (ayahNumber == null ||
            ayahNumber <= 0 ||
            text == null ||
            text.isEmpty) {
          continue;
        }
        translations[ayahNumber] = text;
      }
      return translations;
    } on FormatException {
      return {};
    }
  }

  String _surahKey(int surahNumber) =>
      'quran_translation_ku_surah_$surahNumber';
}

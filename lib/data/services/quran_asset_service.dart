import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;

import '../models/ayah.dart';
import '../models/memorization_word.dart';
import '../models/surah.dart';

class QuranAssetService {
  QuranAssetService({this.remoteAudioBaseUrl, this.reciter = 'banna'});

  /// Optional HTTP(S) base URL where ayah audio files live, e.g.
  /// https://cdn.example.com/ayahs/audio/
  /// When null, local bundled assets are used.
  final String? remoteAudioBaseUrl;

  /// Reciter folder name used both in assets and remote path.
  String reciter;
  bool preferDownloadedAudio = false;
  String? localAudioBasePath;

  static const String _quranAssetPath = 'assets/quran_.json';

  Map<String, dynamic>? _cachedJson;

  void configureReciter({
    required String reciterId,
    required bool useDownloadedAudio,
    String? downloadedAudioBasePath,
  }) {
    reciter = reciterId;
    preferDownloadedAudio = useDownloadedAudio;
    localAudioBasePath = downloadedAudioBasePath;
  }

  Future<List<Surah>> fetchSurahs() async {
    final data = await _loadJson();
    final surahKeys = data.keys.toList()..sort();
    return surahKeys
        .map((surahKey) {
          final surahJson = data[surahKey] as Map<String, dynamic>;
          return Surah(
            number: int.parse(surahKey),
            nameArabic: (surahJson['surah_name_ar'] as String?) ?? '',
            nameEnglish: (surahJson['surah_name_en'] as String?) ?? '',
            ayahCount: (surahJson['ayah_count'] as int?) ?? 0,
          );
        })
        .toList(growable: false);
  }

  Future<List<Ayah>> fetchAyahsForSurah(int surahNumber) async {
    final data = await _loadJson();
    final surahKey = surahNumber.toString().padLeft(3, '0');
    final surahJson = data[surahKey] as Map<String, dynamic>?;
    if (surahJson == null) {
      return const [];
    }

    final ayahsJson = surahJson['ayahs'] as Map<String, dynamic>? ?? const {};
    final ayahKeys = ayahsJson.keys.toList()..sort();
    return ayahKeys
        .map((ayahKey) {
          final ayahJson = ayahsJson[ayahKey] as Map<String, dynamic>;
          final ayahNumber = int.parse(ayahKey);
          return Ayah(
            surahNumber: surahNumber,
            ayahNumber: ayahNumber,
            arabicText: (ayahJson['ayah_ar'] as String?) ?? '',
            kurdishText: null,
            audioUrl: _buildAudioPath(surahNumber, ayahNumber),
          );
        })
        .toList(growable: false);
  }

  Future<Ayah?> fetchAyah(int surahNumber, int ayahNumber) async {
    final ayahs = await fetchAyahsForSurah(surahNumber);
    for (final ayah in ayahs) {
      if (ayah.ayahNumber == ayahNumber) {
        return ayah;
      }
    }
    return null;
  }

  Future<List<MemorizationWord>> fetchWordsForSurah(int surahNumber) async {
    final data = await _loadJson();
    final surahKey = surahNumber.toString().padLeft(3, '0');
    final surahJson = data[surahKey] as Map<String, dynamic>?;
    if (surahJson == null) {
      return const [];
    }

    final ayahsJson = surahJson['ayahs'] as Map<String, dynamic>? ?? const {};
    final ayahKeys = ayahsJson.keys.toList()..sort();
    final words = <MemorizationWord>[];

    for (final ayahKey in ayahKeys) {
      final ayahJson = ayahsJson[ayahKey] as Map<String, dynamic>;
      final ayahNumber = int.parse(ayahKey);
      final wordsJson = ayahJson['words'] as List<dynamic>? ?? const [];
      for (final entry in wordsJson) {
        final map = entry as Map<String, dynamic>;
        final word = (map['word_ar'] as String?) ?? '';
        if (word.trim().isEmpty) {
          continue;
        }
        words.add(MemorizationWord(ayahNumber: ayahNumber, word: word));
      }
    }

    return words.toList(growable: false);
  }

  Future<Map<String, dynamic>> _loadJson() async {
    if (_cachedJson != null) {
      return _cachedJson!;
    }

    final raw = await rootBundle.loadString(_quranAssetPath);
    _cachedJson = jsonDecode(raw) as Map<String, dynamic>;
    return _cachedJson!;
  }

  String _buildAudioPath(int surahNumber, int ayahNumber) {
    final surah = surahNumber.toString().padLeft(3, '0');
    final ayah = ayahNumber.toString().padLeft(3, '0');
    final fileName = '$surah$ayah.mp3';
    if (preferDownloadedAudio &&
        localAudioBasePath != null &&
        localAudioBasePath!.isNotEmpty) {
      return p.join(localAudioBasePath!, reciter, fileName);
    }
    if (remoteAudioBaseUrl != null && remoteAudioBaseUrl!.isNotEmpty) {
      final base = remoteAudioBaseUrl!.endsWith('/')
          ? remoteAudioBaseUrl!
          : '$remoteAudioBaseUrl/';
      return '$base$reciter/$fileName';
    }
    return 'assets/ayahs/audio/$reciter/$fileName';
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:quran/data/models/ayah.dart';
import 'package:quran/data/models/memorization_word.dart';
import 'package:quran/data/models/surah.dart';
import 'package:quran/data/repositories/quran_repository.dart';
import 'package:quran/data/services/quran_api_service.dart';
import 'package:quran/data/services/quran_asset_service.dart';
import 'package:quran/services/quran_translation_cache_service.dart';

class _FakeAssetService extends QuranAssetService {
  _FakeAssetService({required this.ayahs})
    : super(remoteAudioBaseUrl: 'https://audio.example.com');

  final List<Ayah> ayahs;

  @override
  Future<List<Surah>> fetchSurahs() async => const [];

  @override
  Future<List<Ayah>> fetchAyahsForSurah(int surahNumber) async => ayahs;

  @override
  Future<Ayah?> fetchAyah(int surahNumber, int ayahNumber) async {
    for (final ayah in ayahs) {
      if (ayah.ayahNumber == ayahNumber) {
        return ayah;
      }
    }
    return null;
  }

  @override
  Future<List<MemorizationWord>> fetchWordsForSurah(int surahNumber) async =>
      const [];
}

class _FakeApiService extends QuranApiService {
  _FakeApiService({required this.ayahs});

  final List<Ayah> ayahs;

  @override
  Future<List<Ayah>> fetchAyahsForSurah(int surahNumber) async => ayahs;

  @override
  Future<Ayah> fetchAyah(int surahNumber, int ayahNumber) async {
    return ayahs.firstWhere((ayah) => ayah.ayahNumber == ayahNumber);
  }
}

class _ThrowingApiService extends QuranApiService {
  @override
  Future<List<Ayah>> fetchAyahsForSurah(int surahNumber) async {
    throw Exception('offline');
  }

  @override
  Future<Ayah> fetchAyah(int surahNumber, int ayahNumber) async {
    throw Exception('offline');
  }
}

class _FakeTranslationCacheService extends QuranTranslationCacheService {
  _FakeTranslationCacheService({Map<int, String>? cachedTranslations})
    : _cachedTranslations = cachedTranslations ?? {};

  final Map<int, String> _cachedTranslations;

  @override
  Future<Map<int, String>> loadSurahTranslations(int surahNumber) async {
    return Map<int, String>.from(_cachedTranslations);
  }

  @override
  Future<String?> loadAyahTranslation(int surahNumber, int ayahNumber) async {
    return _cachedTranslations[ayahNumber];
  }

  @override
  Future<void> saveSurahTranslations(
    int surahNumber,
    Iterable<Ayah> ayahs,
  ) async {
    for (final ayah in ayahs) {
      final text = ayah.kurdishText?.trim();
      if (text == null || text.isEmpty) {
        continue;
      }
      _cachedTranslations[ayah.ayahNumber] = text;
    }
  }

  @override
  Future<void> saveAyahTranslation(
    int surahNumber,
    int ayahNumber,
    String translation,
  ) async {
    _cachedTranslations[ayahNumber] = translation;
  }
}

void main() {
  test(
    'repository keeps local Arabic and audio while adding Kurdish text',
    () async {
      final repository = QuranRepository(
        assetService: _FakeAssetService(
          ayahs: const [
            Ayah(
              surahNumber: 1,
              ayahNumber: 1,
              arabicText: 'بِسْمِ اللَّهِ',
              kurdishText: null,
              audioUrl: 'https://audio.example.com/banna/001001.mp3',
            ),
            Ayah(
              surahNumber: 1,
              ayahNumber: 2,
              arabicText: 'الْحَمْدُ لِلَّهِ',
              kurdishText: null,
              audioUrl: 'https://audio.example.com/banna/001002.mp3',
            ),
          ],
        ),
        apiService: _FakeApiService(
          ayahs: const [
            Ayah(
              surahNumber: 1,
              ayahNumber: 1,
              arabicText: '',
              kurdishText: 'بە ناوی خوای',
              audioUrl: '',
            ),
          ],
        ),
        translationCacheService: _FakeTranslationCacheService(),
      );

      final ayahs = await repository.getAyahsForSurah(1);

      expect(ayahs, hasLength(2));
      expect(ayahs[0].arabicText, 'بِسْمِ اللَّهِ');
      expect(ayahs[0].kurdishText, 'بە ناوی خوای');
      expect(ayahs[0].audioUrl, 'https://audio.example.com/banna/001001.mp3');
      expect(ayahs[1].arabicText, 'الْحَمْدُ لِلَّهِ');
      expect(ayahs[1].kurdishText, isNull);
      expect(ayahs[1].audioUrl, 'https://audio.example.com/banna/001002.mp3');
    },
  );

  test(
    'repository overlays cached Kurdish translation before remote refresh',
    () async {
      final repository = QuranRepository(
        assetService: _FakeAssetService(
          ayahs: const [
            Ayah(
              surahNumber: 1,
              ayahNumber: 1,
              arabicText: 'بِسْمِ اللَّهِ',
              kurdishText: null,
              audioUrl: 'https://audio.example.com/banna/001001.mp3',
            ),
          ],
        ),
        apiService: _FakeApiService(ayahs: const []),
        translationCacheService: _FakeTranslationCacheService(
          cachedTranslations: {1: 'بە ناوی خوای'},
        ),
      );

      final ayahs = await repository.getCachedAyahsForSurah(1);

      expect(ayahs, hasLength(1));
      expect(ayahs.first.arabicText, 'بِسْمِ اللَّهِ');
      expect(ayahs.first.kurdishText, 'بە ناوی خوای');
      expect(
        ayahs.first.audioUrl,
        'https://audio.example.com/banna/001001.mp3',
      );
    },
  );

  test(
    'repository returns bundled ayahs and cached translation while offline',
    () async {
      final repository = QuranRepository(
        assetService: _FakeAssetService(
          ayahs: const [
            Ayah(
              surahNumber: 1,
              ayahNumber: 1,
              arabicText: 'بِسْمِ اللَّهِ',
              kurdishText: null,
              audioUrl: 'assets/ayahs/audio/banna/001001.mp3',
            ),
          ],
        ),
        apiService: _ThrowingApiService(),
        translationCacheService: _FakeTranslationCacheService(
          cachedTranslations: {1: 'بە ناوی خوای'},
        ),
      );

      final ayahs = await repository.getAyahsForSurah(1);

      expect(ayahs, hasLength(1));
      expect(ayahs.first.arabicText, 'بِسْمِ اللَّهِ');
      expect(ayahs.first.kurdishText, 'بە ناوی خوای');
      expect(ayahs.first.audioUrl, 'assets/ayahs/audio/banna/001001.mp3');
    },
  );
}

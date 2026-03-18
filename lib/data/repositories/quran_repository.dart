import '../models/ayah.dart';
import '../models/memorization_word.dart';
import '../models/surah.dart';
import '../../services/quran_translation_cache_service.dart';
import '../services/quran_api_service.dart';
import '../services/quran_asset_service.dart';

class QuranRepository {
  QuranRepository({
    required QuranAssetService assetService,
    required QuranApiService apiService,
    required QuranTranslationCacheService translationCacheService,
  }) : _assetService = assetService,
       _apiService = apiService,
       _translationCacheService = translationCacheService;

  final QuranAssetService _assetService;
  final QuranApiService _apiService;
  final QuranTranslationCacheService _translationCacheService;

  void configureReciter({
    required String reciterId,
    required bool useDownloadedAudio,
    String? downloadedAudioBasePath,
  }) {
    _assetService.configureReciter(
      reciterId: reciterId,
      useDownloadedAudio: useDownloadedAudio,
      downloadedAudioBasePath: downloadedAudioBasePath,
    );
  }

  Future<List<Surah>> getSurahs() async {
    return _assetService.fetchSurahs();
  }

  Future<List<Ayah>> getCachedAyahsForSurah(int surahNumber) async {
    final fallbackAyahs = await _assetService.fetchAyahsForSurah(surahNumber);
    final cachedTranslations = await _translationCacheService
        .loadSurahTranslations(surahNumber);
    return _mergeCachedTranslations(fallbackAyahs, cachedTranslations);
  }

  Future<List<Ayah>> getAyahsForSurah(int surahNumber) async {
    final fallbackAyahs = await getCachedAyahsForSurah(surahNumber);
    try {
      final remoteAyahs = await _apiService.fetchAyahsForSurah(surahNumber);
      await _translationCacheService.saveSurahTranslations(
        surahNumber,
        remoteAyahs,
      );
      return _mergeWithFallback(remoteAyahs, fallbackAyahs);
    } catch (_) {
      return fallbackAyahs;
    }
  }

  Future<Ayah?> getAyah(int surahNumber, int ayahNumber) async {
    final fallbackAyah = await _assetService.fetchAyah(surahNumber, ayahNumber);
    final cachedTranslation = await _translationCacheService
        .loadAyahTranslation(surahNumber, ayahNumber);
    final cachedAyah = fallbackAyah?.copyWith(kurdishText: cachedTranslation);

    try {
      final remoteAyah = await _apiService.fetchAyah(surahNumber, ayahNumber);
      final remoteTranslation = remoteAyah.kurdishText?.trim();
      if (remoteTranslation != null && remoteTranslation.isNotEmpty) {
        await _translationCacheService.saveAyahTranslation(
          surahNumber,
          ayahNumber,
          remoteTranslation,
        );
      }
      if (fallbackAyah == null) {
        return remoteAyah;
      }
      return remoteAyah.copyWith(
        arabicText: remoteAyah.arabicText.isEmpty
            ? fallbackAyah.arabicText
            : remoteAyah.arabicText,
        kurdishText: remoteTranslation == null || remoteTranslation.isEmpty
            ? cachedTranslation
            : remoteTranslation,
        audioUrl: remoteAyah.audioUrl.isEmpty
            ? fallbackAyah.audioUrl
            : remoteAyah.audioUrl,
      );
    } catch (_) {
      return cachedAyah;
    }
  }

  Future<List<MemorizationWord>> getMemorizationWordsForSurah(
    int surahNumber,
  ) async {
    return _assetService.fetchWordsForSurah(surahNumber);
  }

  Future<void> dispose() async {
    _apiService.dispose();
    return;
  }

  List<Ayah> _mergeWithFallback(
    List<Ayah> remoteAyahs,
    List<Ayah> fallbackAyahs,
  ) {
    if (fallbackAyahs.isEmpty) {
      return remoteAyahs;
    }

    if (remoteAyahs.isEmpty) {
      return fallbackAyahs;
    }

    final remoteByAyah = <int, Ayah>{
      for (final ayah in remoteAyahs) ayah.ayahNumber: ayah,
    };
    final fallbackByAyah = <int, Ayah>{
      for (final ayah in fallbackAyahs) ayah.ayahNumber: ayah,
    };

    final mergedAyahs = fallbackAyahs
        .map((ayah) {
          final remoteAyah = remoteByAyah[ayah.ayahNumber];
          if (remoteAyah == null) {
            return ayah;
          }
          return ayah.copyWith(
            arabicText: remoteAyah.arabicText.isEmpty
                ? ayah.arabicText
                : remoteAyah.arabicText,
            kurdishText: remoteAyah.kurdishText,
            audioUrl: remoteAyah.audioUrl.isEmpty
                ? ayah.audioUrl
                : remoteAyah.audioUrl,
          );
        })
        .toList(growable: false);

    final additionalRemoteAyahs = remoteAyahs.where(
      (ayah) => !fallbackByAyah.containsKey(ayah.ayahNumber),
    );

    return [...mergedAyahs, ...additionalRemoteAyahs]
      ..sort((a, b) => a.ayahNumber.compareTo(b.ayahNumber));
  }

  List<Ayah> _mergeCachedTranslations(
    List<Ayah> fallbackAyahs,
    Map<int, String> cachedTranslations,
  ) {
    if (fallbackAyahs.isEmpty || cachedTranslations.isEmpty) {
      return fallbackAyahs;
    }

    return fallbackAyahs
        .map(
          (ayah) =>
              ayah.copyWith(kurdishText: cachedTranslations[ayah.ayahNumber]),
        )
        .toList(growable: false);
  }
}

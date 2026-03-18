import 'package:flutter_test/flutter_test.dart';
import 'package:quran/data/models/ayah.dart';
import 'package:quran/services/quran_translation_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('surah translations are saved and restored by ayah number', () async {
    final service = QuranTranslationCacheService();

    await service.saveSurahTranslations(1, const [
      Ayah(
        surahNumber: 1,
        ayahNumber: 1,
        arabicText: '',
        kurdishText: 'بە ناوی خوای',
        audioUrl: '',
      ),
      Ayah(
        surahNumber: 1,
        ayahNumber: 2,
        arabicText: '',
        kurdishText: 'سوپاس بۆ خوا',
        audioUrl: '',
      ),
    ]);

    final translations = await service.loadSurahTranslations(1);

    expect(translations, {1: 'بە ناوی خوای', 2: 'سوپاس بۆ خوا'});
  });

  test('single ayah translation updates cached surah entry', () async {
    final service = QuranTranslationCacheService();

    await service.saveAyahTranslation(1, 1, 'بە ناوی خوای');
    await service.saveAyahTranslation(1, 2, 'سوپاس بۆ خوا');

    expect(await service.loadAyahTranslation(1, 1), 'بە ناوی خوای');
    expect(await service.loadAyahTranslation(1, 2), 'سوپاس بۆ خوا');
  });
}

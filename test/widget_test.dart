import 'package:flutter_test/flutter_test.dart';

import 'package:quran/services/ayah_comparison_service.dart';
import 'package:quran/services/quran_aware_post_processor.dart';

void main() {
  test('ayah comparison marks missed words as incorrect', () {
    const expected = 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ';
    const spoken = 'الْحَمْدُ رَبِّ الْعَالَمِينَ';

    final comparison = AyahComparisonService().compare(
      expectedAyah: expected,
      spokenAyah: spoken,
    );

    expect(comparison.words.length, 4);
    expect(comparison.words[0].isCorrect, isTrue);
    expect(comparison.words[1].isCorrect, isFalse);
    expect(comparison.words[2].isCorrect, isTrue);
    expect(comparison.words[3].isCorrect, isTrue);
    expect(comparison.isPerfect, isFalse);
  });

  test('ayah comparison marks extra spoken words as incorrect', () {
    const expected = 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ';
    const spoken = 'الْحَمْدُ لِلَّهِ جِدًّا رَبِّ الْعَالَمِينَ';

    final comparison = AyahComparisonService().compare(
      expectedAyah: expected,
      spokenAyah: spoken,
    );

    expect(comparison.isPerfect, isFalse);
    expect(comparison.textMistakes, 1);
    expect(comparison.words.any((word) => word.isExtraSpokenWord), isTrue);
    expect(
      comparison.words.any(
        (word) => word.isExtraSpokenWord && word.word == 'جِدًّا',
      ),
      isTrue,
    );
  });

  test('ayah comparison marks substituted words as incorrect', () {
    const expected = 'اهدنا الصراط المستقيم';
    const spoken = 'اهدنا الطريق المستقيم';

    final comparison = AyahComparisonService().compare(
      expectedAyah: expected,
      spokenAyah: spoken,
    );

    expect(comparison.isPerfect, isFalse);
    expect(comparison.textMistakes, 1);
    expect(
      comparison.words.any(
        (word) => word.word == 'الصراط' && word.isTextMismatch,
      ),
      isTrue,
    );
  });

  test('quran-aware post processor snaps close STT words to ayah words', () {
    const expected = 'ٱلرَّحۡمَٰنُ ٱلرَّحِيمِ';
    const raw = 'الرحمان الرحيم';

    final processed = QuranAwarePostProcessor().process(
      expectedAyah: expected,
      rawRecognizedText: raw,
    );

    expect(processed.correctedText, expected);
    expect(processed.correctedTokenCount, 2);
  });

  test('quran-aware post processor handles muqattaat spoken as letters', () {
    const expected = 'الٓمٓ';
    const raw = '١٠٠٠ لام میم';

    final processed = QuranAwarePostProcessor().process(
      expectedAyah: expected,
      rawRecognizedText: raw,
    );

    expect(processed.correctedText, expected);
    expect(processed.matchedTokenCount, 1);
  });

  test('quran-aware post processor corrects memorization slice locally', () {
    const expected = 'اهدنا الصراط المستقيم';
    const raw = 'اهدنا الصرات المستقيم';

    final processed = QuranAwarePostProcessor().process(
      expectedAyah: expected,
      rawRecognizedText: raw,
      maxLookahead: 3,
      maxSpelledLookahead: 2,
    );

    expect(processed.correctedText, expected);
    expect(processed.correctedTokenCount, 1);
  });

  test('comparison computes weighted score for close arabic substitutions', () {
    const expected = 'الرحمن';
    const spoken = 'الرحمان';

    final result = AyahComparisonService().compare(
      expectedAyah: expected,
      spokenAyah: spoken,
      mode: ComparisonMode.strictArabic,
    );

    expect(result.charErrorRate, greaterThan(0));
    expect(
      result.weightedCharErrorRate,
      lessThanOrEqualTo(result.charErrorRate),
    );
    expect(result.similarityScore, greaterThan(0.8));
  });

  test('tajweed mode marks missing harakat as incorrect', () {
    const expected = 'ٱلرَّحۡمَٰنُ';
    const spoken = 'الرحمن';

    final result = AyahComparisonService().compare(
      expectedAyah: expected,
      spokenAyah: spoken,
      mode: ComparisonMode.tajweed,
    );

    expect(result.isPerfect, isFalse);
    expect(result.hasOnlyTajweedMistakes, isTrue);
    expect(result.tajweedScore, 0);
    expect(result.similarityScore, 0);
  });
}

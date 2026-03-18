import 'package:flutter_test/flutter_test.dart';
import 'package:quran/services/memorization_match_service.dart';

void main() {
  test('memorization match tolerates common Arabic orthography variants', () {
    final service = MemorizationMatchService();
    final expectedWords = ['إياك', 'نعبد'];
    final expectedNormalized = expectedWords
        .map(service.normalize)
        .toList(growable: false);
    final spokenWords = service.tokenize('اياك نعبد');

    final result = service.match(
      expectedWords: expectedWords,
      expectedNormalized: expectedNormalized,
      spokenWords: spokenWords,
    );

    expect(result.hasMistake, isFalse);
    expect(result.matchedCount, 2);
  });

  test('memorization match flags extra inserted words as mistakes', () {
    final service = MemorizationMatchService();
    final expectedWords = ['اهدنا', 'الصراط', 'المستقيم'];
    final expectedNormalized = expectedWords
        .map(service.normalize)
        .toList(growable: false);
    final spokenWords = service.tokenize('اهدنا الطريق الصراط المستقيم');

    final result = service.match(
      expectedWords: expectedWords,
      expectedNormalized: expectedNormalized,
      spokenWords: spokenWords,
    );

    expect(result.hasMistake, isTrue);
    expect(result.matchedCount, 1);
    expect(result.mistakeIndex, 1);
    expect(result.expectedWord, 'الصراط');
    expect(result.spokenWord, 'الطريق');
  });
}

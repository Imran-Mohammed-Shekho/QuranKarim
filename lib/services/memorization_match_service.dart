class MemorizationMatchResult {
  const MemorizationMatchResult({
    required this.matchedCount,
    required this.hasMistake,
    this.mistakeIndex,
    this.expectedWord,
    this.spokenWord,
  });

  final int matchedCount;
  final bool hasMistake;
  final int? mistakeIndex;
  final String? expectedWord;
  final String? spokenWord;
}

class MemorizationMatchService {
  MemorizationMatchResult match({
    required List<String> expectedWords,
    required List<String> expectedNormalized,
    required List<String> spokenWords,
  }) {
    int matchedCount = 0;
    int expectedIndex = 0;
    int spokenIndex = 0;

    while (spokenIndex < spokenWords.length) {
      if (expectedIndex >= expectedWords.length) {
        return MemorizationMatchResult(
          matchedCount: matchedCount,
          hasMistake: true,
          mistakeIndex: expectedWords.isNotEmpty ? expectedWords.length - 1 : 0,
          expectedWord: expectedWords.isNotEmpty ? expectedWords.last : null,
          spokenWord: spokenWords[spokenIndex],
        );
      }

      final spoken = _normalizeStrict(spokenWords[spokenIndex]);
      if (spoken == expectedNormalized[expectedIndex]) {
        matchedCount++;
        expectedIndex++;
        spokenIndex++;
        continue;
      }

      final expectedLetterKey = _normalizeForLetters(
        expectedWords[expectedIndex],
      );
      final consumed = _matchSpelledLetters(
        expectedLetterKey,
        spokenWords,
        spokenIndex,
      );
      if (consumed != null) {
        matchedCount++;
        expectedIndex++;
        spokenIndex += consumed;
        continue;
      }

      return MemorizationMatchResult(
        matchedCount: matchedCount,
        hasMistake: true,
        mistakeIndex: expectedIndex,
        expectedWord: expectedWords[expectedIndex],
        spokenWord: spokenWords[spokenIndex],
      );
    }

    return MemorizationMatchResult(
      matchedCount: matchedCount,
      hasMistake: false,
    );
  }

  List<String> tokenize(String text) {
    if (text.trim().isEmpty) {
      return const [];
    }

    return text
        .trim()
        .split(RegExp(r'\s+'))
        .map((token) => token.trim())
        .where(
          (token) => token.isNotEmpty && _normalizeStrict(token).isNotEmpty,
        )
        .toList(growable: false);
  }

  String normalize(String input) => _normalizeStrict(input);

  String _normalizeStrict(String input) {
    var normalized = input;
    normalized = normalized
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '')
        .replaceAll('ٱ', 'ا')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ی', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll('ک', 'ك')
        .replaceAll('ـ', '');
    normalized = normalized.replaceAll(RegExp(r'[^\u0621-\u064A\u0671]'), '');
    return normalized;
  }

  String _normalizeForLetters(String input) {
    var normalized = input;

    normalized = normalized
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '')
        .replaceAll('ٱ', 'ا')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ی', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll('ك', 'ك')
        .replaceAll('ک', 'ك')
        .replaceAll('ـ', '');

    normalized = normalized.replaceAll(RegExp(r'[^\u0621-\u064A0-9]'), '');
    return normalized;
  }

  int? _matchSpelledLetters(
    String expectedNormalized,
    List<String> spokenWords,
    int spokenStartIndex,
  ) {
    if (expectedNormalized.length < 2 || expectedNormalized.length > 5) {
      return null;
    }

    final maxConsume = spokenStartIndex + 5 < spokenWords.length
        ? 5
        : spokenWords.length - spokenStartIndex;
    var built = '';

    for (int consumed = 1; consumed <= maxConsume; consumed++) {
      final normalized = _normalizeForLetters(
        spokenWords[spokenStartIndex + consumed - 1],
      );
      final letter = _letterFromSpelledToken(normalized);
      if (letter == null) {
        break;
      }

      built += letter;
      if (!expectedNormalized.startsWith(built)) {
        break;
      }
      if (built == expectedNormalized) {
        return consumed;
      }
    }

    return null;
  }

  String? _letterFromSpelledToken(String token) {
    const map = <String, String>{
      '1000': 'ا',
      'الف': 'ا',
      'الفا': 'ا',
      'ا': 'ا',
      'الفلام': 'ا',
      'لام': 'ل',
      'ل': 'ل',
      'ميم': 'م',
      'م': 'م',
      'صاد': 'ص',
      'ص': 'ص',
      'را': 'ر',
      'ر': 'ر',
      'كاف': 'ك',
      'ك': 'ك',
      'ها': 'ه',
      'ه': 'ه',
      'يا': 'ي',
      'ي': 'ي',
      'عين': 'ع',
      'ع': 'ع',
      'طا': 'ط',
      'ط': 'ط',
      'سين': 'س',
      'س': 'س',
      'حا': 'ح',
      'ح': 'ح',
      'قاف': 'ق',
      'ق': 'ق',
      'نون': 'ن',
      'ن': 'ن',
    };

    return map[token];
  }
}

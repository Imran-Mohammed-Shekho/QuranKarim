import 'dart:math' as math;

enum ComparisonMode { lenient, strictArabic, tajweed }

enum WordEvaluation { correct, textMismatch, tajweedMismatch }

enum WordFeedbackSource { expected, spokenExtra }

class WordFeedback {
  const WordFeedback({
    required this.word,
    required this.evaluation,
    this.source = WordFeedbackSource.expected,
    this.spokenWord,
  });

  final String word;
  final WordEvaluation evaluation;
  final WordFeedbackSource source;
  final String? spokenWord;

  bool get isCorrect => evaluation == WordEvaluation.correct;
  bool get isTextMismatch => evaluation == WordEvaluation.textMismatch;
  bool get isTajweedMismatch => evaluation == WordEvaluation.tajweedMismatch;
  bool get isExtraSpokenWord => source == WordFeedbackSource.spokenExtra;
}

class ComparisonResult {
  const ComparisonResult({
    required this.mode,
    required this.words,
    required this.spokenHasAnyTajweedMarks,
    this.tajweedVerifiedByBackend = false,
    required this.wordEditDistance,
    required this.charEditDistance,
    required this.wordErrorRate,
    required this.charErrorRate,
    required this.weightedCharErrorRate,
  });

  final ComparisonMode mode;
  final List<WordFeedback> words;
  final bool spokenHasAnyTajweedMarks;
  final bool tajweedVerifiedByBackend;
  final int wordEditDistance;
  final int charEditDistance;
  final double wordErrorRate;
  final double charErrorRate;
  final double weightedCharErrorRate;

  bool get isPerfect =>
      words.isNotEmpty && words.every((word) => word.isCorrect);

  int get mistakes => words.where((word) => !word.isCorrect).length;
  int get textMistakes => words.where((word) => word.isTextMismatch).length;
  int get tajweedMistakes =>
      words.where((word) => word.isTajweedMismatch).length;

  bool get hasOnlyTajweedMistakes =>
      textMistakes == 0 &&
      tajweedMistakes > 0 &&
      mode == ComparisonMode.tajweed;

  bool get tajweedValidationLimited =>
      mode == ComparisonMode.tajweed &&
      !spokenHasAnyTajweedMarks &&
      !tajweedVerifiedByBackend;

  double get tajweedErrorRate {
    if (mode != ComparisonMode.tajweed || words.isEmpty) {
      return 0;
    }

    final totalMistakes = textMistakes + tajweedMistakes;
    return totalMistakes / words.length;
  }

  double get tajweedScore => 1.0 - tajweedErrorRate;

  double get similarityScore {
    if (mode != ComparisonMode.tajweed) {
      return 1.0 - weightedCharErrorRate;
    }
    final baseScore = 1.0 - weightedCharErrorRate;
    final combined = baseScore < tajweedScore ? baseScore : tajweedScore;
    return combined.clamp(0, 1);
  }

  bool get isNearPerfect =>
      !isPerfect &&
      textMistakes <= 1 &&
      wordErrorRate <= 0.20 &&
      weightedCharErrorRate <= 0.14;
}

class AyahComparisonService {
  ComparisonResult compare({
    required String expectedAyah,
    required String spokenAyah,
    ComparisonMode mode = ComparisonMode.lenient,
  }) {
    final expectedTokens = _tokenize(expectedAyah);
    final spokenTokens = _tokenize(spokenAyah);

    if (expectedTokens.isEmpty) {
      return ComparisonResult(
        mode: mode,
        words: const [],
        spokenHasAnyTajweedMarks: false,
        tajweedVerifiedByBackend: false,
        wordEditDistance: 0,
        charEditDistance: 0,
        wordErrorRate: 0,
        charErrorRate: 0,
        weightedCharErrorRate: 0,
      );
    }

    final expectedKeys = expectedTokens
        .map((token) => _keyForMode(token, mode))
        .toList();
    final spokenKeys = spokenTokens
        .map((token) => _keyForMode(token, mode))
        .toList();

    final expectedChars = expectedKeys.join();
    final spokenChars = spokenKeys.join();

    final wordEditDistance = _levenshteinTokenDistance(
      expectedKeys,
      spokenKeys,
    );
    final charEditDistance = _levenshteinCharDistance(
      expectedChars,
      spokenChars,
    );
    final weightedCharDistance = _weightedLevenshteinCharDistance(
      expectedChars,
      spokenChars,
    );

    final wordDenominator = expectedKeys.isEmpty ? 1 : expectedKeys.length;
    final charDenominator = expectedChars.isEmpty ? 1 : expectedChars.length;

    final wordErrorRate = wordEditDistance / wordDenominator;
    final charErrorRate = charEditDistance / charDenominator;
    final weightedCharErrorRate = _clamp01(
      weightedCharDistance / charDenominator,
    );

    final spokenHasTajweed = spokenTokens.any(
      (token) => token.tajweedMarks.isNotEmpty,
    );

    final feedback = _buildWordFeedback(
      expectedTokens: expectedTokens,
      spokenTokens: spokenTokens,
      expectedKeys: expectedKeys,
      spokenKeys: spokenKeys,
      mode: mode,
    );

    return ComparisonResult(
      mode: mode,
      words: feedback,
      spokenHasAnyTajweedMarks: spokenHasTajweed,
      tajweedVerifiedByBackend: false,
      wordEditDistance: wordEditDistance,
      charEditDistance: charEditDistance,
      wordErrorRate: wordErrorRate,
      charErrorRate: charErrorRate,
      weightedCharErrorRate: weightedCharErrorRate,
    );
  }

  List<WordFeedback> _buildWordFeedback({
    required List<_NormalizedToken> expectedTokens,
    required List<_NormalizedToken> spokenTokens,
    required List<String> expectedKeys,
    required List<String> spokenKeys,
    required ComparisonMode mode,
  }) {
    final matrix = _buildTokenDistanceMatrix(expectedKeys, spokenKeys);
    final feedback = <WordFeedback>[];

    int i = 0;
    int j = 0;

    while (i < expectedKeys.length || j < spokenKeys.length) {
      if (i < expectedKeys.length &&
          j < spokenKeys.length &&
          expectedKeys[i] == spokenKeys[j] &&
          matrix[i][j] == matrix[i + 1][j + 1]) {
        final expectedToken = expectedTokens[i];
        final spokenToken = spokenTokens[j];

        if (mode == ComparisonMode.tajweed &&
            expectedToken.tajweedMarks != spokenToken.tajweedMarks) {
          feedback.add(
            WordFeedback(
              word: expectedToken.original,
              evaluation: WordEvaluation.tajweedMismatch,
              spokenWord: spokenToken.original,
            ),
          );
        } else {
          feedback.add(
            WordFeedback(
              word: expectedToken.original,
              evaluation: WordEvaluation.correct,
              spokenWord: spokenToken.original,
            ),
          );
        }
        i++;
        j++;
        continue;
      }

      final substitutionCost =
          (i < expectedKeys.length && j < spokenKeys.length) ? 1 : 1 << 20;
      final substitution = (i < expectedKeys.length && j < spokenKeys.length)
          ? matrix[i + 1][j + 1] + substitutionCost
          : 1 << 20;
      final deletion = i < expectedKeys.length ? matrix[i + 1][j] + 1 : 1 << 20;
      final insertion = j < spokenKeys.length ? matrix[i][j + 1] + 1 : 1 << 20;
      final current = matrix[i][j];

      if (i < expectedKeys.length &&
          j < spokenKeys.length &&
          current == substitution) {
        feedback.add(
          WordFeedback(
            word: expectedTokens[i].original,
            evaluation: WordEvaluation.textMismatch,
            spokenWord: spokenTokens[j].original,
          ),
        );
        i++;
        j++;
      } else if (i < expectedKeys.length && current == deletion) {
        feedback.add(
          WordFeedback(
            word: expectedTokens[i].original,
            evaluation: WordEvaluation.textMismatch,
          ),
        );
        i++;
      } else if (j < spokenKeys.length && current == insertion) {
        feedback.add(
          WordFeedback(
            word: spokenTokens[j].original,
            evaluation: WordEvaluation.textMismatch,
            source: WordFeedbackSource.spokenExtra,
            spokenWord: spokenTokens[j].original,
          ),
        );
        j++;
      } else {
        if (i < expectedKeys.length) {
          feedback.add(
            WordFeedback(
              word: expectedTokens[i].original,
              evaluation: WordEvaluation.textMismatch,
            ),
          );
          i++;
        } else if (j < spokenKeys.length) {
          feedback.add(
            WordFeedback(
              word: spokenTokens[j].original,
              evaluation: WordEvaluation.textMismatch,
              source: WordFeedbackSource.spokenExtra,
              spokenWord: spokenTokens[j].original,
            ),
          );
          j++;
        }
      }
    }

    return feedback;
  }

  List<List<int>> _buildTokenDistanceMatrix(List<String> a, List<String> b) {
    final matrix = List.generate(
      a.length + 1,
      (_) => List<int>.filled(b.length + 1, 0),
      growable: false,
    );

    for (int i = 0; i <= a.length; i++) {
      matrix[i][b.length] = a.length - i;
    }
    for (int j = 0; j <= b.length; j++) {
      matrix[a.length][j] = b.length - j;
    }

    for (int i = a.length - 1; i >= 0; i--) {
      for (int j = b.length - 1; j >= 0; j--) {
        final substitutionCost = a[i] == b[j] ? 0 : 1;
        final substitution = matrix[i + 1][j + 1] + substitutionCost;
        final deletion = matrix[i + 1][j] + 1;
        final insertion = matrix[i][j + 1] + 1;

        matrix[i][j] = math.min(math.min(substitution, deletion), insertion);
      }
    }

    return matrix;
  }

  int _levenshteinTokenDistance(List<String> a, List<String> b) {
    if (a.isEmpty) {
      return b.length;
    }
    if (b.isEmpty) {
      return a.length;
    }

    final previous = List<int>.generate(b.length + 1, (index) => index);
    final current = List<int>.filled(b.length + 1, 0);

    for (int i = 1; i <= a.length; i++) {
      current[0] = i;
      for (int j = 1; j <= b.length; j++) {
        final substitutionCost = a[i - 1] == b[j - 1] ? 0 : 1;
        final deletion = previous[j] + 1;
        final insertion = current[j - 1] + 1;
        final substitution = previous[j - 1] + substitutionCost;

        current[j] = math.min(math.min(deletion, insertion), substitution);
      }

      for (int j = 0; j <= b.length; j++) {
        previous[j] = current[j];
      }
    }

    return previous[b.length];
  }

  int _levenshteinCharDistance(String a, String b) {
    if (a.isEmpty) {
      return b.length;
    }
    if (b.isEmpty) {
      return a.length;
    }

    final previous = List<int>.generate(b.length + 1, (index) => index);
    final current = List<int>.filled(b.length + 1, 0);

    for (int i = 1; i <= a.length; i++) {
      current[0] = i;
      for (int j = 1; j <= b.length; j++) {
        final substitutionCost = a[i - 1] == b[j - 1] ? 0 : 1;
        final deletion = previous[j] + 1;
        final insertion = current[j - 1] + 1;
        final substitution = previous[j - 1] + substitutionCost;

        current[j] = math.min(math.min(deletion, insertion), substitution);
      }

      for (int j = 0; j <= b.length; j++) {
        previous[j] = current[j];
      }
    }

    return previous[b.length];
  }

  double _weightedLevenshteinCharDistance(String a, String b) {
    if (a.isEmpty) {
      return b.length.toDouble();
    }
    if (b.isEmpty) {
      return a.length.toDouble();
    }

    final previous = List<double>.generate(
      b.length + 1,
      (index) => index.toDouble(),
    );
    final current = List<double>.filled(b.length + 1, 0);

    for (int i = 1; i <= a.length; i++) {
      current[0] = i.toDouble();
      for (int j = 1; j <= b.length; j++) {
        final substitutionCost = _weightedSubstitutionCost(a[i - 1], b[j - 1]);
        final deletion = previous[j] + 1;
        final insertion = current[j - 1] + 1;
        final substitution = previous[j - 1] + substitutionCost;

        current[j] = math.min(math.min(deletion, insertion), substitution);
      }

      for (int j = 0; j <= b.length; j++) {
        previous[j] = current[j];
      }
    }

    return previous[b.length];
  }

  double _weightedSubstitutionCost(String a, String b) {
    if (a == b) {
      return 0;
    }

    if (_isConfusablePair(a, b)) {
      return 0.35;
    }

    return 1;
  }

  bool _isConfusablePair(String a, String b) {
    for (final group in _confusableGroups) {
      if (group.contains(a) && group.contains(b)) {
        return true;
      }
    }
    return false;
  }

  List<_NormalizedToken> _tokenize(String value) {
    return value
        .trim()
        .split(RegExp(r'\s+'))
        .map((token) => token.trim())
        .where((token) => token.isNotEmpty)
        .map(
          (token) => _NormalizedToken(
            original: token,
            lenient: _normalizeArabicLenient(token),
            strictArabic: _normalizeArabicStrict(token),
            tajweedBase: _normalizeArabicTajweedBase(token),
            tajweedMarks: _extractTajweedMarks(token),
          ),
        )
        .where((token) => token.strictArabic.isNotEmpty)
        .toList(growable: false);
  }

  String _keyForMode(_NormalizedToken token, ComparisonMode mode) {
    switch (mode) {
      case ComparisonMode.lenient:
        return token.lenient;
      case ComparisonMode.strictArabic:
        return token.strictArabic;
      case ComparisonMode.tajweed:
        return token.tajweedBase;
    }
  }

  String _normalizeArabicLenient(String input) {
    var normalized = input;

    normalized = normalized
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '')
        .replaceAll('ٱ', 'ا')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll('ـ', '');

    normalized = normalized.replaceAll(RegExp(r'[^\u0621-\u064A0-9]'), '');
    return normalized;
  }

  String _normalizeArabicStrict(String input) {
    var normalized = input;
    normalized = normalized
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '')
        .replaceAll('ـ', '');
    normalized = normalized.replaceAll(RegExp(r'[^\u0621-\u064A\u0671]'), '');
    return normalized;
  }

  String _normalizeArabicTajweedBase(String input) {
    var normalized = input;
    normalized = normalized
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '')
        .replaceAll('ٱ', 'ا')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ـ', '');
    normalized = normalized.replaceAll(RegExp(r'[^\u0621-\u064A]'), '');
    return normalized;
  }

  String _extractTajweedMarks(String input) {
    final tajweedMarks = RegExp(r'[\u064B-\u0652\u0653-\u065F\u0670]');
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      if (tajweedMarks.hasMatch(char)) {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  double _clamp01(double value) {
    if (value < 0) {
      return 0;
    }
    if (value > 1) {
      return 1;
    }
    return value;
  }

  static const List<Set<String>> _confusableGroups = [
    {'ا', 'أ', 'إ', 'آ', 'ٱ'},
    {'ي', 'ى', 'ئ', 'ی'},
    {'و', 'ؤ'},
    {'ه', 'ة'},
    {'س', 'ص'},
    {'ت', 'ط'},
    {'ذ', 'ز', 'ظ', 'ض'},
  ];
}

class _NormalizedToken {
  const _NormalizedToken({
    required this.original,
    required this.lenient,
    required this.strictArabic,
    required this.tajweedBase,
    required this.tajweedMarks,
  });

  final String original;
  final String lenient;
  final String strictArabic;
  final String tajweedBase;
  final String tajweedMarks;
}

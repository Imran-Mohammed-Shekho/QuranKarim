import 'ayah_comparison_service.dart';

enum LocalCoachHintType { wrongWaqf, maddTiming, repeatedWeakWord }

enum LocalCoachHintSeverity { info, warning }

class LocalCoachHint {
  const LocalCoachHint({
    required this.type,
    required this.message,
    required this.severity,
    this.word,
    this.repeatCount,
  });

  final LocalCoachHintType type;
  final String message;
  final LocalCoachHintSeverity severity;
  final String? word;
  final int? repeatCount;
}

class LocalCoachResult {
  const LocalCoachResult({
    required this.focusWords,
    required this.hints,
    required this.shouldSuggestReplay,
  });

  final List<String> focusWords;
  final List<LocalCoachHint> hints;
  final bool shouldSuggestReplay;

  bool get hasContent => focusWords.isNotEmpty || hints.isNotEmpty;
}

class LocalTajweedCoachService {
  LocalCoachResult analyze({
    required String expectedAyah,
    required String spokenAyah,
    required ComparisonResult comparisonResult,
    required Map<String, int> weakWordCounts,
    Duration? recordingDuration,
  }) {
    final focusWords = comparisonResult.words
        .where((word) => !word.isCorrect && !word.isExtraSpokenWord)
        .map((word) => word.word)
        .where((word) => word.trim().isNotEmpty)
        .toSet()
        .toList(growable: false);

    final hints = <LocalCoachHint>[];

    final waqfHint = _buildWrongWaqfHint(
      expectedAyah: expectedAyah,
      comparisonResult: comparisonResult,
    );
    if (waqfHint != null) {
      hints.add(waqfHint);
    }

    final maddHint = _buildMaddHint(
      expectedAyah: expectedAyah,
      spokenAyah: spokenAyah,
      recordingDuration: recordingDuration,
    );
    if (maddHint != null) {
      hints.add(maddHint);
    }

    for (final word in focusWords) {
      final repeatCount = weakWordCounts[normalizeWeakWordKey(word)] ?? 0;
      if (repeatCount >= 2) {
        hints.add(
          LocalCoachHint(
            type: LocalCoachHintType.repeatedWeakWord,
            word: word,
            repeatCount: repeatCount,
            severity: LocalCoachHintSeverity.warning,
            message:
                'This word has been difficult $repeatCount times. Give "$word" extra review.',
          ),
        );
      }
    }

    return LocalCoachResult(
      focusWords: focusWords,
      hints: hints,
      shouldSuggestReplay: comparisonResult.mistakes > 0,
    );
  }

  LocalCoachHint? _buildWrongWaqfHint({
    required String expectedAyah,
    required ComparisonResult comparisonResult,
  }) {
    if (comparisonResult.words.isEmpty) {
      return null;
    }

    final matchedPrefixCount = _matchedPrefixCount(comparisonResult);
    if (matchedPrefixCount <= 0) {
      return null;
    }

    final trailing = comparisonResult.words.skip(matchedPrefixCount).toList();
    if (trailing.isEmpty) {
      return null;
    }

    final looksLikeEarlyStop = trailing.every(
      (word) =>
          !word.isExtraSpokenWord &&
          word.isTextMismatch &&
          word.spokenWord == null,
    );
    if (!looksLikeEarlyStop) {
      return null;
    }

    final expectedWords = _splitWords(expectedAyah);
    if (matchedPrefixCount >= expectedWords.length) {
      return null;
    }

    final lastSpokenWord = expectedWords[matchedPrefixCount - 1];
    if (_isPauseFriendlyWord(lastSpokenWord)) {
      return null;
    }

    return LocalCoachHint(
      type: LocalCoachHintType.wrongWaqf,
      word: lastSpokenWord,
      severity: LocalCoachHintSeverity.warning,
      message:
          'You stopped after "$lastSpokenWord". Try continuing to the next natural waqf point.',
    );
  }

  LocalCoachHint? _buildMaddHint({
    required String expectedAyah,
    required String spokenAyah,
    required Duration? recordingDuration,
  }) {
    if (recordingDuration == null || recordingDuration.inMilliseconds <= 0) {
      return null;
    }

    final spokenWords = _splitWords(spokenAyah);
    if (spokenWords.length < 3) {
      return null;
    }

    final expectedWords = _splitWords(expectedAyah);
    final inspectedWords = expectedWords
        .take(
          spokenWords.length < expectedWords.length
              ? spokenWords.length
              : expectedWords.length,
        )
        .where(_containsMaddLetters)
        .toList(growable: false);

    if (inspectedWords.isEmpty) {
      return null;
    }

    final millisecondsPerWord =
        recordingDuration.inMilliseconds / spokenWords.length;
    if (millisecondsPerWord >= 650) {
      return null;
    }

    final sampleWords = inspectedWords.take(2).join(' - ');
    return LocalCoachHint(
      type: LocalCoachHintType.maddTiming,
      severity: LocalCoachHintSeverity.info,
      message:
          'Slow down slightly on madd words like $sampleWords and stretch the long vowels more clearly.',
    );
  }

  int _matchedPrefixCount(ComparisonResult result) {
    var matched = 0;
    for (final word in result.words) {
      if (word.isExtraSpokenWord || !word.isCorrect) {
        break;
      }
      matched++;
    }
    return matched;
  }

  List<String> _splitWords(String text) {
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .map((word) => word.trim())
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
  }

  bool _isPauseFriendlyWord(String word) {
    return RegExp(r'[ۖۗۚۙۛۜۘ۝،؛,.!?]$').hasMatch(word);
  }

  bool _containsMaddLetters(String word) {
    return RegExp(r'[اويىآ]').hasMatch(word);
  }

  static String normalizeWeakWordKey(String word) {
    var normalized = word.trim();
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
}

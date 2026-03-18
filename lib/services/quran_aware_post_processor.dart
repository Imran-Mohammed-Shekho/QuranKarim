class PostProcessedSpeech {
  const PostProcessedSpeech({
    required this.rawText,
    required this.correctedText,
    required this.correctedTokenCount,
    required this.matchedTokenCount,
  });

  final String rawText;
  final String correctedText;
  final int correctedTokenCount;
  final int matchedTokenCount;
}

class QuranAwarePostProcessor {
  PostProcessedSpeech process({
    required String expectedAyah,
    required String rawRecognizedText,
    int maxLookahead = 7,
    int maxSpelledLookahead = 7,
  }) {
    final raw = rawRecognizedText.trim();
    if (raw.isEmpty) {
      return const PostProcessedSpeech(
        rawText: '',
        correctedText: '',
        correctedTokenCount: 0,
        matchedTokenCount: 0,
      );
    }

    final expectedTokens = _tokenize(expectedAyah);
    final recognizedTokens = _tokenize(rawRecognizedText);

    if (expectedTokens.isEmpty || recognizedTokens.isEmpty) {
      return PostProcessedSpeech(
        rawText: raw,
        correctedText: raw,
        correctedTokenCount: 0,
        matchedTokenCount: 0,
      );
    }

    final corrected = <String>[];
    int correctedCount = 0;
    int matchedCount = 0;
    int cursor = 0;
    int spokenIndex = 0;

    while (spokenIndex < recognizedTokens.length) {
      final spelledMatch = _matchSpelledLetters(
        expectedTokens: expectedTokens,
        recognizedTokens: recognizedTokens,
        expectedStartIndex: cursor,
        recognizedStartIndex: spokenIndex,
        maxLookahead: maxSpelledLookahead,
      );

      if (spelledMatch != null) {
        final target = expectedTokens[spelledMatch.expectedIndex].original;
        final phrase = recognizedTokens
            .sublist(spokenIndex, spokenIndex + spelledMatch.consumedTokens)
            .map((e) => e.original)
            .join(' ');

        corrected.add(target);
        matchedCount++;
        if (phrase != target) {
          correctedCount++;
        }

        cursor = spelledMatch.expectedIndex + 1;
        spokenIndex += spelledMatch.consumedTokens;
        continue;
      }

      final spoken = recognizedTokens[spokenIndex];
      int? bestIndex;
      double bestRatio = 1.0;

      for (int i = cursor; i < expectedTokens.length; i++) {
        final expected = expectedTokens[i];
        final ratio = _distanceRatio(spoken.normalized, expected.normalized);

        if (_canSnap(spoken.normalized, expected.normalized, ratio) &&
            ratio <= bestRatio) {
          bestRatio = ratio;
          bestIndex = i;
          if (ratio == 0) {
            break;
          }
        }

        // Keep snapping local to avoid jumping too far across the ayah.
        if (i - cursor >= maxLookahead) {
          break;
        }
      }

      if (bestIndex != null) {
        final target = expectedTokens[bestIndex].original;
        corrected.add(target);
        matchedCount++;
        if (target != spoken.original) {
          correctedCount++;
        }
        cursor = bestIndex + 1;
      } else {
        corrected.add(spoken.original);
      }
      spokenIndex++;
    }

    return PostProcessedSpeech(
      rawText: raw,
      correctedText: corrected.join(' '),
      correctedTokenCount: correctedCount,
      matchedTokenCount: matchedCount,
    );
  }

  bool _canSnap(String spoken, String expected, double ratio) {
    if (spoken.isEmpty || expected.isEmpty) {
      return false;
    }

    if (spoken == expected) {
      return true;
    }

    if (spoken[0] != expected[0]) {
      return false;
    }

    final maxLength = spoken.length > expected.length
        ? spoken.length
        : expected.length;

    if (maxLength <= 3) {
      return ratio <= 0.25;
    }

    if (maxLength <= 5) {
      return ratio <= 0.30;
    }

    return ratio <= 0.35;
  }

  _SpelledLetterMatch? _matchSpelledLetters({
    required List<_PostToken> expectedTokens,
    required List<_PostToken> recognizedTokens,
    required int expectedStartIndex,
    required int recognizedStartIndex,
    required int maxLookahead,
  }) {
    if (expectedStartIndex >= expectedTokens.length ||
        recognizedStartIndex >= recognizedTokens.length) {
      return null;
    }

    final maxExpectedIndex = expectedStartIndex + maxLookahead <
            expectedTokens.length
        ? expectedStartIndex + maxLookahead
        : expectedTokens.length - 1;

    for (int i = expectedStartIndex; i <= maxExpectedIndex; i++) {
      final expected = expectedTokens[i].normalized;
      if (expected.length < 2 || expected.length > 5) {
        continue;
      }

      var built = '';
      final maxConsume = recognizedStartIndex + 5 < recognizedTokens.length
          ? 5
          : recognizedTokens.length - recognizedStartIndex;

      for (int consumed = 1; consumed <= maxConsume; consumed++) {
        final token =
            recognizedTokens[recognizedStartIndex + consumed - 1].normalized;
        final letter = _letterFromSpelledToken(token);
        if (letter == null) {
          break;
        }

        built += letter;
        if (!expected.startsWith(built)) {
          break;
        }
        if (built == expected) {
          return _SpelledLetterMatch(
            expectedIndex: i,
            consumedTokens: consumed,
          );
        }
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

  double _distanceRatio(String a, String b) {
    if (a.isEmpty && b.isEmpty) {
      return 0;
    }

    final distance = _levenshtein(a, b);
    final length = a.length > b.length ? a.length : b.length;
    return distance / length;
  }

  int _levenshtein(String a, String b) {
    if (a == b) {
      return 0;
    }
    if (a.isEmpty) {
      return b.length;
    }
    if (b.isEmpty) {
      return a.length;
    }

    final previous = List<int>.generate(b.length + 1, (i) => i);
    final current = List<int>.filled(b.length + 1, 0);

    for (int i = 1; i <= a.length; i++) {
      current[0] = i;
      for (int j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        final deletion = previous[j] + 1;
        final insertion = current[j - 1] + 1;
        final substitution = previous[j - 1] + cost;

        int best = deletion;
        if (insertion < best) {
          best = insertion;
        }
        if (substitution < best) {
          best = substitution;
        }
        current[j] = best;
      }

      for (int j = 0; j <= b.length; j++) {
        previous[j] = current[j];
      }
    }

    return previous[b.length];
  }

  List<_PostToken> _tokenize(String value) {
    return value
        .trim()
        .split(RegExp(r'\s+'))
        .map((token) => token.trim())
        .where((token) => token.isNotEmpty)
        .map(
          (token) => _PostToken(
            original: token,
            normalized: _normalizeForMatching(token),
          ),
        )
        .where((token) => token.normalized.isNotEmpty)
        .toList(growable: false);
  }

  String _normalizeForMatching(String input) {
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
        .replaceAll('٠', '0')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4')
        .replaceAll('٥', '5')
        .replaceAll('٦', '6')
        .replaceAll('٧', '7')
        .replaceAll('٨', '8')
        .replaceAll('٩', '9')
        .replaceAll('۰', '0')
        .replaceAll('۱', '1')
        .replaceAll('۲', '2')
        .replaceAll('۳', '3')
        .replaceAll('۴', '4')
        .replaceAll('۵', '5')
        .replaceAll('۶', '6')
        .replaceAll('۷', '7')
        .replaceAll('۸', '8')
        .replaceAll('۹', '9')
        .replaceAll('ـ', '');

    normalized = normalized.replaceAll(RegExp(r'[^\u0621-\u064A0-9]'), '');
    return normalized;
  }
}

class _PostToken {
  const _PostToken({required this.original, required this.normalized});

  final String original;
  final String normalized;
}

class _SpelledLetterMatch {
  const _SpelledLetterMatch({
    required this.expectedIndex,
    required this.consumedTokens,
  });

  final int expectedIndex;
  final int consumedTokens;
}

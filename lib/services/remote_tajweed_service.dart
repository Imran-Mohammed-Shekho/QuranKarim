import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class RemoteTajweedResult {
  const RemoteTajweedResult({
    required this.text,
    required this.provider,
    required this.canVerifyHarakat,
    required this.isSynthetic,
  });

  final String text;
  final String provider;
  final bool canVerifyHarakat;
  final bool isSynthetic;
}

class RemoteTajweedWordResult {
  const RemoteTajweedWordResult({
    required this.index,
    required this.word,
    required this.spokenWord,
    required this.correct,
    required this.score,
    required this.mistakeTypes,
  });

  final int index;
  final String word;
  final String spokenWord;
  final bool correct;
  final double score;
  final List<String> mistakeTypes;
}

class RemoteTajweedVerificationResult {
  const RemoteTajweedVerificationResult({
    required this.recognizedText,
    required this.provider,
    required this.canVerifyHarakat,
    required this.isSynthetic,
    required this.overallScore,
    required this.wordErrorRate,
    required this.charErrorRate,
    required this.weightedCharErrorRate,
    required this.tajweedScore,
    required this.textMistakes,
    required this.tajweedMistakes,
    required this.stopReading,
    required this.words,
  });

  final String recognizedText;
  final String provider;
  final bool canVerifyHarakat;
  final bool isSynthetic;
  final double overallScore;
  final double wordErrorRate;
  final double charErrorRate;
  final double weightedCharErrorRate;
  final double tajweedScore;
  final int textMistakes;
  final int tajweedMistakes;
  final bool stopReading;
  final List<RemoteTajweedWordResult> words;
}

class RemoteTajweedService {
  RemoteTajweedService({required String endpoint, http.Client? client})
    : _endpoint = endpoint.trim(),
      _client = client ?? http.Client();

  String _endpoint;
  final http.Client _client;

  bool get isConfigured => _endpoint.isNotEmpty;
  String get endpoint => _endpoint;

  void updateEndpoint(String endpoint) {
    _endpoint = endpoint.trim();
  }

  Uri get _transcribeUri {
    if (_endpoint.endsWith('/transcribe')) {
      return Uri.parse(_endpoint);
    }
    if (_endpoint.endsWith('/')) {
      return Uri.parse('${_endpoint}transcribe');
    }
    return Uri.parse('$_endpoint/transcribe');
  }

  Uri get _verificationUri {
    if (_endpoint.endsWith('/transcribe')) {
      return Uri.parse(
        '${_endpoint.substring(0, _endpoint.length - '/transcribe'.length)}/verify-tajweed',
      );
    }
    if (_endpoint.endsWith('/')) {
      return Uri.parse('${_endpoint}verify-tajweed');
    }
    return Uri.parse('$_endpoint/verify-tajweed');
  }

  Future<RemoteTajweedResult?> transcribeWithHarakat({
    required String expectedAyah,
    required String audioFilePath,
  }) async {
    if (!isConfigured) {
      return null;
    }

    final file = File(audioFilePath);
    if (!await file.exists()) {
      return null;
    }

    try {
      final request = http.MultipartRequest('POST', _transcribeUri);
      request.fields['expected_ayah'] = expectedAyah;
      request.files.add(
        await http.MultipartFile.fromPath('audio', audioFilePath),
      );

      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 12));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        return null;
      }

      final provider = (body['provider'] as String?)?.trim() ?? 'unknown';
      final canVerifyHarakat = body['can_verify_harakat'] as bool? ?? false;
      final isSynthetic = body['is_synthetic'] as bool? ?? false;

      final candidates = <String?>[
        body['text_with_harakat'] as String?,
        body['recognized_text_with_harakat'] as String?,
        body['text'] as String?,
        body['recognized_text'] as String?,
      ];

      for (final candidate in candidates) {
        if (candidate != null && candidate.trim().isNotEmpty) {
          return RemoteTajweedResult(
            text: candidate.trim(),
            provider: provider,
            canVerifyHarakat: canVerifyHarakat,
            isSynthetic: isSynthetic,
          );
        }
      }
    } on SocketException {
      return null;
    } on http.ClientException {
      return null;
    } on FormatException {
      return null;
    }

    return null;
  }

  Future<RemoteTajweedVerificationResult?> verifyTajweed({
    required String expectedAyah,
    required String audioFilePath,
    required String ayahId,
  }) async {
    if (!isConfigured) {
      return null;
    }

    final file = File(audioFilePath);
    if (!await file.exists()) {
      return null;
    }

    try {
      final request = http.MultipartRequest('POST', _verificationUri);
      request.fields['expected_ayah'] = expectedAyah;
      request.fields['ayah_id'] = ayahId;
      request.files.add(
        await http.MultipartFile.fromPath('audio', audioFilePath),
      );

      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        return null;
      }

      final wordsBody = body['words'];
      if (wordsBody is! List) {
        return null;
      }

      final words = <RemoteTajweedWordResult>[];
      for (final entry in wordsBody) {
        if (entry is! Map<String, dynamic>) {
          continue;
        }
        words.add(
          RemoteTajweedWordResult(
            index: (entry['index'] as num?)?.toInt() ?? words.length,
            word: (entry['word'] as String?)?.trim() ?? '',
            spokenWord: (entry['spoken_word'] as String?)?.trim() ?? '',
            correct: entry['correct'] as bool? ?? false,
            score: (entry['score'] as num?)?.toDouble() ?? 0,
            mistakeTypes: ((entry['mistake_types'] as List?) ?? const [])
                .whereType<String>()
                .map((value) => value.trim())
                .where((value) => value.isNotEmpty)
                .toList(growable: false),
          ),
        );
      }

      if (words.isEmpty) {
        return null;
      }

      return RemoteTajweedVerificationResult(
        recognizedText: (body['recognized_text'] as String?)?.trim() ?? '',
        provider: (body['provider'] as String?)?.trim() ?? 'unknown',
        canVerifyHarakat: body['can_verify_harakat'] as bool? ?? false,
        isSynthetic: body['is_synthetic'] as bool? ?? false,
        overallScore: (body['overall_score'] as num?)?.toDouble() ?? 0,
        wordErrorRate: (body['word_error_rate'] as num?)?.toDouble() ?? 0,
        charErrorRate: (body['char_error_rate'] as num?)?.toDouble() ?? 0,
        weightedCharErrorRate:
            (body['weighted_char_error_rate'] as num?)?.toDouble() ?? 0,
        tajweedScore: (body['tajweed_score'] as num?)?.toDouble() ?? 0,
        textMistakes: (body['text_mistakes'] as num?)?.toInt() ?? 0,
        tajweedMistakes: (body['tajweed_mistakes'] as num?)?.toInt() ?? 0,
        stopReading: body['stop_reading'] as bool? ?? false,
        words: words,
      );
    } on SocketException {
      return null;
    } on http.ClientException {
      return null;
    } on FormatException {
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}

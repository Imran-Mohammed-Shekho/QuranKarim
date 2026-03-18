enum PracticeSessionType { recitation, memorization }

class LastReadProgress {
  const LastReadProgress({
    required this.surahNumber,
    required this.ayahNumber,
    required this.updatedAt,
  });

  final int surahNumber;
  final int ayahNumber;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LastReadProgress.fromJson(Map<String, dynamic> json) {
    return LastReadProgress(
      surahNumber: (json['surahNumber'] as num?)?.toInt() ?? 0,
      ayahNumber: (json['ayahNumber'] as num?)?.toInt() ?? 0,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class MemorizationCheckpoint {
  const MemorizationCheckpoint({
    required this.surahNumber,
    required this.revealedWords,
    required this.updatedAt,
  });

  final int surahNumber;
  final int revealedWords;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'surahNumber': surahNumber,
      'revealedWords': revealedWords,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MemorizationCheckpoint.fromJson(Map<String, dynamic> json) {
    return MemorizationCheckpoint(
      surahNumber: (json['surahNumber'] as num?)?.toInt() ?? 0,
      revealedWords: (json['revealedWords'] as num?)?.toInt() ?? 0,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class PracticeSessionRecord {
  const PracticeSessionRecord({
    required this.type,
    required this.surahNumber,
    required this.timestamp,
    this.ayahNumber,
    this.mode,
    this.memorizationWordIndex,
  });

  final PracticeSessionType type;
  final int surahNumber;
  final DateTime timestamp;
  final int? ayahNumber;
  final String? mode;
  final int? memorizationWordIndex;

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'surahNumber': surahNumber,
      'timestamp': timestamp.toIso8601String(),
      'ayahNumber': ayahNumber,
      'mode': mode,
      'memorizationWordIndex': memorizationWordIndex,
    };
  }

  factory PracticeSessionRecord.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String?;
    return PracticeSessionRecord(
      type: PracticeSessionType.values.firstWhere(
        (value) => value.name == typeName,
        orElse: () => PracticeSessionType.recitation,
      ),
      surahNumber: (json['surahNumber'] as num?)?.toInt() ?? 0,
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      ayahNumber: (json['ayahNumber'] as num?)?.toInt(),
      mode: (json['mode'] as String?)?.trim(),
      memorizationWordIndex: (json['memorizationWordIndex'] as num?)?.toInt(),
    );
  }
}

class QuranProgressSnapshot {
  const QuranProgressSnapshot({
    required this.favoriteSurahNumbers,
    required this.memorizationCheckpoints,
    required this.recentSessions,
    required this.weakWordCounts,
    this.lastRead,
  });

  final Set<int> favoriteSurahNumbers;
  final LastReadProgress? lastRead;
  final Map<int, MemorizationCheckpoint> memorizationCheckpoints;
  final List<PracticeSessionRecord> recentSessions;
  final Map<String, int> weakWordCounts;
}

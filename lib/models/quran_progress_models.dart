enum PracticeSessionType { recitation, memorization }

enum MemorizationWorkflowStage {
  newLesson,
  continueLesson,
  needsPractice,
  memorized,
}

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
    this.totalWords = 0,
    this.needsReview = false,
    this.lastMistakeWordIndex,
    required this.updatedAt,
  });

  final int surahNumber;
  final int revealedWords;
  final int totalWords;
  final bool needsReview;
  final int? lastMistakeWordIndex;
  final DateTime updatedAt;

  bool get isCompleted => totalWords > 0 && revealedWords >= totalWords;

  MemorizationWorkflowStage get stage {
    if (isCompleted) {
      return MemorizationWorkflowStage.memorized;
    }
    if (needsReview) {
      return MemorizationWorkflowStage.needsPractice;
    }
    if (revealedWords > 0) {
      return MemorizationWorkflowStage.continueLesson;
    }
    return MemorizationWorkflowStage.newLesson;
  }

  Map<String, dynamic> toJson() {
    return {
      'surahNumber': surahNumber,
      'revealedWords': revealedWords,
      'totalWords': totalWords,
      'needsReview': needsReview,
      'lastMistakeWordIndex': lastMistakeWordIndex,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MemorizationCheckpoint.fromJson(Map<String, dynamic> json) {
    return MemorizationCheckpoint(
      surahNumber: (json['surahNumber'] as num?)?.toInt() ?? 0,
      revealedWords: (json['revealedWords'] as num?)?.toInt() ?? 0,
      totalWords: (json['totalWords'] as num?)?.toInt() ?? 0,
      needsReview: json['needsReview'] as bool? ?? false,
      lastMistakeWordIndex: (json['lastMistakeWordIndex'] as num?)?.toInt(),
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

class AyahStudyEntry {
  const AyahStudyEntry({
    required this.surahNumber,
    required this.ayahNumber,
    required this.isBookmarked,
    required this.updatedAt,
    this.note,
  });

  final int surahNumber;
  final int ayahNumber;
  final bool isBookmarked;
  final String? note;
  final DateTime updatedAt;

  bool get hasNote => note != null && note!.trim().isNotEmpty;

  String get key => '$surahNumber:$ayahNumber';

  AyahStudyEntry copyWith({
    bool? isBookmarked,
    String? note,
    bool clearNote = false,
    DateTime? updatedAt,
  }) {
    return AyahStudyEntry(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      note: clearNote ? null : (note ?? this.note),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber,
      'isBookmarked': isBookmarked,
      'note': note,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AyahStudyEntry.fromJson(Map<String, dynamic> json) {
    return AyahStudyEntry(
      surahNumber: (json['surahNumber'] as num?)?.toInt() ?? 0,
      ayahNumber: (json['ayahNumber'] as num?)?.toInt() ?? 0,
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      note: (json['note'] as String?)?.trim(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class QuranProgressSnapshot {
  const QuranProgressSnapshot({
    required this.favoriteSurahNumbers,
    required this.memorizationCheckpoints,
    required this.recentSessions,
    required this.studyEntries,
    required this.weakWordCounts,
    this.lastRead,
  });

  final Set<int> favoriteSurahNumbers;
  final LastReadProgress? lastRead;
  final Map<int, MemorizationCheckpoint> memorizationCheckpoints;
  final List<PracticeSessionRecord> recentSessions;
  final List<AyahStudyEntry> studyEntries;
  final Map<String, int> weakWordCounts;
}

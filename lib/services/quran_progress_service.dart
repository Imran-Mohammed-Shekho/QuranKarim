import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/quran_progress_models.dart';

class QuranProgressService {
  QuranProgressService({
    Future<SharedPreferences> Function()? preferencesProvider,
  }) : _preferencesProvider =
           preferencesProvider ?? SharedPreferences.getInstance;

  static const _favoriteSurahsKey = 'quran_favorite_surahs';
  static const _lastReadKey = 'quran_last_read';
  static const _memorizationCheckpointsKey = 'quran_memorization_checkpoints';
  static const _recentSessionsKey = 'quran_recent_sessions';
  static const _ayahStudyEntriesKey = 'quran_ayah_study_entries';
  static const _weakWordCountsKey = 'quran_weak_word_counts';
  static const _maxRecentSessions = 10;

  final Future<SharedPreferences> Function() _preferencesProvider;

  Future<QuranProgressSnapshot> loadSnapshot() async {
    final prefs = await _preferencesProvider();
    final favoriteSurahNumbers = (prefs.getStringList(_favoriteSurahsKey) ?? [])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();

    final lastRead = _decodeLastRead(prefs.getString(_lastReadKey));
    final memorizationCheckpoints = _decodeCheckpoints(
      prefs.getString(_memorizationCheckpointsKey),
    );
    final recentSessions = _decodeRecentSessions(
      prefs.getString(_recentSessionsKey),
    );
    final studyEntries = _decodeStudyEntries(
      prefs.getString(_ayahStudyEntriesKey),
    );
    final weakWordCounts = _decodeWeakWordCounts(
      prefs.getString(_weakWordCountsKey),
    );

    return QuranProgressSnapshot(
      favoriteSurahNumbers: favoriteSurahNumbers,
      lastRead: lastRead,
      memorizationCheckpoints: memorizationCheckpoints,
      recentSessions: recentSessions,
      studyEntries: studyEntries,
      weakWordCounts: weakWordCounts,
    );
  }

  Future<void> saveFavoriteSurahs(Set<int> surahNumbers) async {
    final prefs = await _preferencesProvider();
    final values = surahNumbers.toList()..sort();
    await prefs.setStringList(
      _favoriteSurahsKey,
      values.map((value) => value.toString()).toList(growable: false),
    );
  }

  Future<void> saveLastRead(LastReadProgress progress) async {
    final prefs = await _preferencesProvider();
    await prefs.setString(_lastReadKey, jsonEncode(progress.toJson()));
  }

  Future<void> clearLastRead() async {
    final prefs = await _preferencesProvider();
    await prefs.remove(_lastReadKey);
  }

  Future<void> saveMemorizationCheckpoint(
    MemorizationCheckpoint checkpoint,
  ) async {
    final prefs = await _preferencesProvider();
    final checkpoints = _decodeCheckpoints(
      prefs.getString(_memorizationCheckpointsKey),
    );
    checkpoints[checkpoint.surahNumber] = checkpoint;
    await prefs.setString(
      _memorizationCheckpointsKey,
      jsonEncode(
        checkpoints.map(
          (key, value) => MapEntry(key.toString(), value.toJson()),
        ),
      ),
    );
  }

  Future<void> clearMemorizationCheckpoint(int surahNumber) async {
    final prefs = await _preferencesProvider();
    final checkpoints = _decodeCheckpoints(
      prefs.getString(_memorizationCheckpointsKey),
    );
    checkpoints.remove(surahNumber);
    await prefs.setString(
      _memorizationCheckpointsKey,
      jsonEncode(
        checkpoints.map(
          (key, value) => MapEntry(key.toString(), value.toJson()),
        ),
      ),
    );
  }

  Future<void> addRecentSession(PracticeSessionRecord record) async {
    final prefs = await _preferencesProvider();
    final sessions = _decodeRecentSessions(prefs.getString(_recentSessionsKey));

    sessions.removeWhere(
      (session) =>
          session.type == record.type &&
          session.surahNumber == record.surahNumber &&
          session.ayahNumber == record.ayahNumber &&
          session.memorizationWordIndex == record.memorizationWordIndex &&
          session.mode == record.mode,
    );
    sessions.insert(0, record);
    if (sessions.length > _maxRecentSessions) {
      sessions.removeRange(_maxRecentSessions, sessions.length);
    }

    await prefs.setString(
      _recentSessionsKey,
      jsonEncode(
        sessions.map((value) => value.toJson()).toList(growable: false),
      ),
    );
  }

  Future<void> saveAyahStudyEntries(Iterable<AyahStudyEntry> entries) async {
    final prefs = await _preferencesProvider();
    final values = entries.toList(growable: false)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await prefs.setString(
      _ayahStudyEntriesKey,
      jsonEncode(values.map((value) => value.toJson()).toList(growable: false)),
    );
  }

  Future<Map<String, int>> incrementWeakWords(Iterable<String> wordKeys) async {
    final prefs = await _preferencesProvider();
    final weakWordCounts = _decodeWeakWordCounts(
      prefs.getString(_weakWordCountsKey),
    );

    for (final key in wordKeys) {
      if (key.trim().isEmpty) {
        continue;
      }
      weakWordCounts[key] = (weakWordCounts[key] ?? 0) + 1;
    }

    await prefs.setString(_weakWordCountsKey, jsonEncode(weakWordCounts));
    return weakWordCounts;
  }

  LastReadProgress? _decodeLastRead(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final progress = LastReadProgress.fromJson(decoded);
      if (progress.surahNumber <= 0 || progress.ayahNumber <= 0) {
        return null;
      }
      return progress;
    } on FormatException {
      return null;
    }
  }

  Map<int, MemorizationCheckpoint> _decodeCheckpoints(String? raw) {
    if (raw == null || raw.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return {};
      }

      final checkpoints = <int, MemorizationCheckpoint>{};
      for (final entry in decoded.entries) {
        final map = entry.value;
        if (map is! Map<String, dynamic>) {
          continue;
        }
        final checkpoint = MemorizationCheckpoint.fromJson(map);
        if (checkpoint.surahNumber > 0 && checkpoint.revealedWords > 0) {
          checkpoints[checkpoint.surahNumber] = checkpoint;
        }
      }
      return checkpoints;
    } on FormatException {
      return {};
    }
  }

  List<PracticeSessionRecord> _decodeRecentSessions(String? raw) {
    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(PracticeSessionRecord.fromJson)
          .where((session) => session.surahNumber > 0)
          .toList(growable: true);
    } on FormatException {
      return [];
    }
  }

  List<AyahStudyEntry> _decodeStudyEntries(String? raw) {
    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return [];
      }

      final entries = decoded
          .whereType<Map<String, dynamic>>()
          .map(AyahStudyEntry.fromJson)
          .where(
            (entry) =>
                entry.surahNumber > 0 &&
                entry.ayahNumber > 0 &&
                (entry.isBookmarked || entry.hasNote),
          )
          .toList(growable: true)
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return entries;
    } on FormatException {
      return [];
    }
  }

  Map<String, int> _decodeWeakWordCounts(String? raw) {
    if (raw == null || raw.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return {};
      }

      final weakWords = <String, int>{};
      for (final entry in decoded.entries) {
        final count = (entry.value as num?)?.toInt() ?? 0;
        if (entry.key.trim().isEmpty || count <= 0) {
          continue;
        }
        weakWords[entry.key] = count;
      }
      return weakWords;
    } on FormatException {
      return {};
    }
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:quran/models/quran_progress_models.dart';
import 'package:quran/services/quran_progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('favorites and last read persist in snapshot', () async {
    final service = QuranProgressService();

    await service.saveFavoriteSurahs({2, 1, 55});
    await service.saveLastRead(
      LastReadProgress(
        surahNumber: 2,
        ayahNumber: 255,
        updatedAt: DateTime(2026, 3, 16, 18, 0),
      ),
    );

    final snapshot = await service.loadSnapshot();

    expect(snapshot.favoriteSurahNumbers, equals({1, 2, 55}));
    expect(snapshot.lastRead?.surahNumber, 2);
    expect(snapshot.lastRead?.ayahNumber, 255);
  });

  test('memorization checkpoints can be saved and cleared', () async {
    final service = QuranProgressService();

    await service.saveMemorizationCheckpoint(
      MemorizationCheckpoint(
        surahNumber: 18,
        revealedWords: 42,
        updatedAt: DateTime(2026, 3, 16, 18, 30),
      ),
    );

    var snapshot = await service.loadSnapshot();
    expect(snapshot.memorizationCheckpoints[18]?.revealedWords, 42);

    await service.clearMemorizationCheckpoint(18);
    snapshot = await service.loadSnapshot();
    expect(snapshot.memorizationCheckpoints.containsKey(18), isFalse);
  });

  test('recent sessions are deduplicated and capped', () async {
    final service = QuranProgressService();

    for (int i = 0; i < 12; i++) {
      await service.addRecentSession(
        PracticeSessionRecord(
          type: PracticeSessionType.recitation,
          surahNumber: i + 1,
          ayahNumber: 1,
          mode: 'lenient',
          timestamp: DateTime(2026, 3, 16, 18, i),
        ),
      );
    }

    await service.addRecentSession(
      PracticeSessionRecord(
        type: PracticeSessionType.recitation,
        surahNumber: 12,
        ayahNumber: 1,
        mode: 'lenient',
        timestamp: DateTime(2026, 3, 16, 19, 0),
      ),
    );

    final snapshot = await service.loadSnapshot();

    expect(snapshot.recentSessions, hasLength(10));
    expect(snapshot.recentSessions.first.surahNumber, 12);
    expect(
      snapshot.recentSessions.where((session) => session.surahNumber == 12),
      hasLength(1),
    );
  });

  test('weak word counts are incremented and restored', () async {
    final service = QuranProgressService();

    await service.incrementWeakWords(['الصراط', 'الصراط', 'الرحمن']);

    final snapshot = await service.loadSnapshot();

    expect(snapshot.weakWordCounts['الصراط'], 2);
    expect(snapshot.weakWordCounts['الرحمن'], 1);
  });
}

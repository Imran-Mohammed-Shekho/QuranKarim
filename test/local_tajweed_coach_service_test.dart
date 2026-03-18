import 'package:flutter_test/flutter_test.dart';
import 'package:quran/services/ayah_comparison_service.dart';
import 'package:quran/services/local_tajweed_coach_service.dart';

void main() {
  final comparisonService = AyahComparisonService();
  final coachService = LocalTajweedCoachService();

  test('coach warns when recitation stops before a natural waqf point', () {
    final result = comparisonService.compare(
      expectedAyah: 'الحمد لله رب العالمين',
      spokenAyah: 'الحمد لله',
    );

    final coach = coachService.analyze(
      expectedAyah: 'الحمد لله رب العالمين',
      spokenAyah: 'الحمد لله',
      comparisonResult: result,
      weakWordCounts: const {},
      recordingDuration: const Duration(seconds: 2),
    );

    expect(
      coach.hints.any((hint) => hint.type == LocalCoachHintType.wrongWaqf),
      isTrue,
    );
  });

  test('coach suggests slowing down on madd-heavy passages', () {
    final result = comparisonService.compare(
      expectedAyah: 'قالوا آمنا بالله',
      spokenAyah: 'قالوا آمنا بالله',
    );

    final coach = coachService.analyze(
      expectedAyah: 'قالوا آمنا بالله',
      spokenAyah: 'قالوا آمنا بالله',
      comparisonResult: result,
      weakWordCounts: const {},
      recordingDuration: const Duration(milliseconds: 1200),
    );

    expect(
      coach.hints.any((hint) => hint.type == LocalCoachHintType.maddTiming),
      isTrue,
    );
  });

  test('coach highlights repeated weak words', () {
    final result = comparisonService.compare(
      expectedAyah: 'اهدنا الصراط المستقيم',
      spokenAyah: 'اهدنا السراط المستقيم',
    );

    final coach = coachService.analyze(
      expectedAyah: 'اهدنا الصراط المستقيم',
      spokenAyah: 'اهدنا السراط المستقيم',
      comparisonResult: result,
      weakWordCounts: {
        LocalTajweedCoachService.normalizeWeakWordKey('الصراط'): 3,
      },
      recordingDuration: const Duration(seconds: 3),
    );

    expect(
      coach.hints.any(
        (hint) => hint.type == LocalCoachHintType.repeatedWeakWord,
      ),
      isTrue,
    );
    expect(coach.focusWords, isNotEmpty);
  });
}

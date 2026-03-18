import 'package:flutter_test/flutter_test.dart';
import 'package:quran/models/reciter_option.dart';
import 'package:quran/services/reciter_download_service.dart';
import 'package:quran/state/app_settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeReciterDownloadService extends ReciterDownloadService {
  _FakeReciterDownloadService({
    required Map<String, Set<int>> downloadedSurahsByReciter,
  }) : _downloadedSurahsByReciter = downloadedSurahsByReciter,
       super(remoteAudioBaseUrl: 'https://audio.example.com');

  final Map<String, Set<int>> _downloadedSurahsByReciter;

  @override
  Future<Map<String, Set<int>>> loadDownloadedSurahsByReciter() async {
    return _downloadedSurahsByReciter.map(
      (reciterId, surahs) => MapEntry(reciterId, Set<int>.from(surahs)),
    );
  }

  @override
  Future<String> getLocalAudioBasePath() async => '/tmp/reciter_audio';

  @override
  Future<void> downloadSurah(
    String reciterId,
    int surahNumber, {
    void Function(ReciterDownloadProgress progress)? onProgress,
  }) async {
    final surahs = _downloadedSurahsByReciter.putIfAbsent(
      reciterId,
      () => <int>{},
    );
    surahs.add(surahNumber);
  }

  @override
  void dispose() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bootstrap keeps a saved reciter selection', () async {
    SharedPreferences.setMockInitialValues({
      'selected_reciter': 'abdul_basit_mp3',
    });
    final controller = AppSettingsController(
      reciterDownloadService: _FakeReciterDownloadService(
        downloadedSurahsByReciter: {
          'abdul_basit_mp3': {1},
        },
      ),
    );

    await controller.bootstrap();

    expect(controller.selectedReciterId, 'abdul_basit_mp3');
    expect(
      controller.downloadedSurahsForReciter('abdul_basit_mp3'),
      contains(1),
    );
  });

  test('downloadReciterSurah stores the surah locally', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppSettingsController(
      reciterDownloadService: _FakeReciterDownloadService(
        downloadedSurahsByReciter: <String, Set<int>>{},
      ),
    );

    await controller.bootstrap();
    await controller.setSelectedReciter('abdul_basit_mp3');
    await controller.downloadReciterSurah('abdul_basit_mp3', 2);

    expect(controller.selectedReciterId, 'abdul_basit_mp3');
    expect(controller.isReciterSurahDownloaded('abdul_basit_mp3', 2), isTrue);
  });

  test('completeOnboarding persists the first-run flag', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppSettingsController(
      reciterDownloadService: _FakeReciterDownloadService(
        downloadedSurahsByReciter: <String, Set<int>>{},
      ),
    );

    await controller.bootstrap();
    expect(controller.isBootstrapped, isTrue);
    expect(controller.hasCompletedOnboarding, isFalse);

    await controller.completeOnboarding();

    expect(controller.hasCompletedOnboarding, isTrue);

    final reloaded = AppSettingsController(
      reciterDownloadService: _FakeReciterDownloadService(
        downloadedSurahsByReciter: <String, Set<int>>{},
      ),
    );
    await reloaded.bootstrap();

    expect(reloaded.hasCompletedOnboarding, isTrue);
  });
}

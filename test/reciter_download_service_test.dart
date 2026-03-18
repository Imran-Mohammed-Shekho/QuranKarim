import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:quran/models/reciter_option.dart';
import 'package:quran/services/reciter_download_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('downloadReciter saves files locally and remembers the reciter', () async {
    SharedPreferences.setMockInitialValues({});
    final tempDir = await Directory.systemTemp.createTemp(
      'reciter_download_service_test',
    );
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final requestedUrls = <String>[];
    final service = ReciterDownloadService(
      remoteAudioBaseUrl:
          'https://cigavogfeiszxjnvvinm.supabase.co/storage/v1/object/public/hello',
      client: MockClient((request) async {
        requestedUrls.add(request.url.toString());
        return http.Response.bytes(const [1, 2, 3, 4], 200);
      }),
      applicationSupportDirectoryProvider: () async => tempDir,
      ayahManifestProvider: () async => const [
        ReciterAyahReference(surahNumber: 1, ayahNumber: 1),
        ReciterAyahReference(surahNumber: 1, ayahNumber: 2),
      ],
    );

    await service.downloadSurah('abdul_basit_mp3', 1);

    expect(
      requestedUrls,
      contains(
        'https://cigavogfeiszxjnvvinm.supabase.co/storage/v1/object/public/hello/abdul_basit_mp3/001001.mp3',
      ),
    );
    expect(
      requestedUrls,
      contains(
        'https://cigavogfeiszxjnvvinm.supabase.co/storage/v1/object/public/hello/abdul_basit_mp3/001002.mp3',
      ),
    );

    final localFile = File(
      p.join(tempDir.path, 'reciter_audio', 'abdul_basit_mp3', '001001.mp3'),
    );
    expect(await localFile.exists(), isTrue);
    expect(await localFile.readAsBytes(), const [1, 2, 3, 4]);

    final downloaded = await service.loadDownloadedSurahsForReciter(
      'abdul_basit_mp3',
    );
    expect(downloaded, contains(1));

    service.dispose();
  });
}

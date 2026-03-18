import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/reciter_option.dart';

class ReciterDownloadService {
  ReciterDownloadService({
    required String remoteAudioBaseUrl,
    http.Client? client,
    Future<SharedPreferences> Function()? preferencesProvider,
    Future<Directory> Function()? applicationSupportDirectoryProvider,
    Future<List<ReciterAyahReference>> Function()? ayahManifestProvider,
  }) : _remoteAudioBaseUrl = remoteAudioBaseUrl,
       _client = client ?? http.Client(),
       _preferencesProvider =
           preferencesProvider ?? SharedPreferences.getInstance,
       _applicationSupportDirectoryProvider =
           applicationSupportDirectoryProvider ??
           getApplicationSupportDirectory,
       _ayahManifestProvider = ayahManifestProvider ?? _loadAyahManifest;

  static const downloadedReciterSurahsKey = 'downloaded_reciter_surahs_v2';
  static const List<ReciterOption> availableReciters = [
    ReciterOption(id: 'banna', displayName: 'Banna'),
    ReciterOption(id: 'abdul_basit_mp3', displayName: 'Abdul Basit'),
  ];

  final String _remoteAudioBaseUrl;
  final http.Client _client;
  final Future<SharedPreferences> Function() _preferencesProvider;
  final Future<Directory> Function() _applicationSupportDirectoryProvider;
  final Future<List<ReciterAyahReference>> Function() _ayahManifestProvider;

  Future<Map<String, Set<int>>> loadDownloadedSurahsByReciter() async {
    final prefs = await _preferencesProvider();
    final raw = prefs.getString(downloadedReciterSurahsKey);
    if (raw == null || raw.trim().isEmpty) {
      return <String, Set<int>>{};
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((reciterId, value) {
      final surahs = (value as List<dynamic>? ?? const [])
          .map((entry) => (entry as num?)?.toInt())
          .whereType<int>()
          .toSet();
      return MapEntry(reciterId, surahs);
    });
  }

  Future<Set<int>> loadDownloadedSurahsForReciter(String reciterId) async {
    final downloaded = await loadDownloadedSurahsByReciter();
    return downloaded[reciterId] ?? <int>{};
  }

  Future<String> getLocalAudioBasePath() async {
    final baseDir = await _applicationSupportDirectoryProvider();
    final dir = Directory(p.join(baseDir.path, 'reciter_audio'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  String buildRemoteAudioUrl(
    String reciterId,
    int surahNumber,
    int ayahNumber,
  ) {
    final base = _remoteAudioBaseUrl.endsWith('/')
        ? _remoteAudioBaseUrl
        : '$_remoteAudioBaseUrl/';
    return '$base$reciterId/${_ayahFileName(surahNumber, ayahNumber)}';
  }

  Future<String> buildLocalAudioPath(
    String reciterId,
    int surahNumber,
    int ayahNumber,
  ) async {
    final root = await getLocalAudioBasePath();
    return p.join(root, reciterId, _ayahFileName(surahNumber, ayahNumber));
  }

  Future<void> downloadSurah(
    String reciterId,
    int surahNumber, {
    void Function(ReciterDownloadProgress progress)? onProgress,
  }) async {
    final refs = await _ayahManifestProvider();
    final surahRefs = refs
        .where((ref) => ref.surahNumber == surahNumber)
        .toList(growable: false);
    if (surahRefs.isEmpty) {
      throw Exception('No ayah audio entries found for surah $surahNumber.');
    }
    final reciterDirectory = Directory(
      p.join(await getLocalAudioBasePath(), reciterId),
    );
    if (!await reciterDirectory.exists()) {
      await reciterDirectory.create(recursive: true);
    }

    var completed = 0;
    final total = surahRefs.length;
    for (final ref in surahRefs) {
      final file = File(
        p.join(
          reciterDirectory.path,
          _ayahFileName(ref.surahNumber, ref.ayahNumber),
        ),
      );

      if (await file.exists() && await file.length() > 0) {
        completed++;
        onProgress?.call(
          ReciterDownloadProgress(
            reciterId: reciterId,
            completedFiles: completed,
            totalFiles: total,
            surahNumber: ref.surahNumber,
            ayahNumber: ref.ayahNumber,
          ),
        );
        continue;
      }

      final response = await _client.get(
        Uri.parse(
          buildRemoteAudioUrl(reciterId, ref.surahNumber, ref.ayahNumber),
        ),
      );
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to download $reciterId audio ${ref.surahNumber}:${ref.ayahNumber} (${response.statusCode}).',
        );
      }

      await file.writeAsBytes(response.bodyBytes, flush: true);
      completed++;
      onProgress?.call(
        ReciterDownloadProgress(
          reciterId: reciterId,
          completedFiles: completed,
          totalFiles: total,
          surahNumber: ref.surahNumber,
          ayahNumber: ref.ayahNumber,
        ),
      );
    }

    final downloaded = await loadDownloadedSurahsByReciter();
    final reciterSurahs = downloaded.putIfAbsent(reciterId, () => <int>{});
    reciterSurahs.add(surahNumber);
    final prefs = await _preferencesProvider();
    final normalized = downloaded.map(
      (id, surahs) =>
          MapEntry(id, (surahs.toList()..sort()).toList(growable: false)),
    );
    await prefs.setString(downloadedReciterSurahsKey, jsonEncode(normalized));
  }

  static Future<List<ReciterAyahReference>> _loadAyahManifest() async {
    final raw = await rootBundle.loadString('assets/quran_.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final refs = <ReciterAyahReference>[];

    final surahKeys = decoded.keys.toList()..sort();
    for (final surahKey in surahKeys) {
      final surahJson = decoded[surahKey] as Map<String, dynamic>? ?? const {};
      final ayahsJson = surahJson['ayahs'] as Map<String, dynamic>? ?? const {};
      final ayahKeys = ayahsJson.keys.toList()..sort();
      for (final ayahKey in ayahKeys) {
        refs.add(
          ReciterAyahReference(
            surahNumber: int.parse(surahKey),
            ayahNumber: int.parse(ayahKey),
          ),
        );
      }
    }

    return refs.toList(growable: false);
  }

  String _ayahFileName(int surahNumber, int ayahNumber) {
    final surah = surahNumber.toString().padLeft(3, '0');
    final ayah = ayahNumber.toString().padLeft(3, '0');
    return '$surah$ayah.mp3';
  }

  void dispose() {
    _client.close();
  }
}

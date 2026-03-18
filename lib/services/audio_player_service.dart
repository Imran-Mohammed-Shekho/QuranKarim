import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class AudioPlaybackState {
  const AudioPlaybackState({
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.isCompleted,
  });

  final Duration position;
  final Duration? duration;
  final bool isPlaying;
  final bool isCompleted;
}

class AudioPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final StreamController<AudioPlaybackState> _playbackStateController =
      StreamController<AudioPlaybackState>.broadcast();
  Directory? _cacheDir;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  Duration _lastPosition = Duration.zero;
  Duration? _lastDuration;
  bool _isPlaying = false;
  bool _didComplete = false;
  bool _isInitialized = false;

  Stream<AudioPlaybackState> get playbackStateStream =>
      _playbackStateController.stream;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      _lastPosition = position;
      _emitPlaybackState();
    });
    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      _lastDuration = duration;
      _emitPlaybackState();
    });
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _didComplete = state.processingState == ProcessingState.completed;
      if (_didComplete) {
        _lastPosition = _lastDuration ?? _lastPosition;
      }
      _emitPlaybackState();
    });
    _isInitialized = true;
  }

  Future<void> playAyah(String sourcePath) async {
    if (sourcePath.startsWith('http://') || sourcePath.startsWith('https://')) {
      try {
        final file = await _getOrDownloadAudio(sourcePath);
        await _audioPlayer.setFilePath(file.path);
      } catch (_) {
        // Fallback to direct streaming if caching fails.
        await _audioPlayer.setAudioSource(
          AudioSource.uri(Uri.parse(sourcePath)),
        );
      }
    } else if (path.isAbsolute(sourcePath)) {
      await _audioPlayer.setFilePath(sourcePath);
    } else {
      await _audioPlayer.setAsset(sourcePath);
    }
    await _audioPlayer.play();
  }

  Future<void> waitForCompletionOrStop() async {
    await _audioPlayer.playerStateStream
        .skipWhile(
          (state) =>
              state.processingState == ProcessingState.idle && !state.playing,
        )
        .firstWhere(
          (state) =>
              state.processingState == ProcessingState.completed ||
              state.processingState == ProcessingState.idle,
        );
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    await _audioPlayer.play();
  }

  void _emitPlaybackState() {
    if (_playbackStateController.isClosed) {
      return;
    }
    _playbackStateController.add(
      AudioPlaybackState(
        position: _lastPosition,
        duration: _lastDuration,
        isPlaying: _isPlaying,
        isCompleted: _didComplete,
      ),
    );
  }

  Future<File> _getOrDownloadAudio(String url) async {
    final uri = Uri.parse(url);
    final cacheDir = await _getCacheDir();
    final fileName = _buildCacheFileName(uri);
    final file = File(path.join(cacheDir.path, fileName));

    if (await file.exists()) {
      final length = await file.length();
      if (length > 0) {
        return file;
      }
    }

    final response = await http.get(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to download audio (${response.statusCode}): $url',
      );
    }

    await file.writeAsBytes(response.bodyBytes, flush: true);
    return file;
  }

  Future<Directory> _getCacheDir() async {
    if (_cacheDir != null) {
      return _cacheDir!;
    }
    final baseDir = await getApplicationSupportDirectory();
    final dir = Directory(path.join(baseDir.path, 'audio_cache'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cacheDir = dir;
    return dir;
  }

  String _buildCacheFileName(Uri uri) {
    final joined = uri.pathSegments.isEmpty
        ? 'audio'
        : uri.pathSegments.join('_');
    final queryHash = uri.hasQuery ? uri.query.hashCode : 0;
    return queryHash == 0 ? joined : '${joined}_$queryHash';
  }

  void dispose() {
    unawaited(_positionSubscription?.cancel());
    unawaited(_durationSubscription?.cancel());
    unawaited(_playerStateSubscription?.cancel());
    unawaited(_playbackStateController.close());
    unawaited(_audioPlayer.dispose());
  }
}

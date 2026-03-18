import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/ayah.dart';
import '../data/models/memorization_word.dart';
import '../data/models/surah.dart';
import '../data/repositories/quran_repository.dart';
import '../models/quran_progress_models.dart';
import '../services/audio_player_service.dart';
import '../services/ayah_comparison_service.dart';
import '../services/local_tajweed_coach_service.dart';
import '../services/quran_progress_service.dart';
import '../services/quran_aware_post_processor.dart';
import '../services/recitation_recorder_service.dart';
import '../services/speech_recognition_service.dart';

class QuranPracticeController extends ChangeNotifier {
  QuranPracticeController({
    required QuranRepository repository,
    required AudioPlayerService audioPlayerService,
    required SpeechRecognitionService speechRecognitionService,
    required AyahComparisonService comparisonService,
    required LocalTajweedCoachService localCoachService,
    required QuranProgressService progressService,
    required QuranAwarePostProcessor postProcessor,
    required RecitationRecorderService recorderService,
  }) : _repository = repository,
       _audioPlayerService = audioPlayerService,
       _speechRecognitionService = speechRecognitionService,
       _comparisonService = comparisonService,
       _localCoachService = localCoachService,
       _progressService = progressService,
       _postProcessor = postProcessor,
       _recorderService = recorderService;

  final QuranRepository _repository;
  final AudioPlayerService _audioPlayerService;
  final SpeechRecognitionService _speechRecognitionService;
  final AyahComparisonService _comparisonService;
  final LocalTajweedCoachService _localCoachService;
  final QuranProgressService _progressService;
  final QuranAwarePostProcessor _postProcessor;
  final RecitationRecorderService _recorderService;
  StreamSubscription<AudioPlaybackState>? _audioPlaybackSubscription;

  final Map<int, ComparisonResult> _comparisonByAyah = {};
  final Map<int, LocalCoachResult> _coachByAyah = {};
  final Map<int, String> _feedbackByAyah = {};

  List<Surah> surahs = [];
  List<Ayah> ayahs = [];

  bool isLoadingSurahs = false;
  bool isLoadingAyahs = false;

  String? globalError;
  String recognizedText = '';
  String rawRecognizedText = '';
  String displayRecognizedText = '';
  String? _lastSpeechError;
  bool needsArabicSpeechInstall = false;
  int _lastAutoCorrectionCount = 0;
  ComparisonMode comparisonMode = ComparisonMode.lenient;

  int? practicingAyahNumber;
  int? _pendingEvaluationAyahNumber;
  Timer? _pendingEvaluationTimer;

  bool _isAutoReading = false;
  int? _autoReadingStartAyahNumber;
  int _autoReadingSessionId = 0;
  int? _playingAyahNumber;
  int? _highlightedPlaybackWordIndex;
  bool _isAudioPlaying = false;
  int? _currentSurahNumber;
  String _configuredReciterId = 'banna';
  Set<int> _downloadedSurahsForConfiguredReciter = <int>{};
  String? _downloadedAudioBasePath;

  String? _lastRecordingFilePath;
  DateTime? _recordingStartedAt;
  Duration? _lastRecordingDuration;

  bool _evaluating = false;
  final Set<int> _favoriteSurahNumbers = <int>{};
  LastReadProgress? _lastReadProgress;
  Map<int, MemorizationCheckpoint> _memorizationCheckpoints = {};
  List<PracticeSessionRecord> _recentSessions = const [];
  Map<String, int> _weakWordCounts = {};

  bool get isListening => _speechRecognitionService.isListening;
  bool get shouldPromptArabicSpeechInstall => needsArabicSpeechInstall;

  bool isMemorizationLoading = false;
  bool _isMemorizationListening = false;
  bool _memorizationRestarting = false;
  int _memorizationResumeIndex = 0;
  int? memorizationSurahNumber;
  List<MemorizationWord> memorizationWords = [];
  List<String> _memorizationExpectedWords = [];
  int memorizationRevealedCount = 0;
  bool memorizationCompleted = false;
  String memorizationRawText = '';
  String memorizationCorrectedText = '';
  String? memorizationError;
  ComparisonResult? memorizationComparisonResult;
  int? memorizationMistakeIndex;
  String? memorizationExpectedWord;
  String? memorizationSpokenWord;

  bool get isAutoReading => _isAutoReading;
  int? get playingAyahNumber => _playingAyahNumber;
  bool get isAudioPlaying => _isAudioPlaying;
  bool get hasActivePlayback => _playingAyahNumber != null;
  Ayah? get currentPlaybackAyah {
    final ayahNumber = _playingAyahNumber;
    if (ayahNumber == null) {
      return null;
    }
    for (final ayah in ayahs) {
      if (ayah.ayahNumber == ayahNumber) {
        return ayah;
      }
    }
    return null;
  }

  bool get isMemorizationListening => _isMemorizationListening;

  bool get hasMemorizationMistake => memorizationMistakeIndex != null;

  int? get autoReadingStartAyahNumber => _autoReadingStartAyahNumber;
  Set<int> get favoriteSurahNumbers => Set.unmodifiable(_favoriteSurahNumbers);
  LastReadProgress? get lastReadProgress => _lastReadProgress;
  List<PracticeSessionRecord> get recentSessions =>
      List.unmodifiable(_recentSessions);
  List<Surah> get favoriteSurahs => surahs
      .where((surah) => _favoriteSurahNumbers.contains(surah.number))
      .toList(growable: false);

  void acknowledgeArabicSpeechPrompt() {
    if (!needsArabicSpeechInstall) {
      return;
    }
    needsArabicSpeechInstall = false;
    notifyListeners();
  }

  ComparisonResult? resultForAyah(int ayahNumber) =>
      _comparisonByAyah[ayahNumber];

  LocalCoachResult? coachForAyah(int ayahNumber) => _coachByAyah[ayahNumber];

  String? feedbackForAyah(int ayahNumber) => _feedbackByAyah[ayahNumber];

  Surah? surahByNumber(int surahNumber) {
    for (final surah in surahs) {
      if (surah.number == surahNumber) {
        return surah;
      }
    }
    return null;
  }

  bool isFavoriteSurah(int surahNumber) =>
      _favoriteSurahNumbers.contains(surahNumber);

  MemorizationCheckpoint? checkpointForSurah(int surahNumber) =>
      _memorizationCheckpoints[surahNumber];

  int? initialAyahNumberForSurah(int surahNumber) {
    final lastRead = _lastReadProgress;
    if (lastRead == null || lastRead.surahNumber != surahNumber) {
      return null;
    }
    return lastRead.ayahNumber;
  }

  void setComparisonMode(ComparisonMode mode) {
    if (comparisonMode == mode) {
      return;
    }
    comparisonMode = mode;
    _comparisonByAyah.clear();
    _coachByAyah.clear();
    _feedbackByAyah.clear();
    notifyListeners();
  }

  Future<void> bootstrap() async {
    await _audioPlayerService.initialize();
    _audioPlaybackSubscription ??= _audioPlayerService.playbackStateStream
        .listen(_handleAudioPlaybackState);
    await _speechRecognitionService.initialize();
    final snapshot = await _progressService.loadSnapshot();
    _favoriteSurahNumbers
      ..clear()
      ..addAll(snapshot.favoriteSurahNumbers);
    _lastReadProgress = snapshot.lastRead;
    _memorizationCheckpoints = snapshot.memorizationCheckpoints;
    _recentSessions = snapshot.recentSessions;
    _weakWordCounts = snapshot.weakWordCounts;
    await loadSurahs();
  }

  Future<void> loadSurahs() async {
    try {
      globalError = null;
      isLoadingSurahs = true;
      notifyListeners();

      surahs = await _repository.getSurahs();
    } catch (error) {
      globalError =
          'Could not load surahs. Check internet connection and retry.';
    } finally {
      isLoadingSurahs = false;
      notifyListeners();
    }
  }

  Future<void> loadAyahs(int surahNumber) async {
    try {
      _currentSurahNumber = surahNumber;
      _repository.configureReciter(
        reciterId: _configuredReciterId,
        useDownloadedAudio: _downloadedSurahsForConfiguredReciter.contains(
          surahNumber,
        ),
        downloadedAudioBasePath: _downloadedAudioBasePath,
      );
      await stopAutoReading();
      _clearPlaybackTracking();
      globalError = null;
      isLoadingAyahs = true;
      _comparisonByAyah.clear();
      _coachByAyah.clear();
      _feedbackByAyah.clear();
      recognizedText = '';
      rawRecognizedText = '';
      displayRecognizedText = '';
      practicingAyahNumber = null;
      _pendingEvaluationAyahNumber = null;
      _lastRecordingFilePath = null;
      _lastRecordingDuration = null;
      notifyListeners();

      ayahs = await _repository.getCachedAyahsForSurah(surahNumber);
      notifyListeners();

      ayahs = await _repository.getAyahsForSurah(surahNumber);
    } catch (error) {
      if (ayahs.isEmpty) {
        globalError =
            'Could not load ayahs. Check internet connection and retry.';
      }
    } finally {
      isLoadingAyahs = false;
      notifyListeners();
    }
  }

  Future<void> configureReciter({
    required String reciterId,
    required Set<int> downloadedSurahNumbers,
    String? downloadedAudioBasePath,
  }) async {
    final normalizedPath = downloadedAudioBasePath?.trim();
    final normalizedSurahs = Set<int>.from(downloadedSurahNumbers);
    if (_configuredReciterId == reciterId &&
        setEquals(_downloadedSurahsForConfiguredReciter, normalizedSurahs) &&
        _downloadedAudioBasePath == normalizedPath) {
      return;
    }

    _configuredReciterId = reciterId;
    _downloadedSurahsForConfiguredReciter = normalizedSurahs;
    _downloadedAudioBasePath = normalizedPath;
    final currentSurahNumber = _currentSurahNumber;
    final replayAyahNumber = _isAudioPlaying ? _playingAyahNumber : null;

    _repository.configureReciter(
      reciterId: reciterId,
      useDownloadedAudio:
          currentSurahNumber != null &&
          normalizedSurahs.contains(currentSurahNumber),
      downloadedAudioBasePath: normalizedPath,
    );

    await _stopAudioPlayback();

    if (currentSurahNumber != null) {
      await loadAyahs(currentSurahNumber);
      if (replayAyahNumber != null) {
        Ayah? ayah;
        for (final item in ayahs) {
          if (item.ayahNumber == replayAyahNumber) {
            ayah = item;
            break;
          }
        }
        if (ayah != null) {
          await playAyah(ayah);
        }
      }
    }
  }

  Future<void> loadMemorizationSurah(int surahNumber) async {
    try {
      await stopMemorizationListening();
      await stopAutoReading();
      if (isListening) {
        await _speechRecognitionService.stopListening();
      }

      memorizationSurahNumber = surahNumber;
      isMemorizationLoading = true;
      memorizationError = null;
      _resetMemorizationProgress();
      notifyListeners();

      memorizationWords = await _repository.getMemorizationWordsForSurah(
        surahNumber,
      );
      _memorizationExpectedWords = memorizationWords
          .map((word) => word.word)
          .toList(growable: false);
      final checkpoint = checkpointForSurah(surahNumber);
      final revealedCount = checkpoint == null
          ? 0
          : checkpoint.revealedWords.clamp(
              0,
              _memorizationExpectedWords.length,
            );
      memorizationRevealedCount = revealedCount;
      _memorizationResumeIndex = revealedCount;
    } catch (_) {
      memorizationError =
          'Could not load memorization data. Check storage and try again.';
      memorizationWords = [];
      _memorizationExpectedWords = [];
    } finally {
      isMemorizationLoading = false;
      notifyListeners();
    }
  }

  Future<void> startMemorization() async {
    if (_memorizationExpectedWords.isEmpty) {
      return;
    }

    if (_memorizationResumeIndex >= _memorizationExpectedWords.length) {
      memorizationCompleted = true;
      _isMemorizationListening = false;
      notifyListeners();
      return;
    }

    await stopAutoReading();
    if (isListening) {
      await _speechRecognitionService.stopListening();
    }

    _pendingEvaluationTimer?.cancel();
    _pendingEvaluationAyahNumber = null;
    practicingAyahNumber = null;

    _clearMemorizationFeedback();
    memorizationError = null;
    memorizationCompleted = false;
    _isMemorizationListening = true;
    _memorizationRestarting = false;
    notifyListeners();

    Future<void> beginListening() async {
      final resumeIndex = _memorizationResumeIndex;
      final expectedWords = _memorizationExpectedWords.sublist(resumeIndex);
      final expectedText = expectedWords.join(' ');

      final started = await _speechRecognitionService.startListening(
        pauseFor: const Duration(seconds: 3),
        listenFor: const Duration(minutes: 2),
        onResult: (text, isFinal) {
          if (!_isMemorizationListening) {
            return;
          }
          memorizationRawText = text;
          if (comparisonMode == ComparisonMode.tajweed) {
            memorizationCorrectedText = _buildTajweedDisplayText(
              expectedAyah: expectedText,
              sourceText: text,
            );
          } else {
            final processed = _postProcessor.process(
              expectedAyah: expectedText,
              rawRecognizedText: text,
            );
            memorizationCorrectedText = processed.correctedText;
          }
          final compareText = memorizationCorrectedText.isNotEmpty
              ? memorizationCorrectedText
              : text;
          final result = _comparisonService.compare(
            expectedAyah: expectedText,
            spokenAyah: compareText,
            mode: comparisonMode,
          );
          memorizationComparisonResult = result;

          final absoluteMatched =
              resumeIndex + _matchedMemorizationPrefixCount(result);
          if (absoluteMatched > memorizationRevealedCount) {
            memorizationRevealedCount = absoluteMatched;
          }

          if (isFinal) {
            _applyMemorizationComparisonResult(
              result,
              resumeIndex: resumeIndex,
              expectedWords: expectedWords,
            );
            if (!_isMemorizationListening) {
              memorizationRawText = text;
            }
          }

          notifyListeners();
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (_isMemorizationListening &&
                !memorizationCompleted &&
                !hasMemorizationMistake) {
              _restartMemorizationListening(beginListening);
              return;
            }
            _isMemorizationListening = false;
            notifyListeners();
          }
        },
        onError: (error) {
          if (_isMemorizationListening && _isTransientSpeechError(error)) {
            _restartMemorizationListening(beginListening);
            return;
          }
          memorizationError = 'Speech error: $error';
          _isMemorizationListening = false;
          notifyListeners();
        },
      );

      if (!started) {
        if (_speechRecognitionService.isArabicLocaleMissing) {
          needsArabicSpeechInstall = true;
          memorizationError = 'Arabic speech recognition is not installed.';
        } else {
          memorizationError =
              'Microphone or speech recognition is not available.';
        }
        _isMemorizationListening = false;
        notifyListeners();
      }
    }

    await beginListening();
  }

  void _restartMemorizationListening(Future<void> Function() beginListening) {
    if (_memorizationRestarting) {
      return;
    }
    _memorizationRestarting = true;
    unawaited(() async {
      try {
        await beginListening();
      } finally {
        _memorizationRestarting = false;
      }
    }());
  }

  bool _isTransientSpeechError(String error) {
    final normalized = error.toLowerCase();
    return normalized.contains('timeout') ||
        normalized.contains('no_match') ||
        normalized.contains('no match') ||
        normalized.contains('busy');
  }

  Future<void> stopMemorizationListening() async {
    if (!_isMemorizationListening) {
      return;
    }

    _isMemorizationListening = false;
    _memorizationRestarting = false;
    await _speechRecognitionService.stopListening();
    await _persistMemorizationCheckpoint();
    if (memorizationRevealedCount > 0) {
      await _recordRecentSession(PracticeSessionType.memorization);
    }
    notifyListeners();
  }

  Future<void> retryMemorization() async {
    await stopMemorizationListening();
    _memorizationResumeIndex = 0;
    _resetMemorizationProgress();
    await _clearMemorizationCheckpointForCurrentSurah();
    notifyListeners();
  }

  Future<void> continueMemorization() async {
    _clearMemorizationFeedback();
    _memorizationResumeIndex = memorizationRevealedCount;
    notifyListeners();
    await startMemorization();
  }

  void _resetMemorizationProgress() {
    memorizationRevealedCount = 0;
    memorizationCompleted = false;
    memorizationRawText = '';
    memorizationCorrectedText = '';
    _memorizationResumeIndex = 0;
    _clearMemorizationFeedback();
  }

  void _clearMemorizationFeedback() {
    memorizationComparisonResult = null;
    memorizationMistakeIndex = null;
    memorizationExpectedWord = null;
    memorizationSpokenWord = null;
  }

  int _matchedMemorizationPrefixCount(ComparisonResult result) {
    var matchedCount = 0;
    for (final word in result.words) {
      if (word.isExtraSpokenWord || !word.isCorrect) {
        break;
      }
      matchedCount++;
    }
    return matchedCount;
  }

  void _applyMemorizationComparisonResult(
    ComparisonResult result, {
    required int resumeIndex,
    required List<String> expectedWords,
  }) {
    final matchedCount = _matchedMemorizationPrefixCount(result);
    final absoluteMatched = resumeIndex + matchedCount;
    if (absoluteMatched > memorizationRevealedCount) {
      memorizationRevealedCount = absoluteMatched;
    }

    final firstIssue = result.words.firstWhere(
      (word) => word.isExtraSpokenWord || !word.isCorrect,
      orElse: () =>
          const WordFeedback(word: '', evaluation: WordEvaluation.correct),
    );

    if (firstIssue.isExtraSpokenWord || !firstIssue.isCorrect) {
      final absoluteMistake = resumeIndex + matchedCount;
      memorizationMistakeIndex = absoluteMistake;
      if (absoluteMistake < _memorizationExpectedWords.length &&
          !firstIssue.isExtraSpokenWord) {
        memorizationExpectedWord = _memorizationExpectedWords[absoluteMistake];
      } else if (matchedCount < expectedWords.length) {
        memorizationExpectedWord = expectedWords[matchedCount];
      } else {
        memorizationExpectedWord = null;
      }
      memorizationSpokenWord = firstIssue.spokenWord;
      _isMemorizationListening = false;
      unawaited(_speechRecognitionService.stopListening());
      unawaited(_persistMemorizationCheckpoint());
      return;
    }

    if (memorizationRevealedCount >= _memorizationExpectedWords.length &&
        _memorizationExpectedWords.isNotEmpty) {
      memorizationCompleted = true;
      _isMemorizationListening = false;
      unawaited(_speechRecognitionService.stopListening());
      unawaited(_clearMemorizationCheckpointForCurrentSurah());
      unawaited(_recordRecentSession(PracticeSessionType.memorization));
      return;
    }

    unawaited(_persistMemorizationCheckpoint());
  }

  Future<void> playAyah(Ayah ayah) async {
    if (_isAutoReading) {
      await stopAutoReading();
    }
    globalError = null;
    _setPlaybackAyah(ayah);
    notifyListeners();

    try {
      await _audioPlayerService.playAyah(ayah.audioUrl);
    } catch (error) {
      _clearPlaybackTracking();
      globalError = 'Audio playback failed: $error';
      notifyListeners();
    }
  }

  Future<void> pauseAudioPlayback() async {
    if (_playingAyahNumber == null || !_isAudioPlaying) {
      return;
    }
    globalError = null;
    try {
      await _audioPlayerService.pause();
    } catch (error) {
      globalError = 'Audio playback failed: $error';
      notifyListeners();
    }
  }

  Future<void> resumeAudioPlayback() async {
    if (_playingAyahNumber == null || _isAudioPlaying) {
      return;
    }
    globalError = null;
    try {
      await _audioPlayerService.resume();
    } catch (error) {
      globalError = 'Audio playback failed: $error';
      notifyListeners();
    }
  }

  Future<void> toggleCurrentPlayback() async {
    if (_playingAyahNumber == null) {
      return;
    }
    if (_isAudioPlaying) {
      await pauseAudioPlayback();
    } else {
      await resumeAudioPlayback();
    }
  }

  Future<void> toggleReading(Ayah ayah) async {
    if (_isAutoReading) {
      await stopAutoReading();
    }
    globalError = null;
    await _stopAudioPlayback();

    if (isListening && practicingAyahNumber == ayah.ayahNumber) {
      await _speechRecognitionService.stopListening();
      await _stopRecordingSession();
      _schedulePendingEvaluation();
      notifyListeners();
      return;
    }

    if (isListening) {
      await _speechRecognitionService.stopListening();
      await _stopRecordingSession();
      _schedulePendingEvaluation();
    }

    _pendingEvaluationTimer?.cancel();
    practicingAyahNumber = ayah.ayahNumber;
    _pendingEvaluationAyahNumber = ayah.ayahNumber;
    recognizedText = '';
    rawRecognizedText = '';
    displayRecognizedText = '';
    _lastSpeechError = null;
    _lastAutoCorrectionCount = 0;
    _lastRecordingFilePath = null;
    _feedbackByAyah.remove(ayah.ayahNumber);

    final recordingStarted = await _startRecordingSession();
    if (!recordingStarted) {
      _feedbackByAyah[ayah.ayahNumber] =
          'Audio recording could not start. Tajweed enhancement may be limited.';
    }
    notifyListeners();

    final started = await _speechRecognitionService.startListening(
      onResult: (text, isFinal) {
        rawRecognizedText = text;
        if (comparisonMode == ComparisonMode.tajweed) {
          recognizedText = text;
          displayRecognizedText = _buildTajweedDisplayText(
            expectedAyah: ayah.arabicText,
            sourceText: text,
          );
          _lastAutoCorrectionCount = 0;
        } else {
          final processed = _postProcessor.process(
            expectedAyah: ayah.arabicText,
            rawRecognizedText: text,
          );
          recognizedText = processed.correctedText;
          displayRecognizedText = processed.correctedText;
          _lastAutoCorrectionCount = processed.correctedTokenCount;
        }
        notifyListeners();
        if (isFinal) {
          _pendingEvaluationTimer?.cancel();
          unawaited(_stopRecordingSession());
          unawaited(_evaluatePendingAyah());
        }
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          unawaited(_stopRecordingSession());
          _schedulePendingEvaluation();
        }
      },
      onError: (error) {
        _lastSpeechError = error;
        _feedbackByAyah[ayah.ayahNumber] = 'Speech error: $error';
        notifyListeners();
      },
    );

    if (!started) {
      await _stopRecordingSession();
      if (_speechRecognitionService.isArabicLocaleMissing) {
        needsArabicSpeechInstall = true;
        _feedbackByAyah[ayah.ayahNumber] =
            'Arabic speech recognition is not installed.';
      } else {
        _feedbackByAyah[ayah.ayahNumber] =
            'Microphone or speech recognition is not available.';
      }
      notifyListeners();
    }
  }

  Future<void> toggleAutoReading(Ayah startAyah) async {
    globalError = null;

    if (_isAutoReading && _autoReadingStartAyahNumber == startAyah.ayahNumber) {
      await stopAutoReading();
      return;
    }

    await stopAutoReading();
    await _startAutoReading(startAyah);
  }

  Future<void> stopAutoReading() async {
    if (!_isAutoReading) {
      return;
    }

    _autoReadingSessionId++;
    _isAutoReading = false;
    _autoReadingStartAyahNumber = null;
    practicingAyahNumber = null;
    _clearPlaybackTracking();
    notifyListeners();

    try {
      await _audioPlayerService.stop();
    } catch (_) {
      // Ignore stop failures.
    }
  }

  Future<void> _startAutoReading(Ayah startAyah) async {
    final startIndex = ayahs.indexWhere(
      (item) => item.ayahNumber == startAyah.ayahNumber,
    );
    if (startIndex < 0) {
      return;
    }

    if (isListening) {
      await _speechRecognitionService.stopListening();
      await _stopRecordingSession();
    }

    _pendingEvaluationTimer?.cancel();
    _pendingEvaluationAyahNumber = null;

    recognizedText = '';
    rawRecognizedText = '';
    displayRecognizedText = '';
    _lastSpeechError = null;
    _lastAutoCorrectionCount = 0;
    _lastRecordingFilePath = null;

    _autoReadingSessionId++;
    final sessionId = _autoReadingSessionId;
    _isAutoReading = true;
    _autoReadingStartAyahNumber = startAyah.ayahNumber;
    notifyListeners();

    for (var index = startIndex; index < ayahs.length; index++) {
      if (!_isAutoReading || _autoReadingSessionId != sessionId) {
        break;
      }

      final ayah = ayahs[index];
      practicingAyahNumber = ayah.ayahNumber;
      _setPlaybackAyah(ayah);
      notifyListeners();

      try {
        await _audioPlayerService.playAyah(ayah.audioUrl);
      } catch (_) {
        _clearPlaybackTracking();
        globalError = 'Audio playback failed for this ayah.';
        break;
      }

      await _audioPlayerService.waitForCompletionOrStop();
    }

    if (_autoReadingSessionId == sessionId) {
      _isAutoReading = false;
      _autoReadingStartAyahNumber = null;
      practicingAyahNumber = null;
      _clearPlaybackTracking();
      notifyListeners();
    }
  }

  Future<bool> _startRecordingSession() async {
    try {
      _recordingStartedAt = DateTime.now();
      _lastRecordingDuration = null;
      return await _recorderService.start();
    } catch (_) {
      _recordingStartedAt = null;
      _lastRecordingDuration = null;
      return false;
    }
  }

  Future<void> _stopRecordingSession() async {
    if (_lastRecordingFilePath != null) {
      return;
    }

    try {
      _lastRecordingFilePath = await _recorderService.stop();
      if (_recordingStartedAt != null) {
        _lastRecordingDuration = DateTime.now().difference(
          _recordingStartedAt!,
        );
      }
    } catch (_) {
      _lastRecordingFilePath = null;
      _lastRecordingDuration = null;
    } finally {
      _recordingStartedAt = null;
    }
  }

  void _schedulePendingEvaluation() {
    _pendingEvaluationTimer?.cancel();
    _pendingEvaluationTimer = Timer(const Duration(milliseconds: 1200), () {
      unawaited(_evaluatePendingAyah());
    });
  }

  Future<void> _evaluatePendingAyah() async {
    if (_evaluating) {
      return;
    }

    final pendingAyahNumber = _pendingEvaluationAyahNumber;
    if (pendingAyahNumber == null) {
      return;
    }

    Ayah? ayah;
    for (final item in ayahs) {
      if (item.ayahNumber == pendingAyahNumber) {
        ayah = item;
        break;
      }
    }
    if (ayah == null) {
      return;
    }

    await _stopRecordingSession();

    _evaluating = true;
    _pendingEvaluationAyahNumber = null;

    final result = _comparisonService.compare(
      expectedAyah: ayah.arabicText,
      spokenAyah: recognizedText,
      mode: comparisonMode,
    );
    final metrics = _metricsSummary(result);

    _comparisonByAyah[ayah.ayahNumber] = result;
    _coachByAyah.remove(ayah.ayahNumber);
    unawaited(
      _recordRecentSession(
        PracticeSessionType.recitation,
        ayahNumber: ayah.ayahNumber,
        mode: comparisonMode.name,
      ),
    );
    final canCoach =
        recognizedText.trim().isNotEmpty && _containsArabic(recognizedText);
    if (canCoach) {
      await _updateWeakWordTracking(result);
      final coach = _localCoachService.analyze(
        expectedAyah: ayah.arabicText,
        spokenAyah: recognizedText,
        comparisonResult: result,
        weakWordCounts: _weakWordCounts,
        recordingDuration: _lastRecordingDuration,
      );
      if (coach.hasContent) {
        _coachByAyah[ayah.ayahNumber] = coach;
      }
    }

    if (recognizedText.trim().isEmpty) {
      if (_lastSpeechError != null && _lastSpeechError!.trim().isNotEmpty) {
        _feedbackByAyah[ayah.ayahNumber] = 'Speech error: $_lastSpeechError';
      } else {
        _feedbackByAyah[ayah.ayahNumber] =
            'No speech detected. Check microphone permission and Arabic speech language.';
      }
    } else if (!_containsArabic(recognizedText)) {
      _feedbackByAyah[ayah.ayahNumber] =
          'Speech recognized, but not in Arabic. Change speech recognition language to Arabic.';
    } else if (comparisonMode == ComparisonMode.tajweed) {
      if (result.isPerfect) {
        _feedbackByAyah[ayah.ayahNumber] =
            'Excellent tajweed recitation. $metrics';
      } else if (result.tajweedValidationLimited) {
        _feedbackByAyah[ayah.ayahNumber] =
            'Device speech text does not include enough harakat, so tajweed checking is limited on the frontend. '
            'Playing correct recitation now. $metrics';
        await playAyah(ayah);
      } else if (result.hasOnlyTajweedMistakes) {
        _feedbackByAyah[ayah.ayahNumber] =
            'Harakat/tajweed mismatch detected. Playing correct recitation now. $metrics';
        await playAyah(ayah);
      } else {
        _feedbackByAyah[ayah.ayahNumber] =
            'Recitation differs from the ayah/tajweed target. Playing correct recitation now. $metrics';
        await playAyah(ayah);
      }
    } else if (result.isNearPerfect) {
      _feedbackByAyah[ayah.ayahNumber] =
          'Very close recitation. Minor differences detected. $metrics';
    } else if (result.isPerfect) {
      _feedbackByAyah[ayah.ayahNumber] = _lastAutoCorrectionCount > 0
          ? 'Excellent recitation. Qur\'an-aware correction adjusted $_lastAutoCorrectionCount word(s). $metrics'
          : 'Excellent recitation. Continue. $metrics';
    } else {
      _feedbackByAyah[ayah.ayahNumber] = _lastAutoCorrectionCount > 0
          ? 'Some words need correction. Qur\'an-aware correction adjusted $_lastAutoCorrectionCount word(s). '
                'The correct recitation is now playing. $metrics'
          : 'Some words need correction. The correct recitation is now playing. $metrics';
      await playAyah(ayah);
    }

    _evaluating = false;
    notifyListeners();
  }

  String _buildTajweedDisplayText({
    required String expectedAyah,
    required String sourceText,
  }) {
    final expectedWords = _splitWords(expectedAyah);
    final spokenWords = _splitWords(sourceText);

    if (expectedWords.isEmpty || spokenWords.isEmpty) {
      return '';
    }

    final processed = _postProcessor.process(
      expectedAyah: expectedAyah,
      rawRecognizedText: sourceText,
    );
    final snappedWords = _splitWords(processed.correctedText);
    if (snappedWords.isNotEmpty && _containsHarakat(processed.correctedText)) {
      return snappedWords.take(spokenWords.length).join(' ');
    }

    final count = spokenWords.length <= expectedWords.length
        ? spokenWords.length
        : expectedWords.length;
    return expectedWords.take(count).join(' ');
  }

  bool _containsArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  List<String> _splitWords(String text) {
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .map((word) => word.trim())
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
  }

  bool _containsHarakat(String text) {
    return RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]').hasMatch(text);
  }

  String _metricsSummary(ComparisonResult result) {
    final score = (result.similarityScore * 100).round();
    final wer = (result.wordErrorRate * 100).round();
    final cer = (result.charErrorRate * 100).round();
    final wcer = (result.weightedCharErrorRate * 100).round();
    if (result.mode == ComparisonMode.tajweed) {
      final tajweed = (result.tajweedScore * 100).round();
      return 'Score $score% • Tajweed $tajweed% • WER $wer% • CER $cer% • Weighted CER $wcer%';
    }
    return 'Score $score% • WER $wer% • CER $cer% • Weighted CER $wcer%';
  }

  Future<void> toggleFavoriteSurah(int surahNumber) async {
    if (_favoriteSurahNumbers.contains(surahNumber)) {
      _favoriteSurahNumbers.remove(surahNumber);
    } else {
      _favoriteSurahNumbers.add(surahNumber);
    }
    notifyListeners();
    await _progressService.saveFavoriteSurahs(_favoriteSurahNumbers);
  }

  Future<void> _updateWeakWordTracking(ComparisonResult result) async {
    final weakWordKeys = result.words
        .where((word) => !word.isCorrect && !word.isExtraSpokenWord)
        .map((word) => LocalTajweedCoachService.normalizeWeakWordKey(word.word))
        .where((word) => word.isNotEmpty)
        .toSet();
    if (weakWordKeys.isEmpty) {
      return;
    }
    _weakWordCounts = await _progressService.incrementWeakWords(weakWordKeys);
  }

  Future<void> markLastReadAyah(Ayah ayah) async {
    _recordLastRead(ayah);
    notifyListeners();
  }

  bool isPlayingAudioForAyah(int ayahNumber) =>
      _playingAyahNumber == ayahNumber && _isAudioPlaying;

  int? highlightedPlaybackWordIndexForAyah(int ayahNumber) =>
      _playingAyahNumber == ayahNumber ? _highlightedPlaybackWordIndex : null;

  void _recordLastRead(Ayah ayah) {
    _lastReadProgress = LastReadProgress(
      surahNumber: ayah.surahNumber,
      ayahNumber: ayah.ayahNumber,
      updatedAt: DateTime.now(),
    );
    unawaited(_progressService.saveLastRead(_lastReadProgress!));
  }

  Future<void> _persistMemorizationCheckpoint() async {
    final surahNumber = memorizationSurahNumber;
    if (surahNumber == null) {
      return;
    }
    if (memorizationRevealedCount <= 0) {
      await _clearMemorizationCheckpointForCurrentSurah();
      return;
    }

    final checkpoint = MemorizationCheckpoint(
      surahNumber: surahNumber,
      revealedWords: memorizationRevealedCount,
      updatedAt: DateTime.now(),
    );
    _memorizationCheckpoints = {
      ..._memorizationCheckpoints,
      surahNumber: checkpoint,
    };
    notifyListeners();
    await _progressService.saveMemorizationCheckpoint(checkpoint);
  }

  Future<void> _clearMemorizationCheckpointForCurrentSurah() async {
    final surahNumber = memorizationSurahNumber;
    if (surahNumber == null ||
        !_memorizationCheckpoints.containsKey(surahNumber)) {
      return;
    }
    _memorizationCheckpoints = Map<int, MemorizationCheckpoint>.from(
      _memorizationCheckpoints,
    )..remove(surahNumber);
    notifyListeners();
    await _progressService.clearMemorizationCheckpoint(surahNumber);
  }

  Future<void> _recordRecentSession(
    PracticeSessionType type, {
    int? ayahNumber,
    String? mode,
  }) async {
    final surahNumber = type == PracticeSessionType.memorization
        ? memorizationSurahNumber
        : (ayahNumber == null ? null : ayahs.first.surahNumber);
    if (surahNumber == null) {
      return;
    }

    final record = PracticeSessionRecord(
      type: type,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      mode: mode,
      memorizationWordIndex: type == PracticeSessionType.memorization
          ? memorizationRevealedCount
          : null,
      timestamp: DateTime.now(),
    );

    _recentSessions = [
      record,
      ..._recentSessions.where(
        (entry) =>
            !(entry.type == record.type &&
                entry.surahNumber == record.surahNumber &&
                entry.ayahNumber == record.ayahNumber &&
                entry.memorizationWordIndex == record.memorizationWordIndex &&
                entry.mode == record.mode),
      ),
    ].take(10).toList(growable: false);
    notifyListeners();
    await _progressService.addRecentSession(record);
  }

  void _cancelAutoReadingForDispose() {
    _autoReadingSessionId++;
    _isAutoReading = false;
    _autoReadingStartAyahNumber = null;
    practicingAyahNumber = null;
    _clearPlaybackTracking();
    unawaited(_audioPlayerService.stop());
  }

  Future<void> _stopAudioPlayback() async {
    if (_playingAyahNumber == null && !_isAudioPlaying) {
      return;
    }
    _clearPlaybackTracking();
    try {
      await _audioPlayerService.stop();
    } catch (_) {
      // Ignore audio stop failures before starting another interaction.
    }
  }

  void _setPlaybackAyah(Ayah ayah) {
    _playingAyahNumber = ayah.ayahNumber;
    _highlightedPlaybackWordIndex = _splitWords(ayah.arabicText).isEmpty
        ? null
        : 0;
    _isAudioPlaying = true;
  }

  void _clearPlaybackTracking() {
    _playingAyahNumber = null;
    _highlightedPlaybackWordIndex = null;
    _isAudioPlaying = false;
  }

  void _handleAudioPlaybackState(AudioPlaybackState state) {
    final ayahNumber = _playingAyahNumber;
    if (ayahNumber == null) {
      return;
    }

    Ayah? ayah;
    for (final item in ayahs) {
      if (item.ayahNumber == ayahNumber) {
        ayah = item;
        break;
      }
    }
    if (ayah == null) {
      return;
    }

    final words = _splitWords(ayah.arabicText);
    final previousIsPlaying = _isAudioPlaying;
    final previousIndex = _highlightedPlaybackWordIndex;
    _isAudioPlaying = state.isPlaying;

    if (words.isEmpty) {
      _highlightedPlaybackWordIndex = null;
    } else if (state.isCompleted) {
      _highlightedPlaybackWordIndex = words.length - 1;
    } else if (state.duration == null || state.duration == Duration.zero) {
      _highlightedPlaybackWordIndex = 0;
    } else {
      final totalMs = state.duration!.inMilliseconds;
      final positionMs = state.position.inMilliseconds.clamp(0, totalMs);
      final ratio = totalMs == 0 ? 0 : positionMs / totalMs;
      final index = (ratio * words.length).floor().clamp(0, words.length - 1);
      _highlightedPlaybackWordIndex = index;
    }

    if (!state.isPlaying && state.isCompleted && !_isAutoReading) {
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        if (_playingAyahNumber == ayahNumber &&
            !_isAutoReading &&
            !isListening) {
          _clearPlaybackTracking();
          notifyListeners();
        }
      });
    }

    if (previousIsPlaying != _isAudioPlaying ||
        previousIndex != _highlightedPlaybackWordIndex) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _pendingEvaluationTimer?.cancel();
    unawaited(_audioPlaybackSubscription?.cancel());
    _cancelAutoReadingForDispose();
    _audioPlayerService.dispose();
    _speechRecognitionService.dispose();
    unawaited(_recorderService.dispose());
    unawaited(_repository.dispose());
    super.dispose();
  }
}

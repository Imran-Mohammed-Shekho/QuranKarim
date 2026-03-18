import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

class SpeechRecognitionService {
  final SpeechToText _speechToText = SpeechToText();

  bool _initialized = false;
  String? _arabicLocaleId;
  bool _arabicLocaleMissing = false;
  void Function(String status)? _statusCallback;
  void Function(String error)? _errorCallback;

  bool get isListening => _speechToText.isListening;
  String? get arabicLocaleId => _arabicLocaleId;
  bool get isArabicLocaleMissing => _arabicLocaleMissing;

  Future<bool> initialize() async {
    if (_initialized) {
      return true;
    }

    _initialized = await _speechToText.initialize(
      onStatus: (status) => _statusCallback?.call(status),
      onError: (SpeechRecognitionError error) =>
          _errorCallback?.call(error.errorMsg),
    );
    if (!_initialized) {
      return false;
    }

    _arabicLocaleId = null;
    _arabicLocaleMissing = false;

    final locales = await _speechToText.locales();
    final arabicLocales = locales
        .where((locale) => locale.localeId.toLowerCase().startsWith('ar'))
        .toList(growable: false);

    if (arabicLocales.isNotEmpty) {
      const preferred = ['ar-IQ', 'ar-SA', 'ar-EG', 'ar-AE'];
      for (final localeId in preferred) {
        final match = arabicLocales.where((l) => l.localeId == localeId);
        if (match.isNotEmpty) {
          _arabicLocaleId = match.first.localeId;
          break;
        }
      }
      _arabicLocaleId ??= arabicLocales.first.localeId;
    } else {
      _arabicLocaleMissing = true;
    }

    return true;
  }

  Future<bool> startListening({
    required void Function(String text, bool isFinal) onResult,
    required void Function(String status) onStatus,
    void Function(String error)? onError,
    Duration pauseFor = const Duration(seconds: 5),
    Duration listenFor = const Duration(seconds: 45),
  }) async {
    _statusCallback = onStatus;
    _errorCallback = onError;

    final ready = await initialize();
    if (!ready) {
      return false;
    }

    if (_arabicLocaleId == null) {
      onError?.call(
        'Arabic speech recognition is not installed. '
        'Please install Arabic language from Google Speech Services.',
      );
      return false;
    }

    await _speechToText.listen(
      localeId: _arabicLocaleId,
      pauseFor: pauseFor,
      listenFor: listenFor,
      onResult: (result) =>
          onResult(result.recognizedWords, result.finalResult),
      onSoundLevelChange: (_) {},
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        partialResults: true,
        onDevice: false,
        cancelOnError: true,
      ),
    );

    return true;
  }

  Future<void> stopListening() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
  }

  void dispose() {
    _speechToText.stop();
  }
}

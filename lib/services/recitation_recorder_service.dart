import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class RecitationRecorderService {
  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;

  Future<bool> start() async {
    if (_isRecording) {
      return true;
    }

    final allowed = await _recorder.hasPermission();
    if (!allowed) {
      return false;
    }

    final tempDir = await getTemporaryDirectory();
    final filePath = path.join(
      tempDir.path,
      'recitation_${DateTime.now().millisecondsSinceEpoch}.wav',
    );

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
      ),
      path: filePath,
    );

    _isRecording = true;
    return true;
  }

  Future<String?> stop() async {
    if (!_isRecording) {
      return null;
    }

    final filePath = await _recorder.stop();
    _isRecording = false;
    return filePath;
  }

  Future<void> dispose() async {
    if (_isRecording) {
      await _recorder.stop();
      _isRecording = false;
    }

    await _recorder.dispose();
  }
}

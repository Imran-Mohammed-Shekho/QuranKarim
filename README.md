# Qibla Quran (Flutter)

A Flutter mobile app for Quran recitation practice:
- Browse all Surahs
- Open Ayahs for a selected Surah
- Listen to correct recitation audio (stream + cache)
- Recite using microphone and Arabic speech recognition
- Apply Qur'an-aware post-processing to fix common STT spelling drift
- See word-level correctness feedback
- Show stronger accuracy metrics (`WER`, `CER`, weighted `CER`, similarity score)
- Replay correct recitation after mistakes

## Tech Stack

- `provider` for state management
- `sqflite` for local Quran data cache
- `http` for Quran API requests
- `record` + `path_provider` for recitation audio capture
- `just_audio` + `audio_session` for playback/streaming/caching
- `speech_to_text` for Arabic speech recognition

## Data Source

- Surah metadata + Ayah text: `https://api.alquran.cloud/v1`
- Audio CDN: `https://everyayah.com/data/Alafasy_128kbps/`

Ayah text and metadata are cached in SQLite. Audio is streamed and cached through `LockCachingAudioSource` in `just_audio`.

## Project Structure

```text
lib/
  core/config/app_config.dart
  core/theme/app_theme.dart
  data/
    models/
      ayah.dart
      surah.dart
    repositories/
      quran_repository.dart
    services/
      quran_api_service.dart
      quran_database.dart
  services/
    audio_player_service.dart
    ayah_comparison_service.dart
    quran_aware_post_processor.dart
    recitation_recorder_service.dart
    remote_tajweed_service.dart
    speech_recognition_service.dart
  state/
    quran_practice_controller.dart
  ui/
    screens/
      surah_list_screen.dart
      ayah_reading_screen.dart
    widgets/
      ayah_tile.dart
      feedback_words_view.dart
  main.dart
```

## How It Works

1. On startup, app loads Surahs from SQLite; if empty, fetches from API and stores locally.
2. Opening a Surah loads Ayahs from SQLite; if missing, fetches and caches.
3. `🔊` button streams recitation audio and caches playback data.
4. `🎤` button starts Arabic speech recognition.
5. Raw STT text is post-processed with Qur'an-aware snapping to Ayah words.
6. In `Tajweed` mode, app records recitation audio and can call an optional remote API for diacritized transcription.
7. Spoken text is compared to expected Ayah using normalized word matching + LCS.
8. Correct words are highlighted green, text mismatches red, tajweed mismatches orange.
9. Accuracy metrics are computed from recitation text:
   - WER (word error rate)
   - CER (character error rate)
   - Weighted CER (Arabic-confusion-aware)
   - Similarity score
10. If mistakes exist, the app plays correct recitation automatically.

Tajweed mode note:
- In `Tajweed` mode, Qur'an-aware auto-correction is disabled intentionally so harakat mistakes are not hidden.
- Most mobile speech engines do not output harakat. Configure a remote tajweed API for stronger harakat detection:
  ```bash
  flutter run --dart-define=TAJWEED_API_URL=https://your-api/transcribe
  ```
- Expected API response JSON (any one field):
  - `text_with_harakat`
  - `recognized_text_with_harakat`
  - `text`
  - `recognized_text`

## Run Instructions

1. Install dependencies:
   ```bash
   flutter pub get
   ```
2. Run app:
   ```bash
   flutter run
   ```

## Platform Notes

### Android
- `RECORD_AUDIO` permission is enabled in:
  - `android/app/src/main/AndroidManifest.xml`
- `INTERNET` permission is enabled for API/audio streaming.

### iOS
- Usage descriptions added in:
  - `ios/Runner/Info.plist`
  - `NSMicrophoneUsageDescription`
  - `NSSpeechRecognitionUsageDescription`

## Optional Future Extensions

- Progress tracking per Surah/Ayah
- Memorization mode
- Word-by-word listening/training
- Multiple reciters
- Offline Surah download packs

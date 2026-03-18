class AppConfig {
  const AppConfig._();

  /// Optional remote endpoint for tajweed-aware transcription.
  ///
  /// Example:
  /// flutter run --dart-define=TAJWEED_API_URL=https://your-api/transcribe
  static const String tajweedApiUrl = String.fromEnvironment('TAJWEED_API_URL');
}

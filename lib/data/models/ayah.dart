class Ayah {
  const Ayah({
    required this.surahNumber,
    required this.ayahNumber,
    required this.arabicText,
    this.kurdishText,
    required this.audioUrl,
  });

  final int surahNumber;
  final int ayahNumber;
  final String arabicText;
  final String? kurdishText;
  final String audioUrl;

  factory Ayah.fromDb(Map<String, Object?> row) {
    return Ayah(
      surahNumber: row['surah_number'] as int,
      ayahNumber: row['ayah_number'] as int,
      arabicText: row['text_ar'] as String,
      kurdishText: row['translation_ku'] as String?,
      audioUrl: row['audio_url'] as String,
    );
  }

  factory Ayah.fromApi({
    required int surahNumber,
    required int ayahNumber,
    required String arabicText,
    String? kurdishText,
    required String audioUrl,
  }) {
    return Ayah(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      arabicText: arabicText,
      kurdishText: kurdishText,
      audioUrl: audioUrl,
    );
  }

  Map<String, Object?> toDb() {
    return {
      'surah_number': surahNumber,
      'ayah_number': ayahNumber,
      'text_ar': arabicText,
      'translation_ku': kurdishText,
      'audio_url': audioUrl,
    };
  }

  Ayah copyWith({String? arabicText, String? kurdishText, String? audioUrl}) {
    return Ayah(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      arabicText: arabicText ?? this.arabicText,
      kurdishText: kurdishText ?? this.kurdishText,
      audioUrl: audioUrl ?? this.audioUrl,
    );
  }
}

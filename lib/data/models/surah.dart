class Surah {
  const Surah({
    required this.number,
    required this.nameArabic,
    required this.nameEnglish,
    required this.ayahCount,
  });

  final int number;
  final String nameArabic;
  final String nameEnglish;
  final int ayahCount;

  factory Surah.fromApi(Map<String, dynamic> json) {
    return Surah(
      number: json['number'] as int,
      nameArabic: (json['name'] as String?) ?? '',
      nameEnglish: (json['englishName'] as String?) ?? '',
      ayahCount: (json['numberOfAyahs'] as int?) ?? 0,
    );
  }

  factory Surah.fromDb(Map<String, Object?> row) {
    return Surah(
      number: row['number'] as int,
      nameArabic: row['name_ar'] as String,
      nameEnglish: row['name_en'] as String,
      ayahCount: row['ayah_count'] as int,
    );
  }

  Map<String, Object?> toDb() {
    return {
      'number': number,
      'name_ar': nameArabic,
      'name_en': nameEnglish,
      'ayah_count': ayahCount,
    };
  }
}

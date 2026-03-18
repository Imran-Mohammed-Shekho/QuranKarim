class GodNamesCollection {
  const GodNamesCollection({
    required this.standalone,
    required this.meta,
    required this.names,
  });

  final GodNameStandalone standalone;
  final GodNamesMeta meta;
  final List<GodNameEntry> names;

  factory GodNamesCollection.fromJson(Map<String, dynamic> json) {
    final namesJson = json['names'] as List<dynamic>? ?? const [];
    return GodNamesCollection(
      standalone: GodNameStandalone.fromJson(
        json['standalone'] as Map<String, dynamic>? ?? const {},
      ),
      meta: GodNamesMeta.fromJson(
        json['meta'] as Map<String, dynamic>? ?? const {},
      ),
      names: namesJson
          .whereType<Map<String, dynamic>>()
          .map(GodNameEntry.fromJson)
          .toList(growable: false),
    );
  }
}

class GodNameStandalone {
  const GodNameStandalone({
    required this.arabic,
    required this.kurdish,
    required this.english,
  });

  final String arabic;
  final String kurdish;
  final String english;

  factory GodNameStandalone.fromJson(Map<String, dynamic> json) {
    return GodNameStandalone(
      arabic: (json['arabic'] as String? ?? '').trim(),
      kurdish: (json['kurdish'] as String? ?? '').trim(),
      english: (json['english'] as String? ?? '').trim(),
    );
  }
}

class GodNamesMeta {
  const GodNamesMeta({
    required this.total,
    required this.titleEnglish,
    required this.titleArabic,
    required this.titleKurdish,
  });

  final int total;
  final String titleEnglish;
  final String titleArabic;
  final String titleKurdish;

  factory GodNamesMeta.fromJson(Map<String, dynamic> json) {
    return GodNamesMeta(
      total: (json['total'] as num?)?.toInt() ?? 0,
      titleEnglish: (json['title_en'] as String? ?? '').trim(),
      titleArabic: (json['title_ar'] as String? ?? '').trim(),
      titleKurdish: (json['title_ku'] as String? ?? '').trim(),
    );
  }
}

class GodNameEntry {
  const GodNameEntry({
    required this.id,
    required this.arabic,
    required this.english,
    required this.kurdish,
    this.audioPath,
  });

  final int id;
  final GodNameArabic arabic;
  final GodNameEnglish english;
  final GodNameKurdish kurdish;
  final String? audioPath;

  factory GodNameEntry.fromJson(Map<String, dynamic> json) {
    return GodNameEntry(
      id: (json['id'] as num?)?.toInt() ?? 0,
      arabic: GodNameArabic.fromJson(
        json['arabic'] as Map<String, dynamic>? ?? const {},
      ),
      english: GodNameEnglish.fromJson(
        json['english'] as Map<String, dynamic>? ?? const {},
      ),
      kurdish: GodNameKurdish.fromJson(
        json['kurdish'] as Map<String, dynamic>? ?? const {},
      ),
      audioPath: (json['audio'] as String?)?.trim(),
    );
  }
}

class GodNameArabic {
  const GodNameArabic({
    required this.name,
    required this.plain,
    required this.meaning,
  });

  final String name;
  final String plain;
  final String meaning;

  factory GodNameArabic.fromJson(Map<String, dynamic> json) {
    return GodNameArabic(
      name: (json['name'] as String? ?? '').trim(),
      plain: (json['plain'] as String? ?? '').trim(),
      meaning: (json['meaning'] as String? ?? '').trim(),
    );
  }
}

class GodNameEnglish {
  const GodNameEnglish({
    required this.transliteration,
    required this.translation,
    required this.meaning,
  });

  final String transliteration;
  final String translation;
  final String meaning;

  factory GodNameEnglish.fromJson(Map<String, dynamic> json) {
    return GodNameEnglish(
      transliteration: (json['transliteration'] as String? ?? '').trim(),
      translation: (json['translation'] as String? ?? '').trim(),
      meaning: (json['meaning'] as String? ?? '').trim(),
    );
  }
}

class GodNameKurdish {
  const GodNameKurdish({required this.translation});

  final String translation;

  factory GodNameKurdish.fromJson(Map<String, dynamic> json) {
    return GodNameKurdish(
      translation: (json['translation'] as String? ?? '').trim(),
    );
  }
}

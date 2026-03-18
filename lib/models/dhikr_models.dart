import '../core/localization/app_strings.dart';

class LocalizedText {
  const LocalizedText({
    required this.english,
    required this.arabic,
    required this.kurdish,
  });

  final String english;
  final String arabic;
  final String kurdish;

  factory LocalizedText.fromJson(Map<String, dynamic> json) {
    return LocalizedText(
      english: (json['english'] as String? ?? json['en'] as String? ?? '')
          .trim(),
      arabic: (json['arabic'] as String? ?? json['ar'] as String? ?? '').trim(),
      kurdish: (json['kurdish'] as String? ?? json['ku'] as String? ?? '')
          .trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'english': english, 'arabic': arabic, 'kurdish': kurdish};
  }

  String forLanguage(AppLanguage language) {
    return switch (language) {
      AppLanguage.english => english,
      AppLanguage.arabic => arabic,
      AppLanguage.kurdish => kurdish,
    };
  }
}

class DhikrDefinition {
  const DhikrDefinition({
    required this.id,
    required this.arabicText,
    required this.transliteration,
    this.meaning,
    this.localizedMeaning,
    required this.defaultTarget,
    this.isCustom = false,
  });

  final String id;
  final String arabicText;
  final String transliteration;
  final String? meaning;
  final LocalizedText? localizedMeaning;
  final int defaultTarget;
  final bool isCustom;

  factory DhikrDefinition.fromJson(Map<String, dynamic> json) {
    return DhikrDefinition(
      id: (json['id'] as String?) ?? '',
      arabicText: (json['arabicText'] as String?) ?? '',
      transliteration: (json['transliteration'] as String?) ?? '',
      meaning: (json['meaning'] as String?)?.trim().isEmpty ?? true
          ? null
          : (json['meaning'] as String).trim(),
      localizedMeaning: json['localizedMeaning'] is Map<String, dynamic>
          ? LocalizedText.fromJson(
              json['localizedMeaning'] as Map<String, dynamic>,
            )
          : null,
      defaultTarget: (json['defaultTarget'] as num?)?.toInt() ?? 33,
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'arabicText': arabicText,
      'transliteration': transliteration,
      'meaning': meaning,
      'localizedMeaning': localizedMeaning?.toJson(),
      'defaultTarget': defaultTarget,
      'isCustom': isCustom,
    };
  }

  String labelFor(AppLanguage language) {
    if (language == AppLanguage.arabic) {
      return arabicText;
    }
    final normalizedTransliteration = transliteration.trim();
    return normalizedTransliteration.isEmpty
        ? arabicText
        : normalizedTransliteration;
  }

  String? meaningFor(AppLanguage language) {
    final translated = localizedMeaning?.forLanguage(language).trim();
    if (translated != null && translated.isNotEmpty) {
      return translated;
    }
    final fallback = meaning?.trim();
    return fallback == null || fallback.isEmpty ? null : fallback;
  }
}

class DhikrSetStep {
  const DhikrSetStep({required this.dhikrId, required this.targetCount});

  final String dhikrId;
  final int targetCount;

  factory DhikrSetStep.fromJson(Map<String, dynamic> json) {
    return DhikrSetStep(
      dhikrId: (json['dhikrId'] as String? ?? '').trim(),
      targetCount: (json['targetCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'dhikrId': dhikrId, 'targetCount': targetCount};
  }
}

class DhikrSetDefinition {
  const DhikrSetDefinition({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.steps,
    this.localizedTitle,
    this.localizedSubtitle,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<DhikrSetStep> steps;
  final LocalizedText? localizedTitle;
  final LocalizedText? localizedSubtitle;

  factory DhikrSetDefinition.fromJson(Map<String, dynamic> json) {
    final steps = (json['steps'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map>()
        .map((value) => value.cast<String, dynamic>())
        .map(DhikrSetStep.fromJson)
        .where((step) => step.dhikrId.isNotEmpty && step.targetCount > 0)
        .toList(growable: false);
    return DhikrSetDefinition(
      id: (json['id'] as String? ?? '').trim(),
      title: (json['title'] as String? ?? '').trim(),
      subtitle: (json['subtitle'] as String? ?? '').trim(),
      steps: steps,
      localizedTitle: json['localizedTitle'] is Map<String, dynamic>
          ? LocalizedText.fromJson(
              json['localizedTitle'] as Map<String, dynamic>,
            )
          : null,
      localizedSubtitle: json['localizedSubtitle'] is Map<String, dynamic>
          ? LocalizedText.fromJson(
              json['localizedSubtitle'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  String titleFor(AppLanguage language) {
    final translated = localizedTitle?.forLanguage(language).trim();
    return translated == null || translated.isEmpty ? title : translated;
  }

  String subtitleFor(AppLanguage language) {
    final translated = localizedSubtitle?.forLanguage(language).trim();
    return translated == null || translated.isEmpty ? subtitle : translated;
  }
}

class DhikrLibrary {
  const DhikrLibrary({required this.builtInDhikrs, required this.presetSets});

  final List<DhikrDefinition> builtInDhikrs;
  final List<DhikrSetDefinition> presetSets;

  factory DhikrLibrary.fromJson(Map<String, dynamic> json) {
    final builtInDhikrs =
        (json['builtInDhikrs'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map>()
            .map((value) => value.cast<String, dynamic>())
            .map(DhikrDefinition.fromJson)
            .where(
              (dhikr) => dhikr.id.isNotEmpty && dhikr.arabicText.isNotEmpty,
            )
            .toList(growable: false);
    final presetSets =
        (json['presetSets'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map>()
            .map((value) => value.cast<String, dynamic>())
            .map(DhikrSetDefinition.fromJson)
            .where((set) => set.id.isNotEmpty && set.steps.isNotEmpty)
            .toList(growable: false);
    return DhikrLibrary(builtInDhikrs: builtInDhikrs, presetSets: presetSets);
  }
}

class DhikrSetProgress {
  const DhikrSetProgress({
    required this.currentStepIndex,
    required this.stepCounts,
  });

  final int currentStepIndex;
  final List<int> stepCounts;

  factory DhikrSetProgress.empty(DhikrSetDefinition definition) {
    return DhikrSetProgress(
      currentStepIndex: 0,
      stepCounts: List<int>.filled(definition.steps.length, 0),
    );
  }

  factory DhikrSetProgress.fromJson(Map<String, dynamic> json) {
    final counts = (json['stepCounts'] as List<dynamic>? ?? const [])
        .map((value) => (value as num).toInt())
        .toList(growable: false);
    return DhikrSetProgress(
      currentStepIndex: (json['currentStepIndex'] as num?)?.toInt() ?? 0,
      stepCounts: counts,
    );
  }

  Map<String, dynamic> toJson() {
    return {'currentStepIndex': currentStepIndex, 'stepCounts': stepCounts};
  }

  DhikrSetProgress copyWith({int? currentStepIndex, List<int>? stepCounts}) {
    return DhikrSetProgress(
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      stepCounts: stepCounts ?? this.stepCounts,
    );
  }
}

enum DhikrTapOutcome { incremented, advanced, completed }

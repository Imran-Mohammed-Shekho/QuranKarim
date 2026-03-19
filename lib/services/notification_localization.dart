import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/localization/app_strings.dart';
import '../models/prayer_time_model.dart';

class LocalizedNotificationContent {
  const LocalizedNotificationContent({this.title, this.body});

  final String? title;
  final String? body;
}

class NotificationLocalization {
  static const String _languagePreferenceKey = 'app_language';

  static Future<AppLanguage> loadCurrentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return languageFromPreference(prefs.getString(_languagePreferenceKey));
  }

  static AppLanguage languageFromPreference(String? rawLanguage) {
    return AppLanguage.values.firstWhere(
      (value) => value.name == rawLanguage,
      orElse: () => AppLanguage.kurdish,
    );
  }

  static String prayerTitle(PrayerName prayer, AppLanguage language) {
    final strings = AppStrings(language);
    return strings.prayerNotificationTitle(strings.prayerLabel(prayer));
  }

  static String prayerBody(PrayerName prayer, AppLanguage language) {
    final strings = AppStrings(language);
    return strings.prayerNotificationBody(strings.prayerLabel(prayer));
  }

  static LocalizedNotificationContent resolvePushContent({
    required Map<String, dynamic> data,
    required AppLanguage language,
    String? fallbackTitle,
    String? fallbackBody,
  }) {
    return LocalizedNotificationContent(
      title: _resolveLocalizedValue(
        data: data,
        baseKey: 'title',
        language: language,
        fallbackValue: fallbackTitle,
      ),
      body: _resolveLocalizedValue(
        data: data,
        baseKey: 'body',
        language: language,
        fallbackValue: fallbackBody,
      ),
    );
  }

  static String? _resolveLocalizedValue({
    required Map<String, dynamic> data,
    required String baseKey,
    required AppLanguage language,
    String? fallbackValue,
  }) {
    final localizedMap = _readLocalizedMap(
      data['${baseKey}_localized'] ?? data['${baseKey}Localized'],
    );
    final localizedValue = _pickLocalizedMapValue(localizedMap, language);
    if (localizedValue != null) {
      return localizedValue;
    }

    for (final key in _preferredKeys(baseKey, language)) {
      final value = _readString(data[key]);
      if (value != null) {
        return value;
      }
    }

    final genericValue = _readString(data[baseKey]);
    if (genericValue != null) {
      return genericValue;
    }

    return _readString(fallbackValue);
  }

  static Iterable<String> _preferredKeys(
    String baseKey,
    AppLanguage language,
  ) sync* {
    final localizedKeys = switch (language) {
      AppLanguage.english => ['${baseKey}_en', '${baseKey}_english'],
      AppLanguage.arabic => ['${baseKey}_ar', '${baseKey}_arabic'],
      AppLanguage.kurdish => [
        '${baseKey}_ku',
        '${baseKey}_ckb',
        '${baseKey}_kurdish',
      ],
    };

    for (final key in localizedKeys) {
      yield key;
    }

    if (language != AppLanguage.english) {
      yield '${baseKey}_en';
      yield '${baseKey}_english';
    }
  }

  static Map<String, dynamic>? _readLocalizedMap(dynamic rawValue) {
    if (rawValue is Map<String, dynamic>) {
      return rawValue;
    }

    if (rawValue is String) {
      final trimmed = rawValue.trim();
      if (!trimmed.startsWith('{') || !trimmed.endsWith('}')) {
        return null;
      }

      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  static String? _pickLocalizedMapValue(
    Map<String, dynamic>? localizedMap,
    AppLanguage language,
  ) {
    if (localizedMap == null) {
      return null;
    }

    final keys = switch (language) {
      AppLanguage.english => const ['en', 'english'],
      AppLanguage.arabic => const ['ar', 'arabic'],
      AppLanguage.kurdish => const ['ku', 'ckb', 'kurdish'],
    };

    for (final key in keys) {
      final value = _readString(localizedMap[key]);
      if (value != null) {
        return value;
      }
    }

    if (language != AppLanguage.english) {
      return _readString(localizedMap['en']) ??
          _readString(localizedMap['english']);
    }

    return null;
  }

  static String? _readString(dynamic value) {
    if (value is! String) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

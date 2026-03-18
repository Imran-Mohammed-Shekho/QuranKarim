import 'package:flutter_test/flutter_test.dart';
import 'package:quran/core/localization/app_strings.dart';
import 'package:quran/models/prayer_time_model.dart';
import 'package:quran/services/notification_localization.dart';

void main() {
  group('NotificationLocalization.languageFromPreference', () {
    test('returns saved app language when it matches enum name', () {
      expect(
        NotificationLocalization.languageFromPreference('arabic'),
        AppLanguage.arabic,
      );
      expect(
        NotificationLocalization.languageFromPreference('kurdish'),
        AppLanguage.kurdish,
      );
    });

    test('falls back to english for missing or invalid values', () {
      expect(
        NotificationLocalization.languageFromPreference(null),
        AppLanguage.english,
      );
      expect(
        NotificationLocalization.languageFromPreference('unknown'),
        AppLanguage.english,
      );
    });
  });

  group('NotificationLocalization.resolvePushContent', () {
    test('prefers arabic payload fields for arabic users', () {
      final content = NotificationLocalization.resolvePushContent(
        data: const {
          'title': 'English title',
          'body': 'English body',
          'title_ar': 'عنوان عربي',
          'body_ar': 'نص عربي',
        },
        language: AppLanguage.arabic,
        fallbackTitle: 'Fallback title',
        fallbackBody: 'Fallback body',
      );

      expect(content.title, 'عنوان عربي');
      expect(content.body, 'نص عربي');
    });

    test('supports kurdish ckb payload keys', () {
      final content = NotificationLocalization.resolvePushContent(
        data: const {
          'title': 'English title',
          'body': 'English body',
          'title_ckb': 'سەردێڕی کوردی',
          'body_ckb': 'ناوەڕۆکی کوردی',
        },
        language: AppLanguage.kurdish,
      );

      expect(content.title, 'سەردێڕی کوردی');
      expect(content.body, 'ناوەڕۆکی کوردی');
    });

    test('supports localized json payload maps', () {
      final content = NotificationLocalization.resolvePushContent(
        data: const {
          'title_localized':
              '{"en":"English title","ar":"عنوان عربي","ku":"سەردێڕی کوردی"}',
          'body_localized':
              '{"en":"English body","ar":"نص عربي","ku":"ناوەڕۆکی کوردی"}',
        },
        language: AppLanguage.kurdish,
      );

      expect(content.title, 'سەردێڕی کوردی');
      expect(content.body, 'ناوەڕۆکی کوردی');
    });

    test('falls back to generic values when localized fields are missing', () {
      final content = NotificationLocalization.resolvePushContent(
        data: const {'title': 'English title', 'body': 'English body'},
        language: AppLanguage.kurdish,
        fallbackTitle: 'Fallback title',
        fallbackBody: 'Fallback body',
      );

      expect(content.title, 'English title');
      expect(content.body, 'English body');
    });
  });

  group('NotificationLocalization prayer text', () {
    test('builds localized prayer notification content', () {
      expect(
        NotificationLocalization.prayerTitle(
          PrayerName.fajr,
          AppLanguage.arabic,
        ),
        'موعد صلاة الفجر',
      );
      expect(
        NotificationLocalization.prayerBody(
          PrayerName.fajr,
          AppLanguage.kurdish,
        ),
        'کاتی نوێژی بەیانی هاتووە.',
      );
    });
  });
}

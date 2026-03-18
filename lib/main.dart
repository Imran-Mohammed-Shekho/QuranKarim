import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/quran_repository.dart';
import 'data/services/quran_api_service.dart';
import 'data/services/quran_asset_service.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';
import 'services/audio_player_service.dart';
import 'services/ayah_comparison_service.dart';
import 'services/god_names_service.dart';
import 'services/local_tajweed_coach_service.dart';
import 'services/prayer_time_service.dart';
import 'services/push_notification_service.dart';
import 'services/quran_progress_service.dart';
import 'services/quran_translation_cache_service.dart';
import 'services/quran_aware_post_processor.dart';
import 'services/recitation_recorder_service.dart';
import 'services/reciter_download_service.dart';
import 'services/speech_recognition_service.dart';
import 'state/app_settings_controller.dart';
import 'state/god_names_controller.dart';
import 'state/prayer_times_controller.dart';
import 'state/quran_practice_controller.dart';
import 'state/zikir_controller.dart';
import 'ui/screens/splash_screen.dart';

const _audioBaseUrl = String.fromEnvironment('AUDIO_BASE_URL');
const _defaultAudioBaseUrl =
    'https://cigavogfeiszxjnvvinm.supabase.co/storage/v1/object/public/hello';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    initializeDateFormatting('en'),
    initializeDateFormatting('ar'),
  ]);
  final notificationService = NotificationService();
  await notificationService.initialize();
  final pushNotificationService = PushNotificationService(
    notificationService: notificationService,
  );
  await pushNotificationService.initialize();
  runApp(
    QuranNoorApp(
      notificationService: notificationService,
      pushNotificationService: pushNotificationService,
    ),
  );
}

class QuranNoorApp extends StatelessWidget {
  const QuranNoorApp({
    super.key,
    required this.notificationService,
    required this.pushNotificationService,
  });

  final NotificationService notificationService;
  final PushNotificationService pushNotificationService;

  @override
  Widget build(BuildContext context) {
    final audioBaseUrl = _audioBaseUrl.isEmpty
        ? _defaultAudioBaseUrl
        : _audioBaseUrl;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppSettingsController>(
          create: (_) {
            final controller = AppSettingsController(
              reciterDownloadService: ReciterDownloadService(
                remoteAudioBaseUrl: audioBaseUrl,
              ),
            );
            unawaited(controller.bootstrap());
            return controller;
          },
        ),
        ChangeNotifierProxyProvider<
          AppSettingsController,
          QuranPracticeController
        >(
          create: (_) {
            final controller = QuranPracticeController(
              repository: QuranRepository(
                apiService: QuranApiService(),
                assetService: QuranAssetService(
                  remoteAudioBaseUrl: audioBaseUrl,
                ),
                translationCacheService: QuranTranslationCacheService(),
              ),
              audioPlayerService: AudioPlayerService(),
              speechRecognitionService: SpeechRecognitionService(),
              comparisonService: AyahComparisonService(),
              localCoachService: LocalTajweedCoachService(),
              progressService: QuranProgressService(),
              postProcessor: QuranAwarePostProcessor(),
              recorderService: RecitationRecorderService(),
            );

            unawaited(controller.bootstrap());
            return controller;
          },
          update: (_, settings, controller) {
            if (controller != null) {
              unawaited(
                controller.configureReciter(
                  reciterId: settings.selectedReciterId,
                  downloadedSurahNumbers: settings.downloadedSurahsForReciter(
                    settings.selectedReciterId,
                  ),
                  downloadedAudioBasePath: settings.localReciterAudioBasePath,
                ),
              );
            }
            return controller!;
          },
        ),
        ChangeNotifierProvider<PrayerTimesController>(
          create: (_) {
            final controller = PrayerTimesController(
              locationService: LocationService(),
              prayerTimeService: PrayerTimeService(),
              notificationService: notificationService,
            );

            unawaited(controller.bootstrap());
            return controller;
          },
        ),
        ChangeNotifierProvider<GodNamesController>(
          create: (_) => GodNamesController(service: GodNamesService()),
        ),
        ChangeNotifierProxyProvider2<
          AppSettingsController,
          PrayerTimesController,
          ZikirController
        >(
          create: (_) {
            final controller = ZikirController(
              notificationService: notificationService,
            );
            unawaited(controller.bootstrap());
            return controller;
          },
          update: (_, settings, prayerTimes, controller) {
            if (controller != null) {
              unawaited(
                controller.syncExternalContext(
                  language: settings.language,
                  todaySchedule: prayerTimes.todaySchedule,
                  tomorrowSchedule: prayerTimes.tomorrowSchedule,
                ),
              );
            }
            return controller!;
          },
        ),
      ],
      child: Consumer<AppSettingsController>(
        builder: (context, appSettings, _) {
          return MaterialApp(
            title: appSettings.strings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: appSettings.themeMode,
            builder: (context, child) {
              return Directionality(
                textDirection: appSettings.isRtl
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

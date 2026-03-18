import 'package:flutter/material.dart';
import 'package:hijri_calendar/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../models/prayer_time_model.dart';
import '../../services/qibla_service.dart';
import '../../state/app_settings_controller.dart';
import '../../state/prayer_times_controller.dart';
import 'qibla_compass_screen.dart';
import '../widgets/prayer_time_card.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<PrayerTimesController>();
      if (controller.schedule == null && !controller.isLoading) {
        controller.refreshPrayerTimes();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = context.watch<AppSettingsController>();
    final strings = settings.strings;

    return SafeArea(
      bottom: false,
      child: Consumer<PrayerTimesController>(
        builder: (context, controller, _) {
          if (controller.isLoading && controller.schedule == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.schedule == null) {
            return _PrayerErrorState(controller: controller);
          }

          final schedule = controller.schedule!;
          final nextPrayer = schedule.nextPrayer;
          final locale = _intlLocaleFor(settings.language);
          final timeFormat = DateFormat('h:mm', locale);
          final selectedCity = controller.useDeviceLocation
              ? (schedule.bangCity == null
                    ? schedule.location.city
                    : strings.localizedCityName(schedule.bangCity!))
              : controller.selectedBangCity == null
              ? (schedule.bangCity == null
                    ? schedule.location.city
                    : strings.localizedCityName(schedule.bangCity!))
              : strings.localizedCityName(controller.selectedBangCity!);
          final gregorianDateLabel = _gregorianDateLabel(
            date: schedule.date,
            language: settings.language,
          );
          final qiblaService = QiblaService();
          final qiblaBearing = qiblaService.qiblaBearing(schedule.location);
          final hijriDateLabel = _hijriDateLabel(
            date: schedule.date,
            language: settings.language,
            hijriSuffix: strings.hijriSuffix,
          );

          return RefreshIndicator(
            onRefresh: controller.refreshPrayerTimes,
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              children: [
                Text(
                  strings.prayerTitle,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  strings.prayerSubtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.28),
                        blurRadius: 28,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          selectedCity,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        gregorianDateLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimary.withValues(alpha: 0.82),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hijriDateLabel,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              nextPrayer.name.icon,
                              color: colorScheme.onPrimary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.nextPrayer,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: colorScheme.onPrimary.withValues(
                                      alpha: 0.82,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  strings.prayerLabel(nextPrayer.name),
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        color: colorScheme.onPrimary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  strings.beginsIn(controller.countdownLabel),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onPrimary.withValues(
                                      alpha: 0.90,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            timeFormat.format(nextPrayer.time),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.68),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.qiblaSectionTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        strings.qiblaSectionSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.qiblaBearingLabel(
                                    qiblaBearing.round(),
                                    qiblaService.cardinalDirection(
                                      qiblaBearing,
                                    ),
                                  ),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  selectedCity,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.tonalIcon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const LiveQiblaCompassScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.explore_rounded),
                            label: Text(strings.openQiblaCompass),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  strings.todaysSchedule,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  strings.highlightedPrayerHint,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                ...schedule.prayers.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: PrayerTimeCard(
                      entry: entry,
                      timeLabel: timeFormat.format(entry.time),
                      isHighlighted: controller.isEntryNextPrayer(entry),
                    ),
                  ),
                ),
                if (controller.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    controller.errorMessage!,
                    style: TextStyle(color: colorScheme.error),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

String _intlLocaleFor(AppLanguage language) {
  return switch (language) {
    AppLanguage.english => 'en',
    AppLanguage.arabic => 'ar',
    AppLanguage.kurdish => 'ar',
  };
}

String _gregorianDateLabel({
  required DateTime date,
  required AppLanguage language,
}) {
  if (language == AppLanguage.kurdish) {
    final weekday = _kurdishWeekdayName(date.weekday);
    final month = _kurdishMonthName(date.month);
    return '$weekday، ${date.day} $month ${date.year}';
  }

  final locale = _intlLocaleFor(language);
  return DateFormat('EEEE, d MMMM y', locale).format(date);
}

String _kurdishWeekdayName(int weekday) {
  return switch (weekday) {
    DateTime.monday => 'دووشەممە',
    DateTime.tuesday => 'سێشەممە',
    DateTime.wednesday => 'چوارشەممە',
    DateTime.thursday => 'پێنجشەممە',
    DateTime.friday => 'هەینی',
    DateTime.saturday => 'شەممە',
    DateTime.sunday => 'یەکشەممە',
    _ => '',
  };
}

String _kurdishMonthName(int month) {
  return switch (month) {
    1 => 'کانونی دووەم',
    2 => 'شوبات',
    3 => 'ئادار',
    4 => 'نیسان',
    5 => 'ئایار',
    6 => 'حوزەیران',
    7 => 'تەمموز',
    8 => 'ئاب',
    9 => 'ئەیلول',
    10 => 'تشرینی یەکەم',
    11 => 'تشرینی دووەم',
    12 => 'کانونی یەکەم',
    _ => '',
  };
}

String _hijriDateLabel({
  required DateTime date,
  required AppLanguage language,
  required String hijriSuffix,
}) {
  final hijriLocale = language == AppLanguage.english ? 'en' : 'ar';
  HijriCalendarConfig.setLocal(hijriLocale);
  final hijri = HijriCalendarConfig.fromGregorian(date);
  return '${hijri.hDay} ${hijri.getLongMonthName()} ${hijri.hYear} $hijriSuffix';
}

class _PrayerErrorState extends StatelessWidget {
  const _PrayerErrorState({required this.controller});

  final PrayerTimesController controller;

  @override
  Widget build(BuildContext context) {
    final failure = controller.locationFailureType;
    final colorScheme = Theme.of(context).colorScheme;
    final strings = context.read<AppSettingsController>().strings;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.65),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_off_rounded,
                size: 52,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                controller.errorMessage ?? strings.prayerLoadFailed,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: controller.refreshPrayerTimes,
                child: Text(strings.retry),
              ),
              if (failure == LocationFailureType.servicesDisabled) ...[
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: controller.openLocationSettings,
                  child: Text(strings.openLocationSettings),
                ),
              ],
              if (failure == LocationFailureType.permissionDeniedForever) ...[
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: controller.openAppSettings,
                  child: Text(strings.openAppSettings),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

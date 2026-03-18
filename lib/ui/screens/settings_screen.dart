import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../models/prayer_time_model.dart';
import '../../state/app_settings_controller.dart';
import '../../state/prayer_times_controller.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsController>();
    final prayerController = context.watch<PrayerTimesController>();
    final strings = settings.strings;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      bottom: false,
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          Text(
            strings.settingsTitle,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.settingsSubtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          _SectionCard(
            title: strings.citySectionTitle,
            subtitle: strings.citySectionSubtitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile.adaptive(
                  value: prayerController.useDeviceLocation,
                  contentPadding: EdgeInsets.zero,
                  onChanged: prayerController.setUseDeviceLocation,
                  title: Text(strings.useDeviceLocation),
                ),
                const SizedBox(height: 10),
                if (prayerController.useDeviceLocation) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.my_location_rounded,
                      color: colorScheme.primary,
                    ),
                    title: Text(strings.livePrayerLocationTitle),
                    subtitle: Text(
                      prayerController.schedule?.location.city ??
                          prayerController.errorMessage ??
                          strings.locationAccessRequired,
                    ),
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: prayerController.refreshPrayerTimes,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(strings.retry),
                      ),
                      OutlinedButton.icon(
                        onPressed: prayerController.openLocationSettings,
                        icon: const Icon(Icons.location_on_outlined),
                        label: Text(strings.openLocationSettings),
                      ),
                      if (prayerController.locationFailureType ==
                          LocationFailureType.permissionDeniedForever)
                        OutlinedButton.icon(
                          onPressed: prayerController.openAppSettings,
                          icon: const Icon(Icons.settings_outlined),
                          label: Text(strings.openAppSettings),
                        ),
                    ],
                  ),
                ] else ...[
                  DropdownMenu<String>(
                    initialSelection: prayerController.selectedCitySlug,
                    expandedInsets: EdgeInsets.zero,
                    leadingIcon: const Icon(Icons.location_city_rounded),
                    hintText: strings.selectedCity,
                    textStyle: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    inputDecorationTheme: InputDecorationTheme(
                      filled: true,
                      fillColor: colorScheme.primaryContainer.withValues(
                        alpha: 0.22,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    menuStyle: MenuStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        colorScheme.surface,
                      ),
                      surfaceTintColor: const WidgetStatePropertyAll(
                        Colors.transparent,
                      ),
                      elevation: const WidgetStatePropertyAll(10),
                      shadowColor: WidgetStatePropertyAll(
                        Colors.black.withValues(alpha: 0.10),
                      ),
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(vertical: 8),
                      ),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                          side: BorderSide(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.55,
                            ),
                          ),
                        ),
                      ),
                    ),
                    dropdownMenuEntries: prayerController.availableBangCities
                        .map((city) {
                          return DropdownMenuEntry<String>(
                            value: city.slug,
                            label: _cityLabel(strings, city),
                          );
                        })
                        .toList(growable: false),
                    onSelected: (slug) {
                      if (slug != null) {
                        prayerController.setSelectedCity(slug);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    strings.cityDownloadsHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: strings.offlineSectionTitle,
            subtitle: strings.offlineSectionSubtitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OfflineInfoRow(
                  icon: Icons.menu_book_rounded,
                  label: strings.offlineQuranReadyLabel,
                ),
                const SizedBox(height: 10),
                _OfflineInfoRow(
                  icon: Icons.history_rounded,
                  label: strings.offlineHistoryReadyLabel,
                ),
                const SizedBox(height: 10),
                _OfflineInfoRow(
                  icon: Icons.download_done_rounded,
                  label: strings.offlineDownloadedAudioLabel(
                    settings.downloadedSurahCount(settings.selectedReciterId),
                  ),
                ),
                const SizedBox(height: 10),
                _OfflineInfoRow(
                  icon: Icons.schedule_rounded,
                  label:
                      prayerController.useDeviceLocation ||
                          prayerController.selectedBangCity == null
                      ? strings.liveLocationOfflineHint
                      : strings.offlinePrayerCacheLabel(
                          strings.localizedCityName(
                            prayerController.selectedBangCity!,
                          ),
                          prayerController.offlineCachedMonthCount,
                        ),
                ),
                const SizedBox(height: 6),
                Text(
                  prayerController.useDeviceLocation
                      ? strings.liveLocationOfflineHint
                      : strings.offlinePrayerCacheHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                if (prayerController.offlineCacheError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    prayerController.offlineCacheError!,
                    style: TextStyle(color: colorScheme.error),
                  ),
                ],
                if (!prayerController.useDeviceLocation &&
                    prayerController.selectedBangCity != null) ...[
                  const SizedBox(height: 14),
                  FilledButton.tonalIcon(
                    onPressed: prayerController.isPreparingOfflineCache
                        ? null
                        : prayerController.prepareSelectedCityOffline,
                    icon: Icon(
                      prayerController.isPreparingOfflineCache
                          ? Icons.sync_rounded
                          : Icons.download_for_offline_rounded,
                    ),
                    label: Text(
                      prayerController.isPreparingOfflineCache
                          ? strings.savingOfflineLabel
                          : strings.savePrayerTimesOfflineLabel,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: strings.prayerSettingsTitle,
            subtitle: strings.prayerSettingsSubtitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.34),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: SwitchListTile.adaptive(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    value: prayerController.notificationsEnabled,
                    onChanged: prayerController.setNotificationsEnabled,
                    title: Text(strings.prayerNotifications),
                    subtitle: Text(strings.prayerNotificationsSubtitle),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: strings.languageSectionTitle,
            subtitle: strings.languageSectionSubtitle,
            child: SegmentedButton<AppLanguage>(
              segments: AppLanguage.values
                  .map((language) {
                    return ButtonSegment<AppLanguage>(
                      value: language,
                      label: Text(strings.languageLabel(language)),
                    );
                  })
                  .toList(growable: false),
              selected: {settings.language},
              onSelectionChanged: (selection) async {
                await settings.setLanguage(selection.first);
                await prayerController
                    .rescheduleNotificationsForCurrentLanguage();
              },
            ),
          ),
          _SectionCard(
            title: strings.appearanceSectionTitle,
            subtitle: strings.appearanceSectionSubtitle,
            child: SwitchListTile.adaptive(
              value: settings.themeMode == ThemeMode.dark,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                settings.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
              },
              title: Text(strings.darkModeTitle),
              subtitle: Text(strings.darkModeSubtitle),
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: strings.aboutSectionTitle,
            subtitle: strings.appName,
            child: FilledButton.tonalIcon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
                );
              },
              icon: const Icon(Icons.info_outline_rounded),
              label: Text(strings.openAboutPage),
            ),
          ),
        ],
      ),
    );
  }

  String _cityLabel(AppStrings strings, BangCityOption city) {
    return '${strings.localizedCityName(city)} • ${city.englishName}';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _OfflineInfoRow extends StatelessWidget {
  const _OfflineInfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
        ),
      ],
    );
  }
}

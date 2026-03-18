import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../models/prayer_time_model.dart';
import '../../state/app_settings_controller.dart';
import '../../state/prayer_times_controller.dart';
import 'app_shell_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  bool _didInitialize = false;
  bool _useLiveLocation = false;
  bool _enableNotifications = false;
  bool _isCompleting = false;
  String? _selectedCitySlug;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitialize) {
      return;
    }

    final prayerController = context.read<PrayerTimesController>();
    _useLiveLocation = prayerController.useDeviceLocation;
    _enableNotifications = prayerController.notificationsEnabled;
    _selectedCitySlug =
        prayerController.selectedCitySlug ??
        prayerController.defaultBangCity?.slug;
    _didInitialize = true;
  }

  Future<void> _setLanguage(AppLanguage language) async {
    await context.read<AppSettingsController>().setLanguage(language);
  }

  Future<void> _completeOnboarding() async {
    if (_isCompleting) {
      return;
    }

    setState(() {
      _isCompleting = true;
    });

    final appSettings = context.read<AppSettingsController>();
    final prayerController = context.read<PrayerTimesController>();

    await prayerController.configurePrayerLocation(
      useLiveLocation: _useLiveLocation,
      citySlug: _selectedCitySlug,
    );
    await prayerController.setNotificationsEnabled(_enableNotifications);
    await appSettings.completeOnboarding();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AppShellScreen()),
      (route) => false,
    );
  }

  void _goBack() {
    if (_currentStep == 0) {
      return;
    }

    setState(() {
      _currentStep--;
    });
  }

  void _goForward() {
    if (_currentStep >= 2) {
      _completeOnboarding();
      return;
    }

    setState(() {
      _currentStep++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = context.watch<AppSettingsController>();
    final prayerController = context.watch<PrayerTimesController>();
    final strings = settings.strings;
    final language = settings.language;
    final steps = <_OnboardingStepData>[
      _OnboardingStepData(
        title: strings.onboardingLanguageTitle,
        icon: Icons.translate_rounded,
      ),
      _OnboardingStepData(
        title: strings.onboardingLocationTitle,
        icon: Icons.mosque_rounded,
      ),
      _OnboardingStepData(
        title: strings.onboardingNotificationsTitle,
        icon: Icons.notifications_active_rounded,
      ),
    ];

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFF8F3E7),
              colorScheme.primary.withValues(alpha: 0.12),
              colorScheme.secondary.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.45,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Image.asset('assets/app_logo.png'),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  strings.onboardingTitle,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  strings.onboardingSubtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / steps.length,
                    minHeight: 8,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: List<Widget>.generate(steps.length, (index) {
                    final step = steps[index];
                    final isActive = index == _currentStep;
                    final isComplete = index < _currentStep;
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(
                          right: index == steps.length - 1 ? 0 : 8,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? colorScheme.primaryContainer.withValues(
                                  alpha: 0.92,
                                )
                              : colorScheme.surface.withValues(
                                  alpha: isComplete ? 0.96 : 0.72,
                                ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive
                                ? colorScheme.primary.withValues(alpha: 0.28)
                                : colorScheme.outlineVariant.withValues(
                                    alpha: 0.45,
                                  ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isComplete ? Icons.check_rounded : step.icon,
                              size: 18,
                              color: isActive || isComplete
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                step.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isActive || isComplete
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 22),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.55,
                        ),
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final stepChild = switch (_currentStep) {
                          0 => _LanguageStep(
                            key: const ValueKey(0),
                            language: language,
                            strings: strings,
                            onLanguageChanged: _setLanguage,
                          ),
                          1 => _LocationStep(
                            key: const ValueKey(1),
                            strings: strings,
                            theme: theme,
                            colorScheme: colorScheme,
                            useLiveLocation: _useLiveLocation,
                            selectedCitySlug: _selectedCitySlug,
                            availableCities:
                                prayerController.availableBangCities,
                            onUseLiveLocationChanged: (value) {
                              setState(() {
                                _useLiveLocation = value;
                                _selectedCitySlug ??=
                                    prayerController.defaultBangCity?.slug;
                              });
                            },
                            onCityChanged: (slug) {
                              setState(() {
                                _selectedCitySlug = slug;
                              });
                            },
                          ),
                          _ => _NotificationsStep(
                            key: const ValueKey(2),
                            strings: strings,
                            enabled: _enableNotifications,
                            onChanged: (value) {
                              setState(() {
                                _enableNotifications = value;
                              });
                            },
                          ),
                        };

                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: SingleChildScrollView(
                            key: ValueKey(_currentStep),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: stepChild,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  strings.onboardingSettingsHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (_currentStep > 0)
                      OutlinedButton(
                        onPressed: _isCompleting ? null : _goBack,
                        child: Text(strings.onboardingBackLabel),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isCompleting ? null : _goForward,
                        child: Text(
                          _currentStep == steps.length - 1
                              ? strings.onboardingFinishLabel
                              : strings.onboardingContinueLabel,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingStepData {
  const _OnboardingStepData({required this.title, required this.icon});

  final String title;
  final IconData icon;
}

class _LanguageStep extends StatelessWidget {
  const _LanguageStep({
    super.key,
    required this.language,
    required this.strings,
    required this.onLanguageChanged,
  });

  final AppLanguage language;
  final AppStrings strings;
  final Future<void> Function(AppLanguage value) onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.onboardingLanguageTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          strings.onboardingLanguageSubtitle,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
        ),
        const SizedBox(height: 26),
        SegmentedButton<AppLanguage>(
          segments: AppLanguage.values
              .map(
                (value) => ButtonSegment<AppLanguage>(
                  value: value,
                  label: Text(strings.languageLabel(value)),
                ),
              )
              .toList(growable: false),
          selected: {language},
          onSelectionChanged: (selection) {
            onLanguageChanged(selection.first);
          },
        ),
      ],
    );
  }
}

class _LocationStep extends StatelessWidget {
  const _LocationStep({
    super.key,
    required this.strings,
    required this.theme,
    required this.colorScheme,
    required this.useLiveLocation,
    required this.selectedCitySlug,
    required this.availableCities,
    required this.onUseLiveLocationChanged,
    required this.onCityChanged,
  });

  final AppStrings strings;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final bool useLiveLocation;
  final String? selectedCitySlug;
  final List<BangCityOption> availableCities;
  final ValueChanged<bool> onUseLiveLocationChanged;
  final ValueChanged<String?> onCityChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.onboardingLocationTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          strings.onboardingLocationSubtitle,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
        ),
        const SizedBox(height: 20),
        _ChoiceCard(
          title: strings.onboardingLiveLocationCardTitle,
          body: strings.onboardingLiveLocationCardBody,
          icon: Icons.my_location_rounded,
          selected: useLiveLocation,
          onTap: () => onUseLiveLocationChanged(true),
        ),
        const SizedBox(height: 12),
        _ChoiceCard(
          title: strings.onboardingCityCardTitle,
          body: strings.onboardingCityCardBody,
          icon: Icons.location_city_rounded,
          selected: !useLiveLocation,
          onTap: () => onUseLiveLocationChanged(false),
        ),
        const SizedBox(height: 18),
        if (!useLiveLocation)
          DropdownMenu<String>(
            key: ValueKey(selectedCitySlug),
            initialSelection: selectedCitySlug,
            expandedInsets: EdgeInsets.zero,
            leadingIcon: const Icon(Icons.location_city_rounded),
            hintText: strings.selectedCity,
            textStyle: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: colorScheme.primaryContainer.withValues(alpha: 0.2),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
            dropdownMenuEntries: availableCities
                .map(
                  (city) => DropdownMenuEntry<String>(
                    value: city.slug,
                    label:
                        '${strings.localizedCityName(city)} • ${city.englishName}',
                  ),
                )
                .toList(growable: false),
            onSelected: onCityChanged,
          ),
      ],
    );
  }
}

class _NotificationsStep extends StatelessWidget {
  const _NotificationsStep({
    super.key,
    required this.strings,
    required this.enabled,
    required this.onChanged,
  });

  final AppStrings strings;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.onboardingNotificationsTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          strings.onboardingNotificationsSubtitle,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
        ),
        const SizedBox(height: 24),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(24),
          ),
          child: SwitchListTile.adaptive(
            value: enabled,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            onChanged: onChanged,
            title: Text(strings.prayerNotifications),
            subtitle: Text(strings.onboardingNotificationsHint),
          ),
        ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String body;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primaryContainer.withValues(alpha: 0.4)
                : colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? colorScheme.primary.withValues(alpha: 0.35)
                  : colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? colorScheme.primary.withValues(alpha: 0.12)
                      : colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

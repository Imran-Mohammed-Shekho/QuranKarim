import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../models/dhikr_models.dart';
import '../../models/prayer_time_model.dart';
import '../../models/zikir_reminder_models.dart';
import '../../state/app_settings_controller.dart';
import '../../state/zikir_controller.dart';
import 'zikir_collection_screen.dart';
import 'tasbih_counter_screen.dart';

String _localizedDhikrLabel(
  AppSettingsController settings,
  DhikrDefinition dhikr,
) {
  return dhikr.arabicText;
}

class ZikirHomeScreen extends StatefulWidget {
  const ZikirHomeScreen({super.key});

  @override
  State<ZikirHomeScreen> createState() => _ZikirHomeScreenState();
}

class _ZikirHomeScreenState extends State<ZikirHomeScreen> {
  Future<void> _showAddCustomDhikrSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) => const _AddCustomDhikrSheet(),
    );
  }

  void _openSingleCounter(DhikrDefinition dhikr) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TasbihCounterScreen.single(dhikrId: dhikr.id),
      ),
    );
  }

  void _openPresetCounter(DhikrSetDefinition preset) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ZikirCollectionScreen(setId: preset.id),
      ),
    );
  }

  Future<void> _confirmDeleteCustomDhikr(DhikrDefinition dhikr) async {
    final strings = context.read<AppSettingsController>().strings;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(strings.deleteCustomZikirTitle),
          content: Text(strings.deleteCustomZikirBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(strings.cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(strings.deleteCustomZikir),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    await context.read<ZikirController>().deleteCustomDhikr(dhikr.id);
  }

  Future<void> _showReminderEditorSheet({ZikirReminderRule? reminder}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => _ReminderEditorSheet(reminder: reminder),
    );
  }

  Future<void> _confirmDeleteReminder(ZikirReminderRule reminder) async {
    final strings = context.read<AppSettingsController>().strings;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(strings.deleteZikirReminderTitle),
          content: Text(strings.deleteZikirReminderBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(strings.cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(strings.deleteCustomZikir),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && mounted) {
      await context.read<ZikirController>().deleteReminder(reminder.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final strings = context.watch<AppSettingsController>().strings;

    return SafeArea(
      bottom: false,
      child: Consumer<ZikirController>(
        builder: (context, controller, _) {
          if (!controller.isReady) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      strings.zikirTitle,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.zikirSubtitle,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary.withValues(alpha: 0.94),
                            colorScheme.secondary.withValues(alpha: 0.88),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.24),
                            blurRadius: 30,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'وَاذْكُرُوا اللَّهَ كَثِيرًا',
                            textDirection: TextDirection.rtl,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            strings.zikirHeroBody,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onPrimary.withValues(
                                alpha: 0.9,
                              ),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 18),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: SwitchListTile.adaptive(
                              value: controller.vibrationEnabled,
                              onChanged: controller.setVibrationEnabled,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              title: Text(
                                strings.vibrationFeedback,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                strings.vibrationFeedbackSubtitle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onPrimary.withValues(
                                    alpha: 0.82,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.68,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      strings.zikirReminderTitle,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      strings.zikirReminderSubtitle,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                            height: 1.4,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: _showReminderEditorSheet,
                                icon: const Icon(Icons.add_alarm_rounded),
                                label: Text(strings.addZikirReminder),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (controller.reminderRules.isEmpty)
                            _EmptyCustomState(
                              message: strings.zikirReminderEmpty,
                            )
                          else
                            for (final reminder
                                in controller.reminderRules) ...[
                              _ReminderCard(
                                reminder: reminder,
                                onEdit: () => _showReminderEditorSheet(
                                  reminder: reminder,
                                ),
                                onDelete: () =>
                                    _confirmDeleteReminder(reminder),
                              ),
                              const SizedBox(height: 12),
                            ],
                          if (controller.reminderError != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              controller.reminderError!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    _SectionHeader(
                      title: strings.zikirPresetsTitle,
                      subtitle: strings.zikirPresetsSubtitle,
                    ),
                    const SizedBox(height: 14),
                    for (final preset in controller.presetSets) ...[
                      _PresetCard(
                        preset: preset,
                        isResumable: controller.hasProgressForSet(preset.id),
                        onTap: () => _openPresetCounter(preset),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 12),
                    _SectionHeader(
                      title: strings.zikirCommonTitle,
                      subtitle: strings.zikirCommonSubtitle,
                    ),
                    const SizedBox(height: 14),
                    for (final dhikr in controller.builtInDhikrs) ...[
                      _DhikrCard(
                        dhikr: dhikr,
                        progressLabel: controller.hasProgressForDhikr(dhikr.id)
                            ? strings.progressInline(
                                controller.countForDhikr(dhikr.id),
                                controller.targetForDhikr(dhikr.id),
                              )
                            : null,
                        onTap: () => _openSingleCounter(dhikr),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _SectionHeader(
                            title: strings.customZikirTitle,
                            subtitle: strings.customZikirSubtitle,
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _showAddCustomDhikrSheet,
                          icon: const Icon(Icons.add_rounded),
                          label: Text(strings.addCustomZikir),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (controller.customDhikrs.isEmpty)
                      _EmptyCustomState(message: strings.customZikirEmpty)
                    else
                      for (final dhikr in controller.customDhikrs) ...[
                        _DhikrCard(
                          dhikr: dhikr,
                          progressLabel:
                              controller.hasProgressForDhikr(dhikr.id)
                              ? strings.progressInline(
                                  controller.countForDhikr(dhikr.id),
                                  controller.targetForDhikr(dhikr.id),
                                )
                              : null,
                          onTap: () => _openSingleCounter(dhikr),
                          trailing: IconButton(
                            tooltip: strings.deleteCustomZikir,
                            onPressed: () => _confirmDeleteCustomDhikr(dhikr),
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: colorScheme.error,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AddCustomDhikrSheet extends StatefulWidget {
  const _AddCustomDhikrSheet();

  @override
  State<_AddCustomDhikrSheet> createState() => _AddCustomDhikrSheetState();
}

class _AddCustomDhikrSheetState extends State<_AddCustomDhikrSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _arabicController;
  late final TextEditingController _transliterationController;
  late final TextEditingController _meaningController;
  late final TextEditingController _targetController;

  @override
  void initState() {
    super.initState();
    _arabicController = TextEditingController();
    _transliterationController = TextEditingController();
    _meaningController = TextEditingController();
    _targetController = TextEditingController(text: '100');
  }

  @override
  void dispose() {
    _arabicController.dispose();
    _transliterationController.dispose();
    _meaningController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.read<AppSettingsController>().strings;
    final zikirController = context.read<ZikirController>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.addCustomZikir,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                strings.customZikirFormSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _arabicController,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  labelText: strings.customPhraseLabel,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return strings.customPhraseValidation;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _transliterationController,
                decoration: InputDecoration(
                  labelText: strings.customTransliterationLabel,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _meaningController,
                decoration: InputDecoration(
                  labelText: strings.customMeaningLabel,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: strings.customTargetLabel,
                ),
                validator: (value) {
                  final parsed = int.tryParse((value ?? '').trim());
                  if (parsed == null || parsed <= 0) {
                    return strings.customTargetValidation;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }

                    final arabicText = _arabicController.text;
                    final transliteration = _transliterationController.text;
                    final meaning = _meaningController.text;
                    final targetCount = int.parse(
                      _targetController.text.trim(),
                    );

                    Navigator.of(context).pop();
                    await zikirController.addCustomDhikr(
                      arabicText: arabicText,
                      transliteration: transliteration,
                      meaning: meaning,
                      targetCount: targetCount,
                    );
                  },
                  child: Text(strings.saveCustomZikir),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminder,
    required this.onEdit,
    required this.onDelete,
  });

  final ZikirReminderRule reminder;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = context.read<AppSettingsController>();
    final strings = settings.strings;
    final controller = context.read<ZikirController>();
    final localizations = MaterialLocalizations.of(context);
    final targetLabel = _reminderTargetLabel(settings, controller, reminder);
    final summary = _reminderSummary(
      strings: strings,
      localizations: localizations,
      controller: controller,
      reminder: reminder,
    );
    final isUnscheduled =
        reminder.enabled && !controller.reminderHasFutureOccurrence(reminder);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      targetLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: reminder.enabled,
                onChanged: (value) {
                  context.read<ZikirController>().setReminderEnabled(
                    reminder.id,
                    value,
                  );
                },
              ),
            ],
          ),
          if (isUnscheduled) ...[
            const SizedBox(height: 10),
            Text(
              strings.zikirReminderNeedsPrayerTimes,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
                label: Text(strings.editZikirReminder),
              ),
              OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(strings.deleteCustomZikir),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReminderEditorSheet extends StatefulWidget {
  const _ReminderEditorSheet({this.reminder});

  final ZikirReminderRule? reminder;

  @override
  State<_ReminderEditorSheet> createState() => _ReminderEditorSheetState();
}

class _ReminderEditorSheetState extends State<_ReminderEditorSheet> {
  late ZikirReminderTargetType _targetType;
  late String _targetId;
  late ZikirReminderScheduleType _scheduleType;
  late Set<int> _weekdays;
  TimeOfDay? _time;
  late Set<PrayerName> _prayers;
  late final TextEditingController _offsetController;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    final reminder = widget.reminder;
    _targetType = reminder?.targetType ?? ZikirReminderTargetType.singleDhikr;
    _targetId = reminder?.targetId ?? '';
    _scheduleType =
        reminder?.scheduleType ?? ZikirReminderScheduleType.dailyTime;
    _weekdays = {
      ...(reminder?.weekdays ??
          const <int>{
            DateTime.monday,
            DateTime.tuesday,
            DateTime.wednesday,
            DateTime.thursday,
            DateTime.friday,
            DateTime.saturday,
            DateTime.sunday,
          }),
    };
    _time = reminder?.time ?? const TimeOfDay(hour: 20, minute: 0);
    _prayers = {
      ...(reminder?.prayers ?? const <PrayerName>{PrayerName.fajr}),
    };
    _offsetController = TextEditingController(
      text: (reminder?.minutesAfterPrayer ?? 10).toString(),
    );
    _enabled = reminder?.enabled ?? true;
  }

  @override
  void dispose() {
    _offsetController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 20, minute: 0),
    );
    if (selected != null) {
      setState(() {
        _time = selected;
      });
    }
  }

  Future<void> _save() async {
    final strings = context.read<AppSettingsController>().strings;
    final controller = context.read<ZikirController>();
    final messenger = ScaffoldMessenger.of(context);
    if (_targetId.trim().isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(strings.customPhraseValidation)),
      );
      return;
    }
    if (_weekdays.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(strings.zikirReminderWeekdaysRequired)),
      );
      return;
    }
    if (_scheduleType == ZikirReminderScheduleType.dailyTime && _time == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(strings.zikirReminderTimeRequired)),
      );
      return;
    }
    if (_scheduleType == ZikirReminderScheduleType.afterPrayer &&
        _prayers.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(strings.zikirReminderPrayersRequired)),
      );
      return;
    }

    final offset = int.tryParse(_offsetController.text.trim()) ?? 0;
    final reminder = ZikirReminderRule(
      id:
          widget.reminder?.id ??
          'reminder_${DateTime.now().microsecondsSinceEpoch}',
      enabled: _enabled,
      targetType: _targetType,
      targetId: _targetId.trim(),
      scheduleType: _scheduleType,
      weekdays: _weekdays,
      time: _scheduleType == ZikirReminderScheduleType.dailyTime ? _time : null,
      prayers: _scheduleType == ZikirReminderScheduleType.afterPrayer
          ? _prayers.toList(growable: false)
          : const <PrayerName>[],
      minutesAfterPrayer: _scheduleType == ZikirReminderScheduleType.afterPrayer
          ? offset
          : 0,
    );

    if (widget.reminder == null) {
      await controller.addReminder(reminder);
    } else {
      await controller.updateReminder(reminder);
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.read<AppSettingsController>();
    final strings = settings.strings;
    final controller = context.read<ZikirController>();
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final targetEntries = _targetType == ZikirReminderTargetType.singleDhikr
        ? controller.allDhikrs
              .map(
                (dhikr) => DropdownMenuEntry<String>(
                  value: dhikr.id,
                  label: _reminderSingleTargetLabel(settings, dhikr),
                ),
              )
              .toList(growable: false)
        : controller.presetSets
              .map(
                (preset) => DropdownMenuEntry<String>(
                  value: preset.id,
                  label: preset.titleFor(settings.language),
                ),
              )
              .toList(growable: false);

    if (_targetId.isEmpty && targetEntries.isNotEmpty) {
      _targetId = targetEntries.first.value;
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.reminder == null
                  ? strings.addZikirReminder
                  : strings.editZikirReminder,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              value: _enabled,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) => setState(() => _enabled = value),
              title: Text(strings.onLabel),
              subtitle: Text(strings.offLabel),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<ZikirReminderTargetType>(
              initialValue: _targetType,
              decoration: InputDecoration(
                labelText: strings.zikirReminderTargetTypeLabel,
              ),
              items: [
                DropdownMenuItem(
                  value: ZikirReminderTargetType.singleDhikr,
                  child: Text(strings.zikirReminderTargetSingle),
                ),
                DropdownMenuItem(
                  value: ZikirReminderTargetType.presetSet,
                  child: Text(strings.zikirReminderTargetPreset),
                ),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                final nextTargetId =
                    value == ZikirReminderTargetType.singleDhikr
                    ? (controller.allDhikrs.isEmpty
                          ? ''
                          : controller.allDhikrs.first.id)
                    : (controller.presetSets.isEmpty
                          ? ''
                          : controller.presetSets.first.id);
                setState(() {
                  _targetType = value;
                  _targetId = nextTargetId;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey<String>('target_${_targetType.name}_$_targetId'),
              initialValue: _targetId.isEmpty ? null : _targetId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: strings.zikirReminderPhraseLabel,
              ),
              items: targetEntries
                  .map(
                    (entry) => DropdownMenuItem<String>(
                      value: entry.value,
                      child: Text(
                        entry.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _targetId = value;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ZikirReminderScheduleType>(
              initialValue: _scheduleType,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: strings.zikirReminderScheduleTypeLabel,
              ),
              items: [
                DropdownMenuItem(
                  value: ZikirReminderScheduleType.dailyTime,
                  child: Text(strings.zikirReminderScheduleDaily),
                ),
                DropdownMenuItem(
                  value: ZikirReminderScheduleType.afterPrayer,
                  child: Text(strings.zikirReminderScheduleAfterPrayer),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _scheduleType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            Text(
              strings.zikirReminderWeekdaysLabel,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List<Widget>.generate(7, (index) {
                final weekday = DateTime.monday + index;
                return FilterChip(
                  label: Text(strings.weekdayShortLabel(weekday)),
                  selected: _weekdays.contains(weekday),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _weekdays = {..._weekdays, weekday};
                      } else {
                        _weekdays = {..._weekdays}..remove(weekday);
                      }
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            if (_scheduleType == ZikirReminderScheduleType.dailyTime) ...[
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 180),
                    child: Text(
                      _time == null
                          ? strings.zikirReminderTimeRequired
                          : strings.zikirReminderDailySummary(
                              strings.allDaysLabel,
                              MaterialLocalizations.of(
                                context,
                              ).formatTimeOfDay(_time!),
                            ),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text(strings.zikirReminderTimeButton),
                  ),
                ],
              ),
            ] else ...[
              Text(
                strings.zikirReminderPrayersLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PrayerName.values
                    .map((prayer) {
                      return FilterChip(
                        label: Text(strings.prayerLabel(prayer)),
                        selected: _prayers.contains(prayer),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _prayers = {..._prayers, prayer};
                            } else {
                              _prayers = {..._prayers}..remove(prayer);
                            }
                          });
                        },
                      );
                    })
                    .toList(growable: false),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _offsetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: strings.zikirReminderOffsetLabel,
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: Text(strings.saveZikirReminder),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _reminderSummary({
  required AppStrings strings,
  required MaterialLocalizations localizations,
  required ZikirController controller,
  required ZikirReminderRule reminder,
}) {
  final weekdays = _weekdaysSummary(strings, reminder.weekdays);
  if (reminder.scheduleType == ZikirReminderScheduleType.dailyTime) {
    final time = reminder.time == null
        ? '--:--'
        : localizations.formatTimeOfDay(reminder.time!);
    return strings.zikirReminderDailySummary(weekdays, time);
  }
  final prayers = reminder.prayers.map(strings.prayerLabel).join(', ');
  return strings.zikirReminderAfterPrayerSummary(
    prayers,
    reminder.minutesAfterPrayer,
    weekdays,
  );
}

String _weekdaysSummary(AppStrings strings, Set<int> weekdays) {
  final normalized = weekdays.toList()..sort();
  if (normalized.length == 7) {
    return strings.allDaysLabel;
  }
  return normalized.map(strings.weekdayShortLabel).join(', ');
}

String _reminderTargetLabel(
  AppSettingsController settings,
  ZikirController controller,
  ZikirReminderRule reminder,
) {
  if (reminder.targetType == ZikirReminderTargetType.singleDhikr) {
    final dhikr = controller.findDhikr(reminder.targetId);
    return dhikr == null
        ? reminder.targetId
        : _reminderSingleTargetLabel(settings, dhikr);
  }
  final preset = controller.findPresetSet(reminder.targetId);
  return preset == null
      ? reminder.targetId
      : preset.titleFor(settings.language);
}

String _reminderSingleTargetLabel(
  AppSettingsController settings,
  DhikrDefinition dhikr,
) {
  final primary = _localizedDhikrLabel(settings, dhikr);
  return primary == dhikr.arabicText
      ? primary
      : '$primary • ${dhikr.arabicText}';
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
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
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({
    required this.preset,
    required this.isResumable,
    required this.onTap,
  });

  final DhikrSetDefinition preset;
  final bool isResumable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final strings = context.read<AppSettingsController>().strings;

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.34),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.28),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    preset.titleFor(
                      context.read<AppSettingsController>().language,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (isResumable)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      strings.resumeLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _InlineChip(
                  label: strings.zikirItemsCountLabel(preset.steps.length),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_rounded, color: colorScheme.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DhikrCard extends StatelessWidget {
  const _DhikrCard({
    required this.dhikr,
    required this.onTap,
    this.progressLabel,
    this.trailing,
  });

  final DhikrDefinition dhikr;
  final VoidCallback onTap;
  final String? progressLabel;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = context.read<AppSettingsController>();
    final localizedLabel = _localizedDhikrLabel(settings, dhikr);

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                dhikr.isCustom
                    ? Icons.edit_note_rounded
                    : Icons.brightness_3_rounded,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dhikr.arabicText,
                    textDirection: TextDirection.rtl,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (localizedLabel != dhikr.arabicText)
                    Text(
                      localizedLabel,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InlineChip(
                        label:
                            '${context.read<AppSettingsController>().strings.targetLabel} ${dhikr.defaultTarget}',
                      ),
                      if (progressLabel != null)
                        _InlineChip(label: progressLabel!),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing ??
                Icon(Icons.arrow_forward_rounded, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

class _InlineChip extends StatelessWidget {
  const _InlineChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EmptyCustomState extends StatelessWidget {
  const _EmptyCustomState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.68),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.self_improvement_rounded, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

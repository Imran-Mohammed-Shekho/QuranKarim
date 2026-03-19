import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/dhikr_models.dart';
import '../../state/app_settings_controller.dart';
import '../../state/zikir_controller.dart';
import '../widgets/dhikr_arabic_text_card.dart';
import 'tasbih_counter_screen.dart';

class ZikirCollectionScreen extends StatelessWidget {
  const ZikirCollectionScreen({super.key, required this.setId});

  final String setId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = context.watch<AppSettingsController>();
    final strings = settings.strings;

    return Scaffold(
      appBar: AppBar(title: Text(strings.tasbihPresetTitle)),
      body: Consumer<ZikirController>(
        builder: (context, controller, _) {
          final preset = controller.findPresetSet(setId);
          if (preset == null) {
            return Center(child: Text(strings.zikirMissing));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.68),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preset.titleFor(settings.language),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      preset.subtitleFor(settings.language),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                TasbihCounterScreen.preset(setId: preset.id),
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        controller.hasProgressForSet(preset.id)
                            ? strings.resumeLabel
                            : strings.openZikirCollectionLabel,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              for (int index = 0; index < preset.steps.length; index++) ...[
                _CollectionStepCard(
                  stepNumber: index + 1,
                  step: preset.steps[index],
                  dhikr: controller.findDhikr(preset.steps[index].dhikrId),
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CollectionStepCard extends StatelessWidget {
  const _CollectionStepCard({
    required this.stepNumber,
    required this.step,
    required this.dhikr,
  });

  final int stepNumber;
  final DhikrSetStep step;
  final DhikrDefinition? dhikr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = context.read<AppSettingsController>();
    final strings = settings.strings;
    final localizedLabel =
        dhikr?.labelFor(settings.language) ?? dhikr?.arabicText ?? step.dhikrId;
    final localizedMeaning =
        dhikr?.meaningFor(settings.language) ??
        strings.localizedDhikrMeaning(
          id: dhikr?.id ?? step.dhikrId,
          fallback: dhikr?.meaning,
        );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.68),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$stepNumber',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${strings.targetLabel} ${step.targetCount}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (dhikr != null) ...[
            if (localizedLabel != dhikr!.arabicText)
              Text(
                localizedLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (localizedLabel != dhikr!.arabicText) const SizedBox(height: 12),
            DhikrArabicTextCard(
              dhikr: dhikr!,
              textStyle: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.85,
              ),
            ),
          ],
          if (dhikr == null)
            Text(
              localizedLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          if (localizedMeaning != null) ...[
            const SizedBox(height: 8),
            Text(
              localizedMeaning,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

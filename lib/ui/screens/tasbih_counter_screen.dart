import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/dhikr_models.dart';
import '../../state/app_settings_controller.dart';
import '../../state/zikir_controller.dart';

String _localizedDhikrLabel(
  AppSettingsController settings,
  DhikrDefinition dhikr,
) {
  return dhikr.arabicText;
}

class TasbihCounterScreen extends StatefulWidget {
  const TasbihCounterScreen.single({super.key, required this.dhikrId})
    : setId = null;

  const TasbihCounterScreen.preset({super.key, required this.setId})
    : dhikrId = null;

  final String? dhikrId;
  final String? setId;

  bool get isPreset => setId != null;

  @override
  State<TasbihCounterScreen> createState() => _TasbihCounterScreenState();
}

class _TasbihCounterScreenState extends State<TasbihCounterScreen> {
  bool _pressed = false;

  Future<void> _increment() async {
    final controller = context.read<ZikirController>();
    final settings = context.read<AppSettingsController>();
    final strings = settings.strings;

    if (widget.isPreset) {
      final outcome = await controller.incrementPresetSet(widget.setId!);
      if (!mounted) {
        return;
      }

      if (outcome == DhikrTapOutcome.advanced) {
        final nextDhikr = controller.currentDhikrForSet(widget.setId!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings.nextDhikrMessage(
                nextDhikr == null
                    ? ''
                    : _localizedDhikrLabel(settings, nextDhikr),
              ),
            ),
          ),
        );
      } else if (outcome == DhikrTapOutcome.completed) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.tasbihCompletedMessage)));
      }
      return;
    }

    await controller.incrementDhikr(widget.dhikrId!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = context.watch<AppSettingsController>();
    final strings = settings.strings;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isPreset ? strings.tasbihPresetTitle : strings.tasbihTitle,
        ),
      ),
      body: Consumer<ZikirController>(
        builder: (context, controller, _) {
          final dhikr = widget.isPreset
              ? controller.currentDhikrForSet(widget.setId!)
              : controller.findDhikr(widget.dhikrId!);
          if (dhikr == null) {
            return Center(child: Text(strings.zikirMissing));
          }

          final preset = widget.isPreset
              ? controller.findPresetSet(widget.setId!)
              : null;
          final presetProgress = widget.isPreset
              ? controller.progressForSet(widget.setId!)
              : null;
          final count = widget.isPreset
              ? controller.currentCountForSet(widget.setId!)
              : controller.countForDhikr(widget.dhikrId!);
          final target = widget.isPreset
              ? controller.currentTargetForSet(widget.setId!)
              : controller.targetForDhikr(widget.dhikrId!);
          final progress = widget.isPreset
              ? controller.currentProgressForSet(widget.setId!)
              : controller.progressForDhikr(widget.dhikrId!);
          final overallProgress = widget.isPreset
              ? controller.overallProgressForSet(widget.setId!)
              : progress;
          final isPresetCompleted = widget.isPreset && overallProgress >= 1;
          final localizedLabel = _localizedDhikrLabel(settings, dhikr);
          final localizedMeaning =
              dhikr.meaningFor(settings.language) ??
              strings.localizedDhikrMeaning(
                id: dhikr.id,
                fallback: dhikr.meaning,
              );

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              if (preset != null && presetProgress != null) ...[
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
                        preset.titleFor(settings.language),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        strings.stepIndicator(
                          presetProgress.currentStepIndex + 1,
                          preset.steps.length,
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: overallProgress,
                          minHeight: 8,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: List<Widget>.generate(preset.steps.length, (
                          index,
                        ) {
                          final step = preset.steps[index];
                          final stepDhikr = controller.findDhikr(step.dhikrId);
                          final stepCount = presetProgress.stepCounts[index];
                          final isActive =
                              index == presetProgress.currentStepIndex;
                          final label = stepDhikr == null
                              ? step.dhikrId
                              : _localizedDhikrLabel(settings, stepDhikr);
                          return _StepPill(
                            label: '$label $stepCount/${step.targetCount}',
                            isActive: isActive,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: Container(
                  key: ValueKey<String>(dhikr.id),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.68),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        dhikr.arabicText,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (localizedLabel != dhikr.arabicText)
                        Text(
                          localizedLabel,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (localizedMeaning != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          localizedMeaning,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                      ],
                      const SizedBox(height: 26),
                      Text(
                        strings.counterLabel,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                        child: Text(
                          '$count',
                          key: ValueKey<int>(count),
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _MetaPill(label: '${strings.targetLabel} $target'),
                          const SizedBox(width: 10),
                          _MetaPill(
                            label: strings.progressInline(count, target),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Center(
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _pressed = true),
                  onTapUp: (_) => setState(() => _pressed = false),
                  onTapCancel: () => setState(() => _pressed = false),
                  onTap: isPresetCompleted ? null : _increment,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 120),
                    scale: _pressed ? 0.96 : 1,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isPresetCompleted
                              ? [
                                  colorScheme.surfaceContainerHighest,
                                  colorScheme.surfaceContainerHighest,
                                ]
                              : [colorScheme.primary, colorScheme.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isPresetCompleted
                                ? colorScheme.shadow.withValues(alpha: 0.04)
                                : colorScheme.primary.withValues(alpha: 0.30),
                            blurRadius: 30,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          isPresetCompleted
                              ? strings.completedLabel
                              : strings.tapToCount,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: isPresetCompleted
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (isPresetCompleted)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    strings.tasbihCompletedBody,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      height: 1.45,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (widget.isPreset) {
                          controller.decrementPresetSet(widget.setId!);
                        } else {
                          controller.decrementDhikr(widget.dhikrId!);
                        }
                      },
                      icon: const Icon(Icons.remove_rounded),
                      label: Text(strings.undoLabel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () {
                        if (widget.isPreset) {
                          controller.resetPresetSet(widget.setId!);
                        } else {
                          controller.resetDhikr(widget.dhikrId!);
                        }
                      },
                      icon: const Icon(Icons.replay_rounded),
                      label: Text(strings.resetCounterLabel),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({required this.label, required this.isActive});

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? colorScheme.primary.withValues(alpha: 0.14)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: isActive ? colorScheme.primary : null,
        ),
      ),
    );
  }
}

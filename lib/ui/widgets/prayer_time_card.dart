import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/prayer_time_model.dart';
import '../../state/app_settings_controller.dart';

class PrayerTimeCard extends StatelessWidget {
  const PrayerTimeCard({
    super.key,
    required this.entry,
    required this.timeLabel,
    required this.isHighlighted,
  });

  final PrayerTimeEntry entry;
  final String timeLabel;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final strings = context.watch<AppSettingsController>().strings;
    const highlightBase = Color(0xFF145A41);
    const highlightAccent = Color(0xFF1F7A58);
    const highlightText = Color(0xFFF3FFF8);
    const highlightSubtle = Color(0xFFBFE8CF);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: isHighlighted ? highlightBase : colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isHighlighted
              ? highlightAccent
              : colorScheme.outlineVariant.withValues(alpha: 0.7),
          width: isHighlighted ? 2 : 1,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: highlightAccent.withValues(alpha: 0.28),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 6,
            height: 58,
            decoration: BoxDecoration(
              color: isHighlighted
                  ? highlightAccent
                  : colorScheme.outlineVariant.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isHighlighted
                  ? highlightAccent.withValues(alpha: 0.35)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              entry.name.icon,
              color: isHighlighted
                  ? highlightText
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.prayerLabel(entry.name),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: isHighlighted ? highlightText : null,
                        ),
                      ),
                    ),
                    if (isHighlighted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: highlightAccent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          strings.upNext,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: highlightText,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isHighlighted ? strings.upNext : strings.scheduledToday,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isHighlighted
                        ? highlightSubtle
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? highlightAccent.withValues(alpha: 0.32)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              timeLabel,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: isHighlighted ? highlightText : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

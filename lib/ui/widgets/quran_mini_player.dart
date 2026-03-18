import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/ayah.dart';
import '../../models/reciter_option.dart';
import '../../state/app_settings_controller.dart';

class QuranMiniPlayer extends StatelessWidget {
  const QuranMiniPlayer({
    super.key,
    required this.ayah,
    required this.reciterName,
    required this.availableReciters,
    required this.selectedReciterId,
    required this.isPlaying,
    required this.onPlayPausePressed,
    required this.onJumpPressed,
    required this.onReciterSelected,
  });

  final Ayah ayah;
  final String reciterName;
  final List<ReciterOption> availableReciters;
  final String selectedReciterId;
  final bool isPlaying;
  final Future<void> Function() onPlayPausePressed;
  final VoidCallback onJumpPressed;
  final Future<void> Function(String reciterId) onReciterSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final strings = context.read<AppSettingsController>().strings;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          children: [
            IconButton.filledTonal(
              tooltip: isPlaying
                  ? strings.pauseAudioLabel
                  : strings.resumeAudioLabel,
              onPressed: onPlayPausePressed,
              icon: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.currentPlaybackLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${strings.ayahNumberLabel(ayah.ayahNumber)} • $reciterName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ayah.arabicText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: strings.jumpToCurrentAyahLabel,
              onPressed: onJumpPressed,
              icon: const Icon(Icons.my_location_rounded),
            ),
            PopupMenuButton<String>(
              tooltip: strings.reciterSectionTitle,
              icon: const Icon(Icons.record_voice_over_rounded),
              onSelected: (value) {
                unawaited(onReciterSelected(value));
              },
              itemBuilder: (context) => availableReciters
                  .map(
                    (reciter) => PopupMenuItem<String>(
                      value: reciter.id,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              reciter.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (reciter.id == selectedReciterId) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/ayah.dart';
import '../../services/ayah_comparison_service.dart';
import '../../services/local_tajweed_coach_service.dart';
import '../../state/app_settings_controller.dart';
import 'feedback_words_view.dart';
import 'quran_ayah_number_mark.dart';

class AyahTile extends StatelessWidget {
  const AyahTile({
    super.key,
    required this.ayah,
    required this.isActive,
    required this.isPlayingAudio,
    required this.highlightedWordIndex,
    required this.isStopMarker,
    required this.isListening,
    required this.isAutoReading,
    required this.rawRecognizedText,
    required this.correctedRecognizedText,
    required this.result,
    required this.coachResult,
    required this.feedbackMessage,
    required this.onListenPressed,
    required this.onReadPressed,
    required this.onAutoReadPressed,
    required this.onStopMarkerPressed,
  });

  final Ayah ayah;
  final bool isActive;
  final bool isPlayingAudio;
  final int? highlightedWordIndex;
  final bool isStopMarker;
  final bool isListening;
  final bool isAutoReading;
  final String rawRecognizedText;
  final String correctedRecognizedText;
  final ComparisonResult? result;
  final LocalCoachResult? coachResult;
  final String? feedbackMessage;
  final VoidCallback onListenPressed;
  final VoidCallback onReadPressed;
  final VoidCallback onAutoReadPressed;
  final VoidCallback onStopMarkerPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final strings = context.watch<AppSettingsController>().strings;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isActive
            ? colorScheme.primaryContainer.withValues(alpha: 0.45)
            : isPlayingAudio
            ? colorScheme.tertiaryContainer.withValues(alpha: 0.42)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isActive
              ? colorScheme.primary
              : isPlayingAudio
              ? colorScheme.tertiary
              : colorScheme.outlineVariant.withValues(alpha: 0.7),
          width: isActive ? 1.3 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _ActionIconButton(
                tooltip: strings.listen,
                onPressed: onListenPressed,
                icon: Icons.volume_up_rounded,
              ),
              const SizedBox(width: 8),
              _ActionIconButton(
                tooltip: isStopMarker
                    ? strings.savedStopPointTooltip
                    : strings.markStopPointTooltip,
                onPressed: onStopMarkerPressed,
                icon: isStopMarker
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
              ),
              const SizedBox(width: 8),
              _ActionIconButton(
                tooltip: isListening && isActive ? strings.stop : strings.read,
                onPressed: onReadPressed,
                isPrimary: true,
                icon: isListening && isActive
                    ? Icons.stop_circle_rounded
                    : Icons.mic_rounded,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: strings.isRtl
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAutoReadPressed,
              icon: Icon(
                isAutoReading && isActive
                    ? Icons.stop_circle_outlined
                    : Icons.play_circle_outline,
              ),
              label: Text(
                isAutoReading && isActive
                    ? strings.stopAutoReading
                    : strings.autoReadingPrompt,
              ),
            ),
          ),
          const SizedBox(height: 16),
          RichText(
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 31,
                height: 1.82,
                fontFamilyFallback: ['Times New Roman', 'serif'],
              ).copyWith(color: colorScheme.onSurface),
              children: _buildArabicWordSpans(colorScheme),
            ),
          ),
          if (isPlayingAudio && highlightedWordIndex != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Playback highlight follows the recitation timing.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.tertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (ayah.kurdishText != null &&
              ayah.kurdishText!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              ayah.kurdishText!,
              textAlign: strings.isRtl ? TextAlign.right : TextAlign.left,
              textDirection: strings.isRtl
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.7,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (isStopMarker) ...[
            const SizedBox(height: 12),
            Align(
              alignment: strings.isRtl
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  strings.youStoppedHereLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ),
          ],
          if (isActive && rawRecognizedText.isNotEmpty) ...[
            const SizedBox(height: 16),
            _TranscriptCard(
              title: strings.rawTranscript,
              text: rawRecognizedText,
            ),
          ],
          if (isActive &&
              correctedRecognizedText.isNotEmpty &&
              (result?.mode == ComparisonMode.tajweed ||
                  correctedRecognizedText != rawRecognizedText)) ...[
            const SizedBox(height: 12),
            _TranscriptCard(
              title: result?.mode == ComparisonMode.tajweed
                  ? strings.tajweedTranscript
                  : strings.quranCorrectedTranscript,
              text: correctedRecognizedText,
              emphasized: true,
            ),
          ],
          if (result != null && result!.words.isNotEmpty) ...[
            const SizedBox(height: 16),
            FeedbackWordsView(result: result!),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _metricLabels(result!)
                  .map((label) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ],
          if (coachResult != null && coachResult!.hasContent) ...[
            const SizedBox(height: 14),
            _CoachCard(
              coachResult: coachResult!,
              onReplayPressed: onListenPressed,
            ),
          ],
          if (feedbackMessage != null) ...[
            const SizedBox(height: 14),
            Text(
              feedbackMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: result?.isPerfect ?? false
                    ? Colors.green.shade700
                    : result?.hasOnlyTajweedMistakes ?? false
                    ? Colors.orange.shade800
                    : colorScheme.error,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<TextSpan> _buildArabicWordSpans(ColorScheme colorScheme) {
    final words = ayah.arabicText
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) {
      return [
        TextSpan(
          text: ayah.arabicText,
          style: const TextStyle(
            fontSize: 31,
            height: 1.82,
            fontFamilyFallback: ['Times New Roman', 'serif'],
          ),
        ),
      ];
    }

    final spans = <TextSpan>[];
    for (var index = 0; index < words.length; index++) {
      final word = words[index];
      final isCurrentWord = isPlayingAudio && highlightedWordIndex == index;
      final isPassedWord =
          isPlayingAudio &&
          highlightedWordIndex != null &&
          index < highlightedWordIndex!;
      spans.add(
        TextSpan(
          text: index == words.length - 1 ? word : '$word ',
          style:
              const TextStyle(
                fontSize: 31,
                height: 1.82,
                fontFamilyFallback: ['Times New Roman', 'serif'],
              ).copyWith(
                color: isCurrentWord
                    ? colorScheme.onTertiaryContainer
                    : colorScheme.onSurface,
                backgroundColor: isCurrentWord
                    ? colorScheme.tertiaryContainer
                    : isPassedWord
                    ? colorScheme.tertiaryContainer.withValues(alpha: 0.38)
                    : null,
                fontWeight: isCurrentWord ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      );
    }
    spans.add(
      TextSpan(
        text: '  ${quranAyahMarker(ayah.ayahNumber)}',
        style: const TextStyle(
          fontSize: 31,
          height: 1.82,
          fontFamilyFallback: ['Times New Roman', 'serif'],
        ).copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    return spans;
  }

  List<String> _metricLabels(ComparisonResult result) {
    if (result.mode == ComparisonMode.tajweed) {
      return [
        'Score ${(result.similarityScore * 100).round()}%',
        'Tajweed ${(result.tajweedScore * 100).round()}%',
        'WER ${(result.wordErrorRate * 100).round()}%',
        'CER ${(result.charErrorRate * 100).round()}%',
      ];
    }

    return [
      'Score ${(result.similarityScore * 100).round()}%',
      'WER ${(result.wordErrorRate * 100).round()}%',
      'CER ${(result.charErrorRate * 100).round()}%',
    ];
  }
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({required this.coachResult, required this.onReplayPressed});

  final LocalCoachResult coachResult;
  final VoidCallback onReplayPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Local coach',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (coachResult.focusWords.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: coachResult.focusWords
                  .map((word) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        word,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ],
          if (coachResult.hints.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final hint in coachResult.hints) ...[
              _CoachHintRow(hint: hint),
              if (hint != coachResult.hints.last) const SizedBox(height: 8),
            ],
          ],
          if (coachResult.shouldSuggestReplay) ...[
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: onReplayPressed,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Replay difficult ayah'),
            ),
          ],
        ],
      ),
    );
  }
}

class _CoachHintRow extends StatelessWidget {
  const _CoachHintRow({required this.hint});

  final LocalCoachHint hint;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isWarning = hint.severity == LocalCoachHintSeverity.warning;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isWarning ? Icons.warning_amber_rounded : Icons.lightbulb_outline,
          size: 18,
          color: isWarning ? Colors.orange.shade800 : colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hint.message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    this.isPrimary = false,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: isPrimary
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              color: isPrimary
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _TranscriptCard extends StatelessWidget {
  const _TranscriptCard({
    required this.title,
    required this.text,
    this.emphasized = false,
  });

  final String title;
  final String text;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: emphasized
            ? colorScheme.primaryContainer.withValues(alpha: 0.42)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(18),
        border: emphasized
            ? Border.all(color: colorScheme.primary.withValues(alpha: 0.35))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 23,
              height: 1.6,
              fontFamilyFallback: ['Times New Roman', 'serif'],
            ),
          ),
        ],
      ),
    );
  }
}

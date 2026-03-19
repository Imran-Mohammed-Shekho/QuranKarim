import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../data/models/memorization_word.dart';
import '../../data/models/surah.dart';
import '../../models/quran_progress_models.dart';
import '../../state/app_settings_controller.dart';
import '../../state/quran_practice_controller.dart';
import '../widgets/quran_ayah_number_mark.dart';

class MemorizationSessionScreen extends StatefulWidget {
  const MemorizationSessionScreen({super.key, required this.surah});

  final Surah surah;

  @override
  State<MemorizationSessionScreen> createState() =>
      _MemorizationSessionScreenState();
}

class _MemorizationSessionScreenState extends State<MemorizationSessionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuranPracticeController>().loadMemorizationSurah(
        widget.surah.number,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final strings = context.watch<AppSettingsController>().strings;

    return Scaffold(
      appBar: AppBar(title: Text(strings.memorizationModeTitle)),
      body: Consumer<QuranPracticeController>(
        builder: (context, controller, _) {
          final checkpoint = controller.checkpointForSurah(widget.surah.number);
          final stage = controller.memorizationStageForSurah(
            widget.surah.number,
          );
          if (controller.isMemorizationLoading &&
              controller.memorizationWords.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.memorizationError != null &&
              controller.memorizationWords.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      controller.memorizationError!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: () =>
                          controller.loadMemorizationSurah(widget.surah.number),
                      child: Text(strings.retry),
                    ),
                  ],
                ),
              ),
            );
          }

          final totalWords = controller.memorizationWords.length;
          final revealed = controller.memorizationRevealedCount;
          final progress = totalWords == 0
              ? 0.0
              : (revealed / totalWords).clamp(0.0, 1.0);
          final stageSummary = strings.memorizationStageSummary(
            stage,
            revealedWords: checkpoint?.revealedWords ?? revealed,
            totalWords: checkpoint?.totalWords ?? totalWords,
            lastMistakeWordIndex: checkpoint?.lastMistakeWordIndex,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.65),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.surah.nameArabic,
                        textDirection: TextDirection.rtl,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.surah.nameEnglish,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _WorkflowStagePill(
                        label: strings.memorizationStageLabel(stage),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _StatusChip(
                            label: controller.isMemorizationListening
                                ? strings.memorizationListening
                                : strings.memorizationStopped,
                            icon: controller.isMemorizationListening
                                ? Icons.graphic_eq_rounded
                                : Icons.pause_circle_filled_rounded,
                            isActive: controller.isMemorizationListening,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              strings.memorizationProgressLabel(
                                revealed,
                                totalWords,
                              ),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        stageSummary,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (stage == MemorizationWorkflowStage.newLesson) ...[
                  _FeedbackCard(
                    title: strings.memorizationWorkflowTitle,
                    body: strings.memorizationWorkflowBody,
                    tone: _FeedbackTone.success,
                  ),
                  const SizedBox(height: 16),
                ],
                if (stage == MemorizationWorkflowStage.continueLesson &&
                    checkpoint != null) ...[
                  _FeedbackCard(
                    title: strings.memorizationSavedCheckpointTitle,
                    body: strings.memorizationSavedCheckpointBody(
                      checkpoint.revealedWords,
                      checkpoint.totalWords > 0
                          ? checkpoint.totalWords
                          : totalWords,
                    ),
                    tone: _FeedbackTone.success,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.tonal(
                        onPressed: controller.startMemorization,
                        child: Text(strings.memorizationResumeLesson),
                      ),
                      OutlinedButton(
                        onPressed: controller.retryMemorization,
                        child: Text(strings.memorizationStartFromBeginning),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                if (stage == MemorizationWorkflowStage.needsPractice &&
                    checkpoint != null) ...[
                  _FeedbackCard(
                    title: strings.memorizationStageLabel(stage),
                    body: stageSummary,
                    tone: _FeedbackTone.error,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.tonal(
                        onPressed: controller.practiceMemorizationWeakPoint,
                        child: Text(strings.memorizationPracticeWeakPoint),
                      ),
                      OutlinedButton(
                        onPressed: controller.retryMemorization,
                        child: Text(strings.memorizationStartFromBeginning),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                if (stage == MemorizationWorkflowStage.memorized &&
                    checkpoint != null &&
                    !controller.memorizationCompleted &&
                    !controller.isMemorizationListening) ...[
                  _FeedbackCard(
                    title: strings.memorizationCompletedTitle,
                    body: strings.memorizationCompletedBody,
                    tone: _FeedbackTone.success,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.tonal(
                        onPressed: controller.reviewMemorizationFromBeginning,
                        child: Text(strings.memorizationReviewFromBeginning),
                      ),
                      OutlinedButton(
                        onPressed: controller.retryMemorization,
                        child: Text(strings.memorizationStartFromBeginning),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: controller.isMemorizationListening
                          ? controller.stopMemorizationListening
                          : controller.startMemorization,
                      icon: Icon(
                        controller.isMemorizationListening
                            ? Icons.stop_circle_rounded
                            : Icons.mic_rounded,
                      ),
                      label: Text(
                        controller.isMemorizationListening
                            ? strings.memorizationStopRecitation
                            : strings.memorizationStartRecitation,
                      ),
                    ),
                  ],
                ),
                if (!controller.isMemorizationListening &&
                    !controller.memorizationCompleted &&
                    revealed == 0) ...[
                  const SizedBox(height: 10),
                  Text(
                    strings.memorizationTapToStart,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (controller.memorizationCompleted) ...[
                  const SizedBox(height: 16),
                  _FeedbackCard(
                    title: strings.memorizationCompletedTitle,
                    body: strings.memorizationCompletedBody,
                    tone: _FeedbackTone.success,
                  ),
                ],
                if (controller.hasMemorizationMistake) ...[
                  const SizedBox(height: 16),
                  _FeedbackCard(
                    title: strings.memorizationMistakeTitle,
                    body: _buildMistakeBody(
                      expected: controller.memorizationExpectedWord,
                      spoken: controller.memorizationSpokenWord,
                      strings: strings,
                    ),
                    tone: _FeedbackTone.error,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton(
                        onPressed: controller.retryMemorization,
                        child: Text(strings.memorizationRetry),
                      ),
                      FilledButton(
                        onPressed: controller.continueMemorization,
                        child: Text(strings.memorizationContinue),
                      ),
                    ],
                  ),
                ],
                if (controller.memorizationError != null &&
                    controller.memorizationWords.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _FeedbackCard(
                    title: strings.memorizationErrorTitle,
                    body: controller.memorizationError!,
                    tone: _FeedbackTone.error,
                  ),
                ],
                if (controller.memorizationRawText.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _TranscriptCard(
                    title: strings.rawTranscript,
                    text: controller.memorizationRawText,
                  ),
                ],
                const SizedBox(height: 20),
                _WordRevealPanel(
                  words: controller.memorizationWords,
                  revealedCount: controller.memorizationRevealedCount,
                  useArabicDigits: strings.isRtl,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _buildMistakeBody({
    required String? expected,
    required String? spoken,
    required AppStrings strings,
  }) {
    final expectedWord = expected ?? '';
    final spokenWord = spoken ?? '';
    if (spokenWord.isEmpty) {
      return '${strings.memorizationExpectedWordLabel}: $expectedWord';
    }
    return '${strings.memorizationExpectedWordLabel}: $expectedWord\n'
        '${strings.memorizationSpokenWordLabel}: $spokenWord';
  }
}

class _WorkflowStagePill extends StatelessWidget {
  const _WorkflowStagePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.icon,
    required this.isActive,
  });

  final String label;
  final IconData icon;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? colorScheme.primaryContainer.withValues(alpha: 0.7)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isActive
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: isActive
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

enum _FeedbackTone { error, success }

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.title,
    required this.body,
    required this.tone,
  });

  final String title;
  final String body;
  final _FeedbackTone tone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSuccess = tone == _FeedbackTone.success;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSuccess
            ? colorScheme.primaryContainer.withValues(alpha: 0.45)
            : colorScheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSuccess
              ? colorScheme.primary.withValues(alpha: 0.4)
              : colorScheme.error.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: isSuccess
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isSuccess
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _TranscriptCard extends StatelessWidget {
  const _TranscriptCard({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(18),
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

class _WordRevealPanel extends StatelessWidget {
  const _WordRevealPanel({
    required this.words,
    required this.revealedCount,
    required this.useArabicDigits,
  });

  final List<MemorizationWord> words;
  final int revealedCount;
  final bool useArabicDigits;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final spans = <InlineSpan>[];
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final isRevealed = i < revealedCount;
      final isLastWordOfAyah =
          i == words.length - 1 || words[i + 1].ayahNumber != word.ayahNumber;

      spans.add(
        TextSpan(
          text: '${word.word} ',
          style:
              const TextStyle(
                fontSize: 28,
                height: 1.7,
                fontFamilyFallback: ['Times New Roman', 'serif'],
              ).copyWith(
                color: isRevealed ? colorScheme.onSurface : Colors.transparent,
              ),
        ),
      );

      if (isLastWordOfAyah) {
        final showAyahMarker = revealedCount >= i + 1;
        spans.add(
          TextSpan(
            text:
                '  ${quranAyahMarker(word.ayahNumber, useArabicIndicDigits: useArabicDigits)} ',
            style:
                const TextStyle(
                  fontSize: 28,
                  height: 1.7,
                  fontFamilyFallback: ['Times New Roman', 'serif'],
                ).copyWith(
                  color: showAyahMarker
                      ? colorScheme.primary
                      : Colors.transparent,
                  fontWeight: FontWeight.w900,
                ),
          ),
        );
        if (showAyahMarker) {
          spans.add(
            TextSpan(
              text: ' ',
              style:
                  const TextStyle(
                    fontSize: 28,
                    height: 1.7,
                    fontFamilyFallback: ['Times New Roman', 'serif'],
                  ).copyWith(color: colorScheme.onSurface),
            ),
          );
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: RichText(
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.justify,
          text: TextSpan(children: spans),
        ),
      ),
    );
  }
}

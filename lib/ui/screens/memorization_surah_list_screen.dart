import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/surah.dart';
import '../../models/quran_progress_models.dart';
import '../../state/app_settings_controller.dart';
import '../../state/quran_practice_controller.dart';
import 'memorization_session_screen.dart';

class MemorizationSurahListScreen extends StatefulWidget {
  const MemorizationSurahListScreen({super.key});

  @override
  State<MemorizationSurahListScreen> createState() =>
      _MemorizationSurahListScreenState();
}

class _MemorizationSurahListScreenState
    extends State<MemorizationSurahListScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<QuranPracticeController>();
      if (controller.surahs.isEmpty && !controller.isLoadingSurahs) {
        controller.loadSurahs();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final strings = context.watch<AppSettingsController>().strings;

    return Scaffold(
      appBar: AppBar(title: Text(strings.memorizationModeTitle)),
      body: SafeArea(
        bottom: false,
        child: Consumer<QuranPracticeController>(
          builder: (context, controller, _) {
            final filteredSurahs =
                controller.surahs
                    .where((surah) {
                      if (_query.trim().isEmpty) {
                        return true;
                      }

                      final normalizedQuery = _query.trim().toLowerCase();
                      return surah.number.toString().contains(
                            normalizedQuery,
                          ) ||
                          surah.nameEnglish.toLowerCase().contains(
                            normalizedQuery,
                          ) ||
                          surah.nameArabic.contains(_query.trim());
                    })
                    .toList(growable: true)
                  ..sort((a, b) {
                    final stageA = controller.memorizationStageForSurah(
                      a.number,
                    );
                    final stageB = controller.memorizationStageForSurah(
                      b.number,
                    );
                    final priority =
                        _stagePriority(stageA) - _stagePriority(stageB);
                    if (priority != 0) {
                      return priority;
                    }

                    final checkpointA = controller.checkpointForSurah(a.number);
                    final checkpointB = controller.checkpointForSurah(b.number);
                    if (checkpointA != null && checkpointB != null) {
                      return checkpointB.updatedAt.compareTo(
                        checkpointA.updatedAt,
                      );
                    }
                    return a.number.compareTo(b.number);
                  });
            final stageCounts = <MemorizationWorkflowStage, int>{
              for (final stage in MemorizationWorkflowStage.values) stage: 0,
            };
            for (final surah in controller.surahs) {
              final stage = controller.memorizationStageForSurah(surah.number);
              stageCounts[stage] = (stageCounts[stage] ?? 0) + 1;
            }

            if (controller.isLoadingSurahs && controller.surahs.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.globalError != null && controller.surahs.isEmpty) {
              return _ErrorState(
                message: controller.globalError!,
                onRetry: controller.loadSurahs,
              );
            }

            return RefreshIndicator(
              onRefresh: controller.loadSurahs,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Text(
                          strings.memorizationModeSubtitle,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.memorizationWorkflowTitle,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                strings.memorizationWorkflowBody,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: MemorizationWorkflowStage.values
                                    .map(
                                      (stage) => _StageCountChip(
                                        label: strings.memorizationStageLabel(
                                          stage,
                                        ),
                                        count: stageCounts[stage] ?? 0,
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          onChanged: (value) {
                            setState(() {
                              _query = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: strings.searchSurahHint,
                            prefixIcon: const Icon(Icons.search_rounded),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _query.trim().isEmpty
                              ? strings.allSurahs
                              : strings.resultsFor(_query.trim()),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          strings.surahCountLabel(filteredSurahs.length),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 14),
                      ]),
                    ),
                  ),
                  if (filteredSurahs.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptySearchState(query: _query),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final surah = filteredSurahs[index];
                          final checkpoint = controller.checkpointForSurah(
                            surah.number,
                          );
                          final stage = controller.memorizationStageForSurah(
                            surah.number,
                          );

                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == filteredSurahs.length - 1
                                  ? 0
                                  : 12,
                            ),
                            child: _SurahCard(
                              surah: surah,
                              stage: stage,
                              summary: strings.memorizationStageSummary(
                                stage,
                                revealedWords: checkpoint?.revealedWords ?? 0,
                                totalWords: checkpoint?.totalWords ?? 0,
                                lastMistakeWordIndex:
                                    checkpoint?.lastMistakeWordIndex,
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        MemorizationSessionScreen(surah: surah),
                                  ),
                                );
                              },
                            ),
                          );
                        }, childCount: filteredSurahs.length),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SurahCard extends StatelessWidget {
  const _SurahCard({
    required this.surah,
    required this.stage,
    required this.summary,
    required this.onTap,
  });

  final Surah surah;
  final MemorizationWorkflowStage stage;
  final String summary;
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.65),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  '${surah.number}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.nameEnglish,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _StageBadge(label: strings.memorizationStageLabel(stage)),
                  const SizedBox(height: 6),
                  Text(
                    summary,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.ayahCountInline(surah.ayahCount),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  surah.nameArabic,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Icon(Icons.arrow_forward_rounded, color: colorScheme.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StageCountChip extends StatelessWidget {
  const _StageCountChip({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label • $count',
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StageBadge extends StatelessWidget {
  const _StageBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.55),
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

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 52,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              context.read<AppSettingsController>().strings.noSurahMatches(
                query.trim(),
              ),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              context.read<AppSettingsController>().strings.searchTryAnother,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

int _stagePriority(MemorizationWorkflowStage stage) {
  return switch (stage) {
    MemorizationWorkflowStage.needsPractice => 0,
    MemorizationWorkflowStage.continueLesson => 1,
    MemorizationWorkflowStage.newLesson => 2,
    MemorizationWorkflowStage.memorized => 3,
  };
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onRetry,
              child: Text(context.read<AppSettingsController>().strings.retry),
            ),
          ],
        ),
      ),
    );
  }
}

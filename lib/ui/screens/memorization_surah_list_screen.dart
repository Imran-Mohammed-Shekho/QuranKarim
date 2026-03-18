import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/surah.dart';
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
            final filteredSurahs = controller.surahs
                .where((surah) {
                  if (_query.trim().isEmpty) {
                    return true;
                  }

                  final normalizedQuery = _query.trim().toLowerCase();
                  return surah.number.toString().contains(normalizedQuery) ||
                      surah.nameEnglish
                          .toLowerCase()
                          .contains(normalizedQuery) ||
                      surah.nameArabic.contains(_query.trim());
                })
                .toList(growable: false);

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

                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == filteredSurahs.length - 1
                                  ? 0
                                  : 12,
                            ),
                            child: _SurahCard(
                              surah: surah,
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
  const _SurahCard({required this.surah, required this.onTap});

  final Surah surah;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                  const SizedBox(height: 6),
                  Text(
                    context
                        .read<AppSettingsController>()
                        .strings
                        .ayahCountInline(surah.ayahCount),
                    style: theme.textTheme.bodyMedium?.copyWith(
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

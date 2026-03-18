import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/surah.dart';
import '../../state/app_settings_controller.dart';
import '../../state/quran_practice_controller.dart';
import 'ayah_reading_screen.dart';
import 'memorization_surah_list_screen.dart';
import '../widgets/quran_mini_player.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  String _query = '';

  void _openSurah(Surah surah, {int? initialAyahNumber}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AyahReadingScreen(
          surah: surah,
          initialAyahNumber: initialAyahNumber,
        ),
      ),
    );
  }

  Future<void> _changeReciter(String reciterId) async {
    final settings = context.read<AppSettingsController>();
    if (settings.selectedReciterId == reciterId) {
      return;
    }
    await settings.setSelectedReciter(reciterId);
  }

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
    final appSettings = context.watch<AppSettingsController>();
    final strings = appSettings.strings;

    return SafeArea(
      bottom: false,
      child: Consumer<QuranPracticeController>(
        builder: (context, controller, _) {
          final lastRead = controller.lastReadProgress;
          final currentPlaybackAyah = controller.currentPlaybackAyah;
          final currentPlaybackSurah = currentPlaybackAyah == null
              ? null
              : controller.surahByNumber(currentPlaybackAyah.surahNumber);
          final hasMiniPlayer = currentPlaybackAyah != null;
          final lastReadSurah = lastRead == null
              ? null
              : controller.surahByNumber(lastRead.surahNumber);
          final filteredSurahs = controller.surahs
              .where((surah) {
                if (_query.trim().isEmpty) {
                  return true;
                }

                final normalizedQuery = _query.trim().toLowerCase();
                return surah.number.toString().contains(normalizedQuery) ||
                    surah.nameEnglish.toLowerCase().contains(normalizedQuery) ||
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

          return Stack(
            children: [
              RefreshIndicator(
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
                            strings.quranLibrary,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            strings.quranLibrarySubtitle,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (lastRead != null && lastReadSurah != null) ...[
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer
                                    .withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: colorScheme.secondary.withValues(
                                    alpha: 0.32,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    strings.resumeWhereStoppedTitle,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${lastReadSurah.nameEnglish} • ${strings.ayahNumberLabel(lastRead.ayahNumber)}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  FilledButton.tonalIcon(
                                    onPressed: () => _openSurah(
                                      lastReadSurah,
                                      initialAyahNumber: lastRead.ayahNumber,
                                    ),
                                    icon: const Icon(Icons.play_circle_rounded),
                                    label: Text(strings.resumeLastReadLabel),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withValues(
                                alpha: 0.35,
                              ),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.memorizationModeTitle,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  strings.memorizationModeSubtitle,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                FilledButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const MemorizationSurahListScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.auto_awesome_rounded),
                                  label: Text(strings.openMemorizationMode),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: colorScheme.outlineVariant.withValues(
                                  alpha: 0.65,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  onChanged: (value) {
                                    setState(() {
                                      _query = value;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    hintText: strings.searchSurahHint,
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_query.trim().isEmpty &&
                              controller.favoriteSurahs.isNotEmpty) ...[
                            Text(
                              strings.favoriteSurahsTitle,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              strings.favoriteSurahsSubtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: controller.favoriteSurahs
                                  .map((surah) {
                                    return ActionChip(
                                      avatar: Icon(
                                        Icons.favorite_rounded,
                                        size: 18,
                                        color: colorScheme.primary,
                                      ),
                                      label: Text(
                                        surah.nameArabic,
                                        textDirection: TextDirection.rtl,
                                      ),
                                      onPressed: () => _openSurah(
                                        surah,
                                        initialAyahNumber: controller
                                            .initialAyahNumberForSurah(
                                              surah.number,
                                            ),
                                      ),
                                    );
                                  })
                                  .toList(growable: false),
                            ),
                            const SizedBox(height: 20),
                          ],
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
                        padding: EdgeInsets.fromLTRB(
                          20,
                          0,
                          20,
                          hasMiniPlayer ? 232 : 120,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final surah = filteredSurahs[index];

                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index == filteredSurahs.length - 1
                                    ? 0
                                    : 12,
                              ),
                              child: _SurahCard(
                                surah: surah,
                                isFavorite: controller.isFavoriteSurah(
                                  surah.number,
                                ),
                                onFavoritePressed: () => controller
                                    .toggleFavoriteSurah(surah.number),
                                onTap: () => _openSurah(
                                  surah,
                                  initialAyahNumber: controller
                                      .initialAyahNumberForSurah(surah.number),
                                ),
                              ),
                            );
                          }, childCount: filteredSurahs.length),
                        ),
                      ),
                  ],
                ),
              ),
              if (currentPlaybackAyah != null && currentPlaybackSurah != null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    top: false,
                    minimum: const EdgeInsets.fromLTRB(16, 0, 16, 102),
                    child: QuranMiniPlayer(
                      ayah: currentPlaybackAyah,
                      reciterName: appSettings.availableReciters
                          .firstWhere(
                            (reciter) =>
                                reciter.id == appSettings.selectedReciterId,
                            orElse: () => appSettings.availableReciters.first,
                          )
                          .displayName,
                      availableReciters: appSettings.availableReciters,
                      selectedReciterId: appSettings.selectedReciterId,
                      isPlaying: controller.isAudioPlaying,
                      onPlayPausePressed: controller.toggleCurrentPlayback,
                      onJumpPressed: () => _openSurah(
                        currentPlaybackSurah,
                        initialAyahNumber: currentPlaybackAyah.ayahNumber,
                      ),
                      onReciterSelected: _changeReciter,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SurahCard extends StatelessWidget {
  const _SurahCard({
    required this.surah,
    required this.isFavorite,
    required this.onFavoritePressed,
    required this.onTap,
  });

  final Surah surah;
  final bool isFavorite;
  final VoidCallback onFavoritePressed;
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.filledTonal(
                      onPressed: onFavoritePressed,
                      style: IconButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
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

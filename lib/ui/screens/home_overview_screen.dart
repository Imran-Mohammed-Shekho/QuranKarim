import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/surah.dart';
import '../../models/quran_progress_models.dart';
import '../../state/app_settings_controller.dart';
import '../../state/prayer_times_controller.dart';
import '../../state/quran_practice_controller.dart';
import '../../state/zikir_controller.dart';
import 'ayah_reading_screen.dart';
import 'god_names_screen.dart';
import 'memorization_session_screen.dart';
import 'tasbih_counter_screen.dart';

class HomeOverviewScreen extends StatefulWidget {
  const HomeOverviewScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  State<HomeOverviewScreen> createState() => _HomeOverviewScreenState();
}

class _HomeOverviewScreenState extends State<HomeOverviewScreen> {
  void _openAyahSession(Surah surah, {required int ayahNumber}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AyahReadingScreen(surah: surah, initialAyahNumber: ayahNumber),
      ),
    );
  }

  void _openMemorizationSession(Surah surah) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MemorizationSessionScreen(surah: surah),
      ),
    );
  }

  void _openSingleZikirCounter(String dhikrId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TasbihCounterScreen.single(dhikrId: dhikrId),
      ),
    );
  }

  void _openPresetZikirCounter(String setId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TasbihCounterScreen.preset(setId: setId),
      ),
    );
  }

  void _openGodNames() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const GodNamesScreen()));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final quranController = context.read<QuranPracticeController>();
      final prayerController = context.read<PrayerTimesController>();

      if (quranController.surahs.isEmpty && !quranController.isLoadingSurahs) {
        quranController.loadSurahs();
      }

      if (prayerController.schedule == null && !prayerController.isLoading) {
        prayerController.refreshPrayerTimes();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final strings = context.watch<AppSettingsController>().strings;

    return SafeArea(
      bottom: false,
      child: Consumer3<QuranPracticeController, PrayerTimesController, ZikirController>(
        builder: (context, quranController, prayerController, zikirController, _) {
          final lastRead = quranController.lastReadProgress;
          final lastReadSurah = lastRead == null
              ? null
              : quranController.surahByNumber(lastRead.surahNumber);
          MemorizationCheckpoint? latestCheckpoint;
          Surah? latestCheckpointSurah;
          for (final surah in quranController.surahs) {
            final checkpoint = quranController.checkpointForSurah(surah.number);
            if (checkpoint == null) {
              continue;
            }
            if (latestCheckpoint == null ||
                checkpoint.updatedAt.isAfter(latestCheckpoint.updatedAt)) {
              latestCheckpoint = checkpoint;
              latestCheckpointSurah = surah;
            }
          }
          final nextPrayer = prayerController.schedule?.nextPrayer;
          final nextPrayerTime = nextPrayer == null
              ? '--:--'
              : DateFormat('h:mm').format(nextPrayer.time);
          _ResumeZikirItem? zikirResumeItem;
          for (final preset in zikirController.presetSets) {
            if (!zikirController.hasProgressForSet(preset.id) ||
                zikirController.overallProgressForSet(preset.id) >= 1) {
              continue;
            }
            final progress = zikirController.progressForSet(preset.id);
            zikirResumeItem = _ResumeZikirItem(
              title: strings.continueZikirSetLabel,
              body:
                  '${preset.titleFor(context.read<AppSettingsController>().language)} • ${strings.stepIndicator(progress.currentStepIndex + 1, preset.steps.length)}',
              onPressed: () => _openPresetZikirCounter(preset.id),
            );
            break;
          }
          if (zikirResumeItem == null) {
            for (final dhikr in zikirController.allDhikrs) {
              final count = zikirController.countForDhikr(dhikr.id);
              final target = zikirController.targetForDhikr(dhikr.id);
              if (count <= 0 || count >= target) {
                continue;
              }
              zikirResumeItem = _ResumeZikirItem(
                title: strings.continueZikirLabel,
                body:
                    '${dhikr.arabicText} • ${strings.progressInline(count, target)}',
                onPressed: () => _openSingleZikirCounter(dhikr.id),
              );
              break;
            }
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
                      strings.greeting,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.overviewIntro,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary,
                            Color.lerp(
                                  colorScheme.primary,
                                  colorScheme.secondary,
                                  0.28,
                                ) ??
                                colorScheme.primary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.30),
                            blurRadius: 28,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              strings.todayFocus,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            nextPrayer == null
                                ? strings.prepareRecitation
                                : strings.nextPrayerAt(
                                    strings.prayerLabel(nextPrayer.name),
                                    nextPrayerTime,
                                  ),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            nextPrayer == null
                                ? strings.enableLocationHint
                                : strings.nextPrayerBeginsIn(
                                    prayerController.countdownLabel,
                                  ),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onPrimary.withValues(
                                alpha: 0.88,
                              ),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              FilledButton.tonal(
                                onPressed: () => widget.onNavigate(1),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: colorScheme.primary,
                                ),
                                child: Text(strings.openQuran),
                              ),
                              OutlinedButton(
                                onPressed: () => widget.onNavigate(3),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.65),
                                  ),
                                  foregroundColor: colorScheme.onPrimary,
                                ),
                                child: Text(strings.prayerTimes),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _FeatureActionCard(
                      title: strings.godNamesTitle,
                      body: strings.godNamesHomeBody,
                      icon: Icons.auto_awesome_rounded,
                      onPressed: _openGodNames,
                      buttonLabel: strings.openGodNames,
                    ),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 640;
                        final cards = [];
                        if (compact) {
                          return Column(
                            children: [
                              for (final card in cards) ...[
                                card,
                                if (card != cards.last)
                                  const SizedBox(height: 12),
                              ],
                            ],
                          );
                        }

                        return Row(
                          children: [
                            for (final card in cards) ...[
                              Expanded(child: card),
                              if (card != cards.last) const SizedBox(width: 12),
                            ],
                          ],
                        );
                      },
                    ),
                    if (lastReadSurah != null ||
                        latestCheckpointSurah != null ||
                        zikirResumeItem != null) ...[
                      const SizedBox(height: 24),
                      _SectionTitle(
                        title: strings.resumeWhereStoppedTitle,
                        subtitle: strings.savedProgressSubtitle,
                      ),
                      const SizedBox(height: 14),
                      if (lastReadSurah != null)
                        _ActionCard(
                          title: strings.resumeLastReadLabel,
                          body:
                              '${lastReadSurah.nameEnglish} • ${strings.ayahNumberLabel(lastRead!.ayahNumber)}',
                          icon: Icons.menu_book_rounded,
                          onPressed: () => _openAyahSession(
                            lastReadSurah,
                            ayahNumber: lastRead.ayahNumber,
                          ),
                          buttonLabel: strings.openAyahLabel,
                        ),
                      if (lastReadSurah != null &&
                          latestCheckpointSurah != null)
                        const SizedBox(height: 12),
                      if (latestCheckpointSurah != null &&
                          latestCheckpoint != null)
                        _ActionCard(
                          title: strings.continueMemorizationLabel,
                          body: strings.recentMemorizationSessionSummary(
                            latestCheckpointSurah.nameEnglish,
                            latestCheckpoint.revealedWords,
                          ),
                          icon: Icons.auto_awesome_rounded,
                          onPressed: () =>
                              _openMemorizationSession(latestCheckpointSurah!),
                          buttonLabel: strings.resumeLabel,
                        ),
                      if ((lastReadSurah != null ||
                              latestCheckpointSurah != null) &&
                          zikirResumeItem != null)
                        const SizedBox(height: 12),
                      if (zikirResumeItem != null)
                        _ActionCard(
                          title: zikirResumeItem.title,
                          body: zikirResumeItem.body,
                          icon: Icons.radio_button_checked_rounded,
                          onPressed: zikirResumeItem.onPressed,
                          buttonLabel: strings.resumeLabel,
                        ),
                    ],
                    if (quranController.recentSessions.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _SectionTitle(
                        title: strings.recentPracticeTitle,
                        subtitle: strings.recentPracticeSubtitle,
                      ),
                      const SizedBox(height: 14),
                      for (final session in quranController.recentSessions.take(
                        3,
                      ))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RecentSessionCard(
                            session: session,
                            surah: quranController.surahByNumber(
                              session.surahNumber,
                            ),
                            onOpen: () {
                              final surah = quranController.surahByNumber(
                                session.surahNumber,
                              );
                              if (surah == null) {
                                widget.onNavigate(1);
                                return;
                              }
                              if (session.type ==
                                  PracticeSessionType.memorization) {
                                _openMemorizationSession(surah);
                              } else {
                                _openAyahSession(
                                  surah,
                                  ayahNumber: session.ayahNumber ?? 1,
                                );
                              }
                            },
                          ),
                        ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

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

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.onPressed,
    required this.buttonLabel,
  });

  final String title;
  final String body;
  final IconData icon;
  final VoidCallback onPressed;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: colorScheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.tonal(
              onPressed: onPressed,
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureActionCard extends StatelessWidget {
  const _FeatureActionCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.onPressed,
    required this.buttonLabel,
  });

  final String title;
  final String body;
  final IconData icon;
  final VoidCallback onPressed;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: colorScheme.secondary),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: onPressed,
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentSessionCard extends StatelessWidget {
  const _RecentSessionCard({
    required this.session,
    required this.surah,
    required this.onOpen,
  });

  final PracticeSessionRecord session;
  final Surah? surah;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final strings = context.read<AppSettingsController>().strings;
    final surahLabel =
        surah?.nameEnglish ?? strings.surahFallbackLabel(session.surahNumber);
    final body = session.type == PracticeSessionType.memorization
        ? strings.recentMemorizationSessionSummary(
            surahLabel,
            session.memorizationWordIndex ?? 0,
          )
        : strings.recentRecitationSessionSummary(
            surahLabel,
            session.ayahNumber ?? 1,
          );

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onOpen,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.68),
          ),
        ),
        child: Row(
          children: [
            Icon(
              session.type == PracticeSessionType.memorization
                  ? Icons.auto_awesome_rounded
                  : Icons.graphic_eq_rounded,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              DateFormat('MMM d, h:mm a').format(session.timestamp),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumeZikirItem {
  const _ResumeZikirItem({
    required this.title,
    required this.body,
    required this.onPressed,
  });

  final String title;
  final String body;
  final VoidCallback onPressed;
}

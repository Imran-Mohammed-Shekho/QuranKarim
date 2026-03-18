import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../data/models/surah.dart';
import '../../services/ayah_comparison_service.dart';
import '../../state/app_settings_controller.dart';
import '../../state/quran_practice_controller.dart';
import '../widgets/ayah_tile.dart';

class AyahReadingScreen extends StatefulWidget {
  const AyahReadingScreen({
    super.key,
    required this.surah,
    this.initialAyahNumber,
  });

  final Surah surah;
  final int? initialAyahNumber;

  @override
  State<AyahReadingScreen> createState() => _AyahReadingScreenState();
}

class _AyahReadingScreenState extends State<AyahReadingScreen> {
  bool _showingArabicSpeechDialog = false;
  final Map<int, GlobalKey> _ayahKeys = <int, GlobalKey>{};
  final ScrollController _scrollController = ScrollController();
  int? _pendingInitialScrollAyahNumber;
  bool _initialScrollCompleted = false;
  int _initialScrollAttempts = 0;

  static const int _maxInitialScrollAttempts = 20;
  static const double _ayahTopInset = 12;

  @override
  void initState() {
    super.initState();
    _pendingInitialScrollAyahNumber = widget.initialAyahNumber;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<QuranPracticeController>().loadAyahs(
        widget.surah.number,
      );
      if (!mounted || widget.initialAyahNumber == null) {
        return;
      }
      _scheduleScrollToAyah(widget.initialAyahNumber!);
    });
  }

  Future<void> _ensureSelectedReciterSurahCached() async {
    if (!mounted) {
      return;
    }
    final settings = context.read<AppSettingsController>();
    await settings.downloadReciterSurah(
      settings.selectedReciterId,
      widget.surah.number,
    );
  }

  Future<void> _changeReciter(String reciterId) async {
    final settings = context.read<AppSettingsController>();
    if (settings.selectedReciterId == reciterId) {
      return;
    }
    await settings.setSelectedReciter(reciterId);
  }

  void _scheduleScrollToAyah(int ayahNumber) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final controller = context.read<QuranPracticeController>();
      unawaited(_scrollToAyahExactly(controller, ayahNumber));
    });
  }

  Future<void> _scrollToAyahExactly(
    QuranPracticeController controller,
    int ayahNumber,
  ) async {
    if (!mounted || _initialScrollCompleted) {
      return;
    }

    final targetContext = _ayahKeys[ayahNumber]?.currentContext;
    if (targetContext != null) {
      final renderObject = targetContext.findRenderObject();
      if (renderObject is RenderObject &&
          renderObject.attached &&
          _scrollController.hasClients) {
        final viewport = RenderAbstractViewport.maybeOf(renderObject);
        if (viewport != null) {
          final reveal = viewport.getOffsetToReveal(renderObject, 0);
          final targetOffset = (reveal.offset - _ayahTopInset).clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          );

          if ((_scrollController.offset - targetOffset).abs() > 1) {
            await _scrollController.animateTo(
              targetOffset,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
            );
          }

          if (!controller.isLoadingAyahs) {
            _initialScrollCompleted = true;
            _pendingInitialScrollAyahNumber = null;
            _initialScrollAttempts = 0;
          } else {
            _scheduleScrollToAyah(ayahNumber);
          }
          return;
        }
      }
    }

    if (!_scrollController.hasClients ||
        _initialScrollAttempts >= _maxInitialScrollAttempts) {
      return;
    }

    final nextOffset =
        (_scrollController.offset +
                (_scrollController.position.viewportDimension * 0.9))
            .clamp(0.0, _scrollController.position.maxScrollExtent);
    if ((nextOffset - _scrollController.offset).abs() < 8) {
      return;
    }
    _initialScrollAttempts++;
    await _scrollController.animateTo(
      nextOffset,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );

    if (!_initialScrollCompleted) {
      _scheduleScrollToAyah(ayahNumber);
    }
  }

  GlobalKey _keyForAyah(int ayahNumber) {
    return _ayahKeys.putIfAbsent(ayahNumber, GlobalKey.new);
  }

  void _maybeShowArabicSpeechDialog(QuranPracticeController controller) {
    if (_showingArabicSpeechDialog ||
        !controller.shouldPromptArabicSpeechInstall) {
      return;
    }

    _showingArabicSpeechDialog = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Arabic speech not installed'),
          content: const Text(
            'Arabic speech recognition is not installed.\n'
            'Please install Arabic language from Google Speech Services.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (!mounted) {
        return;
      }
      controller.acknowledgeArabicSpeechPrompt();
      setState(() {
        _showingArabicSpeechDialog = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appSettings = context.watch<AppSettingsController>();
    final strings = appSettings.strings;
    final selectedReciter = appSettings.availableReciters.firstWhere(
      (reciter) => reciter.id == appSettings.selectedReciterId,
      orElse: () => appSettings.availableReciters.first,
    );
    final isDownloadingSelectedSurah =
        appSettings.downloadingReciterId == selectedReciter.id &&
        appSettings.downloadingSurahNumber == widget.surah.number;
    final isSelectedSurahCached = appSettings.isReciterSurahDownloaded(
      selectedReciter.id,
      widget.surah.number,
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.surah.nameEnglish)),
      body: Consumer<QuranPracticeController>(
        builder: (context, controller, _) {
          _maybeShowArabicSpeechDialog(controller);
          final lastRead = controller.lastReadProgress;
          final pendingScrollAyahNumber = _pendingInitialScrollAyahNumber;
          if (pendingScrollAyahNumber != null &&
              controller.ayahs.any(
                (ayah) => ayah.ayahNumber == pendingScrollAyahNumber,
              )) {
            _scheduleScrollToAyah(pendingScrollAyahNumber);
          }

          if (controller.isLoadingAyahs && controller.ayahs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.globalError != null && controller.ayahs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(controller.globalError!, textAlign: TextAlign.center),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: () =>
                          controller.loadAyahs(widget.surah.number),
                      child: Text(strings.retry),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
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
                      strings.readingReciterTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      strings.readingReciterSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      key: ValueKey<String>(appSettings.selectedReciterId),
                      initialValue: appSettings.selectedReciterId,
                      decoration: InputDecoration(
                        labelText: strings.reciterSectionTitle,
                      ),
                      items: appSettings.availableReciters
                          .map(
                            (reciter) => DropdownMenuItem<String>(
                              value: reciter.id,
                              child: Text(
                                '${reciter.displayName} • ${strings.cachedSurahCountLabel(appSettings.downloadedSurahCount(reciter.id))}',
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value != null) {
                          _changeReciter(value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    if (isDownloadingSelectedSurah) ...[
                      Text(
                        strings.downloadingSurahAudioLabel(
                          selectedReciter.displayName,
                        ),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: appSettings.reciterDownloadProgress?.fraction,
                      ),
                      if (appSettings.reciterDownloadProgress != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          strings.reciterDownloadProgress(
                            appSettings.reciterDownloadProgress!.completedFiles,
                            appSettings.reciterDownloadProgress!.totalFiles,
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ] else ...[
                      Text(
                        isSelectedSurahCached
                            ? strings.surahAudioReadyLabel(
                                selectedReciter.displayName,
                              )
                            : strings.reciterStreamingLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        onPressed: isSelectedSurahCached
                            ? null
                            : _ensureSelectedReciterSurahCached,
                        icon: Icon(
                          isSelectedSurahCached
                              ? Icons.download_done_rounded
                              : Icons.download_rounded,
                        ),
                        label: Text(strings.downloadCurrentSurahAudioLabel),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (controller.isLoadingAyahs && controller.ayahs.isNotEmpty) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 12),
              ],
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
                      strings.surahAyahCount(
                        widget.surah.ayahCount,
                        widget.surah.number,
                      ),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      strings.recitationMode,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<ComparisonMode>(
                      segments: [
                        ButtonSegment<ComparisonMode>(
                          value: ComparisonMode.lenient,
                          label: Text(strings.recitationModeLenient),
                          icon: Icon(Icons.tune_rounded),
                        ),
                        ButtonSegment<ComparisonMode>(
                          value: ComparisonMode.strictArabic,
                          label: Text(strings.recitationModeStrict),
                          icon: Icon(Icons.translate_rounded),
                        ),
                        ButtonSegment<ComparisonMode>(
                          value: ComparisonMode.tajweed,
                          label: Text(strings.recitationModeTajweed),
                          icon: Icon(Icons.auto_awesome_rounded),
                        ),
                      ],
                      selected: {controller.comparisonMode},
                      onSelectionChanged: (selection) {
                        controller.setComparisonMode(selection.first);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                strings.ayahsTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                strings.ayahScreenSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              for (final ayah in controller.ayahs)
                KeyedSubtree(
                  key: _keyForAyah(ayah.ayahNumber),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: AyahTile(
                      ayah: ayah,
                      isActive:
                          controller.practicingAyahNumber == ayah.ayahNumber,
                      isPlayingAudio: controller.isPlayingAudioForAyah(
                        ayah.ayahNumber,
                      ),
                      highlightedWordIndex: controller
                          .highlightedPlaybackWordIndexForAyah(ayah.ayahNumber),
                      isStopMarker:
                          lastRead?.surahNumber == ayah.surahNumber &&
                          lastRead?.ayahNumber == ayah.ayahNumber,
                      isListening: controller.isListening,
                      isAutoReading: controller.isAutoReading,
                      rawRecognizedText:
                          controller.practicingAyahNumber == ayah.ayahNumber
                          ? controller.rawRecognizedText
                          : '',
                      correctedRecognizedText:
                          controller.practicingAyahNumber == ayah.ayahNumber
                          ? controller.displayRecognizedText
                          : '',
                      result: controller.resultForAyah(ayah.ayahNumber),
                      coachResult: controller.coachForAyah(ayah.ayahNumber),
                      feedbackMessage: controller.feedbackForAyah(
                        ayah.ayahNumber,
                      ),
                      onListenPressed: () => controller.playAyah(ayah),
                      onStopMarkerPressed: () =>
                          controller.markLastReadAyah(ayah),
                      onReadPressed: () => controller.toggleReading(ayah),
                      onAutoReadPressed: () =>
                          controller.toggleAutoReading(ayah),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../data/models/ayah.dart';
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
  final TextEditingController _searchController = TextEditingController();
  int? _pendingScrollAyahNumber;
  int _scrollAttempts = 0;
  String _searchQuery = '';

  static const int _maxScrollAttempts = 20;
  static const double _ayahTopInset = 12;

  @override
  void initState() {
    super.initState();
    _pendingScrollAyahNumber = widget.initialAyahNumber;
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
    _pendingScrollAyahNumber = ayahNumber;
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
    if (!mounted || _pendingScrollAyahNumber != ayahNumber) {
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
            _pendingScrollAyahNumber = null;
            _scrollAttempts = 0;
          } else {
            _scheduleScrollToAyah(ayahNumber);
          }
          return;
        }
      }
    }

    if (!_scrollController.hasClients ||
        _scrollAttempts >= _maxScrollAttempts) {
      return;
    }

    final nextOffset =
        (_scrollController.offset +
                (_scrollController.position.viewportDimension * 0.9))
            .clamp(0.0, _scrollController.position.maxScrollExtent);
    if ((nextOffset - _scrollController.offset).abs() < 8) {
      return;
    }
    _scrollAttempts++;
    await _scrollController.animateTo(
      nextOffset,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );

    if (_pendingScrollAyahNumber == ayahNumber) {
      _scheduleScrollToAyah(ayahNumber);
    }
  }

  bool _matchesAyahQuery(String query, Ayah ayah) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return true;
    }

    if ('${ayah.ayahNumber}'.contains(normalizedQuery)) {
      return true;
    }

    if (ayah.arabicText.toLowerCase().contains(normalizedQuery)) {
      return true;
    }

    final kurdishText = ayah.kurdishText?.toLowerCase();
    if (kurdishText != null && kurdishText.contains(normalizedQuery)) {
      return true;
    }

    return false;
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

  Future<void> _showAyahNoteSheet(Ayah ayah) async {
    final controller = context.read<QuranPracticeController>();
    final strings = context.read<AppSettingsController>().strings;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => _AyahNoteSheet(
        ayah: ayah,
        title: strings.studyNoteTitle,
        ayahLabel: strings.ayahNumberLabel(ayah.ayahNumber),
        hintText: strings.ayahNoteHint,
        clearLabel: strings.clearAyahNoteLabel,
        saveLabel: strings.saveAyahNoteLabel,
        initialNote:
            controller.noteForAyah(ayah.surahNumber, ayah.ayahNumber) ?? '',
        onSave: (note) => controller.saveAyahNote(ayah, note),
      ),
    );
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
    final arabicFontSize = appSettings.quranArabicFontSize;
    final showTranslation = appSettings.showQuranTranslation;

    return Scaffold(
      appBar: AppBar(title: Text(widget.surah.nameEnglish)),
      body: Consumer<QuranPracticeController>(
        builder: (context, controller, _) {
          _maybeShowArabicSpeechDialog(controller);
          final lastRead = controller.lastReadProgress;
          final pendingScrollAyahNumber = _pendingScrollAyahNumber;
          final normalizedSearchQuery = _searchQuery.trim();
          final matchedAyahIndex = normalizedSearchQuery.isEmpty
              ? 0
              : controller.ayahs.indexWhere(
                  (ayah) => _matchesAyahQuery(normalizedSearchQuery, ayah),
                );
          final visibleAyahs = matchedAyahIndex < 0
              ? const <Ayah>[]
              : controller.ayahs.sublist(matchedAyahIndex);
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
                            : "",
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
              SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.65),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.readingOptionsTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            strings.arabicFontSizeLabel,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            arabicFontSize.toStringAsFixed(0),
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: arabicFontSize,
                      min: 24,
                      max: 40,
                      divisions: 8,
                      label: arabicFontSize.toStringAsFixed(0),
                      onChanged: (value) {
                        appSettings.setQuranArabicFontSize(value);
                      },
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: showTranslation,
                      onChanged: (value) {
                        appSettings.setShowQuranTranslation(value);
                      },
                      title: Text(
                        strings.showTranslationLabel,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        showTranslation
                            ? strings.translationVisibleLabel
                            : strings.translationHiddenLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
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

              const SizedBox(height: 10),
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: strings.searchAyahHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.trim().isEmpty
                      ? null
                      : IconButton(
                          tooltip: strings.clearAyahSearchLabel,
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.ayahActionsLegendTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _AyahActionLegendChip(
                          icon: Icons.outlined_flag_rounded,
                          title: strings.ayahLastReadLegendLabel,
                          description: strings.ayahLastReadLegendDescription,
                        ),
                        _AyahActionLegendChip(
                          icon: Icons.bookmark_outline_rounded,
                          title: strings.ayahBookmarkLegendLabel,
                          description: strings.ayahBookmarkLegendDescription,
                        ),
                        _AyahActionLegendChip(
                          icon: Icons.edit_note_rounded,
                          title: strings.ayahNoteLegendLabel,
                          description: strings.ayahNoteLegendDescription,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (visibleAyahs.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 40,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          strings.noAyahMatches,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          strings.searchAyahTryAnother,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                for (final ayah in visibleAyahs)
                  KeyedSubtree(
                    key: _keyForAyah(ayah.ayahNumber),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: AyahTile(
                        ayah: ayah,
                        arabicFontSize: arabicFontSize,
                        showTranslation: showTranslation,
                        isStudyBookmarked: controller.isAyahBookmarked(
                          ayah.surahNumber,
                          ayah.ayahNumber,
                        ),
                        noteText: controller.noteForAyah(
                          ayah.surahNumber,
                          ayah.ayahNumber,
                        ),
                        isActive:
                            controller.practicingAyahNumber == ayah.ayahNumber,
                        isPlayingAudio: controller.isPlayingAudioForAyah(
                          ayah.ayahNumber,
                        ),
                        highlightedWordIndex: controller
                            .highlightedPlaybackWordIndexForAyah(
                              ayah.ayahNumber,
                            ),
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
                        onStudyBookmarkPressed: () =>
                            controller.toggleAyahBookmark(ayah),
                        onNotePressed: () => _showAyahNoteSheet(ayah),
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
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _AyahActionLegendChip extends StatelessWidget {
  const _AyahActionLegendChip({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: colorScheme.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AyahNoteSheet extends StatefulWidget {
  const _AyahNoteSheet({
    required this.ayah,
    required this.title,
    required this.ayahLabel,
    required this.hintText,
    required this.clearLabel,
    required this.saveLabel,
    required this.initialNote,
    required this.onSave,
  });

  final Ayah ayah;
  final String title;
  final String ayahLabel;
  final String hintText;
  final String clearLabel;
  final String saveLabel;
  final String initialNote;
  final Future<void> Function(String note) onSave;

  @override
  State<_AyahNoteSheet> createState() => _AyahNoteSheetState();
}

class _AyahNoteSheetState extends State<_AyahNoteSheet> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote);
  }

  Future<void> _save(String note) async {
    if (_saving) {
      return;
    }
    setState(() {
      _saving = true;
    });
    await widget.onSave(note);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.ayahLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              autofocus: true,
              minLines: 4,
              maxLines: 8,
              decoration: InputDecoration(hintText: widget.hintText),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => _save(''),
                    child: Text(widget.clearLabel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : () => _save(_controller.text),
                    child: Text(widget.saveLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../models/god_name.dart';
import '../../state/app_settings_controller.dart';
import '../../state/god_names_controller.dart';

class GodNamesScreen extends StatefulWidget {
  const GodNamesScreen({super.key});

  @override
  State<GodNamesScreen> createState() => _GodNamesScreenState();
}

class _GodNamesScreenState extends State<GodNamesScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<GodNamesController>();
      if (controller.collection == null && !controller.isLoading) {
        controller.bootstrap();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = context.watch<AppSettingsController>();
    final strings = settings.strings;

    return Scaffold(
      appBar: AppBar(title: Text(strings.godNamesTitle)),
      body: Consumer<GodNamesController>(
        builder: (context, controller, _) {
          final collection = controller.collection;
          final names = collection == null
              ? const <GodNameEntry>[]
              : _filterNames(collection.names);

          if (controller.isLoading && collection == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (collection == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      strings.godNamesLoadFailed,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: controller.load,
                      child: Text(strings.godNamesRetryLabel),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _HeroCard(collection: collection, strings: strings),
                      const SizedBox(height: 18),
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            _query = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: strings.godNamesSearchHint,
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: controller.isRefreshing
                              ? Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (names.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.65,
                              ),
                            ),
                          ),
                          child: Text(
                            strings.godNamesNoResults,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = constraints.maxWidth >= 980
                                ? 3
                                : constraints.maxWidth >= 640
                                ? 2
                                : 1;

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: names.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                    mainAxisExtent: 262,
                                  ),
                              itemBuilder: (context, index) {
                                final name = names[index];
                                return _GodNameCard(
                                  name: name,
                                  language: settings.language,
                                  strings: strings,
                                  onTap: () =>
                                      _showDetailsSheet(context, name, strings),
                                );
                              },
                            );
                          },
                        ),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<GodNameEntry> _filterNames(List<GodNameEntry> names) {
    final normalized = _query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return names;
    }

    return names
        .where((name) {
          return name.id.toString().contains(normalized) ||
              name.arabic.name.contains(_query.trim()) ||
              name.arabic.plain.contains(_query.trim()) ||
              name.english.transliteration.toLowerCase().contains(normalized) ||
              name.english.translation.toLowerCase().contains(normalized) ||
              name.kurdish.translation.contains(_query.trim());
        })
        .toList(growable: false);
  }

  Future<void> _showDetailsSheet(
    BuildContext context,
    GodNameEntry name,
    AppStrings strings,
  ) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          maxChildSize: 0.94,
          minChildSize: 0.55,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                children: [
                  Center(
                    child: Container(
                      width: 54,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('#${name.id}'),
                      ),
                      Text(
                        name.english.transliteration,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    name.arabic.name,
                    textDirection: TextDirection.rtl,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name.english.translation,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _MeaningBlock(
                    title: strings.godNamesKurdishMeaningLabel,
                    body: name.kurdish.translation,
                  ),
                  const SizedBox(height: 14),
                  _MeaningBlock(
                    title: strings.godNamesEnglishMeaningLabel,
                    body: name.english.meaning,
                  ),
                  const SizedBox(height: 14),
                  _MeaningBlock(
                    title: strings.godNamesArabicMeaningLabel,
                    body: name.arabic.meaning,
                    isRtl: true,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.collection, required this.strings});

  final GodNamesCollection collection;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          colors: [
            colorScheme.secondary,
            Color.lerp(colorScheme.secondary, colorScheme.primary, 0.45) ??
                colorScheme.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.secondary.withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              strings.godNamesCountLabel(collection.meta.total),
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            collection.meta.titleArabic,
            textDirection: TextDirection.rtl,
            style: theme.textTheme.displaySmall?.copyWith(
              color: colorScheme.onSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            collection.standalone.arabic,
            textDirection: TextDirection.rtl,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: colorScheme.onSecondary.withValues(alpha: 0.95),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            strings.godNamesHeroSubtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSecondary.withValues(alpha: 0.88),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroChip(label: collection.standalone.english),
              _HeroChip(label: collection.standalone.kurdish),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: Colors.white),
      ),
    );
  }
}

class _GodNameCard extends StatelessWidget {
  const _GodNameCard({
    required this.name,
    required this.language,
    required this.strings,
    required this.onTap,
  });

  final GodNameEntry name;
  final AppLanguage language;
  final AppStrings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localizedTranslation = switch (language) {
      AppLanguage.arabic => name.arabic.meaning,
      AppLanguage.kurdish => name.kurdish.translation,
      AppLanguage.english => name.english.translation,
    };
    final supportingText = switch (language) {
      AppLanguage.arabic => name.english.translation,
      AppLanguage.kurdish => name.english.meaning,
      AppLanguage.english => name.english.meaning,
    };

    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.68),
          ),
          gradient: LinearGradient(
            colors: [
              colorScheme.surface,
              colorScheme.primaryContainer.withValues(alpha: 0.22),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '#${name.id}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.auto_awesome_rounded, color: colorScheme.secondary),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              name.arabic.name,
              textDirection: TextDirection.rtl,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name.english.transliteration,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localizedTranslation,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                supportingText,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.godNamesDetailsLabel,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeaningBlock extends StatelessWidget {
  const _MeaningBlock({
    required this.title,
    required this.body,
    this.isRtl = false,
  });

  final String title;
  final String body;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textDirection: isRtl ? TextDirection.rtl : null,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
          ),
        ],
      ),
    );
  }
}

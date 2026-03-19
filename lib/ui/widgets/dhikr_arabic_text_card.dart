import 'package:flutter/material.dart';

import '../../models/dhikr_models.dart';
import 'quran_ayah_number_mark.dart';

class DhikrArabicTextCard extends StatelessWidget {
  const DhikrArabicTextCard({
    super.key,
    required this.dhikr,
    this.padding = const EdgeInsets.all(16),
    this.textStyle,
  });

  final DhikrDefinition dhikr;
  final EdgeInsetsGeometry padding;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final verses = _quranVersesFor(dhikr);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(22),
      ),
      child: SelectionArea(
        child: verses == null
            ? Text(
                dhikr.arabicText,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                softWrap: true,
                style: textStyle,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int index = 0; index < verses.length; index++) ...[
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: verses[index].text),
                          buildQuranAyahMarkerSpan(
                            ayahNumber: verses[index].ayahNumber,
                            style:
                                textStyle ??
                                const TextStyle(
                                  fontSize: 24,
                                  height: 1.85,
                                ),
                            color: colorScheme.primary,
                          ),
                        ],
                      ),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      softWrap: true,
                      style: textStyle,
                    ),
                    if (index != verses.length - 1) const SizedBox(height: 14),
                  ],
                ],
              ),
      ),
    );
  }
}

List<_QuranVerse>? _quranVersesFor(DhikrDefinition dhikr) {
  switch (dhikr.id) {
    case 'morning_ayat_al_kursi':
      return _buildVerseList(dhikr.arabicText, const [255]);
    case 'ikhlas':
      return _buildVerseList(dhikr.arabicText, const [1, 2, 3, 4]);
    case 'falaq':
      return _buildVerseList(dhikr.arabicText, const [1, 2, 3, 4, 5]);
    case 'nas':
      return _buildVerseList(dhikr.arabicText, const [1, 2, 3, 4, 5, 6]);
    default:
      return null;
  }
}

List<_QuranVerse>? _buildVerseList(String arabicText, List<int> ayahNumbers) {
  if (ayahNumbers.length == 1) {
    return <_QuranVerse>[
      _QuranVerse(ayahNumber: ayahNumbers.first, text: arabicText.trim()),
    ];
  }

  final lines = arabicText
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
  if (lines.length != ayahNumbers.length) {
    return null;
  }

  return List<_QuranVerse>.generate(
    lines.length,
    (index) => _QuranVerse(ayahNumber: ayahNumbers[index], text: lines[index]),
    growable: false,
  );
}

class _QuranVerse {
  const _QuranVerse({required this.ayahNumber, required this.text});

  final int ayahNumber;
  final String text;
}

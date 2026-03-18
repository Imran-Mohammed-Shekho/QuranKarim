import 'package:flutter/material.dart';

import '../../services/ayah_comparison_service.dart';

class FeedbackWordsView extends StatelessWidget {
  const FeedbackWordsView({super.key, required this.result});

  final ComparisonResult result;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      textDirection: TextDirection.rtl,
      spacing: 6,
      runSpacing: 6,
      children: result.words
          .map((word) {
            final Color backgroundColor;
            final Color borderColor;
            final Color textColor;

            if (word.isCorrect) {
              backgroundColor = Colors.green.withValues(alpha: 0.22);
              borderColor = Colors.green;
              textColor = Colors.green.shade800;
            } else if (word.isTajweedMismatch) {
              backgroundColor = Colors.orange.withValues(alpha: 0.22);
              borderColor = Colors.orange;
              textColor = Colors.orange.shade900;
            } else {
              backgroundColor = Colors.red.withValues(alpha: 0.22);
              borderColor = Colors.red;
              textColor = Colors.red.shade800;
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor, width: 0.8),
              ),
              child: Text(
                word.isExtraSpokenWord ? '+ ${word.word}' : word.word,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

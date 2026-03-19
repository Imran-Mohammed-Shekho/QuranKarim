import 'package:flutter/material.dart';

InlineSpan buildQuranAyahMarkerSpan({
  required int ayahNumber,
  required TextStyle style,
  required Color color,
  bool useArabicIndicDigits = true,
  bool visible = true,
}) {
  final displayNumber = useArabicIndicDigits
      ? formatArabicIndicNumber(ayahNumber)
      : ayahNumber.toString();
  return TextSpan(
    text: '  ﴿$displayNumber﴾',
    style: style.copyWith(
      color: visible ? color : Colors.transparent,
      fontWeight: FontWeight.w900,
    ),
  );
}

String formatArabicIndicNumber(int value) {
  const western = '0123456789';
  const arabicIndic = '٠١٢٣٤٥٦٧٨٩';
  final digits = value.toString().split('');
  return digits
      .map((digit) => arabicIndic[western.indexOf(digit)])
      .join();
}

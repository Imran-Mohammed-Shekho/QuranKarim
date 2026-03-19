String quranAyahMarker(
  int ayahNumber, {
  bool useArabicIndicDigits = true,
}) {
  final number = useArabicIndicDigits
      ? formatArabicIndicNumber(ayahNumber)
      : ayahNumber.toString();
  return '\uFD3F$number\uFD3E';
}

String formatArabicIndicNumber(int value) {
  const western = '0123456789';
  const arabicIndic = '٠١٢٣٤٥٦٧٨٩';
  final digits = value.toString().split('');
  return digits
      .map((digit) => arabicIndic[western.indexOf(digit)])
      .join();
}

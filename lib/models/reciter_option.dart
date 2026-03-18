class ReciterOption {
  const ReciterOption({required this.id, required this.displayName});

  final String id;
  final String displayName;
}

class ReciterDownloadProgress {
  const ReciterDownloadProgress({
    required this.reciterId,
    required this.completedFiles,
    required this.totalFiles,
    required this.surahNumber,
    required this.ayahNumber,
  });

  final String reciterId;
  final int completedFiles;
  final int totalFiles;
  final int surahNumber;
  final int ayahNumber;

  double get fraction => totalFiles <= 0 ? 0 : completedFiles / totalFiles;
}

class ReciterAyahReference {
  const ReciterAyahReference({
    required this.surahNumber,
    required this.ayahNumber,
  });

  final int surahNumber;
  final int ayahNumber;
}

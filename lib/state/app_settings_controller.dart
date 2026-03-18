import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/localization/app_strings.dart';
import '../models/reciter_option.dart';
import '../services/reciter_download_service.dart';

class AppSettingsController extends ChangeNotifier {
  static const _languageKey = 'app_language';
  static const _themeModeKey = 'app_theme_mode';
  static const _selectedReciterKey = 'selected_reciter';
  static const _onboardingCompletedKey = 'onboarding_completed';

  AppSettingsController({
    required ReciterDownloadService reciterDownloadService,
  }) : _reciterDownloadService = reciterDownloadService;

  final ReciterDownloadService _reciterDownloadService;

  AppLanguage language = AppLanguage.kurdish;
  ThemeMode themeMode = ThemeMode.light;
  String _selectedReciterId = 'banna';
  Map<String, Set<int>> _downloadedSurahsByReciter = <String, Set<int>>{};
  String? _localReciterAudioBasePath;
  bool _isDownloadingReciter = false;
  String? _downloadingReciterId;
  int? _downloadingSurahNumber;
  ReciterDownloadProgress? _reciterDownloadProgress;
  String? _reciterDownloadError;
  bool _hasCompletedOnboarding = false;
  bool _isBootstrapped = false;

  AppStrings get strings => AppStrings(language);

  bool get isRtl => strings.isRtl;
  String get selectedReciterId => _selectedReciterId;
  List<ReciterOption> get availableReciters =>
      ReciterDownloadService.availableReciters;
  String? get localReciterAudioBasePath => _localReciterAudioBasePath;
  bool get isDownloadingReciter => _isDownloadingReciter;
  String? get downloadingReciterId => _downloadingReciterId;
  int? get downloadingSurahNumber => _downloadingSurahNumber;
  ReciterDownloadProgress? get reciterDownloadProgress =>
      _reciterDownloadProgress;
  String? get reciterDownloadError => _reciterDownloadError;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get isBootstrapped => _isBootstrapped;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_languageKey);
    final savedThemeMode = prefs.getString(_themeModeKey);
    final savedReciter = prefs.getString(_selectedReciterKey)?.trim();
    _hasCompletedOnboarding = prefs.getBool(_onboardingCompletedKey) ?? false;
    if (savedLanguage != null) {
      language = AppLanguage.values.firstWhere(
        (value) => value.name == savedLanguage,
        orElse: () => AppLanguage.english,
      );
    }

    if (savedThemeMode != null) {
      themeMode = ThemeMode.values.firstWhere(
        (value) => value.name == savedThemeMode,
        orElse: () => ThemeMode.light,
      );
    }

    _downloadedSurahsByReciter = await _reciterDownloadService
        .loadDownloadedSurahsByReciter();
    _localReciterAudioBasePath = await _reciterDownloadService
        .getLocalAudioBasePath();

    final hasSavedReciter =
        savedReciter != null &&
        availableReciters.any((reciter) => reciter.id == savedReciter);
    if (hasSavedReciter) {
      _selectedReciterId = savedReciter;
    }

    if (!_canSelectReciter(_selectedReciterId)) {
      _selectedReciterId = 'banna';
    }

    _isBootstrapped = true;
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage value) async {
    if (language == value) {
      return;
    }
    language = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, value.name);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode value) async {
    if (themeMode == value) {
      return;
    }
    themeMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, value.name);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    if (_hasCompletedOnboarding) {
      return;
    }

    _hasCompletedOnboarding = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
    notifyListeners();
  }

  Set<int> downloadedSurahsForReciter(String reciterId) {
    return Set.unmodifiable(_downloadedSurahsByReciter[reciterId] ?? <int>{});
  }

  bool isReciterSurahDownloaded(String reciterId, int surahNumber) {
    return _downloadedSurahsByReciter[reciterId]?.contains(surahNumber) ??
        false;
  }

  int downloadedSurahCount(String reciterId) {
    return _downloadedSurahsByReciter[reciterId]?.length ?? 0;
  }

  Future<void> setSelectedReciter(String reciterId) async {
    if (_selectedReciterId == reciterId || !_canSelectReciter(reciterId)) {
      return;
    }
    _selectedReciterId = reciterId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedReciterKey, reciterId);
    notifyListeners();
  }

  Future<void> downloadReciterSurah(String reciterId, int surahNumber) async {
    if (_isDownloadingReciter || !_isKnownReciter(reciterId)) {
      return;
    }
    if (isReciterSurahDownloaded(reciterId, surahNumber)) {
      return;
    }

    _isDownloadingReciter = true;
    _downloadingReciterId = reciterId;
    _downloadingSurahNumber = surahNumber;
    _reciterDownloadProgress = null;
    _reciterDownloadError = null;
    notifyListeners();

    try {
      await _reciterDownloadService.downloadSurah(
        reciterId,
        surahNumber,
        onProgress: (progress) {
          _reciterDownloadProgress = progress;
          notifyListeners();
        },
      );
      _downloadedSurahsByReciter = await _reciterDownloadService
          .loadDownloadedSurahsByReciter();
      _localReciterAudioBasePath ??= await _reciterDownloadService
          .getLocalAudioBasePath();
    } catch (error) {
      _reciterDownloadError = error.toString();
    } finally {
      _isDownloadingReciter = false;
      _downloadingReciterId = null;
      _downloadingSurahNumber = null;
      _reciterDownloadProgress = null;
      notifyListeners();
    }
  }

  bool _isKnownReciter(String reciterId) {
    return availableReciters.any((reciter) => reciter.id == reciterId);
  }

  bool _canSelectReciter(String reciterId) {
    if (!_isKnownReciter(reciterId)) {
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _reciterDownloadService.dispose();
    super.dispose();
  }
}

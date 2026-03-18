import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/dhikr_models.dart';

class DhikrLibraryService {
  static const String _assetPath = 'assets/adhkar_collections.json';

  DhikrLibrary? _cachedLibrary;

  Future<DhikrLibrary> loadLibrary() async {
    if (_cachedLibrary != null) {
      return _cachedLibrary!;
    }
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    _cachedLibrary = DhikrLibrary.fromJson(decoded);
    return _cachedLibrary!;
  }
}

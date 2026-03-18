import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/god_name.dart';
import '../services/god_names_service.dart';

class GodNamesController extends ChangeNotifier {
  GodNamesController({required GodNamesService service}) : _service = service;

  final GodNamesService _service;

  GodNamesCollection? collection;
  bool isLoading = false;
  bool isRefreshing = false;
  String? errorMessage;
  bool _bootstrapped = false;

  Future<void> bootstrap() async {
    if (_bootstrapped) {
      return;
    }
    _bootstrapped = true;
    await load();
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final cached = await _service.loadCachedCollection();
      if (cached != null) {
        collection = cached;
        isLoading = false;
        notifyListeners();
        unawaited(refresh(background: true));
        return;
      }

      collection = await _service.fetchAndCacheCollection();
    } catch (_) {
      errorMessage = 'Could not load the Names of Allah right now.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh({bool background = false}) async {
    if (isRefreshing) {
      return;
    }
    if (!background) {
      errorMessage = null;
    }
    isRefreshing = true;
    notifyListeners();

    try {
      collection = await _service.fetchAndCacheCollection();
    } catch (_) {
      if (collection == null || !background) {
        errorMessage = 'Could not refresh the Names of Allah.';
      }
    } finally {
      isRefreshing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/god_name.dart';

class GodNamesService {
  GodNamesService({
    http.Client? client,
    Future<SharedPreferences> Function()? preferencesProvider,
  }) : _client = client ?? http.Client(),
       _preferencesProvider =
           preferencesProvider ?? SharedPreferences.getInstance;

  static const _endpoint =
      'https://cigavogfeiszxjnvvinm.supabase.co/storage/v1/object/public/hello/GodsName.json';
  static const _cacheKey = 'god_names_cache_v1';

  final http.Client _client;
  final Future<SharedPreferences> Function() _preferencesProvider;

  Future<GodNamesCollection?> loadCachedCollection() async {
    final prefs = await _preferencesProvider();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return _decode(raw);
  }

  Future<GodNamesCollection> fetchAndCacheCollection() async {
    final response = await _client.get(Uri.parse(_endpoint));
    if (response.statusCode != 200) {
      throw Exception(
        'Unable to fetch God names data (${response.statusCode}).',
      );
    }

    final collection = _decode(response.body);
    final prefs = await _preferencesProvider();
    await prefs.setString(_cacheKey, response.body);
    return collection;
  }

  GodNamesCollection _decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('God names JSON is not a valid object.');
    }
    return GodNamesCollection.fromJson(decoded);
  }

  void dispose() {
    _client.close();
  }
}

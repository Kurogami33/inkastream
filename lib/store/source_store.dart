import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';

class SourceStore {
  static const _key = 'sources_v1';

  Future<List<SourceManifest>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) =>
              SourceManifest.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<SourceManifest> sources) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(sources.map((s) => s.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  Future<void> add(SourceManifest source) async {
    final all = await load();
    all.removeWhere((s) => s.id == source.id);
    all.add(source);
    await save(all);
  }

  Future<void> remove(String id) async {
    final all = await load();
    all.removeWhere((s) => s.id == id);
    await save(all);
  }

  Future<void> setEnabled(String id, bool enabled) async {
    final all = await load();
    for (final s in all) {
      if (s.id == id) s.enabled = enabled;
    }
    await save(all);
  }
}

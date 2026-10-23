import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressEntry {
  final String key;
  final String title;
  final int positionMs;
  final int durationMs;
  final int updatedAt;
  final String poster;

  const ProgressEntry({
    required this.key,
    required this.title,
    required this.positionMs,
    required this.durationMs,
    required this.updatedAt,
    this.poster = '',
  });

  double get fraction =>
      durationMs <= 0 ? 0 : (positionMs / durationMs).clamp(0.0, 1.0);

  Map<String, dynamic> toJson() => {
        'key': key,
        'title': title,
        'positionMs': positionMs,
        'durationMs': durationMs,
        'updatedAt': updatedAt,
        'poster': poster,
      };

  factory ProgressEntry.fromJson(Map<String, dynamic> j) => ProgressEntry(
        key: (j['key'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        positionMs: (j['positionMs'] ?? 0) as int,
        durationMs: (j['durationMs'] ?? 0) as int,
        updatedAt: (j['updatedAt'] ?? 0) as int,
        poster: (j['poster'] ?? '').toString(),
      );
}

class ProgressStore {
  static const _key = 'progress_v1';

  static String normalize(String title) => title
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9áéíóúñ]+'), '');

  Future<Map<String, ProgressEntry>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = jsonDecode(raw) as Map;
      return map.map((k, v) => MapEntry(
            k.toString(),
            ProgressEntry.fromJson(Map<String, dynamic>.from(v as Map)),
          ));
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveAll(Map<String, ProgressEntry> all) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(all.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }

  Future<ProgressEntry?> get(String title) async {
    final all = await _loadAll();
    return all[normalize(title)];
  }

  Future<void> save({
    required String title,
    required Duration position,
    required Duration duration,
    String poster = '',
  }) async {
    if (title.trim().isEmpty || position.inSeconds < 5) return;
    final all = await _loadAll();
    final k = normalize(title);
    // Si ya casi terminó, se borra el avance.
    if (duration.inSeconds > 0 &&
        position.inSeconds > duration.inSeconds - 30) {
      all.remove(k);
    } else {
      all[k] = ProgressEntry(
        key: k,
        title: title,
        positionMs: position.inMilliseconds,
        durationMs: duration.inMilliseconds,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        poster: poster,
      );
    }
    await _saveAll(all);
  }

  Future<List<ProgressEntry>> recent({int limit = 20}) async {
    final all = await _loadAll();
    final list = all.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list.take(limit).toList();
  }

  Future<void> remove(String title) async {
    final all = await _loadAll();
    all.remove(normalize(title));
    await _saveAll(all);
  }
}

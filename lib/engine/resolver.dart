import 'dart:async';
import 'dart:convert';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import '../models.dart';

class Limiter {
  final int max;
  int _running = 0;
  final List<Completer<void>> _queue = [];
  Limiter(this.max);

  Future<T> run<T>(Future<T> Function() task) async {
    if (_running >= max) {
      final c = Completer<void>();
      _queue.add(c);
      await c.future;
    } else {
      _running++;
    }
    try {
      return await task();
    } finally {
      if (_queue.isNotEmpty) {
        _queue.removeAt(0).complete();
      } else {
        _running--;
      }
    }
  }
}

class Resolver {
  static final Limiter _limiter = Limiter(3);
  final SourceManifest source;
  String? _activeHost;

  Resolver(this.source);

  List<String> get _hosts => [source.baseUrl, ...source.altHosts]
      .where((h) => h.isNotEmpty)
      .toList();

  Map<String, String> get _headers => {
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36',
        'Accept-Language': 'es,en;q=0.8',
        ...source.headers,
      };

  String absUrl(String u, {String? base}) {
    final t = u.trim();
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    if (t.startsWith('//')) return 'https:$t';
    final b = base ?? _activeHost ?? source.baseUrl;
    try {
      return Uri.parse(b).resolve(t).toString();
    } catch (_) {
      return t;
    }
  }

  Future<String> fetch(String urlOrPath) async {
    final isAbs =
        urlOrPath.startsWith('http://') || urlOrPath.startsWith('https://');
    List<String> hosts;
    if (isAbs) {
      hosts = [''];
    } else if (_activeHost != null) {
      hosts = [_activeHost!, ..._hosts.where((h) => h != _activeHost)];
    } else {
      hosts = _hosts;
    }
    Object? lastErr;
    for (final host in hosts) {
      final url = isAbs ? urlOrPath : absUrl(urlOrPath, base: host);
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          final body = await _limiter.run<String>(() async {
            final res = await http
                .get(Uri.parse(url), headers: _headers)
                .timeout(const Duration(seconds: 15));
            if (res.statusCode >= 400) {
              throw Exception('HTTP ${res.statusCode}');
            }
            return utf8.decode(res.bodyBytes, allowMalformed: true);
          });
          if (!isAbs) _activeHost = host;
          return body;
        } catch (e) {
          lastErr = e;
          await Future.delayed(Duration(milliseconds: 400 * (attempt + 1)));
        }
      }
    }
    throw Exception('No se pudo cargar: $lastErr');
  }

  String _pick(Element? root, String sel) {
    if (root == null || sel.trim().isEmpty) return '';
    var css = sel;
    String? attr;
    final i = sel.lastIndexOf('@');
    if (i >= 0) {
      css = sel.substring(0, i);
      attr = sel.substring(i + 1).trim();
    }
    final Element? el =
        css.trim().isEmpty ? root : root.querySelector(css.trim());
    if (el == null) return '';
    if (attr != null && attr.isNotEmpty) {
      var v = (el.attributes[attr] ?? '').trim();
      if (v.isEmpty && attr == 'src') {
        v = (el.attributes['data-src'] ?? '').trim();
      }
      return v;
    }
    return el.text.trim();
  }

  List<MediaItem> _parseItems(String body, dynamic item) {
    if (item is! Map) return [];
    final nodeSel = (item['node'] ?? '').toString();
    if (nodeSel.isEmpty) return [];
    final doc = html_parser.parse(body);
    final out = <MediaItem>[];
    for (final n in doc.querySelectorAll(nodeSel)) {
      final title = _pick(n, (item['title'] ?? '').toString());
      final href = _pick(n, (item['href'] ?? '').toString());
      if (title.isEmpty || href.isEmpty) continue;
      final poster = _pick(n, (item['poster'] ?? '').toString());
      out.add(MediaItem(
        title: title,
        href: absUrl(href),
        poster: poster.isEmpty ? '' : absUrl(poster),
        type: (item['type'] ?? 'movie').toString(),
        sourceId: source.id,
      ));
    }
    return out;
  }

  Future<List<MediaItem>> search(String query, {int page = 1}) async {
    final s = source.rules['search'];
    if (s is! Map) return [];
    final url = (s['url'] ?? '')
        .toString()
        .replaceAll('{query}', Uri.encodeQueryComponent(query))
        .replaceAll('{page}', '$page');
    if (url.isEmpty) return [];
    final body = await fetch(url);
    return _parseItems(body, s['item']);
  }

  Future<List<MediaItem>> catalog(Map cat, {int page = 1}) async {
    final url = (cat['url'] ?? '').toString().replaceAll('{page}', '$page');
    if (url.isEmpty) return [];
    final body = await fetch(url);
    return _parseItems(body, cat['item']);
  }

  String _guessKind(String u) {
    final l = u.toLowerCase();
    if (l.contains('.m3u8')) return 'hls';
    if (l.contains('.mp4')) return 'mp4';
    return 'iframe';
  }

  dynamic _path(Map m, String path) {
    dynamic cur = m;
    for (final k in path.split('.')) {
      if (cur is Map && cur.containsKey(k)) {
        cur = cur[k];
      } else {
        return null;
      }
    }
    return cur;
  }

  Future<List<StreamLink>> streams(
    String href, {
    int depth = 0,
    Set<String>? seen,
  }) async {
    final rules = source.rules['streams'];
    if (rules is! Map || rules['extract'] is! List) return [];
    final visited = seen ?? <String>{};
    final pageUrl = absUrl(href);
    if (depth > 3 || !visited.add(pageUrl)) return [];

    final String body;
    try {
      body = await fetch(pageUrl);
    } catch (_) {
      return [];
    }
    final doc = html_parser.parse(body);
    final found = <StreamLink>[];

    for (final ex in rules['extract'] as List) {
      if (ex is! Map) continue;
      final type = (ex['type'] ?? '').toString();
      final rule = (ex['rule'] ?? '').toString();
      final kind = (ex['kind'] ?? 'auto').toString();
      final isB64 = ex['base64'] == true;
      final urls = <String>[];
      try {
        if (type == 'css') {
          var css = rule;
          var attr = 'href';
          final i = rule.lastIndexOf('@');
          if (i >= 0) {
            css = rule.substring(0, i);
            attr = rule.substring(i + 1).trim();
          }
          for (final el in doc.querySelectorAll(css.trim())) {
            var v = (el.attributes[attr] ?? '').trim();
            if (v.isEmpty && attr == 'src') {
              v = (el.attributes['data-src'] ?? '').trim();
            }
            if (v.isNotEmpty) urls.add(v);
          }
        } else if (type == 'regex') {
          for (final m in RegExp(rule).allMatches(body)) {
            final v = m.groupCount >= 1 ? m.group(1) : m.group(0);
            if (v != null && v.isNotEmpty) urls.add(v);
          }
        } else if (type == 'jsonList') {
          final m = RegExp(rule).firstMatch(body);
          if (m != null && m.groupCount >= 1 && m.group(1) != null) {
            final data = jsonDecode(m.group(1)!);
            final path = (ex['path'] ?? '').toString();
            if (data is List) {
              for (final e in data) {
                dynamic v = e;
                if (e is Map && path.isNotEmpty) v = _path(e, path);
                if (v is String && v.isNotEmpty) urls.add(v);
              }
            }
          }
        }
      } catch (_) {}

      for (var u in urls) {
        if (isB64) {
          try {
            u = utf8.decode(base64.decode(u));
          } catch (_) {
            continue;
          }
        }
        final full = absUrl(u, base: pageUrl);
        found.add(StreamLink(
          url: full,
          kind: kind == 'auto' ? _guessKind(full) : kind,
          label: source.name,
        ));
      }
    }

    final result = <StreamLink>[];
    for (final l in found) {
      if (l.kind == 'iframe' && depth < 3) {
        final inner = await streams(l.url, depth: depth + 1, seen: visited);
        if (inner.isEmpty) {
          result.add(l);
        } else {
          result.addAll(inner);
        }
      } else {
        result.add(l);
      }
    }
    final uniq = <String>{};
    return result.where((l) => uniq.add(l.url)).toList();
  }
}

class StreamLink {
  final String url;
  final String label;
  final String kind;

  const StreamLink({required this.url, this.label = '', this.kind = 'auto'});

  Map<String, dynamic> toJson() => {'url': url, 'label': label, 'kind': kind};

  factory StreamLink.fromJson(Map<String, dynamic> j) => StreamLink(
        url: (j['url'] ?? '').toString(),
        label: (j['label'] ?? '').toString(),
        kind: (j['kind'] ?? 'auto').toString(),
      );
}

class MediaItem {
  final String title;
  final String href;
  final String poster;
  final String type;
  final String sourceId;

  const MediaItem({
    required this.title,
    required this.href,
    this.poster = '',
    this.type = 'movie',
    this.sourceId = '',
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'href': href,
        'poster': poster,
        'type': type,
        'sourceId': sourceId,
      };

  factory MediaItem.fromJson(Map<String, dynamic> j) => MediaItem(
        title: (j['title'] ?? '').toString(),
        href: (j['href'] ?? '').toString(),
        poster: (j['poster'] ?? '').toString(),
        type: (j['type'] ?? 'movie').toString(),
        sourceId: (j['sourceId'] ?? '').toString(),
      );
}

class SourceManifest {
  final String id;
  final String name;
  final String kind;
  final String lang;
  final String baseUrl;
  final List<String> altHosts;
  final Map<String, String> headers;
  final Map<String, dynamic> rules;
  bool enabled;

  SourceManifest({
    required this.id,
    required this.name,
    this.kind = 'html',
    this.lang = 'es',
    this.baseUrl = '',
    this.altHosts = const [],
    this.headers = const {},
    this.rules = const {},
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind,
        'lang': lang,
        'baseUrl': baseUrl,
        'altHosts': altHosts,
        'headers': headers,
        'rules': rules,
        'enabled': enabled,
      };

  factory SourceManifest.fromJson(Map<String, dynamic> j) {
    final h = j['headers'];
    final a = j['altHosts'];
    final r = j['rules'];
    return SourceManifest(
      id: (j['id'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      kind: (j['kind'] ?? 'html').toString(),
      lang: (j['lang'] ?? 'es').toString(),
      baseUrl: (j['baseUrl'] ?? '').toString(),
      altHosts: a is List ? a.map((e) => e.toString()).toList() : <String>[],
      headers: h is Map
          ? h.map((k, v) => MapEntry(k.toString(), v.toString()))
          : <String, String>{},
      rules: r is Map ? Map<String, dynamic>.from(r) : <String, dynamic>{},
      enabled: j['enabled'] is bool ? j['enabled'] as bool : true,
    );
  }
}

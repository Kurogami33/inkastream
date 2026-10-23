import 'dart:convert';
import '../models.dart';

class QuickAdd {
  static String _slug(String s) {
    final t = s
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return t.isEmpty ? 'fuente_${DateTime.now().millisecondsSinceEpoch}' : t;
  }

  /// Convierte una receta (JSON o código corto base64) en una fuente.
  static SourceManifest parseRecipe(String input) {
    var text = input.trim();
    if (text.isEmpty) {
      throw const FormatException('Pega primero una receta o un código.');
    }
    if (!text.startsWith('{')) {
      try {
        final clean = text.replaceAll(RegExp(r'\s'), '');
        text = utf8.decode(base64.decode(base64.normalize(clean)));
      } catch (_) {
        throw const FormatException('El código no es válido.');
      }
    }
    dynamic data;
    try {
      data = jsonDecode(text);
    } catch (_) {
      throw const FormatException('La receta no tiene formato JSON válido.');
    }
    if (data is! Map) {
      throw const FormatException('La receta debe ser un objeto JSON.');
    }
    final map = Map<String, dynamic>.from(data);
    final name = (map['name'] ?? '').toString().trim();
    final base = (map['baseUrl'] ?? '').toString().trim();
    if (name.isEmpty || base.isEmpty) {
      throw const FormatException('Faltan los campos "name" y "baseUrl".');
    }
    final id = (map['id'] ?? '').toString().trim();
    map['id'] = id.isEmpty ? _slug(name) : _slug(id);
    return SourceManifest.fromJson(map);
  }

  /// Crea una fuente a partir de un enlace directo (HLS, MP4, lista).
  static SourceManifest fromDirectLink(String url, {String name = ''}) {
    final u = url.trim();
    final uri = Uri.tryParse(u);
    if (uri == null ||
        !(uri.scheme == 'http' || uri.scheme == 'https') ||
        uri.host.isEmpty) {
      throw const FormatException('El enlace debe empezar con http o https.');
    }
    final label = name.trim().isEmpty ? uri.host : name.trim();
    return SourceManifest(
      id: _slug(label),
      name: label,
      kind: 'links',
      baseUrl: '${uri.scheme}://${uri.host}',
      rules: {
        'links': [u],
      },
    );
  }

  /// Convierte una fuente en un código corto para compartir por chat.
  static String exportCode(SourceManifest m) {
    return base64.encode(utf8.encode(jsonEncode(m.toJson())));
  }
}

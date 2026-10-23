import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../engine/resolver.dart';
import '../models.dart';
import '../store/source_store.dart';
import '../theme.dart';
import 'player_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _store = SourceStore();
  final _ctrl = TextEditingController();
  final List<MediaItem> _results = [];
  final Set<String> _seen = {};
  final Map<String, SourceManifest> _byId = {};
  bool _searching = false;
  bool _opening = false;
  String? _info;
  int _runId = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _norm(String t) =>
      t.toLowerCase().replaceAll(RegExp(r'[^a-z0-9áéíóúñ]+'), '');

  void _msg(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> _search() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    final id = ++_runId;
    final all = await _store.load();
    final sources = all
        .where((s) => s.enabled && s.rules['search'] is Map)
        .toList();
    if (!mounted) return;
    _byId
      ..clear()
      ..addEntries(sources.map((s) => MapEntry(s.id, s)));
    setState(() {
      _results.clear();
      _seen.clear();
      _info = null;
      _searching = sources.isNotEmpty;
    });
    if (sources.isEmpty) {
      setState(() => _info =
          'No tienes fuentes activas con reglas de búsqueda. Añade una receta en la pestaña Fuentes.');
      return;
    }
    await Future.wait(sources.map((s) async {
      try {
        final items = await Resolver(s).search(q);
        if (!mounted || id != _runId) return;
        setState(() {
          for (final it in items) {
            if (_seen.add(_norm(it.title))) _results.add(it);
          }
        });
      } catch (_) {}
    }));
    if (!mounted || id != _runId) return;
    setState(() {
      _searching = false;
      if (_results.isEmpty) _info = 'Sin resultados para "$q".';
    });
  }

  Future<void> _open(MediaItem item) async {
    if (_opening) return;
    final src = _byId[item.sourceId];
    if (src == null) return;
    setState(() => _opening = true);
    _msg('Buscando servidores...');
    List<StreamLink> links = [];
    try {
      links = await Resolver(src).streams(item.href);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _opening = false);
    if (links.isEmpty) {
      _msg('No se encontraron servidores para este título.');
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PlayerScreen(title: item.title, links: links),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _ctrl,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Título, serie o anime',
                prefixIcon: const Icon(Symbols.search_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Symbols.arrow_forward_rounded),
                  onPressed: _search,
                ),
              ),
            ),
          ),
          if (_searching) const LinearProgressIndicator(minHeight: 2),
          if (_info != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _info!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: _results.length,
              itemBuilder: (ctx, i) {
                final it = _results[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(kCardRadius),
                    border: Border.all(color: AppColors.redSoft),
                  ),
                  child: ListTile(
                    onTap: () => _open(it),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 44,
                        height: 60,
                        child: it.poster.isEmpty
                            ? const Icon(Symbols.movie_rounded)
                            : Image.network(
                                it.poster,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Symbols.movie_rounded),
                              ),
                      ),
                    ),
                    title: Text(it.title,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      _byId[it.sourceId]?.name ?? '',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

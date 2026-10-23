import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../engine/resolver.dart';
import '../models.dart';
import '../store/progress_store.dart';
import '../store/source_store.dart';
import '../theme.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _sources = SourceStore();
  final _progress = ProgressStore();
  List<SourceManifest> _active = [];
  List<ProgressEntry> _recent = [];
  bool _loading = true;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await _sources.load();
    final rec = await _progress.recent();
    if (!mounted) return;
    setState(() {
      _active = all.where((s) => s.enabled).toList();
      _recent = rec;
      _loading = false;
    });
  }

  void _msg(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  Future<List<StreamLink>> _findLinks(ProgressEntry e) async {
    // 1) Fuentes de enlace directo: el título es el nombre de la fuente.
    for (final s in _active) {
      if (s.kind == 'links' && ProgressStore.normalize(s.name) == e.key) {
        final raw = s.rules['links'];
        if (raw is List && raw.isNotEmpty) {
          return raw
              .map((x) => StreamLink(url: x.toString(), label: s.name))
              .toList();
        }
      }
    }
    // 2) Fuentes con búsqueda: se busca el título y se piden servidores.
    for (final s in _active) {
      if (s.rules['search'] is! Map) continue;
      try {
        final r = Resolver(s);
        final items = await r.search(e.title);
        for (final it in items) {
          if (ProgressStore.normalize(it.title) == e.key) {
            final links = await r.streams(it.href);
            if (links.isNotEmpty) return links;
          }
        }
      } catch (_) {}
    }
    return [];
  }

  Future<void> _resume(ProgressEntry e) async {
    if (_opening) return;
    setState(() => _opening = true);
    _msg('Buscando servidores...');
    final links = await _findLinks(e);
    if (!mounted) return;
    setState(() => _opening = false);
    if (links.isEmpty) {
      _msg('No se encontraron servidores para "${e.title}".');
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          PlayerScreen(title: e.title, links: links, poster: e.poster),
    ));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'INKASTREAM',
          style: TextStyle(
            color: AppColors.red,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: AppColors.red,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_active.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Aún no tienes fuentes activas.\nVe a la pestaña Fuentes y añade una.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in _active)
                          Chip(
                            label: Text(s.name),
                            backgroundColor: AppColors.surface,
                            side: const BorderSide(color: AppColors.redSoft),
                          ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    'Continuar viendo',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_recent.isEmpty)
                    const Text(
                      'Todavía no has empezado nada.',
                      style: TextStyle(color: AppColors.textSecondary),
                    )
                  else
                    for (final e in _recent)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(kCardRadius),
                          border: Border.all(color: AppColors.redSoft),
                        ),
                        child: ListTile(
                          onTap: () => _resume(e),
                          leading: const Icon(Symbols.play_circle_rounded,
                              color: AppColors.red),
                          title: Text(e.title,
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: LinearProgressIndicator(
                              value: e.fraction,
                              color: AppColors.red,
                              backgroundColor: AppColors.surfaceElevated,
                              minHeight: 4,
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
    );
  }
}

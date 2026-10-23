import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../engine/quick_add.dart';
import '../models.dart';
import '../store/source_store.dart';
import '../theme.dart';

class SourcesScreen extends StatefulWidget {
  const SourcesScreen({super.key});

  @override
  State<SourcesScreen> createState() => _SourcesScreenState();
}

class _SourcesScreenState extends State<SourcesScreen> {
  final _store = SourceStore();
  List<SourceManifest> _sources = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final s = await _store.load();
    if (!mounted) return;
    setState(() {
      _sources = s;
      _loading = false;
    });
  }

  void _msg(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> _openAdd() async {
    final ctrl = TextEditingController();
    String? error;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kCardRadius)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Añadir fuente',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Pega una receta JSON, un código corto o un enlace directo (http...).',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(hintText: 'Pega aquí'),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: AppColors.error)),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final input = ctrl.text.trim();
                    try {
                      final SourceManifest m = input.startsWith('http')
                          ? QuickAdd.fromDirectLink(input)
                          : QuickAdd.parseRecipe(input);
                      await _store.add(m);
                      if (ctx.mounted) Navigator.pop(ctx);
                      await _reload();
                      _msg('Fuente "${m.name}" añadida');
                    } on FormatException catch (e) {
                      setSheet(() => error = e.message);
                    }
                  },
                  child: const Text('Añadir'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    ctrl.dispose();
  }

  Future<void> _toggle(SourceManifest s, bool v) async {
    await _store.setEnabled(s.id, v);
    await _reload();
  }

  Future<void> _onMenu(SourceManifest s, String action) async {
    if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: QuickAdd.exportCode(s)));
      _msg('Código copiado');
    } else if (action == 'delete') {
      await _store.remove(s.id);
      await _reload();
      _msg('Fuente borrada');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuentes',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        backgroundColor: AppColors.red,
        foregroundColor: AppColors.textPrimary,
        icon: const Icon(Symbols.add_rounded),
        label: const Text('Añadir'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sources.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Aún no tienes fuentes.\nToca "Añadir" para pegar una receta o un enlace.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: _sources.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final s = _sources[i];
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(kCardRadius),
                        border: Border.all(color: AppColors.redSoft),
                      ),
                      child: ListTile(
                        title: Text(s.name),
                        subtitle: Text(
                          s.baseUrl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(color: AppColors.textSecondary),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: s.enabled,
                              activeColor: AppColors.red,
                              onChanged: (v) => _toggle(s, v),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (a) => _onMenu(s, a),
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                    value: 'copy',
                                    child: Text('Copiar código')),
                                PopupMenuItem(
                                    value: 'delete', child: Text('Borrar')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

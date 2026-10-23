import 'dart:async';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models.dart';
import '../player/external.dart';
import '../theme.dart';

class PlayerScreen extends StatefulWidget {
  final String title;
  final List<StreamLink> links;

  const PlayerScreen({super.key, required this.title, required this.links});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player _player = Player();
  late final VideoController _controller = VideoController(_player);
  final List<StreamSubscription> _subs = [];
  int _index = 0;
  Duration _lastPos = Duration.zero;
  bool _switching = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _subs.add(_player.stream.position.listen((p) {
      if (p > Duration.zero) _lastPos = p;
    }));
    _subs.add(_player.stream.error.listen((e) {
      _failover(e);
    }));
    _open(0, Duration.zero);
  }

  Future<void> _open(int i, Duration start) async {
    if (i < 0 || i >= widget.links.length) return;
    if (mounted) {
      setState(() {
        _index = i;
        _status = null;
      });
    }
    await _player.open(Media(widget.links[i].url, start: start));
  }

  Future<void> _failover(String reason) async {
    if (_switching || !mounted) return;
    _switching = true;
    final next = _index + 1;
    if (next < widget.links.length) {
      setState(() => _status =
          'El servidor ${_index + 1} falló. Pasando al ${next + 1}...');
      await _open(next, _lastPos);
    } else {
      setState(() => _status = 'No quedan más servidores. $reason');
    }
    _switching = false;
  }

  Future<void> _openExternal() async {
    final url = widget.links[_index].url;
    await _player.pause();
    final used = await ExternalPlayer.open(url, title: widget.title);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(used == null
          ? 'No se encontró ningún reproductor externo.'
          : 'Abierto en $used'),
    ));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Video(controller: _controller),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _openExternal,
                  icon: const Icon(Symbols.open_in_new_rounded),
                  label: const Text('Abrir en VLC / MX Player'),
                ),
              ),
            ),
            if (_status != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _status!,
                  style: const TextStyle(color: AppColors.warning),
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: widget.links.length,
                itemBuilder: (ctx, i) {
                  final l = widget.links[i];
                  final selected = i == _index;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.surfaceElevated
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(kCardRadius),
                      border: Border.all(
                        color: selected ? AppColors.red : AppColors.redSoft,
                      ),
                    ),
                    child: ListTile(
                      title: Text('Servidor ${i + 1}'),
                      subtitle: Text(
                        l.kind,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      onTap: () => _open(i, _lastPos),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

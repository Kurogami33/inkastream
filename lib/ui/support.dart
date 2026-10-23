import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';

const kSupportEmail = 'inkastreamusuarios@gmail.com';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  String _diag = 'Cargando diagnóstico...';

  @override
  void initState() {
    super.initState();
    _buildDiag();
  }

  Future<void> _buildDiag() async {
    String version = '?';
    try {
      final info = await PackageInfo.fromPlatform();
      version = '${info.version} (${info.buildNumber})';
    } catch (_) {}
    final text = 'App: INKASTREAM $version\n'
        'Sistema: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}\n'
        'Fecha: ${DateTime.now().toIso8601String()}';
    if (!mounted) return;
    setState(() => _diag = text);
  }

  void _msg(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _diag));
    _msg('Diagnóstico copiado');
  }

  Future<void> _write() async {
    final subject = Uri.encodeComponent('Soporte INKASTREAM');
    final body = Uri.encodeComponent('Describe tu problema aquí:\n\n\n---\n$_diag');
    final uri = Uri.parse('mailto:$kSupportEmail?subject=$subject&body=$body');
    bool ok = false;
    try {
      ok = await launchUrl(uri);
    } catch (_) {}
    if (!ok) {
      await Clipboard.setData(ClipboardData(text: _diag));
      _msg('No se abrió el correo. Copié el diagnóstico; escribe a $kSupportEmail');
    }
  }

  Widget _faq(String q, String a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(color: AppColors.redSoft),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(q),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(a, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Soporte')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            kSupportEmail,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _write,
            icon: const Icon(Symbols.mail_rounded),
            label: const Text('Escribir al soporte'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _copy,
            icon: const Icon(Symbols.content_copy_rounded),
            label: const Text('Copiar diagnóstico'),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(kCardRadius),
            ),
            child: Text(
              _diag,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Preguntas frecuentes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _faq(
            '¿Cómo añado una fuente?',
            'En la pestaña Fuentes toca Añadir y pega un enlace directo o una receta.',
          ),
          _faq(
            '¿Un video no se reproduce?',
            'Prueba otro servidor de la lista, o toca "Abrir en VLC / MX Player".',
          ),
          _faq(
            '¿La app guarda mis datos en un servidor?',
            'No. Todo se guarda solo en tu celular. No hay cuentas, anuncios ni telemetría.',
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../theme.dart';
import 'support.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(color: AppColors.redSoft),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.red),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        trailing: const Icon(Symbols.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(
            context,
            icon: Symbols.support_agent_rounded,
            title: 'Soporte',
            subtitle: 'Escribir al soporte y copiar diagnóstico',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SupportScreen()),
            ),
          ),
          _tile(
            context,
            icon: Symbols.cleaning_services_rounded,
            title: 'Limpiar caché',
            subtitle: 'Libera espacio temporal de la app',
            onTap: () {
              PaintingBinding.instance.imageCache.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Caché limpiada')),
              );
            },
          ),
        ],
      ),
    );
  }
}

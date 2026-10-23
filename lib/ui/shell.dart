import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../theme.dart';
import 'search.dart';
import 'settings.dart';
import 'sources.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: const [
            _Placeholder(title: 'Inicio'),
            SearchScreen(),
            SourcesScreen(),
            SettingsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.redSoft,
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Symbols.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Symbols.search_rounded),
            label: 'Buscar',
          ),
          NavigationDestination(
            icon: Icon(Symbols.layers_rounded),
            label: 'Fuentes',
          ),
          NavigationDestination(
            icon: Icon(Symbols.settings_rounded),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String title;
  const _Placeholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 24,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../theme.dart';
import 'home.dart';
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
  int _homeVersion = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: [
            HomeScreen(key: ValueKey(_homeVersion)),
            const SearchScreen(),
            const SourcesScreen(),
            const SettingsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.redSoft,
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() {
          if (i == 0) _homeVersion++;
          _index = i;
        }),
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

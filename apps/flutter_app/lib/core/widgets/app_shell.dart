import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.currentPath, required this.child});

  final String currentPath;
  final Widget child;

  static const _paths = ['/', '/dictionary', '/saved-words', '/progress'];
  static const _labels = ['Home', 'Tra từ', 'Từ đã lưu', 'Tiến độ'];
  static const _icons = [
    Icons.home_outlined,
    Icons.search,
    Icons.bookmark_outline,
    Icons.bar_chart_outlined,
  ];

  int get _selectedIndex {
    final index = _paths.indexOf(currentPath);
    return index < 0 ? 0 : index;
  }

  String get _title => switch (currentPath) {
    '/' => 'Home',
    '/dictionary' => 'Tra từ',
    '/saved-words' => 'Từ đã lưu',
    '/flashcards' => 'Flashcard',
    '/quiz' => 'Quiz',
    '/progress' => 'Tiến độ',
    '/scanner' => 'Scanner',
    '/profile' => 'Hồ sơ',
    _ => 'HanLearn AI',
  };

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 800;
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            tooltip: 'Scanner',
            onPressed: () => context.go('/scanner'),
            icon: const Icon(Icons.document_scanner_outlined),
          ),
          IconButton(
            tooltip: 'Hồ sơ',
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (var i = 0; i < _paths.length; i++)
                      NavigationRailDestination(
                        icon: Icon(_icons[i]),
                        label: Text(_labels[i]),
                      ),
                  ],
                  onDestinationSelected: (index) => context.go(_paths[index]),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            )
          : child,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              destinations: [
                for (var i = 0; i < _paths.length; i++)
                  NavigationDestination(
                    icon: Icon(_icons[i]),
                    label: _labels[i],
                  ),
              ],
              onDestinationSelected: (index) => context.go(_paths[index]),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Chào mừng đến HanLearn AI',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Đây là khung ứng dụng. Tính năng học tập sẽ được xây dựng theo từng phase.',
        ),
        const SizedBox(height: 24),
        const Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _HomeAction(
              label: 'Tra từ',
              icon: Icons.search,
              path: '/dictionary',
            ),
            _HomeAction(
              label: 'Từ đã lưu',
              icon: Icons.bookmark_outline,
              path: '/saved-words',
            ),
            _HomeAction(
              label: 'Ôn Flashcard',
              icon: Icons.style_outlined,
              path: '/flashcards',
            ),
            _HomeAction(
              label: 'Làm Quiz',
              icon: Icons.quiz_outlined,
              path: '/quiz',
            ),
            _HomeAction(
              label: 'Ôn hôm nay',
              icon: Icons.today_outlined,
              path: '/progress',
            ),
            _HomeAction(
              label: 'Scanner',
              icon: Icons.document_scanner_outlined,
              path: '/scanner',
            ),
          ],
        ),
      ],
    );
  }
}

class _HomeAction extends StatelessWidget {
  const _HomeAction({
    required this.label,
    required this.icon,
    required this.path,
  });

  final String label;
  final IconData icon;
  final String path;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 120,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.go(path),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                Text(label, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

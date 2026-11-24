import 'package:flutter/material.dart';

import 'state_panel.dart';

class FeaturePlaceholderPage extends StatelessWidget {
  const FeaturePlaceholderPage({
    super.key,
    required this.title,
    required this.phase,
    required this.description,
  });

  final String title;
  final String phase;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: StatePanel(
        state: ViewState.notReady,
        title: title,
        message: '$description\nChức năng sẽ được triển khai ở $phase.',
      ),
    );
  }
}

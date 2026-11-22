import 'package:flutter/material.dart';

enum ViewState { loading, empty, error, notReady }

class StatePanel extends StatelessWidget {
  const StatePanel({
    super.key,
    required this.state,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final ViewState state;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final icon = switch (state) {
      ViewState.loading => Icons.hourglass_empty,
      ViewState.empty => Icons.inbox_outlined,
      ViewState.error => Icons.error_outline,
      ViewState.notReady => Icons.construction_outlined,
    };

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state == ViewState.loading)
                  const CircularProgressIndicator()
                else
                  Icon(
                    icon,
                    size: 42,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
                if (state == ViewState.error && onRetry != null) ...[
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: onRetry,
                    child: const Text('Thử lại'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

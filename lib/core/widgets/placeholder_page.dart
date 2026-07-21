import 'package:flutter/material.dart';

/// Temporary scaffold for routes not yet implemented. Each build phase replaces
/// these with real screens. Keeps the router navigable end-to-end today.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    required this.title,
    this.phase,
    this.actions,
    super.key,
  });

  final String title;
  final String? phase;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.card_giftcard_outlined,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(title, style: theme.textTheme.headlineSmall),
              if (phase != null) ...[
                const SizedBox(height: 8),
                Text(
                  phase!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
              if (actions != null) ...[
                const SizedBox(height: 24),
                Wrap(spacing: 12, runSpacing: 12, children: actions!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

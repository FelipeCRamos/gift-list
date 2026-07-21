import 'package:flutter/material.dart';

import 'gl_empty_state.dart';

/// Renders the common async states in priority order: loading spinner → error
/// (with optional retry) → empty → content. Keeps cubit-driven screens free of
/// repeated `if (loading) … else if (error) …` ladders.
class GlAsyncView extends StatelessWidget {
  const GlAsyncView({
    required this.loading,
    required this.builder,
    this.error,
    this.onRetry,
    this.isEmpty = false,
    this.empty,
    super.key,
  });

  final bool loading;
  final WidgetBuilder builder;
  final String? error;
  final VoidCallback? onRetry;
  final bool isEmpty;
  final Widget? empty;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return GlEmptyState(
        icon: Icons.error_outline,
        title: 'Something went wrong',
        message: error,
        action: onRetry == null
            ? null
            : OutlinedButton(
                onPressed: onRetry,
                child: const Text('Try again'),
              ),
      );
    }
    if (isEmpty) {
      return empty ??
          const GlEmptyState(
            icon: Icons.inbox_outlined,
            title: 'Nothing here yet',
          );
    }
    return builder(context);
  }
}

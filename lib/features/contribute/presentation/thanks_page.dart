import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_paths.dart';
import '../../../core/widgets/widgets.dart';

/// `/l/:slug/thanks` — post-payment confirmation shown after the giver taps
/// "I've paid". The contribution is already reserved (awaiting confirmation);
/// the creator confirms it against their bank statement.
class ThanksPage extends StatelessWidget {
  const ThanksPage({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context) {
    return GlPageScaffold(
      title: 'Thank you',
      body: GlEmptyState(
        icon: Icons.favorite,
        title: 'Thank you!',
        message:
            'Your gift is reserved. The creator will confirm it once the '
            'Pix transfer lands in their account.',
        action: FilledButton(
          onPressed: () => context.go(RoutePaths.toListView(slug)),
          child: const Text('Back to the list'),
        ),
      ),
    );
  }
}

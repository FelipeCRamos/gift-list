import 'package:flutter/material.dart';

/// A tappable card used for list/item rows. Wraps content in a [Card] with an
/// [InkWell] and consistent padding.
class GlListCard extends StatelessWidget {
  const GlListCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

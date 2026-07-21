import 'package:flutter/material.dart';

/// A filled button that shows an inline spinner (and disables itself) while
/// [busy] is true.
class GlBusyButton extends StatelessWidget {
  const GlBusyButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final Widget child = busy
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label);
    if (icon != null && !busy) {
      return FilledButton.icon(
        onPressed: busy ? null : onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
    }
    return FilledButton(onPressed: busy ? null : onPressed, child: child);
  }
}

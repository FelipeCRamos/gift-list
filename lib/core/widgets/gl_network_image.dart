import 'package:flutter/material.dart';

/// Displays an image from [url] (an https or `data:` URI) with rounded corners,
/// a loading spinner, and a graceful placeholder when the url is null/empty or
/// fails to load. Centralizes image chrome so screens stay declarative.
class GlNetworkImage extends StatelessWidget {
  const GlNetworkImage({
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 12,
    this.placeholderIcon = Icons.image_outlined,
    super.key,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    if (url == null || url!.isEmpty) {
      return _Placeholder(
        width: width,
        height: height,
        radius: radius,
        icon: placeholderIcon,
      );
    }
    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        url!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stack) => _Placeholder(
          width: width,
          height: height,
          radius: radius,
          icon: Icons.broken_image_outlined,
        ),
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : _Placeholder(
                width: width,
                height: height,
                radius: radius,
                child: const Center(child: CircularProgressIndicator()),
              ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.radius,
    this.width,
    this.height,
    this.icon,
    this.child,
  });

  final BorderRadius radius;
  final double? width;
  final double? height;
  final IconData? icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: radius,
      ),
      child: child ?? Icon(icon, color: scheme.outline),
    );
  }
}

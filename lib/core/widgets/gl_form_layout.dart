import 'package:flutter/material.dart';

/// Centered, max-width, scrollable column for forms and settings pages. Children
/// are stretched horizontally.
class GlFormLayout extends StatelessWidget {
  const GlFormLayout({
    required this.children,
    this.maxWidth = 480,
    this.formKey,
    super.key,
  });

  final List<Widget> children;
  final double maxWidth;
  final GlobalKey<FormState>? formKey;

  @override
  Widget build(BuildContext context) {
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: formKey == null ? column : Form(key: formKey, child: column),
        ),
      ),
    );
  }
}

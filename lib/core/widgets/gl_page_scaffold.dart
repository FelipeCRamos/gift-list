import 'package:flutter/material.dart';

/// Standard page chrome: an [AppBar] with a title plus optional actions and a
/// floating action button. Use [GlFormLayout] inside [body] for centered,
/// max-width form content.
class GlPageScaffold extends StatelessWidget {
  const GlPageScaffold({
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    super.key,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      floatingActionButton: floatingActionButton,
      body: body,
    );
  }
}

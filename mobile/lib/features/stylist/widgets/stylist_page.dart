import 'package:flutter/material.dart';

/// `.app-content` (padding 14/20/25) scroll container shared by stylist screens.
class StylistPage extends StatelessWidget {
  const StylistPage({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

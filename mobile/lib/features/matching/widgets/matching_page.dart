import 'package:flutter/material.dart';

/// `.app-content` scroll container shared by the matching screens (mirrors
/// the stylist feature's own `StylistPage`).
class MatchingPage extends StatelessWidget {
  const MatchingPage({super.key, required this.children});

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

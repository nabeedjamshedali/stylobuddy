import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';

void main() {
  runApp(const StyloBuddyApp());
}

/// Temporary shell; Task 3 replaces this with the go_router app.
class StyloBuddyApp extends StatelessWidget {
  const StyloBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StyloBuddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const Scaffold(),
    );
  }
}

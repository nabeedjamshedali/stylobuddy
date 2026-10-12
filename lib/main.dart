import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/splash/view/splash_view.dart';

void main() {
  runApp(const StyloBuddyApp());
}

class StyloBuddyApp extends StatelessWidget {
  const StyloBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StyloBuddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const SplashView(),
    );
  }
}

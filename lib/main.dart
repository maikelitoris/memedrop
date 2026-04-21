import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/landing_screen.dart';
import 'widgets/crt_overlay.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MemeDropApp(),
    ),
  );
}

class MemeDropApp extends ConsumerWidget {
  const MemeDropApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'DROP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          surface: Color(0xFF141414),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: const LandingScreen(),
      builder: (context, child) => Stack(
        children: [
          child!,
          const CRTOverlay(),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/collection_service.dart';
import 'home_screen.dart';

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Concrete gray-ish
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          final collectionServiceAsync = ref.read(collectionServiceProvider);
          collectionServiceAsync.whenData((service) {
            service.getAnonymousId(); // Triggers generation if not exists
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          });
        },
        child: const Center(
          child: Text(
            'DROP.',
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

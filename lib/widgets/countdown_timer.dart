import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/drop_service.dart';

class CountdownTimer extends ConsumerStatefulWidget {
  const CountdownTimer({super.key});

  @override
  ConsumerState<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends ConsumerState<CountdownTimer> {
  late Timer _timer;
  String _displayText = "";

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    final dropService = ref.read(dropServiceProvider);
    final duration = dropService.timeUntilNextDrop();
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    setState(() {
      _displayText = "NEXT DROP: ${hours.toString().padLeft(2, '0')}H ${minutes.toString().padLeft(2, '0')}M";
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayText,
      style: const TextStyle(
        fontSize: 10,
        letterSpacing: 2,
        color: Colors.white54,
        fontWeight: FontWeight.w300,
      ),
    );
  }
}

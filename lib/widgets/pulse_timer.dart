import 'dart:async';
import 'package:flutter/material.dart';

class PulseTimer extends StatefulWidget {
  final int initialSeconds;
  const PulseTimer({super.key, required this.initialSeconds});

  @override
  State<PulseTimer> createState() => _PulseTimerState();
}

class _PulseTimerState extends State<PulseTimer> {
  late int _seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _seconds = widget.initialSeconds;
    _startTimer();
  }

  // 当父组件更新时间（如点击验证存活）时同步
  @override
  void didUpdateWidget(PulseTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSeconds != widget.initialSeconds) {
      _seconds = widget.initialSeconds;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _seconds > 0) {
        setState(() => _seconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int s) {
    int d = s ~/ 86400;
    int h = (s % 86400) ~/ 3600;
    int m = (s % 3600) ~/ 60;
    return "${d}d ${h.toString().padLeft(2,'0')}h ${m.toString().padLeft(2,'0')}m ${(s % 60).toString().padLeft(2,'0')}s";
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatTime(_seconds),
      style: const TextStyle(fontSize: 36, color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
    );
  }
}
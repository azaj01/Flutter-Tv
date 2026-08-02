import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// The time and date shown in the app bar.
///
/// Ticks on a timer — the menu and settings screens each formatted
/// `DateTime.now()` inline, so the clock froze at whatever time the screen was
/// first built.
class ClockLabel extends StatefulWidget {
  const ClockLabel({super.key});

  @override
  State<ClockLabel> createState() => _ClockLabelState();
}

class _ClockLabelState extends State<ClockLabel> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat.jm().format(_now),
          style: const TextStyle(
            fontWeight: FontWeight.w100,
            color: Colors.white70,
            fontSize: 15,
          ),
        ),
        Text(
          DateFormat.yMMMd().format(_now),
          style: const TextStyle(
            fontWeight: FontWeight.w100,
            color: Colors.grey,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

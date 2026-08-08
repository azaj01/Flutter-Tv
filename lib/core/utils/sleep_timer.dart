import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State of the sleep timer: when it will fire, or null when it is off.
class SleepTimerState {
  const SleepTimerState({this.endsAt, this.duration});

  final DateTime? endsAt;
  final Duration? duration;

  bool get isActive => endsAt != null;

  /// Time left, floored at zero.
  Duration get remaining {
    final end = endsAt;
    if (end == null) return Duration.zero;

    final left = end.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }
}

/// Counts how many times the sleep timer has run out.
///
/// The player watches this rather than the timer state, so it reacts to the
/// moment of expiry instead of to the timer being cleared.
class SleepTimerExpiryNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state = state + 1;
}

final sleepTimerExpiredProvider =
    NotifierProvider<SleepTimerExpiryNotifier, int>(
  SleepTimerExpiryNotifier.new,
);

/// Stops playback after a chosen delay.
///
/// Fall asleep with the TV on and it turns itself off.
class SleepTimerNotifier extends Notifier<SleepTimerState> {
  Timer? _timer;

  @override
  SleepTimerState build() {
    ref.onDispose(() => _timer?.cancel());
    return const SleepTimerState();
  }

  void start(Duration duration) {
    _timer?.cancel();
    _timer = Timer(duration, _fire);
    state = SleepTimerState(
      endsAt: DateTime.now().add(duration),
      duration: duration,
    );
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    state = const SleepTimerState();
  }

  void _fire() {
    _timer = null;
    state = const SleepTimerState();
    ref.read(sleepTimerExpiredProvider.notifier).bump();
  }
}

final sleepTimerProvider =
    NotifierProvider<SleepTimerNotifier, SleepTimerState>(
  SleepTimerNotifier.new,
);

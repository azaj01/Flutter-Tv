import 'dart:async';

/// Shares one in-flight operation between concurrent callers.
///
/// The catalog endpoints are large enough that two screens asking for channels
/// at the same time must not trigger two downloads.
class SingleFlight<T> {
  Future<T>? _pending;

  Future<T> run(Future<T> Function() task) {
    final pending = _pending;
    if (pending != null) return pending;

    final future = task();
    _pending = future;

    // Compare before clearing: a [reset] followed by a new run must not have
    // its pending future cleared by the earlier operation finishing.
    //
    // `ignore()` matters — the future returned by `whenComplete` would
    // otherwise carry a duplicate of any failure with nobody listening, which
    // surfaces as an unhandled async error even though the caller handled it.
    future.whenComplete(() {
      if (_pending == future) _pending = null;
    }).ignore();

    return future;
  }

  /// Forgets the in-flight operation, so the next [run] starts a new one.
  void reset() => _pending = null;
}

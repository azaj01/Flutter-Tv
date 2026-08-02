import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// A cached payload plus whether it is still within its time-to-live.
class CachedPayload {
  const CachedPayload({required this.contents, required this.isFresh});

  final String contents;

  /// `false` for an expired entry. Stale entries are still handed back so the
  /// app can fall back to them when the network is unreachable.
  final bool isFresh;
}

/// Stores API payloads on disk so a cold start does not have to re-download
/// ~21 MB, and so the app still has a catalog when offline.
///
/// Every operation degrades to "no cache" instead of throwing: a missing
/// platform implementation (unit tests) or an unwritable directory must never
/// break catalog loading.
class CatalogCacheStore {
  CatalogCacheStore({
    this.maxAge = const Duration(hours: 12),
    Future<Directory> Function()? directoryProvider,
  }) : _directoryProvider = directoryProvider ?? getApplicationCacheDirectory;

  final Duration maxAge;
  final Future<Directory> Function() _directoryProvider;

  Directory? _directory;
  bool _unavailable = false;

  Future<Directory?> _resolveDirectory() async {
    if (_unavailable) return null;
    final cached = _directory;
    if (cached != null) return cached;

    try {
      final directory = Directory('${(await _directoryProvider()).path}/tiwee');
      if (!directory.existsSync()) {
        await directory.create(recursive: true);
      }
      _directory = directory;
      return directory;
    } catch (error) {
      debugPrint('Tiwee: disk cache unavailable ($error)');
      _unavailable = true;
      return null;
    }
  }

  /// Reads [name], or `null` when it is missing or unreadable.
  Future<CachedPayload?> read(String name) async {
    final directory = await _resolveDirectory();
    if (directory == null) return null;

    try {
      final file = File('${directory.path}/$name');
      if (!file.existsSync()) return null;

      final age = DateTime.now().difference(file.lastModifiedSync());
      return CachedPayload(
        contents: await file.readAsString(),
        isFresh: age < maxAge,
      );
    } catch (error) {
      debugPrint('Tiwee: failed to read cache $name ($error)');
      return null;
    }
  }

  /// Writes [contents] to [name]. Failures are logged and otherwise ignored:
  /// a cache write is never worth failing a user-visible operation over.
  Future<void> write(String name, String contents) async {
    final directory = await _resolveDirectory();
    if (directory == null) return;

    try {
      await File('${directory.path}/$name').writeAsString(contents);
    } catch (error) {
      debugPrint('Tiwee: failed to write cache $name ($error)');
    }
  }

  /// Deletes [name] if present, so the next load must hit the network.
  Future<void> delete(String name) async {
    final directory = await _resolveDirectory();
    if (directory == null) return;

    try {
      final file = File('${directory.path}/$name');
      if (file.existsSync()) await file.delete();
    } catch (error) {
      debugPrint('Tiwee: failed to clear cache $name ($error)');
    }
  }
}

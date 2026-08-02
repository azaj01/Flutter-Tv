import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiwee/core/consts.dart';
import 'package:tiwee/core/providers.dart';
import 'package:tiwee/data/datasources/iptv_remote_data_source.dart';

/// Turns an exception into something worth showing a user.
String friendlyErrorMessage(Object? error) {
  if (error is ApiException) return error.message;
  if (error == null) return 'Something went wrong.';
  return 'Could not load channels right now.';
}

/// Error state with a working retry, shown wherever the catalog fails to load.
///
/// Retrying clears the cached catalog and reloads it, which is what a user
/// actually needs after losing connectivity — previously these screens printed
/// the raw exception and offered no way out short of restarting the app.
class CatalogErrorView extends ConsumerStatefulWidget {
  const CatalogErrorView({required this.error, super.key});

  final Object? error;

  @override
  ConsumerState<CatalogErrorView> createState() => _CatalogErrorViewState();
}

class _CatalogErrorViewState extends ConsumerState<CatalogErrorView> {
  bool _retrying = false;

  Future<void> _retry() async {
    setState(() => _retrying = true);
    // The reloaded providers render the new failure, so swallow it here.
    await ref.read(catalogRefresherProvider).refreshQuietly();
    if (mounted) setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    // Centred when there is room, scrollable when there is not (a short
    // landscape viewport would otherwise overflow).
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, color: Colors.white54, size: 56),
              const SizedBox(height: 16),
              Text(
                friendlyErrorMessage(widget.error),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 24),
              if (_retrying)
                const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                FilledButton.icon(
                  onPressed: _retry,
                  style: FilledButton.styleFrom(backgroundColor: kPurple),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

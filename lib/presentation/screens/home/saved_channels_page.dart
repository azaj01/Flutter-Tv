import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiwee/core/providers.dart';
import 'package:tiwee/core/theme/app_colors.dart';
import 'package:tiwee/gen/assets.gen.dart';
import 'package:tiwee/presentation/widgets/channel_grid.dart';
import 'package:tiwee/presentation/widgets/error_view.dart';

/// The channels the user starred, backing the "Saved show" tile.
class SavedChannelsPage extends ConsumerWidget {
  const SavedChannelsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(favouriteChannelsProvider);
    final savedCount = ref.watch(favouritesProvider).length;

    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                    color: Colors.white70,
                  ),
                  const Expanded(
                    child: Text(
                      'Saved shows',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (savedCount > 0)
                    TextButton(
                      onPressed: () => _confirmClear(context, ref),
                      child: const Text('Clear all'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: savedAsync.when(
                data: (channels) {
                  if (channels.isEmpty) {
                    return const _EmptyState();
                  }
                  return ChannelGrid(channels: channels);
                },
                error: (error, stackTrace) => CatalogErrorView(error: error),
                loading: () => Center(
                  child: SizedBox(
                    width: 50,
                    child: Assets.animation.loading.lottie(width: 60),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.card,
        title: const Text('Remove all saved channels?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove all'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      ref.read(favouritesProvider.notifier).clear();
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_border_rounded, color: Colors.white38, size: 56),
            SizedBox(height: 16),
            Text(
              'Nothing saved yet',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the star on any channel to keep it here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }
}

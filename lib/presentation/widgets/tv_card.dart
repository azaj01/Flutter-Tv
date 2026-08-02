import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiwee/core/providers.dart';
import 'package:tiwee/core/theme/app_colors.dart';
import 'package:tiwee/domain/entities/channel_entity.dart';
import 'package:tiwee/presentation/widgets/channel_logo.dart';

/// Grid tile for a channel: artwork, name, quality, and a save toggle.
class TvCard extends ConsumerWidget {
  const TvCard({
    required this.channel,
    super.key,
  });

  final ChannelEntity channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bestQuality = channel.streams?.isNotEmpty ?? false
        ? channel.streams!.first.quality
        : null;
    final isFavourite = ref.watch(isFavouriteProvider(channel.id));

    return Padding(
      padding: const EdgeInsets.all(6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ChannelLogo(channel: channel, borderRadius: 20),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _FavouriteButton(
                      channel: channel,
                      isFavourite: isFavourite,
                    ),
                  ),
                  if (bestQuality != null && bestQuality.isNotEmpty)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          child: Text(
                            bestQuality,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Text(
                channel.name,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Save toggle drawn over the artwork.
///
/// Sits in front of the tile's play gesture, so tapping the star saves the
/// channel instead of starting playback.
class _FavouriteButton extends ConsumerWidget {
  const _FavouriteButton({required this.channel, required this.isFavourite});

  final ChannelEntity channel;
  final bool isFavourite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: isFavourite
          ? 'Remove ${channel.name} from saved'
          : 'Save ${channel.name}',
      child: InkResponse(
        onTap: () {
          final added = ref.read(favouritesProvider.notifier).toggle(channel.id);
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                duration: const Duration(seconds: 2),
                content: Text(
                  added
                      ? '${channel.name} saved'
                      : '${channel.name} removed from saved',
                ),
              ),
            );
        },
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            isFavourite ? Icons.star_rounded : Icons.star_border_rounded,
            size: 20,
            color: isFavourite ? Colors.amber : Colors.white54,
            shadows: const [Shadow(blurRadius: 4)],
          ),
        ),
      ),
    );
  }
}

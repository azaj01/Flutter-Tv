import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tiwee/core/theme/app_colors.dart';
import 'package:tiwee/domain/entities/channel_entity.dart';

/// Channel artwork with graceful fallbacks.
///
/// Roughly a third of channels have no usable logo, and the API also serves
/// dead image links. Instead of the raw exception text the grids used to show,
/// those cases render the channel's initials.
class ChannelLogo extends StatelessWidget {
  const ChannelLogo({
    required this.channel,
    super.key,
    this.borderRadius = 25,
    this.padding = 8,
  });

  final ChannelEntity channel;
  final double borderRadius;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final url = channel.logo;
    final radius = BorderRadius.circular(borderRadius);

    if (url == null || url.isEmpty) {
      return _Fallback(name: channel.name, borderRadius: radius);
    }

    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        // Logos ship at up to ~1000px but never render larger than a grid
        // tile; capping the decode keeps large grids off the memory ceiling.
        memCacheWidth: 320,
        placeholder: (context, _) => _Placeholder(borderRadius: radius),
        errorWidget: (context, _, __) =>
            _Fallback(name: channel.name, borderRadius: radius),
        imageBuilder: (context, imageProvider) => Container(
          padding: EdgeInsets.all(padding),
          decoration:
              BoxDecoration(color: context.colors.card, borderRadius: radius),
          child: Image(image: imageProvider, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.borderRadius});

  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: borderRadius,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.name, required this.borderRadius});

  final String name;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: borderRadius,
      ),
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            _initials(name),
            style: const TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  static String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+'))
      ..removeWhere((word) => word.isEmpty);
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      final word = words.first;
      return (word.length > 2 ? word.substring(0, 2) : word).toUpperCase();
    }
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
}

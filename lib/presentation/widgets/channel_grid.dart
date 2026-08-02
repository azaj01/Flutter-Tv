import 'package:flutter/material.dart';
import 'package:tiwee/domain/entities/channel_entity.dart';
import 'package:tiwee/presentation/widgets/channel_player.dart';
import 'package:tiwee/presentation/widgets/tv_card.dart';

/// Lazily built, responsive grid of channels.
///
/// Countries can have hundreds of channels, so tiles are built on demand
/// instead of all at once, and the column count follows the available width
/// rather than being fixed at four.
class ChannelGrid extends StatelessWidget {
  const ChannelGrid({required this.channels, super.key});

  final List<ChannelEntity> channels;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        childAspectRatio: 0.85,
      ),
      itemCount: channels.length,
      itemBuilder: (context, index) {
        final channel = channels[index];
        return GestureDetector(
          onTap: () => launchChannelPlayer(context, channel),
          child: TvCard(channel: channel),
        );
      },
    );
  }
}

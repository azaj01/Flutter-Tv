import 'package:flutter/material.dart';
import 'package:tiwee/core/utils/show_snackbar.dart';
import 'package:tiwee/domain/entities/channel_entity.dart';
import 'package:tiwee/presentation/screens/home/player.dart';

/// Opens the player for [channel], handing it every playable source so it can
/// fall back when one is offline.
void launchChannelPlayer(BuildContext context, ChannelEntity channel) {
  final streams = (channel.streams ?? const <StreamEntity>[])
      .where((stream) => stream.url.isNotEmpty)
      .toList();

  if (streams.isEmpty) {
    ShowSnackBar(
      context: context,
      text: 'Stream unavailable for ${channel.name}',
    ).show();
    return;
  }

  Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      builder: (context) => Player(
        title: channel.name,
        streams: streams,
      ),
    ),
  );
}

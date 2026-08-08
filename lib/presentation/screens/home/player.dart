import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiwee/core/utils/sleep_timer.dart';
import 'package:tiwee/domain/entities/channel_entity.dart';
import 'package:tiwee/gen/assets.gen.dart';

/// Full screen player for a channel.
///
/// Public IPTV sources go offline constantly, so the player receives every
/// stream the channel has (best quality first) and falls through to the next
/// one when a source fails, instead of leaving the user on a spinner.
class Player extends ConsumerStatefulWidget {
  const Player({
    required this.title,
    required this.streams,
    super.key,
  });

  final String title;
  final List<StreamEntity> streams;

  @override
  ConsumerState<Player> createState() => _PlayerState();
}

class _PlayerState extends ConsumerState<Player> {
  late final BetterPlayerController _controller;
  int _sourceIndex = 0;
  bool _switchingSource = false;
  bool _exhausted = false;

  @override
  void initState() {
    super.initState();
    _controller = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay: true,
        fit: BoxFit.contain,
        allowedScreenSleep: false,
        autoDetectFullscreenDeviceOrientation: true,
        errorBuilder: (context, message) => _PlaybackMessage(
          title: widget.title,
          message: message,
        ),
        controlsConfiguration: BetterPlayerControlsConfiguration(
          // Live TV has no timeline to scrub or duration to show.
          enableProgressBar: false,
          enableProgressText: false,
          enableSkips: false,
          enablePlaybackSpeed: false,
          loadingWidget: SizedBox(
            width: 100,
            child: Assets.animation.spinner.lottie(
              width: 60,
              repeat: true,
              reverse: true,
            ),
          ),
        ),
      ),
      betterPlayerDataSource: _dataSourceAt(0),
    )..addEventsListener(_onPlayerEvent);
  }

  BetterPlayerDataSource _dataSourceAt(int index) {
    final stream = widget.streams[index];
    final headers = stream.headers;

    return BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      stream.url,
      // Marking the source as live keeps the player from trying to buffer a
      // duration or restore a playback position.
      liveStream: true,
      // Some providers only serve the stream with the user agent or referrer
      // recorded in the API; without them playback fails with a 403.
      headers: headers.isEmpty ? null : headers,
    );
  }

  void _onPlayerEvent(BetterPlayerEvent event) {
    if (event.betterPlayerEventType == BetterPlayerEventType.exception) {
      _playNextSource();
    }
  }

  Future<void> _playNextSource() async {
    // A dying source can emit several exceptions; only advance once per source.
    if (_switchingSource) return;

    final next = _sourceIndex + 1;
    if (next >= widget.streams.length) {
      if (mounted) setState(() => _exhausted = true);
      return;
    }

    _switchingSource = true;
    _sourceIndex = next;
    debugPrint('Tiwee: source failed, trying ${next + 1}/'
        '${widget.streams.length} for ${widget.title}');

    try {
      await _controller.setupDataSource(_dataSourceAt(next));
    } finally {
      _switchingSource = false;
    }
  }

  @override
  void dispose() {
    _controller
      ..removeEventsListener(_onPlayerEvent)
      ..dispose();
    // Fullscreen may have locked the device to landscape.
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The sleep timer running out closes the player — that is the whole point
    // of the setting, so it has to reach playback from anywhere in the app.
    ref.listen<int>(sleepTimerExpiredProvider, (previous, next) {
      if (previous == next || !mounted) return;

      _controller.pause();
      Navigator.of(context).maybePop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sleep timer ended playback')),
      );
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: _exhausted
                  ? _PlaybackMessage(
                      title: widget.title,
                      message: widget.streams.length == 1
                          ? 'The only source for this channel is offline.'
                          : 'All ${widget.streams.length} sources for this '
                              'channel are offline.',
                    )
                  : BetterPlayer(controller: _controller),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
                color: Colors.white,
                tooltip: 'Back',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaybackMessage extends StatelessWidget {
  const _PlaybackMessage({required this.title, this.message});

  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.tv_off, color: Colors.white54, size: 56),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            message ?? 'This channel could not be played.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

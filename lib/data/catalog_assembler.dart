import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:tiwee/data/models/channel_model.dart';
import 'package:tiwee/domain/entities/channel_entity.dart';

/// Current layout of the on-disk catalog cache. Bump when the encoded shape
/// changes so stale files are discarded instead of mis-parsed.
const int kCatalogCacheVersion = 1;

/// The result of merging the three catalog endpoints.
///
/// Carries both the domain objects and the payload to persist, so the caller
/// can write the cache without re-encoding on the UI isolate.
class AssembledCatalog {
  const AssembledCatalog({required this.channels, required this.cachePayload});

  final List<ChannelEntity> channels;
  final String cachePayload;
}

/// Merges `channels.json`, `streams.json` and `logos.json` into playable
/// channels on a background isolate.
///
/// The three payloads total ~21 MB, so they are handed over as
/// [TransferableTypedData] (zero-copy) and every decode/parse/merge step runs
/// off the UI isolate.
Future<AssembledCatalog> assembleCatalogInBackground({
  required Uint8List channelsJson,
  required Uint8List streamsJson,
  required Uint8List logosJson,
}) {
  final channels = TransferableTypedData.fromList([channelsJson]);
  final streams = TransferableTypedData.fromList([streamsJson]);
  final logos = TransferableTypedData.fromList([logosJson]);

  return Isolate.run(() {
    final merged = assembleCatalog(
      channelsJson: _materialize(channels),
      streamsJson: _materialize(streams),
      logosJson: _materialize(logos),
    );
    return AssembledCatalog(
      channels: merged,
      cachePayload: encodeCatalog(merged),
    );
  });
}

/// Decodes a previously cached catalog on a background isolate.
Future<List<ChannelEntity>> decodeCatalogInBackground(String payload) {
  return Isolate.run(() => decodeCatalog(payload));
}

String _materialize(TransferableTypedData data) =>
    utf8.decode(data.materialize().asUint8List());

/// Merges the raw endpoint payloads into the playable channel catalog.
///
/// Pure and synchronous so it can be unit tested directly. Channels without a
/// stream, and channels that have shut down, are dropped: the app can do
/// nothing with them and they made up roughly three quarters of the API.
List<ChannelEntity> assembleCatalog({
  required String channelsJson,
  required String streamsJson,
  required String logosJson,
}) {
  final streamsByChannel = _streamsByChannel(streamsJson);
  final logosByChannel = _logosByChannel(logosJson);

  final rawChannels = jsonDecode(channelsJson) as List<dynamic>;

  final catalog = <ChannelEntity>[];
  for (final entry in rawChannels) {
    final model = ChannelModel.fromJson(entry as Map<String, dynamic>);
    if (model.id.isEmpty || model.closed != null || model.replacedBy != null) {
      continue;
    }

    final streams = streamsByChannel[model.id];
    if (streams == null || streams.isEmpty) continue;

    catalog.add(
      model.toEntity(
        logo: logosByChannel[model.id],
        streams: streams,
      ),
    );
  }

  return catalog;
}

/// Groups streams by channel id, best quality first.
Map<String, List<StreamEntity>> _streamsByChannel(String streamsJson) {
  final raw = jsonDecode(streamsJson) as List<dynamic>;
  final grouped = <String, List<StreamEntity>>{};

  for (final entry in raw) {
    final model = StreamModel.fromJson(entry as Map<String, dynamic>);
    final channelId = model.channel;
    if (channelId == null || channelId.isEmpty || model.url.isEmpty) continue;
    grouped.putIfAbsent(channelId, () => <StreamEntity>[]).add(model.toEntity());
  }

  for (final streams in grouped.values) {
    if (streams.length > 1) {
      streams.sort((a, b) => b.qualityRank.compareTo(a.qualityRank));
    }
  }

  return grouped;
}

/// Picks one logo per channel, preferring artwork the API still marks as in use.
Map<String, String> _logosByChannel(String logosJson) {
  final raw = jsonDecode(logosJson) as List<dynamic>;
  final urls = <String, String>{};
  final scores = <String, int>{};

  for (final entry in raw) {
    final model = LogoModel.fromJson(entry as Map<String, dynamic>);
    if (model.channel.isEmpty || model.url.isEmpty) continue;

    final score = model.preferenceScore;
    if (score > (scores[model.channel] ?? -1)) {
      scores[model.channel] = score;
      urls[model.channel] = model.url;
    }
  }

  return urls;
}

/// Encodes the catalog for the on-disk cache.
///
/// Only the fields the app actually renders are stored, with short keys, which
/// keeps the cache around a fifth of the size of the raw endpoints.
String encodeCatalog(List<ChannelEntity> channels) {
  return jsonEncode({
    'v': kCatalogCacheVersion,
    'c': [
      for (final channel in channels)
        <String, dynamic>{
          'i': channel.id,
          'n': channel.name,
          'y': channel.country,
          'g': channel.categories,
          if (channel.altNames.isNotEmpty) 'a': channel.altNames,
          if (channel.isNsfw) 'x': true,
          if (channel.logo != null) 'l': channel.logo,
          's': [
            for (final stream in channel.streams ?? const <StreamEntity>[])
              <String, dynamic>{
                'u': stream.url,
                't': stream.title,
                if (stream.quality != null) 'q': stream.quality,
                if (stream.userAgent != null) 'ua': stream.userAgent,
                if (stream.referrer != null) 'r': stream.referrer,
              },
          ],
        },
    ],
  });
}

/// Reverses [encodeCatalog]. Returns an empty list for payloads written by a
/// different cache version or for anything that fails to parse.
List<ChannelEntity> decodeCatalog(String payload) {
  try {
    final decoded = jsonDecode(payload) as Map<String, dynamic>;
    if (decoded['v'] != kCatalogCacheVersion) return const [];

    final channels = decoded['c'] as List<dynamic>;
    return channels.map((entry) {
      final channel = entry as Map<String, dynamic>;
      return ChannelEntity(
        id: channel['i'] as String,
        name: channel['n'] as String,
        country: channel['y'] as String,
        categories: _stringList(channel['g']),
        altNames: _stringList(channel['a']),
        isNsfw: channel['x'] as bool? ?? false,
        logo: channel['l'] as String?,
        streams: (channel['s'] as List<dynamic>)
            .map((entry) {
              final stream = entry as Map<String, dynamic>;
              return StreamEntity(
                url: stream['u'] as String,
                title: stream['t'] as String,
                quality: stream['q'] as String?,
                userAgent: stream['ua'] as String?,
                referrer: stream['r'] as String?,
              );
            })
            .toList(growable: false),
      );
    }).toList();
  } catch (_) {
    return const [];
  }
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value.map((e) => e as String).toList(growable: false);
}

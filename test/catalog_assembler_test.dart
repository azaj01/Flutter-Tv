import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiwee/data/catalog_assembler.dart';
import 'package:tiwee/domain/entities/channel_entity.dart';

/// Two playable channels, one closed channel, one channel without a stream.
const String _channelsJson = '''
[
  {"id":"Alpha.us","name":"Alpha TV","alt_names":["Alpha One"],"country":"US",
   "categories":["news","general"],"is_nsfw":false,"closed":null,
   "replaced_by":null,"network":null,"owners":[],"launched":null,"website":null},
  {"id":"Beta.fr","name":"Beta","alt_names":[],"country":"fr",
   "categories":["movies"],"is_nsfw":true,"closed":null,"replaced_by":null},
  {"id":"Gone.us","name":"Gone TV","alt_names":[],"country":"US",
   "categories":["news"],"is_nsfw":false,"closed":"2019-01-01",
   "replaced_by":null},
  {"id":"NoStream.us","name":"No Stream","alt_names":[],"country":"US",
   "categories":["news"],"is_nsfw":false,"closed":null,"replaced_by":null}
]
''';

const String _streamsJson = '''
[
  {"channel":"Alpha.us","url":"https://a/480.m3u8","title":"Alpha",
   "quality":"480p","user_agent":null,"referrer":null,"feed":null},
  {"channel":"Alpha.us","url":"https://a/1080.m3u8","title":"Alpha",
   "quality":"1080p","user_agent":"Tiwee/1.0","referrer":"https://a",
   "feed":null},
  {"channel":"Alpha.us","url":"https://a/720.m3u8","title":"Alpha",
   "quality":"720p","user_agent":null,"referrer":null,"feed":null},
  {"channel":"Beta.fr","url":"https://b/live.m3u8","title":"Beta",
   "quality":null,"user_agent":null,"referrer":null,"feed":null},
  {"channel":"Gone.us","url":"https://g/live.m3u8","title":"Gone",
   "quality":null,"user_agent":null,"referrer":null,"feed":null},
  {"channel":null,"url":"https://orphan/live.m3u8","title":"Orphan",
   "quality":null,"user_agent":null,"referrer":null,"feed":null}
]
''';

const String _logosJson = '''
[
  {"channel":"Alpha.us","url":"https://logos/alpha-old.png","feed":null,
   "in_use":false,"tags":[],"width":100,"height":100,"format":"PNG"},
  {"channel":"Alpha.us","url":"https://logos/alpha.png","feed":null,
   "in_use":true,"tags":[],"width":300,"height":300,"format":"PNG"},
  {"channel":"Beta.fr","url":"https://logos/beta-feed.png","feed":"hd",
   "in_use":true,"tags":[],"width":300,"height":300,"format":"PNG"}
]
''';

List<ChannelEntity> _assemble() => assembleCatalog(
      channelsJson: _channelsJson,
      streamsJson: _streamsJson,
      logosJson: _logosJson,
    );

void main() {
  group('assembleCatalog', () {
    test('keeps only channels that can actually be played', () {
      final catalog = _assemble();

      expect(
        catalog.map((channel) => channel.id),
        ['Alpha.us', 'Beta.fr'],
        reason: 'closed channels and channels without a stream are useless',
      );
    });

    test('orders streams by descending quality', () {
      final alpha = _assemble().first;

      expect(
        alpha.streams!.map((stream) => stream.quality),
        ['1080p', '720p', '480p'],
      );
    });

    test('carries the headers a stream needs', () {
      final best = _assemble().first.streams!.first;

      expect(best.headers, {
        'User-Agent': 'Tiwee/1.0',
        'Referer': 'https://a',
      });
    });

    test('prefers the logo the API still marks as in use', () {
      expect(_assemble().first.logo, 'https://logos/alpha.png');
    });

    test('falls back to a feed logo when nothing better exists', () {
      expect(_assemble()[1].logo, 'https://logos/beta-feed.png');
    });

    test('keeps nsfw channels for the repository to filter', () {
      expect(_assemble()[1].isNsfw, isTrue);
    });
  });

  group('catalog cache codec', () {
    test('round trips every field the UI renders', () {
      final original = _assemble();
      final restored = decodeCatalog(encodeCatalog(original));

      expect(restored, original);
    });

    test('rejects a payload from another cache version', () {
      final payload = jsonEncode({
        'v': kCatalogCacheVersion + 1,
        'c': <Object>[],
      });

      expect(decodeCatalog(payload), isEmpty);
    });

    test('rejects unparseable payloads instead of throwing', () {
      expect(decodeCatalog('not json at all'), isEmpty);
    });
  });

  group('StreamEntity', () {
    test('ranks qualities so the sharpest source is tried first', () {
      const uhd = StreamEntity(url: 'u', title: 't', quality: '4K');
      const hd = StreamEntity(url: 'u', title: 't', quality: '1080p');
      const unknown = StreamEntity(url: 'u', title: 't');

      expect(uhd.qualityRank, 2160);
      expect(hd.qualityRank, 1080);
      expect(unknown.qualityRank, 0);
    });

    test('omits headers that are not set', () {
      const stream = StreamEntity(url: 'u', title: 't');

      expect(stream.headers, isEmpty);
    });
  });

  group('assembleCatalogInBackground', () {
    test('produces the same catalog off the UI isolate', () async {
      final assembled = await assembleCatalogInBackground(
        channelsJson: _bytes(_channelsJson),
        streamsJson: _bytes(_streamsJson),
        logosJson: _bytes(_logosJson),
      );

      expect(assembled.channels, _assemble());
      expect(decodeCatalog(assembled.cachePayload), _assemble());
    });
  });
}

Uint8List _bytes(String value) => Uint8List.fromList(utf8.encode(value));

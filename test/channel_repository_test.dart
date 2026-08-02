import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiwee/data/datasources/catalog_cache_store.dart';
import 'package:tiwee/data/datasources/iptv_remote_data_source.dart';
import 'package:tiwee/data/repositories/channel_repository_impl.dart';

const String _channelsJson = '''
[
  {"id":"Alpha.us","name":"Alpha TV","alt_names":["Kanal Bir"],"country":"US",
   "categories":["news"],"is_nsfw":false},
  {"id":"Beta.fr","name":"Beta","alt_names":[],"country":"fr",
   "categories":["movies","news"],"is_nsfw":false},
  {"id":"Adult.us","name":"Adult Channel","alt_names":[],"country":"US",
   "categories":["xxx"],"is_nsfw":true}
]
''';

const String _streamsJson = '''
[
  {"channel":"Alpha.us","url":"https://a/live.m3u8","title":"Alpha"},
  {"channel":"Beta.fr","url":"https://b/live.m3u8","title":"Beta"},
  {"channel":"Adult.us","url":"https://x/live.m3u8","title":"Adult"}
]
''';

const String _logosJson = '[]';

const String _countriesJson = '''
[{"name":"United States","code":"US","flag":"🇺🇸","languages":["eng"]}]
''';

class _FakeRemote extends IptvRemoteDataSource {
  int channelCalls = 0;
  int countryCalls = 0;
  bool offline = false;

  Uint8List _bytes(String value) => Uint8List.fromList(utf8.encode(value));

  void _guard() {
    if (offline) throw ApiException('No internet connection.');
  }

  @override
  Future<Uint8List> getChannelsBytes() async {
    channelCalls++;
    _guard();
    return _bytes(_channelsJson);
  }

  @override
  Future<Uint8List> getStreamsBytes() async {
    _guard();
    return _bytes(_streamsJson);
  }

  @override
  Future<Uint8List> getLogosBytes() async {
    _guard();
    return _bytes(_logosJson);
  }

  @override
  Future<String> getCountriesJson() async {
    countryCalls++;
    _guard();
    return _countriesJson;
  }
}

void main() {
  late Directory tempDir;
  late _FakeRemote remote;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tiwee_test');
    remote = _FakeRemote();
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  CatalogCacheStore store({Duration maxAge = const Duration(hours: 12)}) {
    return CatalogCacheStore(
      maxAge: maxAge,
      directoryProvider: () async => tempDir,
    );
  }

  ChannelRepository repository({CatalogCacheStore? cacheStore}) {
    return ChannelRepository(
      remoteDataSource: remote,
      cacheStore: cacheStore ?? store(),
    );
  }

  group('ChannelRepository', () {
    test('hides nsfw channels unless they are asked for', () async {
      final repo = repository();

      expect(
        (await repo.getChannels()).map((channel) => channel.id),
        ['Alpha.us', 'Beta.fr'],
      );
      expect(await repo.getChannels(includeNsfw: true), hasLength(3));
    });

    test('downloads once for concurrent readers', () async {
      final repo = repository();

      await Future.wait([
        repo.getChannels(),
        repo.getChannelsByCategory('news'),
        repo.getChannelsByCountry('US'),
      ]);

      expect(remote.channelCalls, 1);
    });

    test('matches countries regardless of case', () async {
      final repo = repository();

      expect(
        (await repo.getChannelsByCountry('FR')).single.id,
        'Beta.fr',
        reason: 'the API mixes upper and lower case country codes',
      );
    });

    test('matches search terms against names and alternative names', () async {
      final channels = await repository().getChannels();

      expect(
        channels.where((channel) => channel.matches('kanal')).single.id,
        'Alpha.us',
      );
      expect(channels.where((channel) => channel.matches('alpha t')), isNotEmpty);
      expect(channels.where((channel) => channel.matches('nothing')), isEmpty);
    });

    test('serves a fresh disk cache without touching the network', () async {
      final cacheStore = store();
      await repository(cacheStore: cacheStore).getChannels();
      expect(remote.channelCalls, 1);

      // A new repository instance stands in for a fresh app launch.
      final channels =
          await repository(cacheStore: cacheStore).getChannels();

      expect(remote.channelCalls, 1, reason: 'the cache should have served it');
      expect(channels.map((channel) => channel.id), ['Alpha.us', 'Beta.fr']);
    });

    test('falls back to an expired cache when the network is down', () async {
      await repository(cacheStore: store()).getChannels();

      remote.offline = true;
      final channels = await repository(cacheStore: store(maxAge: Duration.zero))
          .getChannels();

      expect(channels.map((channel) => channel.id), ['Alpha.us', 'Beta.fr']);
    });

    test('reports the failure when there is nothing cached', () async {
      remote.offline = true;

      await expectLater(
        repository().getChannels(),
        throwsA(isA<ApiException>()),
      );
    });

    test('refresh drops the cache so the next read hits the network', () async {
      final cacheStore = store();
      final repo = repository(cacheStore: cacheStore);
      await repo.getChannels();

      await repo.refresh();
      await repo.getChannels();

      expect(remote.channelCalls, 2);
    });
  });

  group('CountryRepository', () {
    test('caches countries across instances', () async {
      final cacheStore = store();
      final first = CountryRepository(
        remoteDataSource: remote,
        cacheStore: cacheStore,
      );
      expect((await first.getCountries()).single.code, 'US');

      final second = CountryRepository(
        remoteDataSource: remote,
        cacheStore: cacheStore,
      );
      expect(await second.getCountryByCode('us'), isNotNull);
      expect(remote.countryCalls, 1);
    });

    test('survives an offline start with a stale cache', () async {
      await CountryRepository(
        remoteDataSource: remote,
        cacheStore: store(),
      ).getCountries();

      remote.offline = true;
      final countries = await CountryRepository(
        remoteDataSource: remote,
        cacheStore: store(maxAge: Duration.zero),
      ).getCountries();

      expect(countries.single.name, 'United States');
    });
  });
}

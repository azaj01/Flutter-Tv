import 'package:flutter/foundation.dart';
import 'package:tiwee/core/utils/single_flight.dart';
import 'package:tiwee/data/catalog_assembler.dart';
import 'package:tiwee/data/datasources/catalog_cache_store.dart';
import 'package:tiwee/data/datasources/iptv_remote_data_source.dart';
import 'package:tiwee/domain/entities/category_entity.dart';
import 'package:tiwee/domain/entities/channel_entity.dart';
import 'package:tiwee/domain/entities/country_entity.dart';
import 'package:tiwee/domain/repositories/i_channel_repository.dart';

/// Implementation of channel repository
/// Follows Interface Segregation and Dependency Inversion principles
class ChannelRepository implements IChannelRepository {
  ChannelRepository({
    required IptvRemoteDataSource remoteDataSource,
    CatalogCacheStore? cacheStore,
  })  : _remoteDataSource = remoteDataSource,
        _cacheStore = cacheStore ?? CatalogCacheStore();

  static const String _cacheFileName = 'catalog.json';

  final IptvRemoteDataSource _remoteDataSource;
  final CatalogCacheStore _cacheStore;

  List<ChannelEntity>? _channels;

  /// Shared so concurrent readers — the menu and a category page opened right
  /// away — trigger a single download.
  final SingleFlight<List<ChannelEntity>> _loading = SingleFlight();

  Future<List<ChannelEntity>> _loadCatalog() {
    final loaded = _channels;
    if (loaded != null) return Future.value(loaded);

    return _loading.run(_fetchCatalog);
  }

  Future<List<ChannelEntity>> _fetchCatalog() async {
    final cached = await _cacheStore.read(_cacheFileName);

    if (cached != null && cached.isFresh) {
      final channels = await decodeCatalogInBackground(cached.contents);
      if (channels.isNotEmpty) {
        _channels = channels;
        return channels;
      }
    }

    try {
      // github.io serves these gzipped, but they still decode to ~21 MB, so
      // fetch them concurrently and merge them off the UI isolate.
      final payloads = await Future.wait([
        _remoteDataSource.getChannelsBytes(),
        _remoteDataSource.getStreamsBytes(),
        _remoteDataSource.getLogosBytes(),
      ]);

      final assembled = await assembleCatalogInBackground(
        channelsJson: payloads[0],
        streamsJson: payloads[1],
        logosJson: payloads[2],
      );

      _channels = assembled.channels;
      await _cacheStore.write(_cacheFileName, assembled.cachePayload);
      return assembled.channels;
    } catch (error) {
      // Offline with an expired cache is still better than an error screen.
      if (cached != null) {
        final channels = await decodeCatalogInBackground(cached.contents);
        if (channels.isNotEmpty) {
          debugPrint('Tiwee: serving stale catalog after failure ($error)');
          _channels = channels;
          return channels;
        }
      }
      rethrow;
    }
  }

  @override
  Future<List<ChannelEntity>> getChannels({bool includeNsfw = false}) async {
    final channels = await _loadCatalog();

    if (includeNsfw) return channels;
    return channels.where((channel) => !channel.isNsfw).toList();
  }

  @override
  Future<List<ChannelEntity>> getChannelsByCategory(String categoryId) async {
    final channels = await getChannels();

    return channels
        .where((channel) => channel.categories.contains(categoryId))
        .toList();
  }

  @override
  Future<List<ChannelEntity>> getChannelsByCountry(String countryCode) async {
    final channels = await getChannels();
    final code = countryCode.toUpperCase();

    return channels
        .where((channel) => channel.country.toUpperCase() == code)
        .toList();
  }

  @override
  Future<ChannelEntity?> getChannelById(String channelId) async {
    final channels = await _loadCatalog();

    for (final channel in channels) {
      if (channel.id == channelId) return channel;
    }
    return null;
  }

  @override
  Future<void> refresh() async {
    _channels = null;
    _loading.reset();
    await _cacheStore.delete(_cacheFileName);
  }
}

/// Implementation of category repository
class CategoryRepository implements ICategoryRepository {
  CategoryRepository({
    required IptvRemoteDataSource remoteDataSource,
    CatalogCacheStore? cacheStore,
  })  : _remoteDataSource = remoteDataSource,
        _cacheStore = cacheStore ?? CatalogCacheStore();

  static const String _cacheFileName = 'categories.json';

  final IptvRemoteDataSource _remoteDataSource;
  final CatalogCacheStore _cacheStore;

  List<CategoryEntity>? _categories;
  final SingleFlight<List<CategoryEntity>> _loading = SingleFlight();

  @override
  Future<List<CategoryEntity>> getCategories() {
    final loaded = _categories;
    if (loaded != null) return Future.value(loaded);

    return _loading.run(_fetch);
  }

  Future<List<CategoryEntity>> _fetch() async {
    final categories = await _loadCachedJson(
      cacheStore: _cacheStore,
      fileName: _cacheFileName,
      fetch: _remoteDataSource.getCategoriesJson,
      parse: (json) =>
          parseCategories(json).map((model) => model.toEntity()).toList(),
    );

    _categories = categories;
    return categories;
  }

  @override
  Future<CategoryEntity?> getCategoryById(String categoryId) async {
    final categories = await getCategories();

    for (final category in categories) {
      if (category.id == categoryId) return category;
    }
    return null;
  }

  @override
  Future<void> refresh() async {
    _categories = null;
    _loading.reset();
    await _cacheStore.delete(_cacheFileName);
  }
}

/// Implementation of country repository
class CountryRepository implements ICountryRepository {
  CountryRepository({
    required IptvRemoteDataSource remoteDataSource,
    CatalogCacheStore? cacheStore,
  })  : _remoteDataSource = remoteDataSource,
        _cacheStore = cacheStore ?? CatalogCacheStore();

  static const String _cacheFileName = 'countries.json';

  final IptvRemoteDataSource _remoteDataSource;
  final CatalogCacheStore _cacheStore;

  List<CountryEntity>? _countries;
  final SingleFlight<List<CountryEntity>> _loading = SingleFlight();

  @override
  Future<List<CountryEntity>> getCountries() {
    final loaded = _countries;
    if (loaded != null) return Future.value(loaded);

    return _loading.run(_fetch);
  }

  Future<List<CountryEntity>> _fetch() async {
    final countries = await _loadCachedJson(
      cacheStore: _cacheStore,
      fileName: _cacheFileName,
      fetch: _remoteDataSource.getCountriesJson,
      parse: (json) =>
          parseCountries(json).map((model) => model.toEntity()).toList(),
    );

    _countries = countries;
    return countries;
  }

  @override
  Future<CountryEntity?> getCountryByCode(String countryCode) async {
    final countries = await getCountries();
    final code = countryCode.toUpperCase();

    for (final country in countries) {
      if (country.code.toUpperCase() == code) return country;
    }
    return null;
  }

  @override
  Future<void> refresh() async {
    _countries = null;
    _loading.reset();
    await _cacheStore.delete(_cacheFileName);
  }
}

/// Reads a small JSON endpoint through the disk cache.
///
/// Fresh cache wins, then the network; a stale cache is the last resort so the
/// app keeps working offline.
Future<List<T>> _loadCachedJson<T>({
  required CatalogCacheStore cacheStore,
  required String fileName,
  required Future<String> Function() fetch,
  required List<T> Function(String json) parse,
}) async {
  final cached = await cacheStore.read(fileName);

  if (cached != null && cached.isFresh) {
    final parsed = _tryParse(cached.contents, parse);
    if (parsed != null && parsed.isNotEmpty) return parsed;
  }

  try {
    final json = await fetch();
    final parsed = parse(json);
    await cacheStore.write(fileName, json);
    return parsed;
  } catch (error) {
    if (cached != null) {
      final parsed = _tryParse(cached.contents, parse);
      if (parsed != null && parsed.isNotEmpty) {
        debugPrint('Tiwee: serving stale $fileName after failure ($error)');
        return parsed;
      }
    }
    rethrow;
  }
}

List<T>? _tryParse<T>(String json, List<T> Function(String json) parse) {
  try {
    return parse(json);
  } catch (error) {
    debugPrint('Tiwee: discarding unreadable cache ($error)');
    return null;
  }
}

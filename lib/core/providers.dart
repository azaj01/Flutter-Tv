import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiwee/core/theme/app_colors.dart';
import 'package:tiwee/data/datasources/catalog_cache_store.dart';
import 'package:tiwee/data/datasources/iptv_remote_data_source.dart';
import 'package:tiwee/data/datasources/preferences_store.dart';
import 'package:tiwee/data/datasources/update_checker.dart';
import 'package:tiwee/data/repositories/channel_repository_impl.dart';
import 'package:tiwee/domain/entities/category_entity.dart';
import 'package:tiwee/domain/entities/channel_entity.dart';
import 'package:tiwee/domain/entities/country_entity.dart';
import 'package:tiwee/domain/entities/parental_settings.dart';
import 'package:tiwee/domain/repositories/i_channel_repository.dart';

// ============================================================================
// Data Source Providers
// ============================================================================

/// Provides the remote data source singleton
final iptvRemoteDataSourceProvider = Provider<IptvRemoteDataSource>((ref) {
  return IptvRemoteDataSource();
});

/// Set up in `main` so preferences can be read synchronously while building.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

/// Provides persisted user settings (favourites, parental control)
final preferencesStoreProvider = Provider<PreferencesStore>((ref) {
  return PreferencesStore(ref.watch(sharedPreferencesProvider));
});

/// Provides the GitHub release lookup behind "Check for update"
final updateCheckerProvider = Provider<UpdateChecker>((ref) {
  return UpdateChecker();
});

/// The running app's version name, e.g. `1.0.0`.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});

/// Provides the shared on-disk cache for API payloads
final catalogCacheStoreProvider = Provider<CatalogCacheStore>((ref) {
  return CatalogCacheStore();
});

// ============================================================================
// Repository Providers
// ============================================================================

/// Provides the channel repository
final channelRepositoryProvider = Provider<IChannelRepository>((ref) {
  return ChannelRepository(
    remoteDataSource: ref.watch(iptvRemoteDataSourceProvider),
    cacheStore: ref.watch(catalogCacheStoreProvider),
  );
});

/// Provides the category repository
final categoryRepositoryProvider = Provider<ICategoryRepository>((ref) {
  return CategoryRepository(
    remoteDataSource: ref.watch(iptvRemoteDataSourceProvider),
    cacheStore: ref.watch(catalogCacheStoreProvider),
  );
});

/// Provides the country repository
final countryRepositoryProvider = Provider<ICountryRepository>((ref) {
  return CountryRepository(
    remoteDataSource: ref.watch(iptvRemoteDataSourceProvider),
    cacheStore: ref.watch(catalogCacheStoreProvider),
  );
});

// ============================================================================
// Async Notifiers / Providers
// ============================================================================

/// Handles loading and exposing the full channel catalog.
class ChannelsNotifier extends AsyncNotifier<List<ChannelEntity>> {
  @override
  Future<List<ChannelEntity>> build() async {
    final repository = ref.watch(channelRepositoryProvider);
    // Re-reads when the parental switch flips; the catalog itself stays cached
    // in the repository, so this only re-filters.
    final allowAdult = ref.watch(
      parentalSettingsProvider.select((it) => it.allowAdultChannels),
    );
    return repository.getChannels(includeNsfw: allowAdult);
  }
}

final channelsProvider =
    AsyncNotifierProvider<ChannelsNotifier, List<ChannelEntity>>(
  ChannelsNotifier.new,
);

/// Handles loading of all categories.
class CategoriesNotifier extends AsyncNotifier<List<CategoryEntity>> {
  @override
  Future<List<CategoryEntity>> build() async {
    final repository = ref.watch(categoryRepositoryProvider);
    return repository.getCategories();
  }
}

final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<CategoryEntity>>(
  CategoriesNotifier.new,
);

/// Handles loading of all countries.
class CountriesNotifier extends AsyncNotifier<List<CountryEntity>> {
  @override
  Future<List<CountryEntity>> build() async {
    final repository = ref.watch(countryRepositoryProvider);
    return repository.getCountries();
  }
}

final countriesProvider =
    AsyncNotifierProvider<CountriesNotifier, List<CountryEntity>>(
  CountriesNotifier.new,
);

/// Groups channels by category for quick lookups.
class ChannelsByCategoryNotifier
    extends AsyncNotifier<Map<String, List<ChannelEntity>>> {
  @override
  Future<Map<String, List<ChannelEntity>>> build() async {
    final channels = await ref.watch(channelsProvider.future);

    final categoryMap = <String, List<ChannelEntity>>{};

    for (final channel in channels) {
      for (final categoryId in channel.categories) {
        categoryMap.putIfAbsent(categoryId, () => []).add(channel);
      }
    }

    return categoryMap;
  }
}

final channelsByCategoryProvider = AsyncNotifierProvider<
    ChannelsByCategoryNotifier, Map<String, List<ChannelEntity>>>(
  ChannelsByCategoryNotifier.new,
);

/// Groups channels by country for quick lookups.
class ChannelsByCountryNotifier
    extends AsyncNotifier<Map<String, List<ChannelEntity>>> {
  @override
  Future<Map<String, List<ChannelEntity>>> build() async {
    final channels = await ref.watch(channelsProvider.future);

    final countryMap = <String, List<ChannelEntity>>{};

    for (final channel in channels) {
      if (channel.country.isNotEmpty) {
        countryMap.putIfAbsent(channel.country.toUpperCase(), () => [])
            .add(channel);
      }
    }

    return countryMap;
  }
}

final channelsByCountryProvider = AsyncNotifierProvider<
    ChannelsByCountryNotifier, Map<String, List<ChannelEntity>>>(
  ChannelsByCountryNotifier.new,
);

/// Loads channels scoped to a single category.
final channelsForCategoryProvider = FutureProvider.autoDispose
    .family<List<ChannelEntity>, String>((ref, categoryId) {
  final repository = ref.watch(channelRepositoryProvider);
  return repository.getChannelsByCategory(categoryId);
});

/// Loads channels scoped to a single country.
final channelsForCountryProvider = FutureProvider.autoDispose
    .family<List<ChannelEntity>, String>((ref, countryCode) {
  final repository = ref.watch(channelRepositoryProvider);
  return repository.getChannelsByCountry(countryCode);
});

// ============================================================================
// Favourites
// ============================================================================

/// Ids of the channels the user saved, oldest first.
class FavouritesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    // LinkedHashSet: insertion order is the order they were saved in.
    return ref.watch(preferencesStoreProvider).favouriteIds().toSet();
  }

  /// Adds or removes [channelId]; returns true when it is now a favourite.
  bool toggle(String channelId) {
    final updated = Set<String>.of(state);
    final added = updated.add(channelId);
    if (!added) updated.remove(channelId);

    state = updated;
    ref.read(preferencesStoreProvider).saveFavouriteIds(updated).ignore();
    return added;
  }

  void clear() {
    state = {};
    ref.read(preferencesStoreProvider).saveFavouriteIds(const []).ignore();
  }
}

final favouritesProvider =
    NotifierProvider<FavouritesNotifier, Set<String>>(FavouritesNotifier.new);

/// Whether a single channel is saved, without rebuilding on unrelated changes.
final isFavouriteProvider = Provider.autoDispose.family<bool, String>(
  (ref, channelId) =>
      ref.watch(favouritesProvider.select((ids) => ids.contains(channelId))),
);

/// The saved channels, resolved against the loaded catalog.
///
/// Ids that no longer exist upstream are skipped rather than shown as blanks.
final favouriteChannelsProvider =
    Provider<AsyncValue<List<ChannelEntity>>>((ref) {
  final ids = ref.watch(favouritesProvider);

  // With nothing saved there is nothing to resolve, so don't make the empty
  // state wait on (or fail with) a catalog load.
  if (ids.isEmpty) return const AsyncData([]);

  return ref.watch(channelsProvider).whenData((channels) {
    final byId = {for (final channel in channels) channel.id: channel};
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
  });
});

// ============================================================================
// Appearance
// ============================================================================

/// The active dark palette, persisted across launches.
class ThemePaletteNotifier extends Notifier<ThemePalette> {
  @override
  ThemePalette build() => ref.watch(preferencesStoreProvider).themePalette();

  void select(ThemePalette palette) {
    state = palette;
    ref.read(preferencesStoreProvider).saveThemePalette(palette).ignore();
  }

  void toggle() => select(
        state == ThemePalette.dark ? ThemePalette.amoled : ThemePalette.dark,
      );
}

final themePaletteProvider =
    NotifierProvider<ThemePaletteNotifier, ThemePalette>(
  ThemePaletteNotifier.new,
);

// ============================================================================
// Parental control
// ============================================================================

class ParentalSettingsNotifier extends Notifier<ParentalSettings> {
  @override
  ParentalSettings build() {
    final store = ref.watch(preferencesStoreProvider);
    return ParentalSettings(
      allowAdultChannels: store.allowAdultChannels(),
      pin: store.parentalPin(),
    );
  }

  void setAllowAdultChannels({required bool allow}) {
    state = state.copyWith(allowAdultChannels: allow);
    ref
        .read(preferencesStoreProvider)
        .saveAllowAdultChannels(allow: allow)
        .ignore();
  }

  void setPin(String? pin) {
    state = pin == null ? state.withoutPin() : state.copyWith(pin: pin);
    ref.read(preferencesStoreProvider).saveParentalPin(pin).ignore();
  }
}

final parentalSettingsProvider =
    NotifierProvider<ParentalSettingsNotifier, ParentalSettings>(
  ParentalSettingsNotifier.new,
);

/// The current query of the all-channels search field.
class ChannelQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  // ignore: use_setters_to_change_properties
  void update(String query) => state = query;
}

final channelQueryProvider =
    NotifierProvider.autoDispose<ChannelQueryNotifier, String>(
  ChannelQueryNotifier.new,
);

/// The catalog narrowed by [channelQueryProvider].
///
/// Filtering the already-loaded catalog synchronously keeps typing smooth — an
/// async search would drop back to a loading state on every keystroke.
final filteredChannelsProvider =
    Provider.autoDispose<AsyncValue<List<ChannelEntity>>>((ref) {
  final channels = ref.watch(channelsProvider);
  final query = ref.watch(channelQueryProvider).trim().toLowerCase();

  if (query.isEmpty) return channels;

  return channels.whenData(
    (list) => list.where((channel) => channel.matches(query)).toList(),
  );
});

// ============================================================================
// Refresh
// ============================================================================

/// Clears every cached layer and reloads the catalog.
///
/// Used by the retry buttons on the error screens and by pull-to-refresh, so a
/// transient network failure does not require restarting the app.
class CatalogRefresher {
  CatalogRefresher(this._ref);

  final Ref _ref;

  Future<void> refresh() async {
    await Future.wait([
      _ref.read(channelRepositoryProvider).refresh(),
      _ref.read(categoryRepositoryProvider).refresh(),
      _ref.read(countryRepositoryProvider).refresh(),
    ]);

    _ref
      ..invalidate(channelsProvider)
      ..invalidate(categoriesProvider)
      ..invalidate(countriesProvider)
      ..invalidate(channelsForCategoryProvider)
      ..invalidate(channelsForCountryProvider);

    // Surface the outcome to the caller so retry buttons can await it.
    await _ref.read(channelsProvider.future);
  }

  /// [refresh] without the throw, for pull-to-refresh and retry buttons: the
  /// reloaded providers already render whatever went wrong.
  Future<void> refreshQuietly() async {
    try {
      await refresh();
    } catch (error) {
      debugPrint('Tiwee: refresh failed ($error)');
    }
  }
}

final catalogRefresherProvider = Provider<CatalogRefresher>(
  CatalogRefresher.new,
);

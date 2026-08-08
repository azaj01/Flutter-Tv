import 'package:tiwee/domain/entities/category_entity.dart';
import 'package:tiwee/domain/entities/channel_entity.dart';
import 'package:tiwee/domain/entities/country_entity.dart';

/// Repository interface for channel-related operations
/// Following Dependency Inversion Principle - domain defines the contract
abstract class IChannelRepository {
  /// Fetches every playable channel.
  ///
  /// Channels without a working stream entry, and channels that have shut
  /// down, are never returned: the app cannot play them.
  Future<List<ChannelEntity>> getChannels({bool includeNsfw = false});

  /// Fetches channels by category
  Future<List<ChannelEntity>> getChannelsByCategory(String categoryId);

  /// Fetches channels by country code
  Future<List<ChannelEntity>> getChannelsByCountry(String countryCode);

  /// Fetches a single channel by ID
  Future<ChannelEntity?> getChannelById(String channelId);

  /// Drops cached data so the next read comes from the network.
  Future<void> refresh();
}

/// Repository interface for category-related operations
abstract class ICategoryRepository {
  /// Fetches all available categories
  Future<List<CategoryEntity>> getCategories();

  /// Fetches a category by ID
  Future<CategoryEntity?> getCategoryById(String categoryId);

  /// Drops cached data so the next read comes from the network.
  Future<void> refresh();
}

/// Repository interface for country-related operations
abstract class ICountryRepository {
  /// Fetches all available countries
  Future<List<CountryEntity>> getCountries();

  /// Fetches a country by code
  Future<CountryEntity?> getCountryByCode(String countryCode);

  /// Drops cached data so the next read comes from the network.
  Future<void> refresh();
}

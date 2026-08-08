import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiwee/core/theme/app_colors.dart';

/// Everything the app remembers between launches.
///
/// Thin wrapper over [SharedPreferences] so the providers deal in domain terms
/// (favourites, parental lock) instead of string keys, and so tests can point
/// at mock values.
class PreferencesStore {
  PreferencesStore(this._prefs);

  static const String _favouritesKey = 'favourite_channel_ids';
  static const String _allowAdultKey = 'allow_adult_channels';
  static const String _parentalPinKey = 'parental_pin';
  static const String _themePaletteKey = 'theme_palette';

  final SharedPreferences _prefs;

  /// Favourite channel ids, oldest first.
  List<String> favouriteIds() => _prefs.getStringList(_favouritesKey) ?? const [];

  Future<void> saveFavouriteIds(Iterable<String> ids) =>
      _prefs.setStringList(_favouritesKey, ids.toList());

  /// Whether channels flagged as adult are allowed into the catalog.
  ///
  /// Off by default: parental control is only useful if it is the initial
  /// state rather than something a parent has to discover.
  bool allowAdultChannels() => _prefs.getBool(_allowAdultKey) ?? false;

  Future<void> saveAllowAdultChannels({required bool allow}) =>
      _prefs.setBool(_allowAdultKey, allow);

  /// The chosen dark palette.
  ThemePalette themePalette() =>
      ThemePalette.fromName(_prefs.getString(_themePaletteKey));

  Future<void> saveThemePalette(ThemePalette palette) =>
      _prefs.setString(_themePaletteKey, palette.name);

  /// The PIN guarding the adult-channel switch, or null when none is set.
  String? parentalPin() => _prefs.getString(_parentalPinKey);

  Future<void> saveParentalPin(String? pin) => pin == null
      ? _prefs.remove(_parentalPinKey)
      : _prefs.setString(_parentalPinKey, pin);
}

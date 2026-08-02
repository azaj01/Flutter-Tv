import 'package:equatable/equatable.dart';

/// Immutable domain entity representing a TV channel.
///
/// Deliberately narrower than the API payload: the catalog holds ten thousand
/// of these, they are cached to disk, and the app never renders a channel's
/// owners, network, launch date or website. Those stay on [ChannelModel] so a
/// cached channel and a freshly downloaded one compare equal.
class ChannelEntity extends Equatable {
  const ChannelEntity({
    required this.id,
    required this.name,
    required this.altNames,
    required this.country,
    required this.categories,
    required this.isNsfw,
    this.logo,
    this.streams,
  });

  final String id;
  final String name;
  final List<String> altNames;
  final String country;
  final List<String> categories;
  final bool isNsfw;
  final String? logo;

  /// Every known source for this channel, best quality first.
  final List<StreamEntity>? streams;

  /// Whether this channel matches a search term.
  ///
  /// [lowerCaseQuery] must already be lower-cased and trimmed — search runs
  /// over the whole catalog on every keystroke, so the caller normalises once.
  bool matches(String lowerCaseQuery) {
    if (name.toLowerCase().contains(lowerCaseQuery)) return true;
    return altNames.any((alt) => alt.toLowerCase().contains(lowerCaseQuery));
  }

  @override
  List<Object?> get props => [
        id,
        name,
        altNames,
        country,
        categories,
        isNsfw,
        logo,
        streams,
      ];

  ChannelEntity copyWith({
    String? id,
    String? name,
    List<String>? altNames,
    String? country,
    List<String>? categories,
    bool? isNsfw,
    String? logo,
    List<StreamEntity>? streams,
  }) {
    return ChannelEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      altNames: altNames ?? this.altNames,
      country: country ?? this.country,
      categories: categories ?? this.categories,
      isNsfw: isNsfw ?? this.isNsfw,
      logo: logo ?? this.logo,
      streams: streams ?? this.streams,
    );
  }
}

/// Immutable domain entity representing a stream
class StreamEntity extends Equatable {
  const StreamEntity({
    required this.url,
    required this.title,
    this.quality,
    this.userAgent,
    this.referrer,
  });

  final String url;
  final String title;
  final String? quality;
  final String? userAgent;
  final String? referrer;

  /// Vertical resolution parsed out of [quality] (`720p` -> 720, `4k` -> 2160).
  ///
  /// Used to try the sharpest stream first; unknown qualities rank lowest.
  int get qualityRank {
    final raw = quality;
    if (raw == null || raw.isEmpty) return 0;
    if (raw.toLowerCase().contains('4k')) return 2160;
    final match = RegExp(r'\d+').firstMatch(raw);
    return match == null ? 0 : int.parse(match.group(0)!);
  }

  /// Headers some providers require before they will serve the stream.
  Map<String, String> get headers => {
        if (userAgent != null && userAgent!.isNotEmpty) 'User-Agent': userAgent!,
        if (referrer != null && referrer!.isNotEmpty) 'Referer': referrer!,
      };

  @override
  List<Object?> get props => [url, title, quality, userAgent, referrer];

  StreamEntity copyWith({
    String? url,
    String? title,
    String? quality,
    String? userAgent,
    String? referrer,
  }) {
    return StreamEntity(
      url: url ?? this.url,
      title: title ?? this.title,
      quality: quality ?? this.quality,
      userAgent: userAgent ?? this.userAgent,
      referrer: referrer ?? this.referrer,
    );
  }
}

import 'package:tiwee/domain/entities/channel_entity.dart';

/// Data model for API response - mutable for JSON parsing
class ChannelModel {
  ChannelModel({
    required this.id,
    required this.name,
    required this.altNames,
    required this.country,
    required this.categories,
    required this.isNsfw,
    this.network,
    this.owners,
    this.launched,
    this.closed,
    this.replacedBy,
    this.website,
  });

  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    return ChannelModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      altNames: (json['alt_names'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      country: json['country'] as String? ?? '',
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isNsfw: json['is_nsfw'] as bool? ?? false,
      network: json['network'] as String?,
      owners:
          (json['owners'] as List<dynamic>?)?.map((e) => e as String).toList(),
      launched: json['launched'] != null
          ? DateTime.tryParse(json['launched'] as String)
          : null,
      closed: json['closed'] != null
          ? DateTime.tryParse(json['closed'] as String)
          : null,
      replacedBy: json['replaced_by'] as String?,
      website: json['website'] as String?,
    );
  }

  final String id;
  final String name;
  final List<String> altNames;
  final String country;
  final List<String> categories;
  final bool isNsfw;
  final String? network;
  final List<String>? owners;
  final DateTime? launched;
  final DateTime? closed;
  final String? replacedBy;
  final String? website;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'alt_names': altNames,
      'country': country,
      'categories': categories,
      'is_nsfw': isNsfw,
      'network': network,
      'owners': owners,
      'launched': launched?.toIso8601String(),
      'closed': closed?.toIso8601String(),
      'replaced_by': replacedBy,
      'website': website,
    };
  }

  /// Converts data model to domain entity
  ChannelEntity toEntity({
    String? logo,
    List<StreamEntity>? streams,
  }) {
    return ChannelEntity(
      id: id,
      name: name,
      altNames: altNames,
      country: country,
      categories: categories,
      isNsfw: isNsfw,
      logo: logo,
      streams: streams,
    );
  }
}

/// Data model for stream API response
class StreamModel {
  StreamModel({
    required this.url,
    required this.title,
    this.channel,
    this.feed,
    this.quality,
    this.userAgent,
    this.referrer,
  });

  factory StreamModel.fromJson(Map<String, dynamic> json) {
    return StreamModel(
      url: json['url'] as String? ?? '',
      title: json['title'] as String? ?? '',
      channel: json['channel'] as String?,
      feed: json['feed'] as String?,
      quality: json['quality'] as String?,
      userAgent: json['user_agent'] as String?,
      referrer: json['referrer'] as String?,
    );
  }

  final String url;
  final String title;
  final String? channel;
  final String? feed;
  final String? quality;
  final String? userAgent;
  final String? referrer;

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'title': title,
      'channel': channel,
      'feed': feed,
      'quality': quality,
      'user_agent': userAgent,
      'referrer': referrer,
    };
  }

  /// Converts data model to domain entity
  StreamEntity toEntity() {
    return StreamEntity(
      url: url,
      title: title,
      quality: quality,
      userAgent: userAgent,
      referrer: referrer,
    );
  }
}

/// Data model for logo API response
class LogoModel {
  LogoModel({
    required this.url,
    required this.channel,
    this.feed,
    this.tags,
    this.width,
    this.height,
    this.format,
    this.inUse = true,
  });

  factory LogoModel.fromJson(Map<String, dynamic> json) {
    return LogoModel(
      url: json['url'] as String? ?? '',
      channel: json['channel'] as String? ?? '',
      feed: json['feed'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      width: json['width'] as int?,
      height: json['height'] as int?,
      format: json['format'] as String?,
      inUse: json['in_use'] as bool? ?? true,
    );
  }

  final String url;
  final String channel;
  final String? feed;
  final List<String>? tags;
  final int? width;
  final int? height;
  final String? format;

  /// The API marks superseded artwork with `in_use: false`; those logos are
  /// still served but no longer represent the channel.
  final bool inUse;

  /// Ranks how well this logo represents its channel. Higher wins.
  int get preferenceScore =>
      (inUse ? 2 : 0) + (feed == null || feed!.isEmpty ? 1 : 0);

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'channel': channel,
      'feed': feed,
      'tags': tags,
      'width': width,
      'height': height,
      'format': format,
      'in_use': inUse,
    };
  }
}

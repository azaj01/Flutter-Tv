import 'package:tiwee/domain/entities/country_entity.dart';

/// Data model for country API response
class CountryModel {
  CountryModel({
    required this.name,
    required this.code,
    required this.flag,
    this.languages,
  });

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    return CountryModel(
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      flag: json['flag'] as String? ?? '',
      languages: (json['languages'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  final String name;
  final String code;
  final String flag;
  final List<String>? languages;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'flag': flag,
      'languages': languages,
    };
  }

  /// Converts data model to domain entity
  CountryEntity toEntity() {
    return CountryEntity(
      name: name,
      code: code,
      flag: flag,
      languages: languages,
    );
  }
}

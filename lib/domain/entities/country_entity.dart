import 'package:equatable/equatable.dart';

/// Immutable domain entity representing a country
class CountryEntity extends Equatable {
  const CountryEntity({
    required this.name,
    required this.code,
    required this.flag,
    this.languages,
  });

  final String name;
  final String code;
  final String flag;
  final List<String>? languages;

  @override
  List<Object?> get props => [name, code, flag, languages];

  CountryEntity copyWith({
    String? name,
    String? code,
    String? flag,
    List<String>? languages,
  }) {
    return CountryEntity(
      name: name ?? this.name,
      code: code ?? this.code,
      flag: flag ?? this.flag,
      languages: languages ?? this.languages,
    );
  }
}

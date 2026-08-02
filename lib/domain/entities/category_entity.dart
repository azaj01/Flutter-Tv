import 'package:equatable/equatable.dart';

/// Immutable domain entity representing a category
class CategoryEntity extends Equatable {
  const CategoryEntity({
    required this.id,
    required this.name,
    this.description,
  });

  final String id;
  final String name;
  final String? description;

  @override
  List<Object?> get props => [id, name, description];

  CategoryEntity copyWith({
    String? id,
    String? name,
    String? description,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }
}

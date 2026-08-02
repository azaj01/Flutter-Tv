import 'package:tiwee/domain/entities/category_entity.dart';

/// Data model for category API response
class CategoryModel {
  CategoryModel({
    required this.id,
    required this.name,
    this.description,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
    );
  }

  final String id;
  final String name;
  final String? description;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }

  /// Converts data model to domain entity
  CategoryEntity toEntity() {
    return CategoryEntity(
      id: id,
      name: name,
      description: description,
    );
  }
}

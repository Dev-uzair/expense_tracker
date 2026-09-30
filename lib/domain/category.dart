import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'category.g.dart';

// HiveObject keeps a mutable box/key reference, so the class can't be fully
// immutable even though all of its own fields are final.
@HiveType(typeId: 1)
// ignore: must_be_immutable
class Category extends HiveObject with EquatableMixin {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String type; // 'expense' or 'income'

  @HiveField(3)
  final String? categoryIcon;

  Category({
    required this.id,
    required this.name,
    required this.type,
    this.categoryIcon,
  });

  Category copyWith({
    String? id,
    String? name,
    String? type,
    String? categoryIcon,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      categoryIcon: categoryIcon ?? this.categoryIcon,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'categoryIcon': categoryIcon,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      categoryIcon: json['categoryIcon'],
    );
  }

  @override
  List<Object?> get props => [id, name, type, categoryIcon];
}

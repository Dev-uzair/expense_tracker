import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'budget.g.dart';

// A monthly spending limit, repeated every month, for one expense category
// or (with [overallCategoryId]) for all expenses together.
//
// HiveObject keeps a mutable box/key reference, so the class can't be fully
// immutable even though all of its own fields are final.
@HiveType(typeId: 2)
// ignore: must_be_immutable
class Budget extends HiveObject with EquatableMixin {
  static const String overallCategoryId = '*';

  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  // Field indexes 3 and 4 held start/end dates in an earlier, unused
  // design; don't reuse them.
  @HiveField(2)
  final String categoryId;

  Budget({required this.id, required this.amount, required this.categoryId});

  bool get isOverall => categoryId == overallCategoryId;

  Budget copyWith({double? amount, String? categoryId}) => Budget(
    id: id,
    amount: amount ?? this.amount,
    categoryId: categoryId ?? this.categoryId,
  );

  Map<String, dynamic> toJson() {
    return {'id': id, 'amount': amount, 'categoryId': categoryId};
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      categoryId: json['categoryId'],
    );
  }

  @override
  List<Object?> get props => [id, amount, categoryId];
}

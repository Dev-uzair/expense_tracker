import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
class Transaction extends HiveObject with EquatableMixin {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String categoryId;

  @HiveField(3)
  final String type;

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  final String? description; // New field

  @HiveField(6)
  final String? paymentMethod; // New field

  Transaction({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.type,
    required this.date,
    this.description, // Made optional
    this.paymentMethod, // Made optional
  });

  Transaction copyWith({
    String? id,
    double? amount,
    String? categoryId,
    String? type,
    DateTime? date,
    String? description,
    String? paymentMethod,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      date: date ?? this.date,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'categoryId': categoryId,
      'type': type,
      'date': date.toIso8601String(),
      'description': description,
      'paymentMethod': paymentMethod,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      amount: json['amount'],
      categoryId: json['categoryId'],
      type: json['type'],
      date: DateTime.parse(json['date']),
      description: json['description'],
      paymentMethod: json['paymentMethod'],
    );
  }

  @override
  List<Object?> get props => [id, amount, categoryId, type, date, description, paymentMethod];
}

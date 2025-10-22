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
  final String category;

  @HiveField(3)
  final String type;

  @HiveField(4)
  final DateTime date;

  Transaction({
    required this.id,
    required this.amount,
    required this.category,
    required this.type,
    required this.date,
  });

  Transaction copyWith({
    String? id,
    double? amount,
    String? category,
    String? type,
    DateTime? date,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      type: type ?? this.type,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'type': type,
      'date': date.toIso8601String(),
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      amount: json['amount'],
      category: json['category'],
      type: json['type'],
      date: DateTime.parse(json['date']),
    );
  }

  @override
  List<Object?> get props => [id, amount, category, type, date];
}

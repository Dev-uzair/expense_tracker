import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/domain/transaction.dart';

void main() {
  group('Transaction', () {
    test('fromJson and toJson', () {
      final date = DateTime.now();
      final transaction = Transaction(
        id: '1',
        amount: 100.0,
        category: 'Food',
        type: 'expense',
        date: date,
      );

      final json = transaction.toJson();
      final fromJson = Transaction.fromJson(json);

      expect(fromJson.id, transaction.id);
      expect(fromJson.amount, transaction.amount);
      expect(fromJson.category, transaction.category);
      expect(fromJson.type, transaction.type);
      expect(fromJson.date, transaction.date);
    });
  });
}

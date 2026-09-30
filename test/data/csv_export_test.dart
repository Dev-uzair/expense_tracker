import 'package:expense_tracker/data/csv_export.dart';
import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/domain/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final categories = {
    'food': Category(id: 'food', name: 'Food & Dining', type: 'expense'),
    'salary': Category(id: 'salary', name: 'Salary', type: 'income'),
  };

  test('writes a header and one row per transaction, oldest first', () {
    final csv = transactionsToCsv(
      [
        Transaction(
          id: '2',
          amount: 12.5,
          categoryId: 'food',
          type: 'expense',
          date: DateTime(2026, 9, 5, 13, 7),
          description: 'Lunch',
          paymentMethod: 'Cash',
        ),
        Transaction(
          id: '1',
          amount: 3000,
          categoryId: 'salary',
          type: 'income',
          date: DateTime(2026, 9, 1, 9),
        ),
      ],
      categories,
      currencyCode: 'PKR',
    );

    expect(csv.startsWith('﻿'), isTrue);
    expect(csv.substring(1).split('\r\n'), [
      'Date,Time,Type,Category,Amount (PKR),Payment method,Description',
      '2026-09-01,09:00,Income,Salary,3000.00,,',
      '2026-09-05,13:07,Expense,Food & Dining,12.50,Cash,Lunch',
    ]);
  });

  test('quotes commas, quotes and newlines; unknown categories', () {
    final csv = transactionsToCsv(
      [
        Transaction(
          id: '1',
          amount: 1,
          categoryId: 'gone',
          type: 'expense',
          date: DateTime(2026, 9, 1),
          description: 'Pens, "gel"\nand paper',
        ),
      ],
      categories,
      currencyCode: 'USD',
    );
    expect(
      csv.substring(1).split('\r\n').skip(1).join('\r\n'),
      '2026-09-01,00:00,Expense,Uncategorized,1.00,,"Pens, ""gel""\nand paper"',
    );
  });

  test('text that looks like a formula is neutralised', () {
    for (final risky in ['=HYPERLINK("x")', '+1+1', '-2', '@SUM(A1)']) {
      final csv = transactionsToCsv(
        [
          Transaction(
            id: '1',
            amount: 1,
            categoryId: 'food',
            type: 'expense',
            date: DateTime(2026, 9, 1),
            description: risky,
          ),
        ],
        categories,
        currencyCode: 'USD',
      );
      final description = csv.split('\r\n').last.split(',').skip(6).join(',');
      expect(description.replaceAll('"', ''), startsWith("'"), reason: risky);
    }
  });
}

import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/domain/transaction.dart';
import 'package:intl/intl.dart';

// Byte-order mark so Excel opens the file as UTF-8 (currency symbols,
// non-English descriptions).
const String _utf8Bom = '﻿';

// CSV of [transactions], oldest first, for spreadsheets. Amounts are plain
// numbers so they can be summed; the header names the currency.
String transactionsToCsv(
  List<Transaction> transactions,
  Map<String, Category> categories, {
  required String currencyCode,
}) {
  final sorted = [...transactions]..sort((a, b) => a.date.compareTo(b.date));
  final date = DateFormat('yyyy-MM-dd');
  final time = DateFormat('HH:mm');
  final rows = <List<String>>[
    [
      'Date',
      'Time',
      'Type',
      'Category',
      'Amount ($currencyCode)',
      'Payment method',
      'Description',
    ],
    for (final t in sorted)
      [
        date.format(t.date),
        time.format(t.date),
        t.type == 'income' ? 'Income' : 'Expense',
        _text(categories[t.categoryId]?.name ?? 'Uncategorized'),
        t.amount.toStringAsFixed(2),
        _text(t.paymentMethod ?? ''),
        _text(t.description ?? ''),
      ],
  ];
  return _utf8Bom + rows.map((r) => r.map(_escape).join(',')).join('\r\n');
}

// Free text is prefixed with an apostrophe when it starts like a formula, so
// a spreadsheet shows it instead of running it (CSV injection).
String _text(String value) =>
    RegExp(r'^[=+\-@\t\r]').hasMatch(value) ? "'$value" : value;

String _escape(String value) {
  if (!RegExp(r'[",\r\n]').hasMatch(value)) return value;
  return '"${value.replaceAll('"', '""')}"';
}

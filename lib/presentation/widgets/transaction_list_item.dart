import 'package:expense_tracker/core/category_icons.dart';
import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/domain/transaction.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final Category? category;

  const TransactionListItem({
    super.key,
    required this.transaction,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'expense';
    final amountColor = isExpense ? Colors.red : Colors.green;
    final amountString =
        '${isExpense ? '-' : '+'}\$${transaction.amount.toStringAsFixed(2)}';

    return ListTile(
      leading: Icon(categoryIconData(category?.categoryIcon)),
      title: Text(transaction.description ?? 'N/A'),
      subtitle: Text(DateFormat.yMd().add_jm().format(transaction.date)),
      trailing: Text(
        amountString,
        style: TextStyle(color: amountColor, fontWeight: FontWeight.bold),
      ),
    );
  }
}

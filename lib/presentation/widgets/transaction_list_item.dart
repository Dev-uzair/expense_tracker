import 'package:expense_tracker/core/category_icons.dart';
import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/domain/transaction.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final Category? category;
  final VoidCallback? onTap;

  const TransactionListItem({
    super.key,
    required this.transaction,
    this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'expense';
    final amountColor = isExpense ? Colors.red : Colors.green;
    final amountString =
        '${isExpense ? '-' : '+'}\$${transaction.amount.toStringAsFixed(2)}';

    return ListTile(
      onTap: onTap,
      leading: Icon(categoryIconData(category?.categoryIcon)),
      title: Text(
        transaction.description ?? category?.name ?? 'Transaction',
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          // The category is already the title when there's no description.
          if (transaction.description != null && category != null)
            category!.name,
          DateFormat.yMd().add_jm().format(transaction.date),
        ].join(' · '),
      ),
      trailing: Text(
        amountString,
        style: TextStyle(color: amountColor, fontWeight: FontWeight.bold),
      ),
    );
  }
}

import 'package:expense_tracker/presentation/providers/transaction_providers.dart';
import 'package:expense_tracker/presentation/pages/edit_transaction_screen.dart';
import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/domain/transaction.dart';
import 'package:expense_tracker/presentation/providers/providers.dart';
import 'package:expense_tracker/presentation/widgets/empty_state_widget.dart';
import 'package:expense_tracker/presentation/widgets/transaction_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../notifiers/transaction_notifier.dart';

abstract class ListItem {}

class DateSeparatorItem extends ListItem {
  final DateTime date;
  final double total;
  DateSeparatorItem(this.date, this.total);
}

class TransactionItem extends ListItem {
  final Transaction transaction;
  TransactionItem(this.transaction);
}

bool isSameDay(DateTime date1, DateTime date2) {
  return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
}

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsyncValue = ref.watch(transactionWithCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
      ),
      body: transactionsAsyncValue.when(
        data: (data) {
          final (transactions, categoryMap) = data;

          if (transactions.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.receipt_long,
              title: 'No Transactions',
              message: 'You haven\'t added any transactions yet.',
            );
          }

          final groupedTransactions = <DateTime, List<Transaction>>{};
          final dailyTotals = <DateTime, double>{};

          for (var tx in transactions) {
            final date = DateTime(tx.date.year, tx.date.month, tx.date.day);
            if (groupedTransactions.containsKey(date)) {
              groupedTransactions[date]!.add(tx);
            } else {
              groupedTransactions[date] = [tx];
            }

            dailyTotals.update(
              date,
              (value) => value + (tx.type == 'expense' ? -tx.amount : tx.amount),
              ifAbsent: () => (tx.type == 'expense' ? -tx.amount : tx.amount),
            );
          }

          final sortedDates = groupedTransactions.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          final items = <ListItem>[];
          for (var date in sortedDates) {
            items.add(DateSeparatorItem(date, dailyTotals[date]!));
            items.addAll(groupedTransactions[date]!.map((tx) => TransactionItem(tx)));
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(transactionWithCategoryProvider.future),
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                if (item is DateSeparatorItem) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat.yMMMd().format(item.date),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          '\$${item.total.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  );
                } else if (item is TransactionItem) {
                  final category = categoryMap[item.transaction.categoryId];
                  return Dismissible(
                    key: Key(item.transaction.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      final deletedTransaction = item.transaction;
                      ref
                          .read(transactionNotifierProvider.notifier)
                          .deleteTransaction(item.transaction.id);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Transaction deleted'),
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () {
                              ref
                                  .read(transactionNotifierProvider.notifier)
                                  .addTransaction(deletedTransaction);
                            },
                          ),
                        ),
                      );
                    },
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EditTransactionScreen(
                              transaction: item.transaction,
                              category: category,
                            ),
                          ),
                        );
                      },
                      child: TransactionListItem(
                        transaction: item.transaction,
                        category: category,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

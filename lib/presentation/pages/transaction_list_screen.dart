import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/presentation/providers/filter_providers.dart';
import 'package:expense_tracker/presentation/providers/transaction_providers.dart';
import 'package:expense_tracker/presentation/pages/edit_transaction_screen.dart';
import 'package:expense_tracker/domain/transaction.dart';
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
  return date1.year == date2.year &&
      date1.month == date2.month &&
      date1.day == date2.day;
}

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  late final TextEditingController _searchController = TextEditingController(
    text: ref.read(transactionFilterProvider).query,
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  TransactionFilter get _filter => ref.read(transactionFilterProvider);

  void _setFilter(TransactionFilter filter) =>
      ref.read(transactionFilterProvider.notifier).setFilter(filter);

  void _clearFilters() {
    _searchController.clear();
    ref.read(transactionFilterProvider.notifier).clear();
  }

  Future<T?> _choose<T>(String title, List<(T, String)> options, T current) {
    return showModalBottomSheet<T>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final (value, label) in options)
              ListTile(
                title: Text(label),
                trailing: value == current ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(value),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _choosePeriod() async {
    final period = await _choose('Period', [
      for (final p in FilterPeriod.values) (p, p.label),
    ], _filter.period);
    if (period == null || !mounted) return;
    if (period != FilterPeriod.custom) {
      _setFilter(_filter.copyWith(period: period));
      return;
    }
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _filter.customRange,
    );
    if (range == null) return;
    _setFilter(_filter.copyWith(period: period, customRange: () => range));
  }

  Future<void> _chooseType() async {
    // A sentinel stands in for "all", since null means the sheet was dismissed.
    const all = '';
    final type = await _choose('Type', const [
      (all, 'All types'),
      ('expense', 'Expense'),
      ('income', 'Income'),
    ], _filter.type ?? all);
    if (type == null) return;
    final newType = type == all ? null : type;
    // Drop a category that doesn't belong to the newly chosen type.
    final categoryType = _categories[_filter.categoryId]?.type;
    final keepCategory =
        newType == null || categoryType == null || categoryType == newType;
    _setFilter(
      _filter.copyWith(
        type: () => newType,
        categoryId: keepCategory ? null : () => null,
      ),
    );
  }

  Map<String, Category> _categories = const {};

  String? _categoryName(String? id) =>
      id == null ? null : _categories[id]?.name;

  Future<void> _chooseCategory() async {
    const all = '';
    final options =
        _categories.values
            .where((c) => _filter.type == null || c.type == _filter.type)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    final id = await _choose('Category', [
      (all, 'All categories'),
      for (final c in options)
        (c.id, _filter.type == null ? '${c.name} (${c.type})' : c.name),
    ], _filter.categoryId ?? all);
    if (id == null) return;
    _setFilter(_filter.copyWith(categoryId: () => id == all ? null : id));
  }

  Widget _buildFilterBar(TransactionFilter filter) {
    final dateFormat = DateFormat.MMMd();
    final periodLabel =
        filter.period == FilterPeriod.custom && filter.customRange != null
        ? '${dateFormat.format(filter.customRange!.start)} – '
              '${dateFormat.format(filter.customRange!.end)}'
        : filter.period.label;
    final typeLabel = switch (filter.type) {
      'expense' => 'Expense',
      'income' => 'Income',
      _ => 'All types',
    };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search description or category',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: filter.query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _setFilter(_filter.copyWith(query: ''));
                      },
                    ),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (value) => _setFilter(_filter.copyWith(query: value)),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _FilterChipButton(
                icon: Icons.date_range,
                label: periodLabel,
                selected: filter.period != FilterPeriod.all,
                onPressed: _choosePeriod,
              ),
              const SizedBox(width: 8),
              _FilterChipButton(
                icon: Icons.swap_vert,
                label: typeLabel,
                selected: filter.type != null,
                onPressed: _chooseType,
              ),
              const SizedBox(width: 8),
              _FilterChipButton(
                icon: Icons.category,
                label: _categoryName(filter.categoryId) ?? 'All categories',
                selected: filter.categoryId != null,
                onPressed: _chooseCategory,
              ),
              if (filter.isActive) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsyncValue = ref.watch(transactionWithCategoryProvider);
    final filter = ref.watch(transactionFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: transactionsAsyncValue.when(
        data: (data) {
          final (transactions, categoryMap) = data;
          _categories = categoryMap;

          if (transactions.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.receipt_long,
              title: 'No Transactions',
              message: 'You haven\'t added any transactions yet.',
            );
          }

          final visible = filter.apply(transactions, categoryMap)
            ..sort((a, b) => b.date.compareTo(a.date));

          return Column(
            children: [
              _buildFilterBar(filter),
              if (filter.isActive) _buildSummary(visible),
              Expanded(
                child: visible.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const EmptyStateWidget(
                              icon: Icons.search_off,
                              title: 'No matching transactions',
                              message: 'Try a different search or filter.',
                            ),
                            TextButton(
                              onPressed: _clearFilters,
                              child: const Text('Clear filters'),
                            ),
                          ],
                        ),
                      )
                    : _buildList(visible, categoryMap),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildSummary(List<Transaction> visible) {
    var income = 0.0;
    var expense = 0.0;
    for (final t in visible) {
      if (t.type == 'income') {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          Text('${visible.length} found'),
          const Spacer(),
          Text(
            '+${income.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.green),
          ),
          const SizedBox(width: 12),
          Text(
            '-${expense.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    List<Transaction> visible,
    Map<String, Category> categoryMap,
  ) {
    final groupedTransactions = <DateTime, List<Transaction>>{};
    final dailyTotals = <DateTime, double>{};

    for (var tx in visible) {
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
      onRefresh: () => ref.refresh(transactionNotifierProvider.future),
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
                // Captured up front: the undo callback can fire after
                // this screen (and its ref) has been disposed.
                final notifier = ref.read(transactionNotifierProvider.notifier);
                final messenger = ScaffoldMessenger.of(context);

                notifier
                    .deleteTransaction(deletedTransaction.id)
                    .then(
                      (_) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: const Text('Transaction deleted'),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () {
                                notifier
                                    .addTransaction(deletedTransaction)
                                    .catchError((Object e) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to restore transaction: $e',
                                          ),
                                        ),
                                      );
                                    });
                              },
                            ),
                          ),
                        );
                      },
                      onError: (Object e) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Failed to delete transaction: $e'),
                          ),
                        );
                      },
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
  }
}

class _FilterChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _FilterChipButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      avatar: Icon(icon, size: 18),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Text(label), const Icon(Icons.arrow_drop_down, size: 18)],
      ),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onPressed(),
    );
  }
}

import 'package:expense_tracker/presentation/notifiers/category_notifier.dart';
import 'package:expense_tracker/presentation/notifiers/transaction_notifier.dart';
import 'package:expense_tracker/data/backup_service.dart';
import 'package:expense_tracker/presentation/providers/backup_providers.dart';
import 'package:expense_tracker/presentation/providers/filter_providers.dart';
import 'package:expense_tracker/presentation/pages/edit_transaction_screen.dart';
import 'package:expense_tracker/presentation/pages/transaction_list_screen.dart';
import 'package:expense_tracker/presentation/providers/transaction_providers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/presentation/pages/category_list_page.dart';
import 'package:expense_tracker/presentation/widgets/balance_summary_card.dart';
import 'package:expense_tracker/presentation/widgets/quick_stats_card.dart';
import 'package:expense_tracker/presentation/widgets/transaction_list_item.dart';

import 'add_transaction_screen.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    DashboardPage(),
    TransactionListScreen(),
    CategoryListPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all transactions?'),
        content: const Text(
          'This permanently deletes every transaction. Categories are kept. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(transactionNotifierProvider.notifier)
          .deleteAllTransactions();
      messenger.showSnackBar(
        const SnackBar(content: Text('All transactions deleted')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to delete transactions: $e')),
      );
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _backUp() async {
    try {
      final json = await ref.read(backupServiceProvider).exportJson();
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final saved = await ref
          .read(backupFilesProvider)
          .save('expense_tracker_backup_$date.json', json);
      if (saved && mounted) _showMessage('Backup saved');
    } catch (e) {
      if (mounted) _showMessage('Backup failed: $e');
    }
  }

  Future<void> _restore() async {
    final String? contents;
    try {
      contents = await ref.read(backupFilesProvider).pickText();
    } catch (e) {
      if (mounted) _showMessage('Could not open file: $e');
      return;
    }
    if (contents == null || !mounted) return;

    try {
      BackupService.parse(contents);
    } on FormatException catch (e) {
      _showMessage(e.message);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore from backup?'),
        content: const Text(
          'This replaces all current transactions and categories with the '
          'ones in the backup file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final summary = await ref
          .read(backupServiceProvider)
          .importJson(contents);
      ref.invalidate(transactionNotifierProvider);
      ref.invalidate(categoryNotifierProvider);
      if (mounted) {
        _showMessage(
          'Restored ${summary.transactions} transactions and '
          '${summary.categories} categories',
        );
      }
    } catch (e) {
      if (mounted) _showMessage('Restore failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'backup':
                  _backUp();
                case 'restore':
                  _restore();
                case 'clear':
                  _confirmClearAll();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'backup',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Back up data'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'restore',
                child: ListTile(
                  leading: Icon(Icons.upload_file),
                  title: Text('Restore from backup'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  leading: Icon(Icons.delete_sweep),
                  title: Text('Clear all transactions'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      floatingActionButton:
          _selectedIndex == 0 ||
              _selectedIndex ==
                  1 // Only show FAB on Dashboard and Transactions
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddTransactionScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categories',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: _onItemTapped,
      ),
    );
  }
}

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  static const int _recentCount = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(transactionWithCategoryProvider);
    final month = ref.watch(selectedMonthProvider);
    final nextMonth = DateTime(month.year, month.month + 1);
    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    final monthLabel = DateFormat.yMMMM().format(month);

    return dataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (data) {
        final (allTransactions, categoryMap) = data;
        final transactions = allTransactions
            .where((t) => !t.date.isBefore(month) && t.date.isBefore(nextMonth))
            .toList();

        var totalIncome = 0.0;
        var totalExpense = 0.0;
        for (final tx in transactions) {
          if (tx.type == 'income') {
            totalIncome += tx.amount;
          } else {
            totalExpense += tx.amount;
          }
        }
        final recent = [...transactions]
          ..sort((a, b) => b.date.compareTo(a.date));

        return SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Previous month',
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () =>
                          ref.read(selectedMonthProvider.notifier).previous(),
                    ),
                    SizedBox(
                      width: 170,
                      child: Text(
                        monthLabel,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Next month',
                      icon: const Icon(Icons.chevron_right),
                      // No point looking at months that haven't happened yet.
                      onPressed: isCurrentMonth
                          ? null
                          : () =>
                                ref.read(selectedMonthProvider.notifier).next(),
                    ),
                  ],
                ),
              ),
              BalanceSummaryCard(
                title: 'Balance this month',
                balance: totalIncome - totalExpense,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: QuickStatsCard(
                        title: 'Income',
                        value: totalIncome,
                        icon: Icons.arrow_upward,
                        color: Colors.green,
                      ),
                    ),
                    Expanded(
                      child: QuickStatsCard(
                        title: 'Expense',
                        value: totalExpense,
                        icon: Icons.arrow_downward,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Recent Transactions',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (recent.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No transactions this month. Tap + to add one.'),
                )
              else
                for (final tx in recent.take(_recentCount))
                  TransactionListItem(
                    transaction: tx,
                    category: categoryMap[tx.categoryId],
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => EditTransactionScreen(
                          transaction: tx,
                          category: categoryMap[tx.categoryId],
                        ),
                      ),
                    ),
                  ),
              const SizedBox(
                height: 80,
              ), // Keep the last item clear of the FAB.
            ],
          ),
        );
      },
    );
  }
}

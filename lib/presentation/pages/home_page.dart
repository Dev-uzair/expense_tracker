import 'package:expense_tracker/presentation/notifiers/category_notifier.dart';
import 'package:expense_tracker/presentation/notifiers/transaction_notifier.dart';
import 'package:expense_tracker/data/backup_service.dart';
import 'package:expense_tracker/data/csv_export.dart';
import 'package:expense_tracker/presentation/providers/backup_providers.dart';
import 'package:expense_tracker/presentation/providers/filter_providers.dart';
import 'package:expense_tracker/presentation/pages/analytics_page.dart';
import 'package:expense_tracker/presentation/pages/budgets_page.dart';
import 'package:expense_tracker/presentation/pages/category_form_screen.dart';
import 'package:expense_tracker/presentation/pages/settings_page.dart';
import 'package:expense_tracker/presentation/pages/transaction_form_screen.dart';
import 'package:expense_tracker/presentation/pages/transaction_list_screen.dart';
import 'package:expense_tracker/presentation/providers/transaction_providers.dart';
import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/domain/transaction.dart';
import 'package:expense_tracker/presentation/budgets/budget_data.dart';
import 'package:expense_tracker/presentation/notifiers/budget_notifier.dart';
import 'package:expense_tracker/presentation/settings/settings_providers.dart';
import 'package:expense_tracker/presentation/widgets/budget_meter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/presentation/pages/category_list_page.dart';
import 'package:expense_tracker/presentation/widgets/balance_summary_card.dart';
import 'package:expense_tracker/presentation/widgets/month_selector.dart';
import 'package:expense_tracker/presentation/widgets/quick_stats_card.dart';
import 'package:expense_tracker/presentation/widgets/transaction_list_item.dart';

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
    AnalyticsPage(),
    CategoryListPage(),
  ];

  static const List<String> _titles = [
    'Expense Tracker',
    'Transactions',
    'Analytics',
    'Categories',
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

  Future<void> _exportCsv() async {
    final data = ref.read(transactionWithCategoryProvider).value;
    if (data == null || data.$1.isEmpty) {
      _showMessage('No transactions to export');
      return;
    }
    final (all, categories) = data;
    var transactions = all;

    // Offer the Transactions tab's current filter as an option.
    final filter = ref.read(transactionFilterProvider);
    if (filter.isActive) {
      final filtered = filter.apply(all, categories);
      final choice = await showDialog<List<Transaction>>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Export which transactions?'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(all),
              child: Text('All transactions (${all.length})'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(filtered),
              child: Text(
                'Only the filtered transactions (${filtered.length})',
              ),
            ),
          ],
        ),
      );
      if (choice == null || !mounted) return;
      transactions = choice;
    }

    try {
      final csv = transactionsToCsv(
        transactions,
        categories,
        currencyCode: ref.read(settingsProvider).currency.code,
      );
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final saved = await ref
          .read(backupFilesProvider)
          .save(
            'expense_tracker_transactions_$date.csv',
            csv,
            mimeType: 'text/csv',
          );
      if (saved && mounted) {
        _showMessage('Exported ${transactions.length} transactions');
      }
    } catch (e) {
      if (mounted) _showMessage('Export failed: $e');
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
          'This replaces all current transactions, categories and budgets '
          'with the ones in the backup file.',
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
      ref.invalidate(budgetNotifierProvider);
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
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'budgets':
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BudgetsPage()),
                  );
                case 'settings':
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
                case 'export':
                  _exportCsv();
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
                value: 'budgets',
                child: ListTile(
                  leading: Icon(Icons.savings_outlined),
                  title: Text('Budgets'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.table_view_outlined),
                  title: Text('Export to CSV'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
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
      // Dashboard/Transactions add a transaction, Categories adds a
      // category; Analytics has no add action.
      floatingActionButton: switch (_selectedIndex) {
        0 || 1 => FloatingActionButton(
          tooltip: 'Add transaction',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const TransactionFormScreen(),
            ),
          ),
          child: const Icon(Icons.add),
        ),
        3 => FloatingActionButton(
          tooltip: 'Add category',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CategoryFormScreen()),
          ),
          child: const Icon(Icons.add),
        ),
        _ => null,
      },
      bottomNavigationBar: BottomNavigationBar(
        // Four items would otherwise switch to the "shifting" style.
        type: BottomNavigationBarType.fixed,
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
            icon: Icon(Icons.bar_chart),
            label: 'Analytics',
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
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: MonthSelector(),
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
              _DashboardBudgets(
                transactions: allTransactions,
                categories: categoryMap,
                month: month,
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
                        builder: (context) => TransactionFormScreen(
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

// This month's budgets on the dashboard, or a prompt to create one.
class _DashboardBudgets extends ConsumerWidget {
  final List<Transaction> transactions;
  final Map<String, Category> categories;
  final DateTime month;

  const _DashboardBudgets({
    required this.transactions,
    required this.categories,
    required this.month,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetNotifierProvider).value ?? const [];
    final statuses = budgetStatuses(budgets, transactions, categories, month);
    void openBudgets() => Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BudgetsPage()));

    if (statuses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextButton.icon(
          onPressed: openBudgets,
          icon: const Icon(Icons.savings_outlined),
          label: const Text('Set a monthly budget'),
        ),
      );
    }
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 4, 0),
              child: Row(
                children: [
                  Text(
                    'Budgets',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: openBudgets,
                    child: const Text('Manage'),
                  ),
                ],
              ),
            ),
            for (final s in statuses) BudgetMeter(status: s),
          ],
        ),
      ),
    );
  }
}

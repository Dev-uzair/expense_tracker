import 'package:expense_tracker/presentation/notifiers/transaction_notifier.dart';
import 'package:expense_tracker/presentation/pages/edit_transaction_screen.dart';
import 'package:expense_tracker/presentation/pages/transaction_list_screen.dart';
import 'package:expense_tracker/presentation/providers/transaction_providers.dart';
import 'package:flutter/material.dart';
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
            'This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(transactionNotifierProvider.notifier).deleteAllTransactions();
      messenger.showSnackBar(
        const SnackBar(content: Text('All transactions deleted')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to delete transactions: $e')),
      );
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
              if (value == 'clear') _confirmClearAll();
            },
            itemBuilder: (context) => const [
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
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      floatingActionButton: _selectedIndex == 0 || _selectedIndex == 1 // Only show FAB on Dashboard and Transactions
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

    return dataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (data) {
        final (transactions, categoryMap) = data;

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
              BalanceSummaryCard(balance: totalIncome - totalExpense),
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
                  child: Text('No transactions yet. Tap + to add one.'),
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
              const SizedBox(height: 80), // Keep the last item clear of the FAB.
            ],
          ),
        );
      },
    );
  }
}

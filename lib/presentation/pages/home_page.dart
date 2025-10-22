import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/presentation/pages/category_list_page.dart';
import 'package:expense_tracker/presentation/widgets/balance_summary_card.dart';
import 'package:expense_tracker/presentation/widgets/quick_stats_card.dart';

import 'add_transaction_screen.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    DashboardPage(), // Changed to DashboardPage
    CategoryListPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      floatingActionButton: _selectedIndex == 0 // Only show FAB on Dashboard
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

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder values for now
    final double totalBalance = 1250.50;
    final double totalIncome = 2500.00;
    final double totalExpense = 1249.50;

    return SingleChildScrollView(
      child: Column(
        children: [
          BalanceSummaryCard(balance: totalBalance),
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
          // TODO: Add recent transactions list here
          const SizedBox(height: 20),
          Text(
            'Recent Transactions',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          // Placeholder for recent transactions
          Container(
            height: 200,
            margin: const EdgeInsets.all(16.0),
            color: Colors.grey[200],
            child: const Center(
              child: Text('List of recent transactions will go here.'),
            ),
          ),
        ],
      ),
    );
  }
}
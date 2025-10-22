import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/presentation/widgets/category_selector.dart';
import 'package:expense_tracker/domain/category.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _amountController = TextEditingController();
  String _transactionType = 'expense'; // 'expense' or 'income'
  Category? _selectedCategory;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onCategorySelected(Category category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Input Field
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Transaction Type Toggle
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Expense'),
                    value: 'expense',
                    groupValue: _transactionType,
                    onChanged: (value) {
                      setState(() {
                        _transactionType = value!;
                        _selectedCategory = null; // Reset selected category
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Income'),
                    value: 'income',
                    groupValue: _transactionType,
                    onChanged: (value) {
                      setState(() {
                        _transactionType = value!;
                        _selectedCategory = null; // Reset selected category
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Category Selector
            Text(
              'Select Category',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: CategorySelector(
                selectedTransactionType: _transactionType,
                onCategorySelected: _onCategorySelected,
                selectedCategory: _selectedCategory,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
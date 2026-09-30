import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/domain/transaction.dart';
import 'package:expense_tracker/presentation/notifiers/transaction_notifier.dart';
import 'package:expense_tracker/presentation/settings/settings_providers.dart';
import 'package:expense_tracker/presentation/widgets/category_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

const List<String> paymentMethods = [
  'Cash',
  'Credit Card',
  'Debit Card',
  'Bank Transfer',
  'Other',
];

const int maxDescriptionLength = 200;

// Returns an error message, or null if [value] is a valid amount: a positive
// number with at most two decimal places.
String? validateAmount(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Please enter an amount';
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text)) {
    return 'Enter a number with at most 2 decimal places';
  }
  final amount = double.parse(text);
  if (amount <= 0) return 'Amount must be greater than 0';
  return null;
}

// 12.0 -> "12", 12.5 -> "12.5", 12.25 -> "12.25".
String formatAmountForInput(double amount) {
  final fixed = amount.toStringAsFixed(2);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}

// Adds a transaction, or edits [transaction] when one is given.
class TransactionFormScreen extends ConsumerStatefulWidget {
  final Transaction? transaction;
  final Category? category;

  const TransactionFormScreen({super.key, this.transaction, this.category});

  bool get isEditing => transaction != null;

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late String _transactionType;
  Category? _selectedCategory;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String? _selectedPaymentMethod;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    final now = DateTime.now();
    _amountController = TextEditingController(
      text: t == null ? '' : formatAmountForInput(t.amount),
    );
    _descriptionController = TextEditingController(text: t?.description);
    _transactionType = t?.type ?? 'expense';
    _selectedCategory = widget.category;
    _selectedDate = t?.date ?? now;
    _selectedTime = TimeOfDay.fromDateTime(t?.date ?? now);
    // Ignore a stored method that is no longer offered.
    _selectedPaymentMethod = paymentMethods.contains(t?.paymentMethod)
        ? t!.paymentMethod
        : null;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showMessage('Please select a category');
      return;
    }

    final date = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    final amount = double.parse(_amountController.text.trim());
    final description = _descriptionController.text.trim();
    final notifier = ref.read(transactionNotifierProvider.notifier);

    setState(() => _saving = true);
    try {
      if (widget.transaction case final existing?) {
        await notifier.updateTransaction(
          existing.copyWith(
            amount: amount,
            categoryId: _selectedCategory!.id,
            type: _transactionType,
            date: date,
            description: () => description.isEmpty ? null : description,
            paymentMethod: () => _selectedPaymentMethod,
          ),
        );
      } else {
        await notifier.addTransaction(
          Transaction(
            id: const Uuid().v4(),
            amount: amount,
            categoryId: _selectedCategory!.id,
            type: _transactionType,
            date: date,
            description: description.isEmpty ? null : description,
            paymentMethod: _selectedPaymentMethod,
          ),
        );
      }
      if (!mounted) return;
      _showMessage(
        widget.isEditing
            ? 'Transaction updated successfully!'
            : 'Transaction added successfully!',
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(
        widget.isEditing
            ? 'Failed to update transaction: $e'
            : 'Failed to add transaction: $e',
      );
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this transaction?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(transactionNotifierProvider.notifier)
          .deleteTransaction(widget.transaction!.id);
      if (!mounted) return;
      _showMessage('Transaction deleted successfully!');
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) _showMessage('Failed to delete transaction: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Transaction' : 'Add Transaction'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (widget.isEditing)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                // Digits with an optional dot and up to two decimals.
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: ref.watch(moneyFormatProvider).currencySymbol,
                border: const OutlineInputBorder(),
              ),
              validator: validateAmount,
            ),
            const SizedBox(height: 20),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'expense',
                  label: Text('Expense'),
                  icon: Icon(Icons.arrow_downward),
                ),
                ButtonSegment(
                  value: 'income',
                  label: Text('Income'),
                  icon: Icon(Icons.arrow_upward),
                ),
              ],
              selected: {_transactionType},
              onSelectionChanged: (selection) => setState(() {
                _transactionType = selection.first;
                // Categories are per type.
                _selectedCategory = null;
              }),
            ),
            const SizedBox(height: 20),
            CategorySelector(
              selectedCategory: _selectedCategory,
              onCategorySelected: (c) => setState(() => _selectedCategory = c),
              selectedTransactionType: _transactionType,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              DateFormat('yyyy-MM-dd').format(_selectedDate),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: _selectTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Time',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              _selectedTime.format(context),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.access_time),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _descriptionController,
              maxLength: maxDescriptionLength,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _selectedPaymentMethod,
              decoration: const InputDecoration(
                labelText: 'Payment Method (Optional)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Not set')),
                for (final method in paymentMethods)
                  DropdownMenuItem(value: method, child: Text(method)),
              ],
              onChanged: (value) =>
                  setState(() => _selectedPaymentMethod = value),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Transaction'),
            ),
          ],
        ),
      ),
    );
  }
}

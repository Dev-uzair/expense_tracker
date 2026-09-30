import 'package:expense_tracker/domain/budget.dart';
import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/presentation/budgets/budget_data.dart';
import 'package:expense_tracker/presentation/notifiers/budget_notifier.dart';
import 'package:expense_tracker/presentation/notifiers/category_notifier.dart';
import 'package:expense_tracker/presentation/pages/transaction_form_screen.dart';
import 'package:expense_tracker/presentation/providers/filter_providers.dart';
import 'package:expense_tracker/presentation/providers/transaction_providers.dart';
import 'package:expense_tracker/presentation/settings/settings_providers.dart';
import 'package:expense_tracker/presentation/widgets/budget_meter.dart';
import 'package:expense_tracker/presentation/widgets/month_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, [Budget? budget]) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BudgetFormSheet(budget: budget),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetNotifierProvider);
    final dataAsync = ref.watch(transactionWithCategoryProvider);
    final month = ref.watch(selectedMonthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add budget',
        onPressed: () => _edit(context, ref),
        child: const Icon(Icons.add),
      ),
      body: switch ((budgetsAsync, dataAsync)) {
        (AsyncData(value: final budgets), AsyncData(value: final data)) => () {
          final (transactions, categories) = data;
          final statuses = budgetStatuses(
            budgets,
            transactions,
            categories,
            month,
          );
          return ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: MonthSelector(),
              ),
              if (statuses.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No budgets yet. Tap + to set a monthly limit for a '
                    'category or for all expenses.',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                for (final s in statuses)
                  BudgetMeter(
                    status: s,
                    onTap: () => _edit(context, ref, s.budget),
                  ),
            ],
          );
        }(),
        (AsyncError(:final error), _) ||
        (_, AsyncError(:final error)) => Center(child: Text('Error: $error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

// Adds a budget, or edits/deletes [budget].
class BudgetFormSheet extends ConsumerStatefulWidget {
  final Budget? budget;

  const BudgetFormSheet({super.key, this.budget});

  @override
  ConsumerState<BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends ConsumerState<BudgetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController = TextEditingController(
    text: widget.budget == null
        ? ''
        : formatAmountForInput(widget.budget!.amount),
  );
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.budget?.categoryId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountController.text.trim());
    final budget =
        widget.budget?.copyWith(amount: amount, categoryId: _categoryId) ??
        Budget(id: const Uuid().v4(), amount: amount, categoryId: _categoryId!);
    await ref.read(budgetNotifierProvider.notifier).saveBudget(budget);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await ref
        .read(budgetNotifierProvider.notifier)
        .deleteBudget(widget.budget!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final budgets = ref.watch(budgetNotifierProvider).value ?? const [];
    final categories =
        (ref.watch(categoryNotifierProvider).value ?? const [])
            .where((c) => c.type == 'expense')
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    // One budget per category: offer only those without one. The selected
    // category always stays listed; right after saving, the new budget is in
    // [budgets] while this sheet is still closing.
    final taken = {
      for (final b in budgets)
        if (b.id != widget.budget?.id && b.categoryId != _categoryId)
          b.categoryId,
    };
    final options = <(String, String)>[
      if (!taken.contains(Budget.overallCategoryId))
        (Budget.overallCategoryId, 'All expenses'),
      for (final Category c in categories)
        if (!taken.contains(c.id)) (c.id, c.name),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.budget == null ? 'New monthly budget' : 'Edit budget',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (options.isEmpty)
              const Text('Every expense category already has a budget.')
            else ...[
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final (id, name) in options)
                    DropdownMenuItem(value: id, child: Text(name)),
                ],
                onChanged: (id) => setState(() => _categoryId = id),
                validator: (id) => id == null ? 'Choose a category' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Monthly limit',
                  prefixText: ref.watch(moneyFormatProvider).currencySymbol,
                  border: const OutlineInputBorder(),
                ),
                validator: validateAmount,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (widget.budget != null)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _save,
                    child: const Text('Save budget'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

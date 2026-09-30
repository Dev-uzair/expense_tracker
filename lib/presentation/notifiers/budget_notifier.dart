import 'package:expense_tracker/domain/budget.dart';
import 'package:expense_tracker/presentation/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BudgetNotifier extends AsyncNotifier<List<Budget>> {
  @override
  Future<List<Budget>> build() async {
    return ref.watch(budgetRepositoryProvider).getAllBudgets();
  }

  Future<void> _reload() async {
    state = AsyncData(await ref.read(budgetRepositoryProvider).getAllBudgets());
  }

  // Adds [budget], or replaces the one with the same id.
  Future<void> saveBudget(Budget budget) async {
    await ref.read(budgetRepositoryProvider).updateBudget(budget);
    await _reload();
  }

  Future<void> deleteBudget(String id) async {
    await ref.read(budgetRepositoryProvider).deleteBudget(id);
    await _reload();
  }

  // Removes budgets for a category that is being deleted.
  Future<void> deleteBudgetsForCategory(String categoryId) async {
    final repository = ref.read(budgetRepositoryProvider);
    for (final b in await repository.getAllBudgets()) {
      if (b.categoryId == categoryId) await repository.deleteBudget(b.id);
    }
    await _reload();
  }
}

final budgetNotifierProvider =
    AsyncNotifierProvider<BudgetNotifier, List<Budget>>(BudgetNotifier.new);

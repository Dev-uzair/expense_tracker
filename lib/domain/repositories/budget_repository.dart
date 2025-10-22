import 'package:expense_tracker/domain/budget.dart';

abstract class BudgetRepository {
  Future<void> addBudget(Budget budget);
  Future<void> updateBudget(Budget budget);
  Future<void> deleteBudget(String id);
  Future<Budget?> getBudget(String id);
  Future<List<Budget>> getAllBudgets();
}

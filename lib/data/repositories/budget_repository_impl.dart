import 'package:expense_tracker/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/domain/budget.dart';
import 'package:expense_tracker/data/hive_database.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final HiveDatabase _hiveDatabase;

  BudgetRepositoryImpl(this._hiveDatabase);

  @override
  Future<void> addBudget(Budget budget) {
    return _hiveDatabase.addBudget(budget);
  }

  @override
  Future<void> deleteBudget(String id) {
    return _hiveDatabase.deleteBudget(id);
  }

  @override
  Future<List<Budget>> getAllBudgets() {
    return Future.value(_hiveDatabase.getAllBudgets());
  }

  @override
  Future<Budget?> getBudget(String id) {
    return Future.value(_hiveDatabase.getBudget(id));
  }

  @override
  Future<void> updateBudget(Budget budget) {
    return _hiveDatabase.updateBudget(budget);
  }
}

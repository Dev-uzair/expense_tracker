import 'package:hive/hive.dart';
import 'package:expense_tracker/domain/transaction.dart';
import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/domain/budget.dart';

class HiveDatabase {
  // Singleton instance
  static final HiveDatabase _instance = HiveDatabase._internal();
  factory HiveDatabase() => _instance;
  HiveDatabase._internal();

  // Box names
  static const String transactionBoxName = 'transactions';
  static const String categoryBoxName = 'categories';
  static const String budgetBoxName = 'budgets';

  // Getters for boxes
  Box<Transaction> get transactionBox => Hive.box<Transaction>(transactionBoxName);
  Box<Category> get categoryBox => Hive.box<Category>(categoryBoxName);
  Box<Budget> get budgetBox => Hive.box<Budget>(budgetBoxName);

  // CRUD operations for Transaction
  Future<void> addTransaction(Transaction transaction) async {
    await transactionBox.put(transaction.id, transaction);
  }

  Transaction? getTransaction(String id) {
    return transactionBox.get(id);
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await transactionBox.put(transaction.id, transaction);
  }

  Future<void> deleteTransaction(String id) async {
    await transactionBox.delete(id);
  }

  List<Transaction> getAllTransactions() {
    return transactionBox.values.toList();
  }

  // CRUD operations for Category
  Future<void> addCategory(Category category) async {
    await categoryBox.put(category.id, category);
  }

  Category? getCategory(String id) {
    return categoryBox.get(id);
  }

  Future<void> updateCategory(Category category) async {
    await categoryBox.put(category.id, category);
  }

  Future<void> deleteCategory(String id) async {
    await categoryBox.delete(id);
  }

  List<Category> getAllCategories() {
    return categoryBox.values.toList();
  }

  // CRUD operations for Budget
  Future<void> addBudget(Budget budget) async {
    await budgetBox.put(budget.id, budget);
  }

  Budget? getBudget(String id) {
    return budgetBox.get(id);
  }

  Future<void> updateBudget(Budget budget) async {
    await budgetBox.put(budget.id, budget);
  }

  Future<void> deleteBudget(String id) async {
    await budgetBox.delete(id);
  }

  List<Budget> getAllBudgets() {
    return budgetBox.values.toList();
  }
}

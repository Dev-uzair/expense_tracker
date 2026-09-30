// In-memory repositories and builders shared by presentation tests.
import 'dart:async';

import 'package:expense_tracker/domain/budget.dart';
import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/domain/repositories/category_repository.dart';
import 'package:expense_tracker/domain/repositories/transaction_repository.dart';
import 'package:expense_tracker/domain/transaction.dart';
import 'package:expense_tracker/presentation/providers/filter_providers.dart';

class InMemoryTransactionRepository implements TransactionRepository {
  final Map<String, Transaction> items = {};
  bool failWrites = false;
  // When set, deletes wait on it, like a real disk write that finishes after
  // the next frame.
  Completer<void>? deleteGate;

  void _check() {
    if (failWrites) throw Exception('disk full');
  }

  @override
  Future<void> addTransaction(Transaction t) async {
    _check();
    items[t.id] = t;
  }

  @override
  Future<void> updateTransaction(Transaction t) async {
    _check();
    items[t.id] = t;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await deleteGate?.future;
    _check();
    items.remove(id);
  }

  @override
  Future<void> deleteAllTransactions() async {
    _check();
    items.clear();
  }

  @override
  Future<Transaction?> getTransaction(String id) async => items[id];

  @override
  Future<List<Transaction>> getAllTransactions() async => items.values.toList();
}

class InMemoryCategoryRepository implements CategoryRepository {
  final Map<String, Category> items = {};

  @override
  Future<void> addCategory(Category c) async => items[c.id] = c;

  @override
  Future<void> updateCategory(Category c) async => items[c.id] = c;

  @override
  Future<void> deleteCategory(String id) async => items.remove(id);

  @override
  Future<void> deleteAllCategories() async => items.clear();

  @override
  Future<Category?> getCategory(String id) async => items[id];

  @override
  Future<List<Category>> getAllCategories() async => items.values.toList();
}

Transaction makeTransaction(
  String id, {
  String? description,
  double amount = 10,
  String type = 'expense',
  DateTime? date,
}) => Transaction(
  id: id,
  amount: amount,
  categoryId: 'c1',
  type: type,
  date: date ?? DateTime(2026, 9, 1, 12),
  description: description,
  paymentMethod: 'Cash',
);

// Pins the dashboard month so tests don't depend on today's date.
class FixedMonthNotifier extends SelectedMonthNotifier {
  final DateTime month;

  FixedMonthNotifier(this.month);

  @override
  DateTime build() => month;
}

class InMemoryBudgetRepository implements BudgetRepository {
  final Map<String, Budget> items = {};

  @override
  Future<void> addBudget(Budget b) async => items[b.id] = b;

  @override
  Future<void> updateBudget(Budget b) async => items[b.id] = b;

  @override
  Future<void> deleteBudget(String id) async => items.remove(id);

  @override
  Future<void> deleteAllBudgets() async => items.clear();

  @override
  Future<Budget?> getBudget(String id) async => items[id];

  @override
  Future<List<Budget>> getAllBudgets() async => items.values.toList();
}

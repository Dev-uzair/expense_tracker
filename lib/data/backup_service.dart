import 'dart:convert';

import 'package:expense_tracker/domain/budget.dart';
import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/domain/repositories/category_repository.dart';
import 'package:expense_tracker/domain/repositories/transaction_repository.dart';
import 'package:expense_tracker/domain/transaction.dart';

class BackupSummary {
  final int categories;
  final int transactions;

  const BackupSummary({required this.categories, required this.transactions});
}

// Serialises all categories and transactions to a JSON backup, and restores
// one by replacing the current data.
class BackupService {
  static const String appId = 'expense_tracker';
  // 2 added budgets; version 1 files (without them) still restore.
  static const int formatVersion = 2;

  final TransactionRepository _transactions;
  final CategoryRepository _categories;
  final BudgetRepository _budgets;

  BackupService(this._transactions, this._categories, this._budgets);

  Future<String> exportJson({DateTime? now}) async {
    final categories = await _categories.getAllCategories();
    final transactions = await _transactions.getAllTransactions();
    final budgets = await _budgets.getAllBudgets();
    return const JsonEncoder.withIndent('  ').convert({
      'app': appId,
      'version': formatVersion,
      'exportedAt': (now ?? DateTime.now()).toIso8601String(),
      'categories': [for (final c in categories) c.toJson()],
      'transactions': [for (final t in transactions) t.toJson()],
      'budgets': [for (final b in budgets) b.toJson()],
    });
  }

  // The whole file is parsed and validated before anything is deleted, so an
  // invalid file leaves the current data untouched.
  Future<BackupSummary> importJson(String source) async {
    final (categories, transactions, budgets) = parse(source);

    await _transactions.deleteAllTransactions();
    await _categories.deleteAllCategories();
    await _budgets.deleteAllBudgets();
    for (final c in categories) {
      await _categories.addCategory(c);
    }
    for (final t in transactions) {
      await _transactions.addTransaction(t);
    }
    for (final b in budgets) {
      await _budgets.addBudget(b);
    }
    return BackupSummary(
      categories: categories.length,
      transactions: transactions.length,
    );
  }

  static (List<Category>, List<Transaction>, List<Budget>) parse(
    String source,
  ) {
    try {
      final data = jsonDecode(source);
      if (data is! Map<String, dynamic> || data['app'] != appId) {
        throw const FormatException('not an Expense Tracker backup');
      }
      final version = data['version'];
      if (version is! int || version > formatVersion) {
        throw const FormatException('backup is from a newer app version');
      }
      final categories = [
        for (final c in data['categories'] as List)
          Category.fromJson(c as Map<String, dynamic>),
      ];
      final transactions = [
        for (final t in data['transactions'] as List)
          Transaction.fromJson(t as Map<String, dynamic>),
      ];
      final budgets = [
        for (final b in (data['budgets'] as List?) ?? const [])
          Budget.fromJson(b as Map<String, dynamic>),
      ];
      return (categories, transactions, budgets);
    } on FormatException catch (e) {
      throw FormatException('Invalid backup file: ${e.message}');
    } catch (_) {
      // Missing fields or wrong types surface as TypeErrors from the casts.
      throw const FormatException('Invalid backup file: unexpected contents');
    }
  }
}

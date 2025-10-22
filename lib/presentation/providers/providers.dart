import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/data/hive_database.dart';
import 'package:expense_tracker/data/repositories/transaction_repository_impl.dart';
import 'package:expense_tracker/domain/repositories/transaction_repository.dart';
import 'package:expense_tracker/data/repositories/category_repository_impl.dart';
import 'package:expense_tracker/domain/repositories/category_repository.dart';
import 'package:expense_tracker/data/repositories/budget_repository_impl.dart';
import 'package:expense_tracker/domain/repositories/budget_repository.dart';

// HiveDatabase provider
final hiveDatabaseProvider = Provider<HiveDatabase>((ref) {
  return HiveDatabase();
});

// TransactionRepository provider
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final hiveDatabase = ref.watch(hiveDatabaseProvider);
  return TransactionRepositoryImpl(hiveDatabase);
});

// CategoryRepository provider
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final hiveDatabase = ref.watch(hiveDatabaseProvider);
  return CategoryRepositoryImpl(hiveDatabase);
});

// BudgetRepository provider
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final hiveDatabase = ref.watch(hiveDatabaseProvider);
  return BudgetRepositoryImpl(hiveDatabase);
});

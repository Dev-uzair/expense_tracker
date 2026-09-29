import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/domain/transaction.dart';
import 'package:expense_tracker/presentation/notifiers/category_notifier.dart';
import 'package:expense_tracker/presentation/notifiers/transaction_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Derived from the notifiers so the list always reflects their state; any
// transaction or category change updates it without manual invalidation.
final transactionWithCategoryProvider =
    Provider<AsyncValue<(List<Transaction>, Map<String, Category>)>>((ref) {
  final transactions = ref.watch(transactionNotifierProvider);
  final categories = ref.watch(categoryNotifierProvider);

  if (transactions.hasError) {
    return AsyncError(transactions.error!, transactions.stackTrace!);
  }
  if (categories.hasError) {
    return AsyncError(categories.error!, categories.stackTrace!);
  }
  if (!transactions.hasValue || !categories.hasValue) {
    return const AsyncLoading();
  }

  final categoryMap = {for (var c in categories.requireValue) c.id: c};
  return AsyncData((transactions.requireValue, categoryMap));
});

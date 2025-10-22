import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/domain/transaction.dart';
import 'package:expense_tracker/presentation/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final transactionWithCategoryProvider = FutureProvider<
    (List<Transaction>, Map<String, Category>)>((ref) async {
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  final categoryRepository = ref.watch(categoryRepositoryProvider);

  final transactions = await transactionRepository.getAllTransactions();
  final categories = await categoryRepository.getAllCategories();

  final categoryMap = {for (var c in categories) c.id: c};

  return (transactions, categoryMap);
});

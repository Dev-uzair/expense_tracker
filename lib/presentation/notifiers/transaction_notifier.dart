import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/domain/repositories/transaction_repository.dart';
import 'package:expense_tracker/domain/transaction.dart';
import 'package:expense_tracker/presentation/providers/providers.dart';

class TransactionNotifier extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() async {
    return _getTransactions();
  }

  Future<List<Transaction>> _getTransactions() {
    final transactionRepository = ref.watch(transactionRepositoryProvider);
    return transactionRepository.getAllTransactions();
  }

  Future<void> addTransaction(Transaction transaction) async {
    final transactionRepository = ref.watch(transactionRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await transactionRepository.addTransaction(transaction);
      return _getTransactions();
    });
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final transactionRepository = ref.watch(transactionRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await transactionRepository.updateTransaction(transaction);
      return _getTransactions();
    });
  }

  Future<void> deleteTransaction(String id) async {
    final transactionRepository = ref.watch(transactionRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await transactionRepository.deleteTransaction(id);
      return _getTransactions();
    });
  }
}

final transactionNotifierProvider =
    AsyncNotifierProvider<TransactionNotifier, List<Transaction>>(
  TransactionNotifier.new,
);
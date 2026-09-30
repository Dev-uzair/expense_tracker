import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/domain/transaction.dart';
import 'package:expense_tracker/presentation/providers/providers.dart';

// Mutations let repository errors propagate so the calling screen can report
// them, and keep the current list visible instead of flashing a loading state.
class TransactionNotifier extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() async {
    return ref.watch(transactionRepositoryProvider).getAllTransactions();
  }

  Future<void> _reload() async {
    state = AsyncData(
      await ref.read(transactionRepositoryProvider).getAllTransactions(),
    );
  }

  Future<void> addTransaction(Transaction transaction) async {
    await ref.read(transactionRepositoryProvider).addTransaction(transaction);
    await _reload();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await ref
        .read(transactionRepositoryProvider)
        .updateTransaction(transaction);
    await _reload();
  }

  Future<void> deleteTransaction(String id) async {
    final previous = state;
    // Drop the item synchronously so a swiped Dismissible leaves the tree on
    // the next frame, before the database write completes.
    if (previous.hasValue) {
      state = AsyncData(
        previous.requireValue.where((t) => t.id != id).toList(),
      );
    }
    try {
      await ref.read(transactionRepositoryProvider).deleteTransaction(id);
    } catch (_) {
      state = previous;
      rethrow;
    }
    await _reload();
  }

  // Moves every transaction in category [fromId] to [toId]; used before a
  // category is deleted.
  Future<void> reassignCategory(String fromId, String toId) async {
    final repository = ref.read(transactionRepositoryProvider);
    for (final t in await repository.getAllTransactions()) {
      if (t.categoryId == fromId) {
        await repository.updateTransaction(t.copyWith(categoryId: toId));
      }
    }
    await _reload();
  }

  Future<void> deleteAllTransactions() async {
    await ref.read(transactionRepositoryProvider).deleteAllTransactions();
    await _reload();
  }
}

final transactionNotifierProvider =
    AsyncNotifierProvider<TransactionNotifier, List<Transaction>>(
      TransactionNotifier.new,
    );

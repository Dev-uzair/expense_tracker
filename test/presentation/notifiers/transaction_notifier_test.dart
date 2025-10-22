import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/domain/repositories/transaction_repository.dart';
import 'package:expense_tracker/presentation/notifiers/transaction_notifier.dart';
import 'package:expense_tracker/domain/transaction.dart';
import 'package:expense_tracker/presentation/providers/providers.dart';

// Concrete mock for TransactionRepository
class TestTransactionRepository implements TransactionRepository {
  List<Transaction> _transactions = [];

  @override
  Future<void> addTransaction(Transaction transaction) async {
    _transactions.add(transaction);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((t) => t.id == id);
  }

  @override
  Future<List<Transaction>> getAllTransactions() async {
    return _transactions;
  }

  @override
  Future<Transaction?> getTransaction(String id) async {
    return _transactions.firstWhere((t) => t.id == id);
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _transactions[index] = transaction;
    }
  }
}

void main() {
  late TestTransactionRepository testTransactionRepository;
  late ProviderContainer container;

  setUp(() {
    testTransactionRepository = TestTransactionRepository();
    container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(testTransactionRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('TransactionNotifier', () {
    final tTransaction = Transaction(
      id: '1',
      amount: 100.0,
      categoryId: '2',
      type: 'expense',
      date: DateTime.now(),
    );

    test('initial state is loading and then data', () async {
      // arrange
      testTransactionRepository._transactions = [tTransaction];
      // act
      final listener = container.listen(transactionNotifierProvider, (previous, next) {});
      // assert
      expect(listener.read(), const AsyncLoading<List<Transaction>>());
      await container.read(transactionNotifierProvider.future);
      expect(listener.read().value, [tTransaction]);
    });

    test('addTransaction calls repository and refreshes state', () async {
      // arrange
      testTransactionRepository._transactions = [];
      // act
      await container.read(transactionNotifierProvider.notifier).addTransaction(tTransaction);
      // assert
      expect(testTransactionRepository._transactions, [tTransaction]);
      expect(container.read(transactionNotifierProvider).value, [tTransaction]);
    });

    test('updateTransaction calls repository and refreshes state', () async {
      // arrange
      testTransactionRepository._transactions = [tTransaction];
      final updatedTransaction = tTransaction.copyWith(amount: 200.0); // Assuming copyWith is available
      // act
      await container.read(transactionNotifierProvider.notifier).updateTransaction(updatedTransaction);
      // assert
      expect(testTransactionRepository._transactions, [updatedTransaction]);
      expect(container.read(transactionNotifierProvider).value, [updatedTransaction]);
    });

    test('deleteTransaction calls repository and refreshes state', () async {
      // arrange
      testTransactionRepository._transactions = [tTransaction];
      // act
      await container.read(transactionNotifierProvider.notifier).deleteTransaction('1');
      // assert
      expect(testTransactionRepository._transactions, []);
      expect(container.read(transactionNotifierProvider).value, []);
    });
  });
}

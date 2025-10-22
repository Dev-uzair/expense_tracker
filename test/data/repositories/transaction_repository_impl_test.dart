import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:expense_tracker/data/hive_database.dart';
import 'package:expense_tracker/data/repositories/transaction_repository_impl.dart';
import 'package:expense_tracker/domain/transaction.dart';

import 'transaction_repository_impl_test.mocks.dart';

@GenerateMocks([HiveDatabase])
void main() {
  late MockHiveDatabase mockHiveDatabase;
  late TransactionRepositoryImpl transactionRepository;

  setUp(() {
    mockHiveDatabase = MockHiveDatabase();
    transactionRepository = TransactionRepositoryImpl(mockHiveDatabase);
  });

  group('TransactionRepositoryImpl', () {
    final tTransaction = Transaction(
      id: '1',
      amount: 100.0,
      category: 'Food',
      type: 'expense',
      date: DateTime.now(),
    );

    test('should call addTransaction on the database', () async {
      // arrange
      when(mockHiveDatabase.addTransaction(any)).thenAnswer((_) async => {});
      // act
      await transactionRepository.addTransaction(tTransaction);
      // assert
      verify(mockHiveDatabase.addTransaction(tTransaction));
      verifyNoMoreInteractions(mockHiveDatabase);
    });

    test('should call deleteTransaction on the database', () async {
      // arrange
      when(mockHiveDatabase.deleteTransaction(any)).thenAnswer((_) async => {});
      // act
      await transactionRepository.deleteTransaction('1');
      // assert
      verify(mockHiveDatabase.deleteTransaction('1'));
      verifyNoMoreInteractions(mockHiveDatabase);
    });

    test('should return a list of transactions from the database', () async {
      // arrange
      when(mockHiveDatabase.getAllTransactions()).thenReturn([tTransaction]);
      // act
      final result = await transactionRepository.getAllTransactions();
      // assert
      expect(result, [tTransaction]);
      verify(mockHiveDatabase.getAllTransactions());
      verifyNoMoreInteractions(mockHiveDatabase);
    });

    test('should return a transaction from the database', () async {
      // arrange
      when(mockHiveDatabase.getTransaction(any)).thenReturn(tTransaction);
      // act
      final result = await transactionRepository.getTransaction('1');
      // assert
      expect(result, tTransaction);
      verify(mockHiveDatabase.getTransaction('1'));
      verifyNoMoreInteractions(mockHiveDatabase);
    });

    test('should call updateTransaction on the database', () async {
      // arrange
      when(mockHiveDatabase.updateTransaction(any)).thenAnswer((_) async => {});
      // act
      await transactionRepository.updateTransaction(tTransaction);
      // assert
      verify(mockHiveDatabase.updateTransaction(tTransaction));
      verifyNoMoreInteractions(mockHiveDatabase);
    });
  });
}

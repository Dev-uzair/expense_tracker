import 'package:expense_tracker/domain/transaction.dart';

abstract class TransactionRepository {
  Future<void> addTransaction(Transaction transaction);
  Future<void> updateTransaction(Transaction transaction);
  Future<void> deleteTransaction(String id);
  Future<Transaction?> getTransaction(String id);
  Future<List<Transaction>> getAllTransactions();
}

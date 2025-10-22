import 'package:expense_tracker/domain/repositories/transaction_repository.dart';
import 'package:expense_tracker/domain/transaction.dart';
import 'package:expense_tracker/data/hive_database.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final HiveDatabase _hiveDatabase;

  TransactionRepositoryImpl(this._hiveDatabase);

  @override
  Future<void> addTransaction(Transaction transaction) {
    return _hiveDatabase.addTransaction(transaction);
  }

  @override
  Future<void> deleteTransaction(String id) {
    return _hiveDatabase.deleteTransaction(id);
  }

  @override
  Future<List<Transaction>> getAllTransactions() {
    return Future.value(_hiveDatabase.getAllTransactions());
  }

  @override
  Future<Transaction?> getTransaction(String id) {
    return Future.value(_hiveDatabase.getTransaction(id));
  }

  @override
  Future<void> updateTransaction(Transaction transaction) {
    return _hiveDatabase.updateTransaction(transaction);
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:expense_tracker/data/repositories/budget_repository_impl.dart';
import 'package:expense_tracker/domain/budget.dart';
import 'transaction_repository_impl_test.mocks.dart';

void main() {
  late MockHiveDatabase mockHiveDatabase;
  late BudgetRepositoryImpl budgetRepository;

  setUp(() {
    mockHiveDatabase = MockHiveDatabase();
    budgetRepository = BudgetRepositoryImpl(mockHiveDatabase);
  });

  group('BudgetRepositoryImpl', () {
    final tBudget = Budget(
      id: '1',
      amount: 500.0,
      category: 'Food',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
    );

    test('should call addBudget on the database', () async {
      // arrange
      when(mockHiveDatabase.addBudget(any)).thenAnswer((_) async => {});
      // act
      await budgetRepository.addBudget(tBudget);
      // assert
      verify(mockHiveDatabase.addBudget(tBudget));
      verifyNoMoreInteractions(mockHiveDatabase);
    });

    test('should call deleteBudget on the database', () async {
      // arrange
      when(mockHiveDatabase.deleteBudget(any)).thenAnswer((_) async => {});
      // act
      await budgetRepository.deleteBudget('1');
      // assert
      verify(mockHiveDatabase.deleteBudget('1'));
      verifyNoMoreInteractions(mockHiveDatabase);
    });

    test('should return a list of budgets from the database', () async {
      // arrange
      when(mockHiveDatabase.getAllBudgets()).thenReturn([tBudget]);
      // act
      final result = await budgetRepository.getAllBudgets();
      // assert
      expect(result, [tBudget]);
      verify(mockHiveDatabase.getAllBudgets());
      verifyNoMoreInteractions(mockHiveDatabase);
    });

    test('should return a budget from the database', () async {
      // arrange
      when(mockHiveDatabase.getBudget(any)).thenReturn(tBudget);
      // act
      final result = await budgetRepository.getBudget('1');
      // assert
      expect(result, tBudget);
      verify(mockHiveDatabase.getBudget('1'));
      verifyNoMoreInteractions(mockHiveDatabase);
    });

    test('should call updateBudget on the database', () async {
      // arrange
      when(mockHiveDatabase.updateBudget(any)).thenAnswer((_) async => {});
      // act
      await budgetRepository.updateBudget(tBudget);
      // assert
      verify(mockHiveDatabase.updateBudget(tBudget));
      verifyNoMoreInteractions(mockHiveDatabase);
    });
  });
}

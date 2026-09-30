import 'dart:convert';

import 'package:expense_tracker/data/backup_service.dart';
import 'package:expense_tracker/domain/budget.dart';
import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/domain/transaction.dart';
import 'package:expense_tracker/presentation/budgets/budget_data.dart';
import 'package:expense_tracker/presentation/pages/budgets_page.dart';
import 'package:expense_tracker/presentation/pages/home_page.dart';
import 'package:expense_tracker/presentation/providers/filter_providers.dart';
import 'package:expense_tracker/presentation/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_repositories.dart';

Transaction tx(
  String id,
  double amount,
  String categoryId, {
  DateTime? date,
  String type = 'expense',
}) => Transaction(
  id: id,
  amount: amount,
  categoryId: categoryId,
  type: type,
  date: date ?? DateTime(2026, 9, 10),
);

void main() {
  final categories = {
    'food': Category(id: 'food', name: 'Food', type: 'expense'),
    'rent': Category(id: 'rent', name: 'Rent', type: 'expense'),
    'fun': Category(id: 'fun', name: 'Fun', type: 'expense'),
    'salary': Category(id: 'salary', name: 'Salary', type: 'income'),
  };

  group('budgetStatuses', () {
    final transactions = [
      tx('1', 70, 'food'),
      tx('2', 15, 'food'),
      tx('3', 500, 'rent'),
      tx('4', 999, 'food', date: DateTime(2026, 8, 31)), // other month
      tx('5', 3000, 'salary', type: 'income'), // not spending
    ];
    final budgets = [
      Budget(id: 'b1', amount: 100, categoryId: 'food'),
      Budget(id: 'b2', amount: 400, categoryId: 'rent'),
      Budget(id: 'b3', amount: 50, categoryId: 'fun'),
      Budget(id: 'b4', amount: 1000, categoryId: Budget.overallCategoryId),
      Budget(id: 'b5', amount: 10, categoryId: 'deleted-category'),
    ];

    test('sums only the month\'s expenses and sets levels', () {
      final result = budgetStatuses(
        budgets,
        transactions,
        categories,
        DateTime(2026, 9),
      );
      expect(result.map((s) => (s.name, s.spent, s.level)).toList(), [
        ('All expenses', 585.0, BudgetLevel.onTrack),
        ('Food', 85.0, BudgetLevel.nearLimit),
        ('Fun', 0.0, BudgetLevel.onTrack),
        ('Rent', 500.0, BudgetLevel.over),
      ]);
      final rent = result.last;
      expect(rent.remaining, -100);
      expect(rent.ratio, 1.25);
    });

    test('exactly 80% is flagged and exactly 100% is not over', () {
      BudgetLevel level(double spent) => BudgetStatus(
        budget: Budget(id: 'x', amount: 100, categoryId: 'food'),
        name: 'Food',
        icon: null,
        spent: spent,
      ).level;
      expect(level(79.99), BudgetLevel.onTrack);
      expect(level(80), BudgetLevel.nearLimit);
      expect(level(100), BudgetLevel.nearLimit);
      expect(level(100.01), BudgetLevel.over);
    });
  });

  group('screens', () {
    late InMemoryTransactionRepository txRepo;
    late InMemoryCategoryRepository catRepo;
    late InMemoryBudgetRepository budgetRepo;

    setUp(() {
      txRepo = InMemoryTransactionRepository()
        ..items['1'] = tx('1', 90, 'food');
      catRepo = InMemoryCategoryRepository()..items.addAll(categories);
      budgetRepo = InMemoryBudgetRepository();
    });

    Future<void> pump(WidgetTester tester, Widget home) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(txRepo),
            categoryRepositoryProvider.overrideWithValue(catRepo),
            budgetRepositoryProvider.overrideWithValue(budgetRepo),
            selectedMonthProvider.overrideWith(
              () => FixedMonthNotifier(DateTime(2026, 9)),
            ),
          ],
          child: MaterialApp(home: home),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('add a budget, then edit and delete it', (tester) async {
      await pump(tester, const BudgetsPage());
      expect(find.textContaining('No budgets yet'), findsOneWidget);

      await tester.tap(find.byTooltip('Add budget'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Food').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Monthly limit'),
        '100',
      );
      await tester.tap(find.text('Save budget'));
      await tester.pumpAndSettle();

      expect(budgetRepo.items.values.single.categoryId, 'food');
      expect(find.text(r'$90.00 / $100.00'), findsOneWidget);
      expect(find.text(r'90% used · $10.00 left'), findsOneWidget);

      // Edit: raise the limit.
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Monthly limit'),
        '200',
      );
      await tester.tap(find.text('Save budget'));
      await tester.pumpAndSettle();
      expect(budgetRepo.items.values.single.amount, 200);
      expect(find.text(r'$110.00 left'), findsOneWidget);

      // Delete.
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(budgetRepo.items, isEmpty);
    });

    testWidgets('only categories without a budget are offered', (tester) async {
      budgetRepo.items['b'] = Budget(id: 'b', amount: 50, categoryId: 'food');
      await pump(tester, const BudgetsPage());
      expect(find.text(r'Over by $40.00'), findsOneWidget);

      await tester.tap(find.byTooltip('Add budget'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Category'));
      await tester.pumpAndSettle();
      expect(find.text('All expenses'), findsWidgets);
      expect(find.text('Rent'), findsWidgets);
      expect(find.text('Salary'), findsNothing, reason: 'income category');
      // "Food" only appears on the existing meter, not in the menu.
      expect(find.text('Food'), findsOneWidget);
    });

    testWidgets('dashboard prompts to set a budget when there are none', (
      tester,
    ) async {
      await pump(tester, const HomePage());
      expect(find.text('Set a monthly budget'), findsOneWidget);
    });

    testWidgets('dashboard shows this month\'s budgets', (tester) async {
      budgetRepo.items['b'] = Budget(
        id: 'b',
        amount: 100,
        categoryId: Budget.overallCategoryId,
      );
      await pump(tester, const HomePage());
      expect(find.text('Budgets'), findsOneWidget);
      expect(find.text('All expenses'), findsOneWidget);
      expect(find.text(r'$90.00 / $100.00'), findsOneWidget);
      expect(find.text('Set a monthly budget'), findsNothing);
    });

    testWidgets('deleting a category also deletes its budget', (tester) async {
      budgetRepo.items['b'] = Budget(id: 'b', amount: 50, categoryId: 'fun');
      await pump(tester, const HomePage());
      await tester.tap(
        find.descendant(
          of: find.byType(BottomNavigationBar),
          matching: find.text('Categories'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fun'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      expect(catRepo.items.containsKey('fun'), isFalse);
      expect(budgetRepo.items, isEmpty);
    });
  });

  group('backups', () {
    test('budgets are included and restored', () async {
      final txRepo = InMemoryTransactionRepository();
      final catRepo = InMemoryCategoryRepository()..items.addAll(categories);
      final budgetRepo = InMemoryBudgetRepository()
        ..items['b'] = Budget(id: 'b', amount: 75, categoryId: 'food');
      final service = BackupService(txRepo, catRepo, budgetRepo);

      final json = await service.exportJson();
      expect(jsonDecode(json)['version'], 2);
      budgetRepo.items.clear();
      await service.importJson(json);
      expect(
        budgetRepo.items['b'],
        Budget(id: 'b', amount: 75, categoryId: 'food'),
      );
    });

    test('version 1 backups (no budgets) still restore', () async {
      final budgetRepo = InMemoryBudgetRepository()
        ..items['old'] = Budget(id: 'old', amount: 1, categoryId: 'food');
      final service = BackupService(
        InMemoryTransactionRepository(),
        InMemoryCategoryRepository(),
        budgetRepo,
      );
      await service.importJson(
        jsonEncode({
          'app': 'expense_tracker',
          'version': 1,
          'categories': [],
          'transactions': [],
        }),
      );
      expect(budgetRepo.items, isEmpty, reason: 'restore replaces budgets');
    });
  });
}

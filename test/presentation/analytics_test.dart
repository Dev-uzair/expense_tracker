import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/domain/transaction.dart';
import 'package:expense_tracker/presentation/analytics/analytics_data.dart';
import 'package:expense_tracker/presentation/pages/home_page.dart';
import 'package:expense_tracker/presentation/providers/filter_providers.dart';
import 'package:expense_tracker/presentation/providers/providers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_repositories.dart';

Transaction tx(
  String id,
  double amount,
  DateTime date, {
  String type = 'expense',
  String categoryId = 'food',
}) => Transaction(
  id: id,
  amount: amount,
  categoryId: categoryId,
  type: type,
  date: date,
);

void main() {
  final categories = {
    'food': Category(id: 'food', name: 'Food & Dining', type: 'expense'),
    'rent': Category(id: 'rent', name: 'Rent', type: 'expense'),
    'salary': Category(id: 'salary', name: 'Salary', type: 'income'),
  };
  final data = [
    tx('1', 30, DateTime(2026, 9, 2)),
    tx('2', 20, DateTime(2026, 9, 30, 23, 59)),
    tx('3', 150, DateTime(2026, 9, 1), categoryId: 'rent'),
    tx('4', 1000, DateTime(2026, 9, 1), type: 'income', categoryId: 'salary'),
    tx('5', 999, DateTime(2026, 8, 31)),
    tx('6', 5, DateTime(2026, 9, 3), categoryId: 'deleted'),
  ];

  group('spendingByCategory', () {
    test('groups the month\'s expenses, largest first, with shares', () {
      final result = spendingByCategory(data, categories, DateTime(2026, 9));
      expect(result.map((c) => (c.name, c.amount)).toList(), [
        ('Rent', 150.0),
        ('Food & Dining', 50.0),
        ('Uncategorized', 5.0),
      ]);
      expect(result.first.share, closeTo(150 / 205, 1e-9));
      expect(result.fold(0.0, (s, c) => s + c.share), closeTo(1, 1e-9));
    });

    test('is empty for a month without expenses', () {
      expect(spendingByCategory(data, categories, DateTime(2026, 7)), isEmpty);
    });
  });

  group('monthlyTotals', () {
    test('covers the last N months oldest first, including empty ones', () {
      final result = monthlyTotals(data, DateTime(2026, 9), count: 3);
      expect(result.map((m) => m.month).toList(), [
        DateTime(2026, 7),
        DateTime(2026, 8),
        DateTime(2026, 9),
      ]);
      expect(result.map((m) => (m.income, m.expense)).toList(), [
        (0.0, 0.0),
        (0.0, 999.0),
        (1000.0, 205.0),
      ]);
    });

    test('crosses year boundaries', () {
      final result = monthlyTotals(const [], DateTime(2026, 2), count: 4);
      expect(result.map((m) => m.month).toList(), [
        DateTime(2025, 11),
        DateTime(2025, 12),
        DateTime(2026, 1),
        DateTime(2026, 2),
      ]);
    });
  });

  testWidgets('Analytics tab shows the breakdown, chart and table', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    final txRepo = InMemoryTransactionRepository();
    for (final t in data) {
      txRepo.items[t.id] = t;
    }
    final catRepo = InMemoryCategoryRepository()..items.addAll(categories);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(txRepo),
          categoryRepositoryProvider.overrideWithValue(catRepo),
          selectedMonthProvider.overrideWith(
            () => FixedMonthNotifier(DateTime(2026, 9)),
          ),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Analytics'));
    await tester.pumpAndSettle();

    expect(find.text('Spending by category'), findsOneWidget);
    expect(find.text('Rent'), findsOneWidget);
    expect(find.text('150.00'), findsOneWidget);
    expect(find.text('73%'), findsOneWidget);
    expect(find.text('205.00'), findsWidgets); // total, and September's row
    expect(find.byType(BarChart), findsOneWidget);
    expect(find.text('Sep 2026'), findsOneWidget); // table row
    expect(find.text('999.00'), findsOneWidget); // August expense

    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    expect(find.text('Rent'), findsNothing);
    expect(find.text('Food & Dining'), findsOneWidget);
  });
}

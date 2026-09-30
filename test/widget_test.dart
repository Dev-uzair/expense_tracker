import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/presentation/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_repositories.dart';

// Smoke test: the whole app starts and every tab opens.
void main() {
  testWidgets('app starts and every tab opens', (tester) async {
    final catRepo = InMemoryCategoryRepository()
      ..items['c1'] = Category(id: 'c1', name: 'Food', type: 'expense');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(
            InMemoryTransactionRepository(),
          ),
          categoryRepositoryProvider.overrideWithValue(catRepo),
          budgetRepositoryProvider.overrideWithValue(InMemoryBudgetRepository()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    AppBar appBar() => tester.widget<AppBar>(find.byType(AppBar));
    String title() => (appBar().title! as Text).data!;

    expect(title(), 'Expense Tracker');
    expect(find.byType(FloatingActionButton), findsOneWidget);

    for (final tab in ['Transactions', 'Analytics', 'Categories']) {
      await tester.tap(
        find.descendant(
          of: find.byType(BottomNavigationBar),
          matching: find.text(tab),
        ),
      );
      await tester.pumpAndSettle();
      expect(title(), tab);
      // Each tab sits inside the home page's Scaffold: one app bar only.
      expect(find.byType(AppBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}

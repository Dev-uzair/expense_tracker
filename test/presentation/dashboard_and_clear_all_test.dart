import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/presentation/notifiers/transaction_notifier.dart';
import 'package:expense_tracker/presentation/pages/home_page.dart';
import 'package:expense_tracker/presentation/providers/filter_providers.dart';
import 'package:expense_tracker/presentation/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_repositories.dart';

void main() {
  late InMemoryTransactionRepository txRepo;
  late InMemoryCategoryRepository catRepo;

  setUp(() {
    txRepo = InMemoryTransactionRepository();
    catRepo = InMemoryCategoryRepository()
      ..items['c1'] = Category(
        id: 'c1',
        name: 'Food',
        type: 'expense',
        categoryIcon: 'food',
      );
  });

  Future<void> pumpHome(WidgetTester tester) async {
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
  }

  testWidgets('dashboard totals come from real transactions', (tester) async {
    txRepo.items
      ..['1'] = makeTransaction('1', amount: 1000, type: 'income')
      ..['2'] = makeTransaction('2', amount: 250.5)
      ..['3'] = makeTransaction('3', amount: 49.5);
    await pumpHome(tester);

    expect(find.text(r'$700.00'), findsOneWidget); // balance
    expect(find.text(r'$1,000.00'), findsOneWidget); // income
    expect(find.text(r'$300.00'), findsOneWidget); // expense
  });

  testWidgets('dashboard lists the newest transactions first, at most 5', (
    tester,
  ) async {
    for (var i = 1; i <= 7; i++) {
      txRepo.items['$i'] = makeTransaction(
        '$i',
        description: 'Item $i',
        date: DateTime(2026, 9, i),
      );
    }
    await pumpHome(tester);

    for (var i = 3; i <= 7; i++) {
      expect(find.text('Item $i'), findsOneWidget);
    }
    expect(find.text('Item 2'), findsNothing);
    expect(find.text('Item 1'), findsNothing);
    expect(
      tester.getTopLeft(find.text('Item 7')).dy,
      lessThan(tester.getTopLeft(find.text('Item 3')).dy),
    );
  });

  testWidgets('dashboard shows an empty message with no transactions', (
    tester,
  ) async {
    await pumpHome(tester);
    expect(find.text(r'$0.00'), findsNWidgets(3));
    expect(
      find.text('No transactions this month. Tap + to add one.'),
      findsOneWidget,
    );
  });

  testWidgets('dashboard only counts the selected month', (tester) async {
    txRepo.items
      ..['sep'] = makeTransaction(
        'sep',
        description: 'September rent',
        amount: 500,
        date: DateTime(2026, 9, 3),
      )
      ..['aug'] = makeTransaction(
        'aug',
        description: 'August rent',
        amount: 450,
        date: DateTime(2026, 8, 3),
      )
      ..['oct'] = makeTransaction(
        'oct',
        description: 'October rent',
        amount: 999,
        date: DateTime(2026, 10, 1),
      );
    await pumpHome(tester);

    expect(find.text('September 2026'), findsOneWidget);
    expect(find.text('September rent'), findsOneWidget);
    expect(find.text('August rent'), findsNothing);
    expect(find.text(r'-$500.00'), findsNWidgets(2)); // balance, recent row
    expect(find.text(r'$500.00'), findsOneWidget); // expense

    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    expect(find.text('August 2026'), findsOneWidget);
    expect(find.text('August rent'), findsOneWidget);
    expect(find.text('September rent'), findsNothing);
    expect(find.text(r'$450.00'), findsOneWidget);
  });

  testWidgets('clear all transactions asks first, then empties everything', (
    tester,
  ) async {
    txRepo.items['1'] = makeTransaction('1', description: 'Lunch');
    await pumpHome(tester);
    expect(find.text('Lunch'), findsOneWidget);

    Future<void> openClearDialog() async {
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear all transactions'));
      await tester.pumpAndSettle();
    }

    await openClearDialog();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(txRepo.items, hasLength(1));
    expect(find.text('Lunch'), findsOneWidget);

    await openClearDialog();
    await tester.tap(find.text('Delete all'));
    await tester.pumpAndSettle();
    expect(txRepo.items, isEmpty);
    expect(catRepo.items, hasLength(1), reason: 'categories are kept');
    expect(find.text('Lunch'), findsNothing);
    expect(find.text('All transactions deleted'), findsOneWidget);
  });

  testWidgets('clear all reports a failure', (tester) async {
    txRepo.items['1'] = makeTransaction('1', description: 'Lunch');
    await pumpHome(tester);
    txRepo.failWrites = true;

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear all transactions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete all'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Failed to delete transactions'),
      findsOneWidget,
    );
    expect(find.text('Lunch'), findsOneWidget);
  });

  test('deleteAllTransactions empties notifier state', () async {
    txRepo.items['1'] = makeTransaction('1');
    final container = ProviderContainer(
      overrides: [transactionRepositoryProvider.overrideWithValue(txRepo)],
    );
    addTearDown(container.dispose);
    await container.read(transactionNotifierProvider.future);

    await container
        .read(transactionNotifierProvider.notifier)
        .deleteAllTransactions();
    expect(container.read(transactionNotifierProvider).requireValue, isEmpty);
  });
}

import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/domain/transaction.dart';
import 'package:expense_tracker/presentation/pages/transaction_form_screen.dart';
import 'package:expense_tracker/presentation/providers/providers.dart';
import 'package:expense_tracker/presentation/widgets/transaction_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_repositories.dart';

void main() {
  group('validateAmount', () {
    test('accepts positive amounts with up to 2 decimals', () {
      for (final ok in ['1', '12.5', '12.50', '0.01', ' 7 ', '100000']) {
        expect(validateAmount(ok), isNull, reason: ok);
      }
    });

    test('rejects empty, zero, negative, too many decimals and junk', () {
      for (final bad in [
        '',
        '0',
        '0.00',
        '-5',
        '1.234',
        '1e5',
        'Infinity',
        'NaN',
        '1.',
        '.5',
        '1,5',
      ]) {
        expect(validateAmount(bad), isNotNull, reason: bad);
      }
    });
  });

  test('formatAmountForInput drops trailing zeros', () {
    expect(formatAmountForInput(12), '12');
    expect(formatAmountForInput(12.5), '12.5');
    expect(formatAmountForInput(12.25), '12.25');
    expect(formatAmountForInput(0.1 + 0.2), '0.3');
  });

  group('TransactionFormScreen', () {
    late InMemoryTransactionRepository txRepo;
    late InMemoryCategoryRepository catRepo;
    final food = Category(id: 'food', name: 'Food', type: 'expense');

    setUp(() {
      txRepo = InMemoryTransactionRepository();
      catRepo = InMemoryCategoryRepository()
        ..items['food'] = food
        ..items['salary'] = Category(
          id: 'salary',
          name: 'Salary',
          type: 'income',
        );
    });

    Future<void> pumpForm(WidgetTester tester, Widget form) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(txRepo),
            categoryRepositoryProvider.overrideWithValue(catRepo),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => form)),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('adds a transaction without a payment method', (tester) async {
      await pumpForm(tester, const TransactionFormScreen());
      expect(find.text('Add Transaction'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount'),
        '12.5',
      );
      await tester.tap(find.text('Food'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description (Optional)'),
        'Lunch',
      );
      await tester.tap(find.text('Save Transaction'));
      await tester.pumpAndSettle();

      final saved = txRepo.items.values.single;
      expect(saved.amount, 12.5);
      expect(saved.categoryId, 'food');
      expect(saved.type, 'expense');
      expect(saved.description, 'Lunch');
      expect(saved.paymentMethod, isNull);
      expect(find.text('Add Transaction'), findsNothing, reason: 'popped');
    });

    testWidgets('invalid amount blocks saving', (tester) async {
      await pumpForm(tester, const TransactionFormScreen());
      await tester.tap(find.text('Food'));
      await tester.tap(find.text('Save Transaction'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter an amount'), findsOneWidget);

      // The input formatter refuses a third decimal digit.
      await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '0');
      await tester.tap(find.text('Save Transaction'));
      await tester.pumpAndSettle();
      expect(find.text('Amount must be greater than 0'), findsOneWidget);
      expect(txRepo.items, isEmpty);
    });

    testWidgets('switching to income clears the expense category', (
      tester,
    ) async {
      await pumpForm(tester, const TransactionFormScreen());
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount'),
        '10',
      );
      await tester.tap(find.text('Food'));
      await tester.tap(find.text('Income'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Transaction'));
      await tester.pumpAndSettle();
      expect(find.text('Please select a category'), findsOneWidget);
      expect(txRepo.items, isEmpty);
    });

    testWidgets('edit pre-fills the form and saves changes', (tester) async {
      final existing = Transaction(
        id: '1',
        amount: 20,
        categoryId: 'food',
        type: 'expense',
        date: DateTime(2026, 9, 1, 12),
        description: 'Dinner',
        paymentMethod: 'Cash',
      );
      txRepo.items['1'] = existing;
      await pumpForm(
        tester,
        TransactionFormScreen(transaction: existing, category: food),
      );

      expect(find.text('Edit Transaction'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.text('Dinner'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description (Optional)'),
        '',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount'),
        '25.75',
      );
      await tester.tap(find.text('Save Transaction'));
      await tester.pumpAndSettle();

      final saved = txRepo.items['1']!;
      expect(saved.amount, 25.75);
      expect(saved.description, isNull);
      expect(saved.paymentMethod, 'Cash');
      expect(saved.date, existing.date);
    });

    testWidgets('edit can delete after confirmation', (tester) async {
      final existing = Transaction(
        id: '1',
        amount: 5,
        categoryId: 'food',
        type: 'expense',
        date: DateTime(2026, 9, 1),
      );
      txRepo.items['1'] = existing;
      await pumpForm(
        tester,
        TransactionFormScreen(transaction: existing, category: food),
      );

      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(txRepo.items, isEmpty);
    });
  });

  testWidgets('list item uses the category name when there is no description', (
    tester,
  ) async {
    final food = Category(id: 'food', name: 'Food', type: 'expense');
    Widget item(String? description) => MaterialApp(
      home: Material(
        child: TransactionListItem(
          transaction: Transaction(
            id: '1',
            amount: 5,
            categoryId: 'food',
            type: 'expense',
            date: DateTime(2026, 9, 1),
            description: description,
          ),
          category: food,
        ),
      ),
    );

    await tester.pumpWidget(item(null));
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('N/A'), findsNothing);

    await tester.pumpWidget(item('Lunch'));
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.textContaining('Food · '), findsOneWidget);
  });
}

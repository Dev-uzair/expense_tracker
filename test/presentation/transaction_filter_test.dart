import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/domain/transaction.dart';
import 'package:expense_tracker/presentation/pages/transaction_list_screen.dart';
import 'package:expense_tracker/presentation/providers/filter_providers.dart';
import 'package:expense_tracker/presentation/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_repositories.dart';

Transaction tx(
  String id,
  DateTime date, {
  String type = 'expense',
  String categoryId = 'food',
  String? note,
}) => Transaction(
  id: id,
  amount: 10,
  categoryId: categoryId,
  type: type,
  date: date,
  description: note,
);

void main() {
  final categories = {
    'food': Category(id: 'food', name: 'Food & Dining', type: 'expense'),
    'salary': Category(id: 'salary', name: 'Salary', type: 'income'),
  };
  // Wednesday 16 September 2026, midday.
  final now = DateTime(2026, 9, 16, 12);
  final all = [
    tx('today', DateTime(2026, 9, 16, 8), note: 'Coffee'),
    tx('monday', DateTime(2026, 9, 14, 23, 59)),
    tx('last-sunday', DateTime(2026, 9, 13, 23, 59)),
    tx('month-start', DateTime(2026, 9, 1)),
    tx('last-month', DateTime(2026, 8, 31, 23, 59)),
    tx('january', DateTime(2026, 1, 1)),
    tx('last-year', DateTime(2025, 12, 31)),
    tx(
      'pay',
      DateTime(2026, 9, 10),
      type: 'income',
      categoryId: 'salary',
      note: 'September pay',
    ),
  ];

  List<String> ids(TransactionFilter f) =>
      f.apply(all, categories, now: now).map((t) => t.id).toList();

  group('TransactionFilter.apply', () {
    test('all time keeps everything', () {
      expect(ids(const TransactionFilter()), hasLength(all.length));
    });

    test('periods', () {
      expect(ids(const TransactionFilter(period: FilterPeriod.today)), [
        'today',
      ]);
      expect(ids(const TransactionFilter(period: FilterPeriod.thisWeek)), [
        'today',
        'monday',
      ]);
      expect(ids(const TransactionFilter(period: FilterPeriod.thisMonth)), [
        'today',
        'monday',
        'last-sunday',
        'month-start',
        'pay',
      ]);
      expect(
        ids(const TransactionFilter(period: FilterPeriod.thisYear)),
        isNot(contains('last-year')),
      );
      expect(
        ids(const TransactionFilter(period: FilterPeriod.thisYear)),
        hasLength(all.length - 1),
      );
    });

    test('custom range includes both end days', () {
      final f = TransactionFilter(
        period: FilterPeriod.custom,
        customRange: DateTimeRange(
          start: DateTime(2026, 8, 31),
          end: DateTime(2026, 9, 1),
        ),
      );
      expect(ids(f), ['month-start', 'last-month']);
    });

    test('type and category', () {
      expect(ids(const TransactionFilter(type: 'income')), ['pay']);
      expect(
        ids(const TransactionFilter(categoryId: 'food')),
        hasLength(all.length - 1),
      );
    });

    test('search matches description or category name, ignoring case', () {
      expect(ids(const TransactionFilter(query: 'COFFEE')), ['today']);
      expect(ids(const TransactionFilter(query: 'salary')), ['pay']);
      expect(ids(const TransactionFilter(query: '  pay ')), ['pay']);
      expect(ids(const TransactionFilter(query: 'nothing')), isEmpty);
    });

    test('isActive and copyWith can clear fields', () {
      const f = TransactionFilter(type: 'income', categoryId: 'salary');
      expect(f.isActive, isTrue);
      final cleared = f.copyWith(type: () => null, categoryId: () => null);
      expect(cleared.type, isNull);
      expect(cleared.categoryId, isNull);
      expect(cleared.isActive, isFalse);
    });
  });

  group('Transactions screen', () {
    late InMemoryTransactionRepository txRepo;
    late InMemoryCategoryRepository catRepo;

    setUp(() {
      txRepo = InMemoryTransactionRepository();
      catRepo = InMemoryCategoryRepository()..items.addAll(categories);
      txRepo.items
        ..['1'] = tx('1', DateTime(2026, 9, 1), note: 'Lunch')
        ..['2'] = tx(
          '2',
          DateTime(2026, 9, 2),
          type: 'income',
          categoryId: 'salary',
          note: 'Pay day',
        );
    });

    Future<void> pumpList(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(txRepo),
            categoryRepositoryProvider.overrideWithValue(catRepo),
            budgetRepositoryProvider.overrideWithValue(InMemoryBudgetRepository()),
          ],
          child: const MaterialApp(home: TransactionListScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('search narrows the list and Clear filters resets it', (
      tester,
    ) async {
      await pumpList(tester);
      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('Pay day'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'lunch');
      await tester.pumpAndSettle();
      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('Pay day'), findsNothing);
      expect(find.text('1 found'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('No matching transactions'), findsOneWidget);

      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();
      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('Pay day'), findsOneWidget);
    });

    testWidgets('type chip filters to income', (tester) async {
      await pumpList(tester);
      await tester.tap(find.text('All types'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Income').last);
      await tester.pumpAndSettle();

      expect(find.text('Pay day'), findsOneWidget);
      expect(find.text('Lunch'), findsNothing);
    });

    testWidgets('category chip filters to one category', (tester) async {
      await pumpList(tester);
      await tester.tap(find.text('All categories'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Food & Dining (expense)'));
      await tester.pumpAndSettle();

      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('Pay day'), findsNothing);
      expect(find.text('Food & Dining'), findsOneWidget); // chip label
    });
  });
}

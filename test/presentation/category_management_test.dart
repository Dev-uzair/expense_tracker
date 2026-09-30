import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/presentation/pages/category_form_screen.dart';
import 'package:expense_tracker/presentation/pages/home_page.dart';
import 'package:expense_tracker/presentation/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_repositories.dart';

void main() {
  group('validateCategoryName', () {
    final existing = [
      Category(id: 'a', name: 'Food', type: 'expense'),
      Category(id: 'b', name: 'Gifts', type: 'income'),
    ];
    String? v(String name, {String type = 'expense', String? editingId}) =>
        validateCategoryName(
          name,
          type: type,
          existing: existing,
          editingId: editingId,
        );

    test('requires a name of at most 30 characters', () {
      expect(v('   '), isNotNull);
      expect(v('x' * 31), isNotNull);
      expect(v('x' * 30), isNull);
    });

    test('names are unique per type, ignoring case and spaces', () {
      expect(v(' food '), isNotNull);
      expect(v('Food', type: 'income'), isNull);
      expect(v('Gifts'), isNull);
      expect(v('Food', editingId: 'a'), isNull, reason: 'its own name');
    });
  });

  group('Categories tab', () {
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
        )
        ..items['other'] = Category(
          id: 'other',
          name: 'Others',
          type: 'expense',
          categoryIcon: 'others',
        )
        ..items['salary'] = Category(
          id: 'salary',
          name: 'Salary',
          type: 'income',
          categoryIcon: 'salary',
        );
    });

    Future<void> openCategoriesTab(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(txRepo),
            categoryRepositoryProvider.overrideWithValue(catRepo),
          ],
          child: const MaterialApp(home: HomePage()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(BottomNavigationBar),
          matching: find.text('Categories'),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('lists categories by type with usage counts', (tester) async {
      txRepo.items['1'] = makeTransaction('1'); // uses c1
      await openCategoriesTab(tester);
      expect(find.text('Expense categories'), findsOneWidget);
      expect(find.text('Income categories'), findsOneWidget);
      expect(find.text('1 transaction'), findsOneWidget);
      expect(find.text('No transactions'), findsNWidgets(2));
    });

    testWidgets('adds a custom income category with an icon', (tester) async {
      await openCategoriesTab(tester);
      await tester.tap(find.byTooltip('Add category'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Side hustle',
      );
      await tester.tap(find.text('Income'));
      await tester.tap(find.bySemanticsLabel('business'));
      await tester.tap(find.text('Save Category'));
      await tester.pumpAndSettle();

      final added = catRepo.items.values.singleWhere(
        (c) => c.name == 'Side hustle',
      );
      expect(added.type, 'income');
      expect(added.categoryIcon, 'business');
      expect(find.text('Side hustle'), findsOneWidget);
    });

    testWidgets('rejects a duplicate name', (tester) async {
      await openCategoriesTab(tester);
      await tester.tap(find.byTooltip('Add category'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'food',
      );
      await tester.tap(find.text('Save Category'));
      await tester.pumpAndSettle();
      expect(
        find.text('Another expense category already has this name'),
        findsOneWidget,
      );
      expect(catRepo.items, hasLength(3));
    });

    testWidgets('renames a category', (tester) async {
      await openCategoriesTab(tester);
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Dining out',
      );
      await tester.tap(find.text('Save Category'));
      await tester.pumpAndSettle();
      expect(catRepo.items['c1']!.name, 'Dining out');
      expect(catRepo.items['c1']!.type, 'expense');
    });

    testWidgets('deleting a used category moves its transactions', (
      tester,
    ) async {
      txRepo.items
        ..['1'] = makeTransaction('1')
        ..['2'] = makeTransaction('2');
      await openCategoriesTab(tester);
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();

      expect(
        find.text('2 transaction(s) use this category. Move them to:'),
        findsOneWidget,
      );
      await tester.tap(find.text('Move and delete'));
      await tester.pumpAndSettle();

      expect(catRepo.items.containsKey('c1'), isFalse);
      expect(txRepo.items.values.map((t) => t.categoryId), ['other', 'other']);
      expect(find.textContaining('moved to Others'), findsOneWidget);
    });

    testWidgets('cancelling delete keeps everything', (tester) async {
      txRepo.items['1'] = makeTransaction('1');
      await openCategoriesTab(tester);
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(catRepo.items.containsKey('c1'), isTrue);
      expect(txRepo.items['1']!.categoryId, 'c1');
    });

    testWidgets("the last category of a type can't be deleted", (tester) async {
      await openCategoriesTab(tester);
      await tester.tap(find.text('Salary'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      expect(find.textContaining("can't be deleted"), findsOneWidget);
      expect(catRepo.items.containsKey('salary'), isTrue);
    });
  });
}

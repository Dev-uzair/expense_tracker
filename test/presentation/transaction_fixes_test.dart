import 'dart:async';
import 'dart:io';

import 'package:expense_tracker/core/category_icons.dart';
import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/domain/repositories/category_repository.dart';
import 'package:expense_tracker/domain/repositories/transaction_repository.dart';
import 'package:expense_tracker/domain/transaction.dart';
import 'package:expense_tracker/presentation/notifiers/category_notifier.dart';
import 'package:expense_tracker/presentation/notifiers/transaction_notifier.dart';
import 'package:expense_tracker/presentation/pages/transaction_list_screen.dart';
import 'package:expense_tracker/presentation/providers/providers.dart';
import 'package:expense_tracker/presentation/providers/transaction_providers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

class InMemoryTransactionRepository implements TransactionRepository {
  final Map<String, Transaction> items = {};
  bool failWrites = false;
  // When set, deletes wait on it, like a real disk write that finishes after
  // the next frame.
  Completer<void>? deleteGate;

  void _check() {
    if (failWrites) throw Exception('disk full');
  }

  @override
  Future<void> addTransaction(Transaction t) async {
    _check();
    items[t.id] = t;
  }

  @override
  Future<void> updateTransaction(Transaction t) async {
    _check();
    items[t.id] = t;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await deleteGate?.future;
    _check();
    items.remove(id);
  }

  @override
  Future<Transaction?> getTransaction(String id) async => items[id];

  @override
  Future<List<Transaction>> getAllTransactions() async => items.values.toList();
}

class InMemoryCategoryRepository implements CategoryRepository {
  final Map<String, Category> items = {};

  @override
  Future<void> addCategory(Category c) async => items[c.id] = c;

  @override
  Future<void> updateCategory(Category c) async => items[c.id] = c;

  @override
  Future<void> deleteCategory(String id) async => items.remove(id);

  @override
  Future<Category?> getCategory(String id) async => items[id];

  @override
  Future<List<Category>> getAllCategories() async => items.values.toList();
}

Transaction makeTransaction(String id, {String? description}) => Transaction(
      id: id,
      amount: 10,
      categoryId: 'c1',
      type: 'expense',
      date: DateTime(2026, 9, 1, 12),
      description: description,
      paymentMethod: 'Cash',
    );

void main() {
  late InMemoryTransactionRepository txRepo;
  late InMemoryCategoryRepository catRepo;

  setUp(() {
    txRepo = InMemoryTransactionRepository();
    catRepo = InMemoryCategoryRepository()
      ..items['c1'] = Category(
          id: 'c1', name: 'Food', type: 'expense', categoryIcon: 'food');
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(overrides: [
      transactionRepositoryProvider.overrideWithValue(txRepo),
      categoryRepositoryProvider.overrideWithValue(catRepo),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  group('TransactionNotifier error handling', () {
    test('add/update/delete rethrow repository errors', () async {
      final container = makeContainer();
      await container.read(transactionNotifierProvider.future);
      final notifier = container.read(transactionNotifierProvider.notifier);
      txRepo.failWrites = true;

      await expectLater(
          notifier.addTransaction(makeTransaction('1')), throwsException);
      await expectLater(
          notifier.updateTransaction(makeTransaction('1')), throwsException);
      await expectLater(notifier.deleteTransaction('1'), throwsException);
    });

    test('delete removes the item before the write completes', () async {
      txRepo.items['1'] = makeTransaction('1');
      final container = makeContainer();
      await container.read(transactionNotifierProvider.future);

      final pending = container
          .read(transactionNotifierProvider.notifier)
          .deleteTransaction('1');
      expect(container.read(transactionNotifierProvider).requireValue, isEmpty);
      await pending;
      expect(txRepo.items, isEmpty);
    });

    test('failed delete restores the item', () async {
      txRepo.items['1'] = makeTransaction('1');
      final container = makeContainer();
      await container.read(transactionNotifierProvider.future);
      txRepo.failWrites = true;

      await expectLater(
          container
              .read(transactionNotifierProvider.notifier)
              .deleteTransaction('1'),
          throwsException);
      expect(container.read(transactionNotifierProvider).requireValue,
          hasLength(1));
    });
  });

  group('transactionWithCategoryProvider', () {
    test('follows transaction and category notifier changes', () async {
      final container = makeContainer();
      container.listen(transactionWithCategoryProvider, (_, _) {});
      await container.read(transactionNotifierProvider.future);
      await container.read(categoryNotifierProvider.future);

      await container
          .read(transactionNotifierProvider.notifier)
          .addTransaction(makeTransaction('1'));
      var (txs, cats) =
          container.read(transactionWithCategoryProvider).requireValue;
      expect(txs.map((t) => t.id), ['1']);

      await container.read(categoryNotifierProvider.notifier).updateCategory(
          Category(id: 'c1', name: 'Dining', type: 'expense'));
      (txs, cats) =
          container.read(transactionWithCategoryProvider).requireValue;
      expect(cats['c1']!.name, 'Dining');
    });
  });

  group('Transaction.copyWith', () {
    test('can clear nullable fields', () {
      final t = makeTransaction('1', description: 'lunch');
      final cleared =
          t.copyWith(description: () => null, paymentMethod: () => null);
      expect(cleared.description, isNull);
      expect(cleared.paymentMethod, isNull);
    });

    test('keeps nullable fields when omitted', () {
      final t = makeTransaction('1', description: 'lunch');
      expect(t.copyWith(amount: 5).description, 'lunch');
    });
  });

  group('categoryIconData', () {
    test('resolves keys, legacy code points and unknown values', () {
      expect(categoryIconData('food'), CupertinoIcons.tuningfork);
      expect(
          categoryIconData(CupertinoIcons.gift.codePoint.toString()),
          CupertinoIcons.gift);
      expect(categoryIconData('nope'), fallbackCategoryIcon);
      expect(categoryIconData(null), fallbackCategoryIcon);
    });
  });

  testWidgets('swipe to delete removes the row and undo restores it',
      (tester) async {
    txRepo.items['1'] = makeTransaction('1', description: 'Lunch');
    await tester.pumpWidget(ProviderScope(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(txRepo),
        categoryRepositoryProvider.overrideWithValue(catRepo),
      ],
      child: const MaterialApp(home: TransactionListScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Lunch'), findsOneWidget);

    txRepo.deleteGate = Completer<void>();
    await tester.drag(find.text('Lunch'), const Offset(-600, 0));
    await tester.pumpAndSettle();

    // Any rebuild while the write is in flight (the old code triggered one by
    // invalidating the list provider) must not find the dismissed row.
    tester.element(find.byType(TransactionListScreen)).markNeedsBuild();
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Lunch'), findsNothing);

    txRepo.deleteGate!.complete();
    await tester.pumpAndSettle();
    expect(txRepo.items, isEmpty);
    expect(find.text('Transaction deleted'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Lunch'), findsOneWidget);
    expect(txRepo.items.keys, ['1']);
  });

  test('a deleted Hive object can be stored again (undo path)', () async {
    final dir = await Directory.systemTemp.createTemp('hive_test');
    addTearDown(() => dir.delete(recursive: true));
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TransactionAdapter());
    final box = await Hive.openBox<Transaction>('tx');
    addTearDown(Hive.close);

    final t = makeTransaction('1');
    await box.put(t.id, t);
    final stored = box.get('1')!;
    await box.delete('1');
    await box.put(stored.id, stored);
    expect(box.get('1'), stored);
  });
}

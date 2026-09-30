import 'dart:convert';

import 'package:expense_tracker/data/backup_service.dart';
import 'package:expense_tracker/domain/category.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_repositories.dart';

void main() {
  late InMemoryTransactionRepository txRepo;
  late InMemoryCategoryRepository catRepo;
  late InMemoryBudgetRepository budgetRepo;
  late BackupService service;

  setUp(() {
    txRepo = InMemoryTransactionRepository();
    catRepo = InMemoryCategoryRepository()
      ..items['c1'] = Category(
        id: 'c1',
        name: 'Food',
        type: 'expense',
        categoryIcon: 'food',
      );
    budgetRepo = InMemoryBudgetRepository();
    service = BackupService(txRepo, catRepo, budgetRepo);
  });

  test('export then import restores the same data', () async {
    txRepo.items
      ..['1'] = makeTransaction('1', description: 'Lunch', amount: 12.5)
      ..['2'] = makeTransaction('2', type: 'income', amount: 1000);
    final json = await service.exportJson();

    txRepo.items.clear();
    catRepo.items['c2'] = Category(id: 'c2', name: 'Extra', type: 'expense');
    txRepo.items['9'] = makeTransaction('9');

    final summary = await service.importJson(json);
    expect(summary.transactions, 2);
    expect(summary.categories, 1);
    expect(catRepo.items.keys, ['c1'], reason: 'restore replaces categories');
    expect(txRepo.items.keys.toSet(), {'1', '2'});
    expect(txRepo.items['1']!.description, 'Lunch');
    expect(txRepo.items['1']!.amount, 12.5);
    expect(txRepo.items['2']!.type, 'income');
  });

  test('accepts whole-number amounts written as JSON integers', () async {
    final json = jsonEncode({
      'app': 'expense_tracker',
      'version': 1,
      'categories': [],
      'transactions': [
        {
          'id': '1',
          'amount': 100,
          'categoryId': 'c1',
          'type': 'expense',
          'date': '2026-09-01T12:00:00.000',
        },
      ],
    });
    await service.importJson(json);
    expect(txRepo.items['1']!.amount, 100.0);
  });

  group('invalid files leave current data untouched', () {
    for (final (name, contents) in [
      ('not JSON', 'hello'),
      ('another app', jsonEncode({'app': 'other', 'version': 1})),
      (
        'newer format',
        jsonEncode({
          'app': 'expense_tracker',
          'version': 99,
          'categories': [],
          'transactions': [],
        }),
      ),
      (
        'missing fields',
        jsonEncode({
          'app': 'expense_tracker',
          'version': 1,
          'categories': [],
          'transactions': [
            {'id': '1'},
          ],
        }),
      ),
    ]) {
      test(name, () async {
        txRepo.items['1'] = makeTransaction('1');
        await expectLater(
          service.importJson(contents),
          throwsA(isA<FormatException>()),
        );
        expect(txRepo.items, hasLength(1));
        expect(catRepo.items, hasLength(1));
      });
    }
  });
}

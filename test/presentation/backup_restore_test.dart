import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/presentation/pages/home_page.dart';
import 'package:expense_tracker/presentation/providers/backup_providers.dart';
import 'package:expense_tracker/presentation/providers/filter_providers.dart';
import 'package:expense_tracker/presentation/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_repositories.dart';

class FakeBackupFiles implements BackupFiles {
  String? savedName;
  String? savedContents;
  String? savedMimeType;
  String? toPick;

  @override
  Future<bool> save(
    String fileName,
    String contents, {
    String mimeType = 'application/json',
  }) async {
    savedName = fileName;
    savedContents = contents;
    savedMimeType = mimeType;
    return true;
  }

  @override
  Future<String?> pickText() async => toPick;
}

void main() {
  late InMemoryTransactionRepository txRepo;
  late InMemoryCategoryRepository catRepo;
  late FakeBackupFiles files;

  setUp(() {
    txRepo = InMemoryTransactionRepository();
    catRepo = InMemoryCategoryRepository()
      ..items['c1'] = Category(
        id: 'c1',
        name: 'Food',
        type: 'expense',
        categoryIcon: 'food',
      );
    files = FakeBackupFiles();
  });

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(txRepo),
          categoryRepositoryProvider.overrideWithValue(catRepo),
          budgetRepositoryProvider.overrideWithValue(
            InMemoryBudgetRepository(),
          ),
          selectedMonthProvider.overrideWith(
            () => FixedMonthNotifier(DateTime(2026, 9)),
          ),
          backupFilesProvider.overrideWithValue(files),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> chooseMenu(WidgetTester tester, String item) async {
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item));
    await tester.pumpAndSettle();
  }

  testWidgets('back up then restore brings the data back', (tester) async {
    txRepo.items['1'] = makeTransaction('1', description: 'Lunch');
    await pumpHome(tester);

    await chooseMenu(tester, 'Back up data');
    expect(
      files.savedName,
      matches(RegExp(r'^expense_tracker_backup_\d{4}-\d{2}-\d{2}\.json$')),
    );
    expect(find.text('Backup saved'), findsOneWidget);

    txRepo.items.clear();
    txRepo.items['2'] = makeTransaction('2', description: 'Coffee');
    files.toPick = files.savedContents;
    await chooseMenu(tester, 'Restore from backup');
    expect(find.text('Restore from backup?'), findsOneWidget);
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

    expect(txRepo.items.keys, ['1']);
    expect(
      find.text('Restored 1 transactions and 1 categories'),
      findsOneWidget,
    );
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Coffee'), findsNothing);
  });

  testWidgets('restoring an invalid file shows an error and changes nothing', (
    tester,
  ) async {
    txRepo.items['1'] = makeTransaction('1', description: 'Lunch');
    await pumpHome(tester);

    files.toPick = 'not a backup';
    await chooseMenu(tester, 'Restore from backup');

    expect(find.text('Restore from backup?'), findsNothing);
    expect(find.textContaining('Invalid backup file'), findsOneWidget);
    expect(txRepo.items.keys, ['1']);
  });

  testWidgets('cancelling the restore dialog changes nothing', (tester) async {
    txRepo.items['1'] = makeTransaction('1', description: 'Lunch');
    await pumpHome(tester);
    await chooseMenu(tester, 'Back up data');
    txRepo.items['2'] = makeTransaction('2');

    files.toPick = files.savedContents;
    await chooseMenu(tester, 'Restore from backup');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(txRepo.items.keys.toSet(), {'1', '2'});
  });

  group('Export to CSV', () {
    Future<void> pumpWithFilter(
      WidgetTester tester,
      TransactionFilter filter,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(txRepo),
            categoryRepositoryProvider.overrideWithValue(catRepo),
            budgetRepositoryProvider.overrideWithValue(
              InMemoryBudgetRepository(),
            ),
            backupFilesProvider.overrideWithValue(files),
            selectedMonthProvider.overrideWith(
              () => FixedMonthNotifier(DateTime(2026, 9)),
            ),
            transactionFilterProvider.overrideWith(
              () => _FixedFilterNotifier(filter),
            ),
          ],
          child: const MaterialApp(home: HomePage()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('exports every transaction as CSV', (tester) async {
      txRepo.items
        ..['1'] = makeTransaction('1', description: 'Lunch')
        ..['2'] = makeTransaction('2', description: 'Taxi');
      await pumpWithFilter(tester, const TransactionFilter());

      await chooseMenu(tester, 'Export to CSV');
      expect(
        files.savedName,
        matches(
          RegExp(r'^expense_tracker_transactions_\d{4}-\d{2}-\d{2}\.csv$'),
        ),
      );
      expect(files.savedMimeType, 'text/csv');
      final lines = files.savedContents!.split('\r\n');
      expect(lines.first, contains('Amount (USD)'));
      expect(lines, hasLength(3));
      expect(find.text('Exported 2 transactions'), findsOneWidget);
    });

    testWidgets('with an active filter, can export only the filtered ones', (
      tester,
    ) async {
      txRepo.items
        ..['1'] = makeTransaction('1', description: 'Lunch')
        ..['2'] = makeTransaction('2', description: 'Taxi');
      await pumpWithFilter(tester, const TransactionFilter(query: 'lunch'));

      await chooseMenu(tester, 'Export to CSV');
      expect(find.text('All transactions (2)'), findsOneWidget);
      await tester.tap(find.text('Only the filtered transactions (1)'));
      await tester.pumpAndSettle();

      final lines = files.savedContents!.split('\r\n');
      expect(lines, hasLength(2));
      expect(lines.last, endsWith('Lunch'));
    });

    testWidgets('nothing to export', (tester) async {
      await pumpWithFilter(tester, const TransactionFilter());
      await chooseMenu(tester, 'Export to CSV');
      expect(find.text('No transactions to export'), findsOneWidget);
      expect(files.savedName, isNull);
    });
  });
}

class _FixedFilterNotifier extends TransactionFilterNotifier {
  final TransactionFilter filter;

  _FixedFilterNotifier(this.filter);

  @override
  TransactionFilter build() => filter;
}

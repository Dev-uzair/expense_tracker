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
  String? toPick;

  @override
  Future<bool> save(String fileName, String contents) async {
    savedName = fileName;
    savedContents = contents;
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
}

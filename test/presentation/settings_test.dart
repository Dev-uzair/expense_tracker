import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/presentation/providers/filter_providers.dart';
import 'package:expense_tracker/presentation/providers/providers.dart';
import 'package:expense_tracker/presentation/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_repositories.dart';

void main() {
  test('settings default to USD and system theme, and are persisted', () async {
    final store = MemorySettingsStore();
    var container = ProviderContainer(
      overrides: [settingsStoreProvider.overrideWithValue(store)],
    );
    expect(container.read(settingsProvider).currency.code, 'USD');
    expect(container.read(settingsProvider).themeMode, ThemeMode.system);

    await container
        .read(settingsProvider.notifier)
        .setCurrency(currencyByCode('PKR'));
    await container
        .read(settingsProvider.notifier)
        .setThemeMode(ThemeMode.dark);
    expect(container.read(moneyFormatProvider).format(-1234.5), '-Rs 1,234.50');
    container.dispose();

    // A fresh container (like an app restart) reads the saved values.
    container = ProviderContainer(
      overrides: [settingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    expect(container.read(settingsProvider).currency.code, 'PKR');
    expect(container.read(settingsProvider).themeMode, ThemeMode.dark);
  });

  test('unknown saved values fall back to defaults', () {
    final store = MemorySettingsStore()
      ..values['currency'] = 'XYZ'
      ..values['themeMode'] = 'purple';
    final container = ProviderContainer(
      overrides: [settingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    expect(container.read(settingsProvider).currency.code, 'USD');
    expect(container.read(settingsProvider).themeMode, ThemeMode.system);
  });

  testWidgets('changing currency and theme from the Settings page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    final txRepo = InMemoryTransactionRepository()
      ..items['1'] = makeTransaction('1', amount: 1500, type: 'income');
    final catRepo = InMemoryCategoryRepository()
      ..items['c1'] = Category(id: 'c1', name: 'Food', type: 'expense');
    final store = MemorySettingsStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(txRepo),
          categoryRepositoryProvider.overrideWithValue(catRepo),
          settingsStoreProvider.overrideWithValue(store),
          selectedMonthProvider.overrideWith(
            () => FixedMonthNotifier(DateTime(2026, 9)),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(r'$1,500.00'), findsWidgets);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Currency'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pakistani Rupee (PKR)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Rs 1,234.50'), findsOneWidget);
    expect(store.values['currency'], 'PKR');

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    expect(
      Theme.of(tester.element(find.text('Settings').first)).brightness,
      Brightness.dark,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Rs 1,500.00'), findsWidgets);
    expect(find.text(r'$1,500.00'), findsNothing);
  });
}

import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/presentation/providers/filter_providers.dart';
import 'package:expense_tracker/presentation/providers/providers.dart';
import 'package:expense_tracker/presentation/security/pin_lock.dart';
import 'package:expense_tracker/presentation/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_repositories.dart';

// A store that already has [pin] set, as after a previous session.
MemorySettingsStore storeWithPin(String pin) {
  const salt = 'test-salt';
  return MemorySettingsStore()
    ..values['pinSalt'] = salt
    ..values['pinHash'] = hashPin(pin, salt);
}

void main() {
  group('hashing', () {
    test('same PIN and salt give the same hash; salt changes it', () {
      expect(hashPin('1234', 'a'), hashPin('1234', 'a'));
      expect(hashPin('1234', 'a'), isNot(hashPin('1234', 'b')));
      expect(hashPin('1234', 'a'), isNot(hashPin('1235', 'a')));
      expect(newSalt(), isNot(newSalt()));
    });

    test('valid PINs are 4 to 6 digits', () {
      for (final ok in ['1234', '00000', '999999']) {
        expect(isValidPin(ok), isTrue, reason: ok);
      }
      for (final bad in ['123', '1234567', '12a4', '', '12 34']) {
        expect(isValidPin(bad), isFalse, reason: bad);
      }
    });
  });

  group('PinLockNotifier', () {
    late DateTime now;
    late MemorySettingsStore store;
    late ProviderContainer container;

    setUp(() {
      now = DateTime(2026, 9, 1, 12);
      store = MemorySettingsStore();
      container = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(store),
          clockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(container.dispose);
    });

    PinLockNotifier notifier() => container.read(pinLockProvider.notifier);

    test('setting a PIN stores only a salted hash', () async {
      expect(container.read(pinLockProvider).enabled, isFalse);
      await notifier().setPin('4321');
      expect(container.read(pinLockProvider).enabled, isTrue);
      expect(container.read(pinLockProvider).locked, isFalse);
      expect(store.values.values, isNot(contains('4321')));
      expect(
        store.values['pinHash'],
        hashPin('4321', store.values['pinSalt']!),
      );
    });

    test('starts locked when a PIN exists; right PIN unlocks', () {
      store.values.addAll(storeWithPin('1111').values);
      expect(container.read(pinLockProvider).locked, isTrue);
      expect(notifier().unlock('2222'), isFalse);
      expect(container.read(pinLockProvider).failedAttempts, 1);
      expect(notifier().unlock('1111'), isTrue);
      expect(container.read(pinLockProvider).locked, isFalse);
      notifier().lock();
      expect(container.read(pinLockProvider).locked, isTrue);
    });

    test('five wrong PINs pause attempts for 30 seconds', () {
      store.values.addAll(storeWithPin('1111').values);
      for (var i = 0; i < 5; i++) {
        expect(notifier().unlock('0000'), isFalse);
      }
      expect(notifier().lockoutRemaining(), const Duration(seconds: 30));
      // Even the right PIN is refused during the pause.
      expect(notifier().unlock('1111'), isFalse);

      now = now.add(const Duration(seconds: 31));
      expect(notifier().lockoutRemaining(), isNull);
      expect(notifier().unlock('1111'), isTrue);
    });

    test('removing the PIN turns the lock off', () async {
      await notifier().setPin('1234');
      await notifier().removePin();
      expect(container.read(pinLockProvider).enabled, isFalse);
      expect(store.values, isEmpty);
      notifier().lock();
      expect(container.read(pinLockProvider).locked, isFalse);
    });
  });

  group('app', () {
    late InMemoryTransactionRepository txRepo;
    late DateTime now;

    setUp(() {
      now = DateTime(2026, 9, 1, 12);
      txRepo = InMemoryTransactionRepository()
        ..items['1'] = makeTransaction('1', description: 'Lunch');
    });

    Future<void> pumpApp(WidgetTester tester, SettingsStore store) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(txRepo),
            categoryRepositoryProvider.overrideWithValue(
              InMemoryCategoryRepository()
                ..items['c1'] = Category(
                  id: 'c1',
                  name: 'Food',
                  type: 'expense',
                ),
            ),
            budgetRepositoryProvider.overrideWithValue(
              InMemoryBudgetRepository(),
            ),
            settingsStoreProvider.overrideWithValue(store),
            clockProvider.overrideWithValue(() => now),
            selectedMonthProvider.overrideWith(
              () => FixedMonthNotifier(DateTime(2026, 9)),
            ),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> enterPin(WidgetTester tester, String pin) async {
      for (final d in pin.split('')) {
        await tester.tap(find.text(d).last);
      }
      await tester.tap(find.bySemanticsLabel('OK'));
      await tester.pumpAndSettle();
    }

    testWidgets('opens locked and unlocks with the right PIN', (tester) async {
      await pumpApp(tester, storeWithPin('2468'));
      expect(find.text('Enter PIN'), findsOneWidget);
      expect(find.text('Lunch'), findsNothing);

      await enterPin(tester, '1357');
      expect(find.text('Wrong PIN. 4 tries left.'), findsOneWidget);

      await enterPin(tester, '2468');
      expect(find.text('Enter PIN'), findsNothing);
      expect(find.text('Lunch'), findsOneWidget);
    });

    testWidgets('turning the lock on and off from Settings', (tester) async {
      final store = MemorySettingsStore();
      await pumpApp(tester, store);
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('App lock'));
      await tester.pumpAndSettle();
      expect(find.text('Choose a PIN'), findsOneWidget);
      await enterPin(tester, '1234');
      expect(find.text('Confirm your PIN'), findsOneWidget);
      await enterPin(tester, '9999');
      expect(find.text("PINs didn't match. Start again."), findsOneWidget);
      await enterPin(tester, '1234');
      await enterPin(tester, '1234');
      expect(find.text('App lock on'), findsOneWidget);
      expect(store.values['pinHash'], isNotNull);
      expect(find.text('Change PIN'), findsOneWidget);

      await tester.tap(find.text('App lock'));
      await tester.pumpAndSettle();
      await enterPin(tester, '0000');
      expect(find.text('Wrong PIN'), findsOneWidget);
      await enterPin(tester, '1234');
      expect(find.text('App lock off'), findsOneWidget);
      expect(store.values, isEmpty);
    });

    testWidgets('forgot PIN deletes transactions and removes the lock', (
      tester,
    ) async {
      final store = storeWithPin('2468');
      await pumpApp(tester, store);
      await tester.tap(find.text('Forgot PIN?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete data and remove lock'));
      await tester.pumpAndSettle();

      expect(txRepo.items, isEmpty);
      expect(store.values, isEmpty);
      expect(find.text('Enter PIN'), findsNothing);
      expect(find.text('Expense Tracker'), findsOneWidget);
    });

    testWidgets('locks again after a minute in the background', (tester) async {
      await pumpApp(tester, storeWithPin('2468'));
      await enterPin(tester, '2468');

      void goBackground() {
        for (final state in [
          AppLifecycleState.inactive,
          AppLifecycleState.hidden,
          AppLifecycleState.paused,
        ]) {
          tester.binding.handleAppLifecycleStateChanged(state);
        }
      }

      void comeBack() {
        for (final state in [
          AppLifecycleState.hidden,
          AppLifecycleState.inactive,
          AppLifecycleState.resumed,
        ]) {
          tester.binding.handleAppLifecycleStateChanged(state);
        }
      }

      // A short trip to the background doesn't lock.
      goBackground();
      now = now.add(const Duration(seconds: 20));
      comeBack();
      await tester.pumpAndSettle();
      expect(find.text('Enter PIN'), findsNothing);

      goBackground();
      now = now.add(const Duration(minutes: 2));
      comeBack();
      await tester.pumpAndSettle();
      expect(find.text('Enter PIN'), findsOneWidget);
    });
  });
}

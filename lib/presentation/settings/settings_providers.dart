import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

class Currency {
  final String code;
  final String name;
  // Printed before the amount, including any spacing.
  final String symbol;

  const Currency(this.code, this.name, this.symbol);
}

const List<Currency> currencies = [
  Currency('USD', 'US Dollar', r'$'),
  Currency('EUR', 'Euro', '€'),
  Currency('GBP', 'British Pound', '£'),
  Currency('PKR', 'Pakistani Rupee', 'Rs '),
  Currency('INR', 'Indian Rupee', '₹'),
  Currency('BDT', 'Bangladeshi Taka', 'Tk '),
  Currency('AED', 'UAE Dirham', 'AED '),
  Currency('SAR', 'Saudi Riyal', 'SAR '),
  Currency('CAD', 'Canadian Dollar', r'CA$'),
  Currency('AUD', 'Australian Dollar', r'A$'),
];

Currency currencyByCode(String? code) => currencies.firstWhere(
  (c) => c.code == code,
  orElse: () => currencies.first,
);

class AppSettings {
  final Currency currency;
  final ThemeMode themeMode;

  const AppSettings({required this.currency, required this.themeMode});

  AppSettings copyWith({Currency? currency, ThemeMode? themeMode}) =>
      AppSettings(
        currency: currency ?? this.currency,
        themeMode: themeMode ?? this.themeMode,
      );
}

// Key-value storage for settings, so tests can swap in a map.
abstract class SettingsStore {
  String? read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

class HiveSettingsStore implements SettingsStore {
  static const String boxName = 'settings';

  // The box is opened by HiveInitializer at startup; until then (e.g. in
  // widget tests) settings fall back to their defaults.
  Box<String>? get _box =>
      Hive.isBoxOpen(boxName) ? Hive.box<String>(boxName) : null;

  @override
  String? read(String key) => _box?.get(key);

  @override
  Future<void> write(String key, String value) async => _box?.put(key, value);

  @override
  Future<void> remove(String key) async => _box?.delete(key);
}

class MemorySettingsStore implements SettingsStore {
  final Map<String, String> values = {};

  @override
  String? read(String key) => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);
}

final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => HiveSettingsStore(),
);

class SettingsNotifier extends Notifier<AppSettings> {
  static const String _currencyKey = 'currency';
  static const String _themeKey = 'themeMode';

  SettingsStore get _store => ref.read(settingsStoreProvider);

  @override
  AppSettings build() {
    final store = ref.watch(settingsStoreProvider);
    return AppSettings(
      currency: currencyByCode(store.read(_currencyKey)),
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == store.read(_themeKey),
        orElse: () => ThemeMode.system,
      ),
    );
  }

  Future<void> setCurrency(Currency currency) async {
    state = state.copyWith(currency: currency);
    await _store.write(_currencyKey, currency.code);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _store.write(_themeKey, mode.name);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

// Formats amounts in the chosen currency, e.g. "$1,234.50" or "-Rs 12.00".
final moneyFormatProvider = Provider<NumberFormat>((ref) {
  final currency = ref.watch(settingsProvider.select((s) => s.currency));
  return NumberFormat.currency(
    locale: 'en_US',
    symbol: currency.symbol,
    decimalDigits: 2,
  );
});

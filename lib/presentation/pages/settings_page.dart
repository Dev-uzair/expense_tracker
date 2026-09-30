import 'package:expense_tracker/presentation/security/pin_lock.dart';
import 'package:expense_tracker/presentation/security/pin_screens.dart';
import 'package:expense_tracker/presentation/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _chooseCurrency(
    BuildContext context,
    WidgetRef ref,
    Currency current,
  ) async {
    final chosen = await showDialog<Currency>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Currency'),
        children: [
          for (final c in currencies)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(c),
              child: Row(
                children: [
                  SizedBox(width: 48, child: Text(c.symbol.trim())),
                  Expanded(child: Text('${c.name} (${c.code})')),
                  if (c.code == current.code) const Icon(Icons.check),
                ],
              ),
            ),
        ],
      ),
    );
    if (chosen != null) {
      await ref.read(settingsProvider.notifier).setCurrency(chosen);
    }
  }

  Future<void> _setLock(BuildContext context, WidgetRef ref, bool on) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (on) {
      final saved = await navigator.push<bool>(
        MaterialPageRoute(builder: (_) => const PinSetupScreen()),
      );
      if (saved == true) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('App lock on')));
      }
      return;
    }
    final ok = await navigator.push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            const PinVerifyScreen(reason: 'to turn off the app lock'),
      ),
    );
    if (ok == true) {
      await ref.read(pinLockProvider.notifier).removePin();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('App lock off')));
    }
  }

  Future<void> _changePin(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await navigator.push<bool>(
      MaterialPageRoute(
        builder: (_) => const PinVerifyScreen(reason: 'to change your PIN'),
      ),
    );
    if (ok != true) return;
    final saved = await navigator.push<bool>(
      MaterialPageRoute(builder: (_) => const PinSetupScreen()),
    );
    if (saved == true) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('PIN changed')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final lockEnabled = ref.watch(pinLockProvider.select((s) => s.enabled));
    final example = ref.watch(moneyFormatProvider).format(1234.5);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: const Text('Currency'),
            subtitle: Text(
              '${settings.currency.name} (${settings.currency.code}) · '
              'e.g. $example',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _chooseCurrency(context, ref, settings.currency),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.dark_mode_outlined),
            title: Text('Theme'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) =>
                  ref.read(settingsProvider.notifier).setThemeMode(s.first),
            ),
          ),
          const Divider(height: 32),
          SwitchListTile(
            secondary: const Icon(Icons.lock_outline),
            title: const Text('App lock'),
            subtitle: const Text(
              'Ask for a PIN when the app opens or returns after a minute '
              'in the background',
            ),
            value: lockEnabled,
            onChanged: (on) => _setLock(context, ref, on),
          ),
          if (lockEnabled)
            ListTile(
              leading: const Icon(Icons.pin_outlined),
              title: const Text('Change PIN'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _changePin(context),
            ),
        ],
      ),
    );
  }
}

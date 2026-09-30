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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
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
        ],
      ),
    );
  }
}

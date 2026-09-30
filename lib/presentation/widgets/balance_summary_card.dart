import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/presentation/settings/settings_providers.dart';

class BalanceSummaryCard extends ConsumerWidget {
  final double balance;
  final String title;

  const BalanceSummaryCard({
    super.key,
    required this.balance,
    this.title = 'Current Balance',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8.0),
            Text(
              ref.watch(moneyFormatProvider).format(balance),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: balance >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

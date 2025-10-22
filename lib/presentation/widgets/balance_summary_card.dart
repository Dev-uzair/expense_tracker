import 'package:flutter/material.dart';

class BalanceSummaryCard extends StatelessWidget {
  final double balance;

  const BalanceSummaryCard({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Balance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8.0),
            Text(
              '${balance.toStringAsFixed(2)}',
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

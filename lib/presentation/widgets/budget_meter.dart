import 'package:expense_tracker/core/category_icons.dart';
import 'package:expense_tracker/presentation/budgets/budget_data.dart';
import 'package:expense_tracker/presentation/settings/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Fixed status colours (never themed); each is always paired with an icon and
// a label so the state never relies on colour alone.
const Color _good = Color(0xFF0CA30C);
const Color _warning = Color(0xFFFAB219);
const Color _critical = Color(0xFFD03B3B);

extension BudgetLevelStyle on BudgetLevel {
  Color get color => switch (this) {
    BudgetLevel.onTrack => _good,
    BudgetLevel.nearLimit => _warning,
    BudgetLevel.over => _critical,
  };

  IconData get icon => switch (this) {
    BudgetLevel.onTrack => Icons.check_circle,
    BudgetLevel.nearLimit => Icons.warning_amber_rounded,
    BudgetLevel.over => Icons.error,
  };
}

class BudgetMeter extends ConsumerWidget {
  final BudgetStatus status;
  final VoidCallback? onTap;

  const BudgetMeter({super.key, required this.status, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(moneyFormatProvider);
    final theme = Theme.of(context);
    final level = status.level;
    final percent = (status.ratio * 100).round();
    final label = switch (level) {
      BudgetLevel.onTrack => '${money.format(status.remaining)} left',
      BudgetLevel.nearLimit =>
        '$percent% used · ${money.format(status.remaining)} left',
      BudgetLevel.over => 'Over by ${money.format(-status.remaining)}',
    };

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  status.budget.isOverall
                      ? Icons.account_balance_wallet_outlined
                      : categoryIconData(status.icon),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(status.name, overflow: TextOverflow.ellipsis),
                ),
                Text(
                  '${money.format(status.spent)} / '
                  '${money.format(status.limit)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Meter: the fill carries the state; the track is a lighter step
            // of the same colour.
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: status.ratio.clamp(0.0, 1.0),
                minHeight: 8,
                color: level.color,
                backgroundColor: level.color.withValues(alpha: 0.18),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(level.icon, size: 16, color: level.color),
                const SizedBox(width: 6),
                Text(label, style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

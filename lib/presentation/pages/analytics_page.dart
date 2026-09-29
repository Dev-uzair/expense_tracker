import 'package:expense_tracker/core/category_icons.dart';
import 'package:expense_tracker/presentation/analytics/analytics_data.dart';
import 'package:expense_tracker/presentation/providers/filter_providers.dart';
import 'package:expense_tracker/presentation/providers/transaction_providers.dart';
import 'package:expense_tracker/presentation/widgets/month_selector.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Series colours for the income/expense chart. Blue/orange rather than
// green/red so the pair stays distinguishable with colour-vision deficiency.
const Color incomeColor = Color(0xFF2A78D6);
const Color expenseColor = Color(0xFFEB6834);

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(transactionWithCategoryProvider);
    final month = ref.watch(selectedMonthProvider);

    return dataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (data) {
        final (transactions, categories) = data;
        final byCategory = spendingByCategory(transactions, categories, month);
        final months = monthlyTotals(transactions, month);

        return ListView(
          padding: const EdgeInsets.only(bottom: 88), // Clear of the FAB.
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: MonthSelector(),
            ),
            _Section(
              title: 'Spending by category',
              child: _CategoryBreakdown(items: byCategory),
            ),
            _Section(
              title: 'Income vs expense, last 6 months',
              child: _MonthlyChart(months: months),
            ),
          ],
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

// A ranked list of horizontal bars: easier to compare than pie slices when
// there are many categories with similar amounts, and it doubles as the table.
class _CategoryBreakdown extends StatelessWidget {
  final List<CategorySpend> items;

  const _CategoryBreakdown({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text('No expenses this month.');
    }
    final theme = Theme.of(context);
    final total = items.fold(0.0, (sum, i) => sum + i.amount);
    final largest = items.first.amount;

    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(categoryIconData(item.icon), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            item.amount.toStringAsFixed(2),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(
                            width: 48,
                            child: Text(
                              '${(item.share * 100).round()}%',
                              textAlign: TextAlign.end,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Scaled to the largest category so small ones stay
                      // visible; the percentage carries the share of total.
                      LayoutBuilder(
                        builder: (context, constraints) => Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 8,
                            width:
                                constraints.maxWidth *
                                (item.amount / largest).clamp(0.02, 1.0),
                            decoration: BoxDecoration(
                              color: expenseColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const Divider(),
        Row(
          children: [
            const Text('Total'),
            const Spacer(),
            Text(
              total.toStringAsFixed(2),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ],
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  final List<MonthTotals> months;

  const _MonthlyChart({required this.months});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final monthLabel = DateFormat.MMM();
    final maxValue = months.fold(
      0.0,
      (m, t) => [m, t.income, t.expense].reduce((a, b) => a > b ? a : b),
    );
    final hasData = maxValue > 0;
    // Round the axis up to a tidy value with 4 gridlines.
    final interval = hasData ? _niceInterval(maxValue / 4) : 1.0;
    final maxY = hasData ? interval * 4 : 4.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            _LegendItem(color: incomeColor, label: 'Income'),
            SizedBox(width: 16),
            _LegendItem(color: expenseColor, label: 'Expense'),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              alignment: BarChartAlignment.spaceAround,
              barGroups: [
                for (var i = 0; i < months.length; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 2,
                    barRods: [
                      _rod(months[i].income, incomeColor),
                      _rod(months[i].expense, expenseColor),
                    ],
                  ),
              ],
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: theme.colorScheme.outlineVariant,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    interval: interval,
                    getTitlesWidget: (value, meta) => Text(
                      NumberFormat.compact().format(value),
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        monthLabel.format(months[value.toInt()].month),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final m = months[group.x];
                    return BarTooltipItem(
                      '${DateFormat.yMMM().format(m.month)}\n'
                      '${rodIndex == 0 ? 'Income' : 'Expense'}: '
                      '${rod.toY.toStringAsFixed(2)}',
                      TextStyle(color: theme.colorScheme.onInverseSurface),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // The same numbers as a table, so nothing depends on reading bars.
        Table(
          columnWidths: const {0: FlexColumnWidth(1.2)},
          children: [
            TableRow(
              children: [
                for (final h in ['Month', 'Income', 'Expense'])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      h,
                      textAlign: h == 'Month' ? TextAlign.start : TextAlign.end,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ),
              ],
            ),
            for (final m in months.reversed)
              TableRow(
                children: [
                  Text(DateFormat.yMMM().format(m.month)),
                  Text(m.income.toStringAsFixed(2), textAlign: TextAlign.end),
                  Text(m.expense.toStringAsFixed(2), textAlign: TextAlign.end),
                ],
              ),
          ],
        ),
      ],
    );
  }

  static BarChartRodData _rod(double value, Color color) => BarChartRodData(
    toY: value,
    color: color,
    width: 10,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
  );

  // Smallest of 1, 2, 2.5 or 5 × 10^n that is >= raw.
  static double _niceInterval(double raw) {
    var magnitude = 1.0;
    while (magnitude * 10 <= raw) {
      magnitude *= 10;
    }
    while (magnitude > raw && magnitude >= 1) {
      magnitude /= 10;
    }
    for (final step in [1.0, 2.0, 2.5, 5.0, 10.0]) {
      if (step * magnitude >= raw) return step * magnitude;
    }
    return 10 * magnitude;
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

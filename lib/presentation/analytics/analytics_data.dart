import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/domain/transaction.dart';

class CategorySpend {
  final String categoryId;
  final String name;
  final String? icon;
  final double amount;
  // Share of the month's total spending, 0..1.
  final double share;

  const CategorySpend({
    required this.categoryId,
    required this.name,
    required this.icon,
    required this.amount,
    required this.share,
  });
}

class MonthTotals {
  final DateTime month;
  final double income;
  final double expense;

  const MonthTotals({
    required this.month,
    required this.income,
    required this.expense,
  });
}

bool _inMonth(DateTime date, DateTime month) =>
    date.year == month.year && date.month == month.month;

// Expenses in [month] grouped by category, largest first.
List<CategorySpend> spendingByCategory(
  List<Transaction> transactions,
  Map<String, Category> categories,
  DateTime month,
) {
  final totals = <String, double>{};
  for (final t in transactions) {
    if (t.type != 'expense' || !_inMonth(t.date, month)) continue;
    totals.update(t.categoryId, (v) => v + t.amount, ifAbsent: () => t.amount);
  }
  final grandTotal = totals.values.fold(0.0, (a, b) => a + b);
  final result = [
    for (final MapEntry(key: id, value: amount) in totals.entries)
      CategorySpend(
        categoryId: id,
        name: categories[id]?.name ?? 'Uncategorized',
        icon: categories[id]?.categoryIcon,
        amount: amount,
        share: grandTotal == 0 ? 0 : amount / grandTotal,
      ),
  ]..sort((a, b) => b.amount.compareTo(a.amount));
  return result;
}

// Income and expense totals for the [count] months ending with [endMonth],
// oldest first. Months without transactions are included as zeros.
List<MonthTotals> monthlyTotals(
  List<Transaction> transactions,
  DateTime endMonth, {
  int count = 6,
}) {
  return [
    for (var i = count - 1; i >= 0; i--)
      () {
        final month = DateTime(endMonth.year, endMonth.month - i);
        var income = 0.0;
        var expense = 0.0;
        for (final t in transactions) {
          if (!_inMonth(t.date, month)) continue;
          if (t.type == 'income') {
            income += t.amount;
          } else {
            expense += t.amount;
          }
        }
        return MonthTotals(month: month, income: income, expense: expense);
      }(),
  ];
}

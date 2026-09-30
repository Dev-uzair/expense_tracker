import 'package:expense_tracker/domain/budget.dart';
import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/domain/transaction.dart';

enum BudgetLevel { onTrack, nearLimit, over }

// Share of the budget at which it is flagged as nearly used up.
const double budgetWarningRatio = 0.8;

class BudgetStatus {
  final Budget budget;
  final String name;
  final String? icon;
  final double spent;

  const BudgetStatus({
    required this.budget,
    required this.name,
    required this.icon,
    required this.spent,
  });

  double get limit => budget.amount;
  double get ratio => limit <= 0 ? 0 : spent / limit;
  double get remaining => limit - spent;

  BudgetLevel get level => ratio > 1
      ? BudgetLevel.over
      : ratio >= budgetWarningRatio
      ? BudgetLevel.nearLimit
      : BudgetLevel.onTrack;
}

// Spending against each budget in [month]: the overall budget first, then
// category budgets by name. Budgets whose category no longer exists are
// skipped.
List<BudgetStatus> budgetStatuses(
  List<Budget> budgets,
  List<Transaction> transactions,
  Map<String, Category> categories,
  DateTime month,
) {
  final spentByCategory = <String, double>{};
  var totalSpent = 0.0;
  for (final t in transactions) {
    if (t.type != 'expense' ||
        t.date.year != month.year ||
        t.date.month != month.month) {
      continue;
    }
    totalSpent += t.amount;
    spentByCategory.update(
      t.categoryId,
      (v) => v + t.amount,
      ifAbsent: () => t.amount,
    );
  }

  final result = <BudgetStatus>[];
  for (final b in budgets) {
    if (b.isOverall) {
      result.add(
        BudgetStatus(
          budget: b,
          name: 'All expenses',
          icon: null,
          spent: totalSpent,
        ),
      );
    } else if (categories[b.categoryId] case final category?) {
      result.add(
        BudgetStatus(
          budget: b,
          name: category.name,
          icon: category.categoryIcon,
          spent: spentByCategory[b.categoryId] ?? 0,
        ),
      );
    }
  }
  result.sort((a, b) {
    if (a.budget.isOverall != b.budget.isOverall) {
      return a.budget.isOverall ? -1 : 1;
    }
    return a.name.compareTo(b.name);
  });
  return result;
}

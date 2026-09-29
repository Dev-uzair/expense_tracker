import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/domain/transaction.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum FilterPeriod { all, today, thisWeek, thisMonth, thisYear, custom }

extension FilterPeriodLabel on FilterPeriod {
  String get label => switch (this) {
    FilterPeriod.all => 'All time',
    FilterPeriod.today => 'Today',
    FilterPeriod.thisWeek => 'This week',
    FilterPeriod.thisMonth => 'This month',
    FilterPeriod.thisYear => 'This year',
    FilterPeriod.custom => 'Custom range',
  };
}

class TransactionFilter {
  final String query;
  final FilterPeriod period;
  // Inclusive day range, used when period is custom.
  final DateTimeRange? customRange;
  // null means both expense and income.
  final String? type;
  final String? categoryId;

  const TransactionFilter({
    this.query = '',
    this.period = FilterPeriod.all,
    this.customRange,
    this.type,
    this.categoryId,
  });

  bool get isActive =>
      query.trim().isNotEmpty ||
      period != FilterPeriod.all ||
      type != null ||
      categoryId != null;

  // Nullable fields take a function so they can be cleared, as in
  // Transaction.copyWith.
  TransactionFilter copyWith({
    String? query,
    FilterPeriod? period,
    DateTimeRange? Function()? customRange,
    String? Function()? type,
    String? Function()? categoryId,
  }) {
    return TransactionFilter(
      query: query ?? this.query,
      period: period ?? this.period,
      customRange: customRange != null ? customRange() : this.customRange,
      type: type != null ? type() : this.type,
      categoryId: categoryId != null ? categoryId() : this.categoryId,
    );
  }

  // Start (inclusive) and end (exclusive) of the selected period, or null for
  // all time. Weeks start on Monday.
  (DateTime, DateTime)? bounds(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return switch (period) {
      FilterPeriod.all => null,
      FilterPeriod.today => (today, today.add(const Duration(days: 1))),
      FilterPeriod.thisWeek => () {
        final start = today.subtract(Duration(days: today.weekday - 1));
        return (start, DateTime(start.year, start.month, start.day + 7));
      }(),
      FilterPeriod.thisMonth => (
        DateTime(now.year, now.month),
        DateTime(now.year, now.month + 1),
      ),
      FilterPeriod.thisYear => (DateTime(now.year), DateTime(now.year + 1)),
      FilterPeriod.custom =>
        customRange == null
            ? null
            : (
                DateTime(
                  customRange!.start.year,
                  customRange!.start.month,
                  customRange!.start.day,
                ),
                DateTime(
                  customRange!.end.year,
                  customRange!.end.month,
                  customRange!.end.day + 1,
                ),
              ),
    };
  }

  List<Transaction> apply(
    List<Transaction> transactions,
    Map<String, Category> categories, {
    DateTime? now,
  }) {
    final range = bounds(now ?? DateTime.now());
    final q = query.trim().toLowerCase();
    return transactions.where((t) {
      if (range != null &&
          (t.date.isBefore(range.$1) || !t.date.isBefore(range.$2))) {
        return false;
      }
      if (type != null && t.type != type) return false;
      if (categoryId != null && t.categoryId != categoryId) return false;
      if (q.isNotEmpty) {
        final description = t.description?.toLowerCase() ?? '';
        final categoryName = categories[t.categoryId]?.name.toLowerCase() ?? '';
        if (!description.contains(q) && !categoryName.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }
}

class TransactionFilterNotifier extends Notifier<TransactionFilter> {
  @override
  TransactionFilter build() => const TransactionFilter();

  void setFilter(TransactionFilter filter) => state = filter;

  void clear() => state = const TransactionFilter();
}

// Kept in a provider so the filter survives switching tabs.
final transactionFilterProvider =
    NotifierProvider<TransactionFilterNotifier, TransactionFilter>(
      TransactionFilterNotifier.new,
    );

// First day of the month shown on the dashboard (and the analytics screen).
class SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void previous() => state = DateTime(state.year, state.month - 1);

  void next() => state = DateTime(state.year, state.month + 1);
}

final selectedMonthProvider = NotifierProvider<SelectedMonthNotifier, DateTime>(
  SelectedMonthNotifier.new,
);

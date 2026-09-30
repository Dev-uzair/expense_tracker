import 'package:expense_tracker/core/category_icons.dart';
import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/presentation/notifiers/category_notifier.dart';
import 'package:expense_tracker/presentation/notifiers/transaction_notifier.dart';
import 'package:expense_tracker/presentation/pages/category_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryListPage extends ConsumerWidget {
  const CategoryListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsyncValue = ref.watch(categoryNotifierProvider);
    final transactions =
        ref.watch(transactionNotifierProvider).value ?? const [];
    final counts = <String, int>{};
    for (final t in transactions) {
      counts.update(t.categoryId, (n) => n + 1, ifAbsent: () => 1);
    }

    return Scaffold(
      body: categoriesAsyncValue.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('No categories found.'));
          }
          List<Category> ofType(String type) =>
              categories.where((c) => c.type == type).toList()
                ..sort((a, b) => a.name.compareTo(b.name));

          return ListView(
            padding: const EdgeInsets.only(bottom: 88), // Clear of the FAB.
            children: [
              for (final (type, title) in [
                ('expense', 'Expense categories'),
                ('income', 'Income categories'),
              ]) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                for (final category in ofType(type))
                  ListTile(
                    leading: Icon(categoryIconData(category.categoryIcon)),
                    title: Text(category.name),
                    subtitle: Text(switch (counts[category.id] ?? 0) {
                      0 => 'No transactions',
                      1 => '1 transaction',
                      final n => '$n transactions',
                    }),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CategoryFormScreen(category: category),
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

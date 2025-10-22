import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/presentation/providers/providers.dart';
import 'package:expense_tracker/presentation/notifiers/category_notifier.dart';

class CategorySelector extends ConsumerWidget {
  final String selectedTransactionType;
  final ValueChanged<Category> onCategorySelected;
  final Category? selectedCategory;

  const CategorySelector({
    super.key,
    required this.selectedTransactionType,
    required this.onCategorySelected,
    this.selectedCategory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsyncValue = ref.watch(categoryNotifierProvider);

    return categoriesAsyncValue.when(
      data: (categories) {
        final filteredCategories = categories
            .where((category) => category.type == selectedTransactionType)
            .toList();

        if (filteredCategories.isEmpty) {
          return Center(
            child: Text('No ${selectedTransactionType} categories found.'),
          );
        }

        return SizedBox(
          height: 300, // Constrain the height of the GridView
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 3 categories per row
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: filteredCategories.length,
            itemBuilder: (context, index) {
              final category = filteredCategories[index];
              final isSelected = selectedCategory?.id == category.id;
              return GestureDetector(
                onTap: () => onCategorySelected(category),
                child: Card(
                  color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
                  elevation: isSelected ? 4 : 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        category.categoryIcon != null
                            ? IconData(int.parse(category.categoryIcon!),
                                fontFamily: 'CupertinoIcons', fontPackage: 'cupertino_icons')
                            : CupertinoIcons.question_circle,
                        color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSurface,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category.name,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error loading categories: $error')),
    );
  }
}

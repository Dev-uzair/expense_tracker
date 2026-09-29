import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/presentation/providers/providers.dart';

// Mutations let repository errors propagate so the calling screen can report
// them, and keep the current list visible instead of flashing a loading state.
class CategoryNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    return ref.watch(categoryRepositoryProvider).getAllCategories();
  }

  Future<void> _reload() async {
    state = AsyncData(
        await ref.read(categoryRepositoryProvider).getAllCategories());
  }

  Future<void> addCategory(Category category) async {
    await ref.read(categoryRepositoryProvider).addCategory(category);
    await _reload();
  }

  Future<void> updateCategory(Category category) async {
    await ref.read(categoryRepositoryProvider).updateCategory(category);
    await _reload();
  }

  Future<void> deleteCategory(String id) async {
    await ref.read(categoryRepositoryProvider).deleteCategory(id);
    await _reload();
  }
}

final categoryNotifierProvider =
    AsyncNotifierProvider<CategoryNotifier, List<Category>>(
  CategoryNotifier.new,
);

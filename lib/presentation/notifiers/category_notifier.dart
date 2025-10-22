import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/domain/repositories/category_repository.dart';
import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/presentation/providers/providers.dart';

class CategoryNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    return _getCategories();
  }

  Future<List<Category>> _getCategories() {
    final categoryRepository = ref.watch(categoryRepositoryProvider);
    return categoryRepository.getAllCategories();
  }

  Future<void> addCategory(Category category) async {
    final categoryRepository = ref.watch(categoryRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await categoryRepository.addCategory(category);
      return _getCategories();
    });
  }

  Future<void> updateCategory(Category category) async {
    final categoryRepository = ref.watch(categoryRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await categoryRepository.updateCategory(category);
      return _getCategories();
    });
  }

  Future<void> deleteCategory(String id) async {
    final categoryRepository = ref.watch(categoryRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await categoryRepository.deleteCategory(id);
      return _getCategories();
    });
  }
}

final categoryNotifierProvider =
    AsyncNotifierProvider<CategoryNotifier, List<Category>>(
  CategoryNotifier.new,
);
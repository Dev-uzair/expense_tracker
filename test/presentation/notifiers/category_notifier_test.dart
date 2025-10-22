import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/domain/repositories/category_repository.dart';
import 'package:expense_tracker/presentation/notifiers/category_notifier.dart';
import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/presentation/providers/providers.dart';

// Concrete mock for CategoryRepository
class TestCategoryRepository implements CategoryRepository {
  List<Category> _categories = [];

  @override
  Future<void> addCategory(Category category) async {
    _categories.add(category);
  }

  @override
  Future<void> deleteCategory(String id) async {
    _categories.removeWhere((c) => c.id == id);
  }

  @override
  Future<List<Category>> getAllCategories() async {
    return _categories;
  }

  @override
  Future<Category?> getCategory(String id) async {
    return _categories.firstWhere((c) => c.id == id);
  }

  @override
  Future<void> updateCategory(Category category) async {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
    }
  }
}

void main() {
  late TestCategoryRepository testCategoryRepository;
  late ProviderContainer container;

  setUp(() {
    testCategoryRepository = TestCategoryRepository();
    container = ProviderContainer(
      overrides: [
        categoryRepositoryProvider.overrideWithValue(testCategoryRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('CategoryNotifier', () {
    final tCategory = Category(
      id: '1',
      name: 'Food',
      type: '',
        categoryIcon: ''
    );

    test('initial state is loading and then data', () async {
      // arrange
      testCategoryRepository._categories = [tCategory];
      // act
      final listener = container.listen(categoryNotifierProvider, (previous, next) {});
      // assert
      expect(listener.read(), const AsyncLoading<List<Category>>());
      await container.read(categoryNotifierProvider.future);
      expect(listener.read().value, [tCategory]);
    });

    test('addCategory calls repository and refreshes state', () async {
      // arrange
      testCategoryRepository._categories = [];
      // act
      await container.read(categoryNotifierProvider.notifier).addCategory(tCategory);
      // assert
      expect(testCategoryRepository._categories, [tCategory]);
      expect(container.read(categoryNotifierProvider).value, [tCategory]);
    });

    test('updateCategory calls repository and refreshes state', () async {
      // arrange
      testCategoryRepository._categories = [tCategory];
      final updatedCategory = tCategory.copyWith(name: 'Groceries');
      // act
      await container.read(categoryNotifierProvider.notifier).updateCategory(updatedCategory);
      // assert
      expect(testCategoryRepository._categories, [updatedCategory]);
      expect(container.read(categoryNotifierProvider).value, [updatedCategory]);
    });

    test('deleteCategory calls repository and refreshes state', () async {
      // arrange
      testCategoryRepository._categories = [tCategory];
      // act
      await container.read(categoryNotifierProvider.notifier).deleteCategory('1');
      // assert
      expect(testCategoryRepository._categories, []);
      expect(container.read(categoryNotifierProvider).value, []);
    });
  });
}

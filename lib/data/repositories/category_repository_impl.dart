import 'package:expense_tracker/domain/repositories/category_repository.dart';
import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/data/hive_database.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final HiveDatabase _hiveDatabase;

  CategoryRepositoryImpl(this._hiveDatabase);

  @override
  Future<void> addCategory(Category category) {
    return _hiveDatabase.addCategory(category);
  }

  @override
  Future<void> deleteCategory(String id) {
    return _hiveDatabase.deleteCategory(id);
  }

  @override
  Future<List<Category>> getAllCategories() {
    return Future.value(_hiveDatabase.getAllCategories());
  }

  @override
  Future<Category?> getCategory(String id) {
    return Future.value(_hiveDatabase.getCategory(id));
  }

  @override
  Future<void> updateCategory(Category category) {
    return _hiveDatabase.updateCategory(category);
  }
}

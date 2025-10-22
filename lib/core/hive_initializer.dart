import 'package:hive_flutter/hive_flutter.dart';
import 'package:expense_tracker/domain/transaction.dart';
import 'package:expense_tracker/domain/category.dart';
import 'package:expense_tracker/domain/budget.dart';
import 'package:expense_tracker/core/default_categories.dart';
import 'package:expense_tracker/data/hive_database.dart'; // To get box names

class HiveInitializer {
  static Future<void> init() async {
    // Initialize Hive
    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(TransactionAdapter());
    Hive.registerAdapter(CategoryAdapter());
    Hive.registerAdapter(BudgetAdapter());

    // Open your boxes here with specific types
    await Hive.openBox<Transaction>(HiveDatabase.transactionBoxName);
    final categoryBox = await Hive.openBox<Category>(HiveDatabase.categoryBoxName); // Open with type and assign
    await Hive.openBox<Budget>(HiveDatabase.budgetBoxName);

    // Initialize default categories if the category box is empty
    // final categoryBox = Hive.box<Category>(HiveDatabase.categoryBoxName);
    if (categoryBox.isEmpty) {
      for (var category in defaultExpenseCategories) {
        await categoryBox.put(category.id, category);
      }
      for (var category in defaultIncomeCategories) {
        await categoryBox.put(category.id, category);
      }
    }
  }
}
import 'package:expense_tracker/domain/category.dart';
import 'package:uuid/uuid.dart';

final Uuid uuid = Uuid();

// categoryIcon values are keys into categoryIcons (lib/core/category_icons.dart).
final List<Category> defaultExpenseCategories = [
  Category(id: uuid.v4(), name: 'Food & Dining', type: 'expense', categoryIcon: 'food'),
  Category(id: uuid.v4(), name: 'Transportation', type: 'expense', categoryIcon: 'transportation'),
  Category(id: uuid.v4(), name: 'Shopping', type: 'expense', categoryIcon: 'shopping'),
  Category(id: uuid.v4(), name: 'Utilities', type: 'expense', categoryIcon: 'utilities'),
  Category(id: uuid.v4(), name: 'Rent', type: 'expense', categoryIcon: 'rent'),
  Category(id: uuid.v4(), name: 'Entertainment', type: 'expense', categoryIcon: 'entertainment'),
  Category(id: uuid.v4(), name: 'Healthcare', type: 'expense', categoryIcon: 'healthcare'),
  Category(id: uuid.v4(), name: 'Education', type: 'expense', categoryIcon: 'education'),
  Category(id: uuid.v4(), name: 'Travel', type: 'expense', categoryIcon: 'travel'),
  Category(id: uuid.v4(), name: 'Others', type: 'expense', categoryIcon: 'others'),
];

final List<Category> defaultIncomeCategories = [
  Category(id: uuid.v4(), name: 'Salary', type: 'income', categoryIcon: 'salary'),
  Category(id: uuid.v4(), name: 'Freelance', type: 'income', categoryIcon: 'freelance'),
  Category(id: uuid.v4(), name: 'Investments', type: 'income', categoryIcon: 'investments'),
  Category(id: uuid.v4(), name: 'Gifts', type: 'income', categoryIcon: 'gifts'),
  Category(id: uuid.v4(), name: 'Others', type: 'income', categoryIcon: 'others'),
];

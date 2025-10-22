import 'package:expense_tracker/domain/category.dart';
import 'package:uuid/uuid.dart';

final Uuid uuid = Uuid();

final List<Category> defaultExpenseCategories = [
  Category(id: uuid.v4(), name: 'Food & Dining', type: 'expense'),
  Category(id: uuid.v4(), name: 'Transportation', type: 'expense'),
  Category(id: uuid.v4(), name: 'Shopping', type: 'expense'),
  Category(id: uuid.v4(), name: 'Utilities', type: 'expense'),
  Category(id: uuid.v4(), name: 'Rent', type: 'expense'),
  Category(id: uuid.v4(), name: 'Entertainment', type: 'expense'),
  Category(id: uuid.v4(), name: 'Healthcare', type: 'expense'),
  Category(id: uuid.v4(), name: 'Education', type: 'expense'),
  Category(id: uuid.v4(), name: 'Travel', type: 'expense'),
  Category(id: uuid.v4(), name: 'Others', type: 'expense'),
];

final List<Category> defaultIncomeCategories = [
  Category(id: uuid.v4(), name: 'Salary', type: 'income'),
  Category(id: uuid.v4(), name: 'Freelance', type: 'income'),
  Category(id: uuid.v4(), name: 'Investments', type: 'income'),
  Category(id: uuid.v4(), name: 'Gifts', type: 'income'),
  Category(id: uuid.v4(), name: 'Others', type: 'income'),
];

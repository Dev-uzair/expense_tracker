import 'package:expense_tracker/domain/category.dart';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';

final Uuid uuid = Uuid();

final List<Category> defaultExpenseCategories = [
  Category(id: uuid.v4(), name: 'Food & Dining', type: 'expense', categoryIcon: CupertinoIcons.tuningfork.codePoint.toString()),
  Category(id: uuid.v4(), name: 'Transportation', type: 'expense', categoryIcon: CupertinoIcons.car_detailed.codePoint.toString()),
  Category(id: uuid.v4(), name: 'Shopping', type: 'expense', categoryIcon: CupertinoIcons.shopping_cart.codePoint.toString()),
  Category(id: uuid.v4(), name: 'Utilities', type: 'expense', categoryIcon: CupertinoIcons.lightbulb.codePoint.toString()),
  Category(id: uuid.v4(), name: 'Rent', type: 'expense', categoryIcon: CupertinoIcons.home.codePoint.toString()),
  Category(id: uuid.v4(), name: 'Entertainment', type: 'expense', categoryIcon: CupertinoIcons.film.codePoint.toString()),
  Category(id: uuid.v4(), name: 'Healthcare', type: 'expense', categoryIcon: CupertinoIcons.heart_circle.codePoint.toString()),
  Category(id: uuid.v4(), name: 'Education', type: 'expense', categoryIcon: CupertinoIcons.book.codePoint.toString()),
  Category(id: uuid.v4(), name: 'Travel', type: 'expense', categoryIcon: CupertinoIcons.airplane.codePoint.toString()),
  Category(id: uuid.v4(), name: 'Others', type: 'expense' , categoryIcon: CupertinoIcons.ellipsis.codePoint.toString()),
];

final List<Category> defaultIncomeCategories = [
  Category(id: uuid.v4(), name: 'Salary', type: 'income', categoryIcon: CupertinoIcons.money_dollar.codePoint.toString()),
  Category(id: uuid.v4(), name: 'Freelance', type: 'income', categoryIcon: CupertinoIcons.briefcase.codePoint.toString()),
  Category(id: uuid.v4(), name: 'Investments', type: 'income', categoryIcon: CupertinoIcons.person.codePoint.toString()),
  Category(id: uuid.v4(), name: 'Gifts', type: 'income', categoryIcon: CupertinoIcons.gift.codePoint.toString()),
  Category(id: uuid.v4(), name: 'Others', type: 'income', categoryIcon: CupertinoIcons.ellipsis.codePoint.toString()),
];
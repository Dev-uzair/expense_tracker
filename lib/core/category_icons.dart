import 'package:flutter/cupertino.dart';

// Icons are looked up by key from this const map instead of being rebuilt from
// a stored code point, so release builds can tree-shake the icon font.
const Map<String, IconData> categoryIcons = {
  'food': CupertinoIcons.tuningfork,
  'transportation': CupertinoIcons.car_detailed,
  'shopping': CupertinoIcons.shopping_cart,
  'utilities': CupertinoIcons.lightbulb,
  'rent': CupertinoIcons.home,
  'entertainment': CupertinoIcons.film,
  'healthcare': CupertinoIcons.heart_circle,
  'education': CupertinoIcons.book,
  'travel': CupertinoIcons.airplane,
  'salary': CupertinoIcons.money_dollar,
  'freelance': CupertinoIcons.briefcase,
  'investments': CupertinoIcons.person,
  'gifts': CupertinoIcons.gift,
  'others': CupertinoIcons.ellipsis,
};

const IconData fallbackCategoryIcon = CupertinoIcons.question_circle;

IconData categoryIconData(String? iconKey) {
  if (iconKey == null) return fallbackCategoryIcon;
  final icon = categoryIcons[iconKey];
  if (icon != null) return icon;

  // Categories seeded by earlier builds stored the icon's code point.
  final codePoint = int.tryParse(iconKey);
  if (codePoint != null) {
    for (final icon in categoryIcons.values) {
      if (icon.codePoint == codePoint) return icon;
    }
  }
  return fallbackCategoryIcon;
}

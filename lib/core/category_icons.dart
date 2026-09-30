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
  // Extra icons for custom categories.
  'groceries': CupertinoIcons.bag,
  'personal_care': CupertinoIcons.sparkles,
  'pets': CupertinoIcons.paw,
  'fitness': CupertinoIcons.sportscourt,
  'phone': CupertinoIcons.phone,
  'internet': CupertinoIcons.wifi,
  'insurance': CupertinoIcons.shield,
  'family': CupertinoIcons.person_2,
  'bus': CupertinoIcons.bus,
  'repairs': CupertinoIcons.wrench,
  'beauty': CupertinoIcons.scissors,
  'medicine': CupertinoIcons.capsule,
  'music': CupertinoIcons.music_note,
  'games': CupertinoIcons.game_controller,
  'tv': CupertinoIcons.tv,
  'electronics': CupertinoIcons.desktopcomputer,
  'water': CupertinoIcons.drop,
  'gas': CupertinoIcons.flame,
  'electricity': CupertinoIcons.bolt,
  'card': CupertinoIcons.creditcard,
  'savings': CupertinoIcons.money_dollar_circle,
  'business': CupertinoIcons.chart_bar,
  'crypto': CupertinoIcons.bitcoin,
  'interest': CupertinoIcons.percent,
  'charity': CupertinoIcons.heart,
  'tag': CupertinoIcons.tag,
  'star': CupertinoIcons.star,
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

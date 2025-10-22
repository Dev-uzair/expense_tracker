import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/domain/category.dart';

void main() {
  group('Category', () {
    test('fromJson and toJson', () {
      final category = Category(
        id: '1',
        name: 'Food',
        type: ''
      );

      final json = category.toJson();
      final fromJson = Category.fromJson(json);

      expect(fromJson.id, category.id);
      expect(fromJson.name, category.name);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:expense_tracker/data/repositories/category_repository_impl.dart';
import 'package:expense_tracker/domain/category.dart';
import 'transaction_repository_impl_test.mocks.dart';

void main() {
  late MockHiveDatabase mockHiveDatabase;
  late CategoryRepositoryImpl categoryRepository;

  setUp(() {
    mockHiveDatabase = MockHiveDatabase();
    categoryRepository = CategoryRepositoryImpl(mockHiveDatabase);
  });

  group('CategoryRepositoryImpl', () {
    final tCategory = Category(
      id: '1',
      name: 'Food',
      type: ''
    );

    test('should call addCategory on the database', () async {
      // arrange
      when(mockHiveDatabase.addCategory(any)).thenAnswer((_) async => {});
      // act
      await categoryRepository.addCategory(tCategory);
      // assert
      verify(mockHiveDatabase.addCategory(tCategory));
      verifyNoMoreInteractions(mockHiveDatabase);
    });

    test('should call deleteCategory on the database', () async {
      // arrange
      when(mockHiveDatabase.deleteCategory(any)).thenAnswer((_) async => {});
      // act
      await categoryRepository.deleteCategory('1');
      // assert
      verify(mockHiveDatabase.deleteCategory('1'));
      verifyNoMoreInteractions(mockHiveDatabase);
    });

    test('should return a list of categories from the database', () async {
      // arrange
      when(mockHiveDatabase.getAllCategories()).thenReturn([tCategory]);
      // act
      final result = await categoryRepository.getAllCategories();
      // assert
      expect(result, [tCategory]);
      verify(mockHiveDatabase.getAllCategories());
      verifyNoMoreInteractions(mockHiveDatabase);
    });

    test('should return a category from the database', () async {
      // arrange
      when(mockHiveDatabase.getCategory(any)).thenReturn(tCategory);
      // act
      final result = await categoryRepository.getCategory('1');
      // assert
      expect(result, tCategory);
      verify(mockHiveDatabase.getCategory('1'));
      verifyNoMoreInteractions(mockHiveDatabase);
    });

    test('should call updateCategory on the database', () async {
      // arrange
      when(mockHiveDatabase.updateCategory(any)).thenAnswer((_) async => {});
      // act
      await categoryRepository.updateCategory(tCategory);
      // assert
      verify(mockHiveDatabase.updateCategory(tCategory));
      verifyNoMoreInteractions(mockHiveDatabase);
    });
  });
}

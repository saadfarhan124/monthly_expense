import 'category_model.dart';
import 'category_repository.dart';

class CategoryService {
  final CategoryRepository _repo;
  
  CategoryService(this._repo);

  Stream<List<Category>> getCategories(String userId) => _repo.getCategories(userId);
  
  Future<void> addCategory(Category category) => _repo.addCategory(category);
  
  Future<void> updateCategory(Category category) => _repo.updateCategory(category);
  
  Future<void> deleteCategory(String categoryId) => _repo.deleteCategory(categoryId);
  
  Future<void> initializeDefaultCategories(String userId) => _repo.initializeDefaultCategories(userId);

  Future<void> addCustomCategory(String name, String icon, String color, String userId) async {
    final category = Category(
      id: '',
      name: name,
      icon: icon,
      color: color,
      userId: userId,
      isDefault: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _repo.addCategory(category);
  }
} 
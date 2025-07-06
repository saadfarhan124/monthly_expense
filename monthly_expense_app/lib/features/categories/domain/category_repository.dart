import 'package:cloud_firestore/cloud_firestore.dart';
import 'category_model.dart';

class CategoryRepository {
  final _collection = FirebaseFirestore.instance.collection('categories');

  Stream<List<Category>> getCategories(String userId) {
    return _collection.where('userId', isEqualTo: userId).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList()
        ..sort((a, b) => a.name.compareTo(b.name)),
    );
  }

  Future<void> addCategory(Category category) async {
    await _collection.add(category.toFirestore());
  }

  Future<void> updateCategory(Category category) async {
    await _collection.doc(category.id).update(category.toFirestore());
  }

  Future<void> deleteCategory(String categoryId) async {
    await _collection.doc(categoryId).delete();
  }

  Future<void> initializeDefaultCategories(String userId) async {
    final defaultCategories = Category.getDefaultCategories(userId);
    
    // Check if categories already exist for this user
    final existingCategories = await _collection
        .where('userId', isEqualTo: userId)
        .where('isDefault', isEqualTo: true)
        .get();
    
    if (existingCategories.docs.isEmpty) {
      // Add all default categories for new users
      for (final category in defaultCategories) {
        await _collection.add(category.toFirestore());
      }
    } else {
      // For existing users, check if new default categories need to be added
      final existingCategoryNames = existingCategories.docs
          .map((doc) => doc.data()['name'] as String)
          .toSet();
      
      for (final category in defaultCategories) {
        if (!existingCategoryNames.contains(category.name)) {
          // Add missing default category
          await _collection.add(category.toFirestore());
        }
      }
    }
  }
} 
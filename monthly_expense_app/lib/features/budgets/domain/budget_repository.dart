import 'package:cloud_firestore/cloud_firestore.dart';
import 'budget_model.dart';

class BudgetRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all budgets for a user
  Stream<List<Budget>> getBudgets(String userId) {
    return _firestore
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Budget.fromFirestore(doc))
            .toList());
  }

  // Get budget by ID
  Future<Budget?> getBudget(String budgetId) async {
    try {
      final doc = await _firestore.collection('budgets').doc(budgetId).get();
      if (doc.exists) {
        return Budget.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting budget: $e');
      return null;
    }
  }

  // Get budgets for a specific category
  Stream<List<Budget>> getBudgetsByCategory(String userId, String categoryId) {
    return _firestore
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .where('categoryId', isEqualTo: categoryId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Budget.fromFirestore(doc))
            .toList());
  }

  // Get active budgets for current period
  Stream<List<Budget>> getActiveBudgets(String userId) {
    final now = DateTime.now();
    print('DEBUG: getActiveBudgets called for user: $userId, now: $now');
    return _firestore
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .handleError((error) {
          print('DEBUG: Firestore query error: $error');
          // Return empty list on error instead of throwing
          return const Stream.empty();
        })
        .map((snapshot) {
          print('DEBUG: Firestore returned ${snapshot.docs.length} documents');
          final budgets = snapshot.docs
              .map((doc) => Budget.fromFirestore(doc))
              .where((budget) => 
                  budget.startDate.isBefore(now.add(const Duration(days: 1))) &&
                  budget.endDate.isAfter(now.subtract(const Duration(days: 1))))
              .toList();
          print('DEBUG: After date filtering: ${budgets.length} budgets');
          return budgets;
        });
  }

  // Add a new budget
  Future<void> addBudget(Budget budget) async {
    try {
      final docRef = _firestore.collection('budgets').doc();
      final budgetWithId = budget.copyWith(id: docRef.id);
      await docRef.set(budgetWithId.toFirestore());
    } catch (e) {
      print('Error adding budget: $e');
      rethrow;
    }
  }

  // Update an existing budget
  Future<void> updateBudget(Budget budget) async {
    try {
      final updatedBudget = budget.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('budgets')
          .doc(budget.id)
          .update(updatedBudget.toFirestore());
    } catch (e) {
      print('Error updating budget: $e');
      rethrow;
    }
  }

  // Delete a budget (soft delete by setting isActive to false)
  Future<void> deleteBudget(String budgetId) async {
    try {
      await _firestore
          .collection('budgets')
          .doc(budgetId)
          .update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error deleting budget: $e');
      rethrow;
    }
  }

  // Hard delete a budget
  Future<void> hardDeleteBudget(String budgetId) async {
    try {
      await _firestore.collection('budgets').doc(budgetId).delete();
    } catch (e) {
      print('Error hard deleting budget: $e');
      rethrow;
    }
  }

  // Check if budget exists for category in current period
  Future<bool> budgetExistsForCategory(String userId, String categoryId, BudgetPeriod period) async {
    try {
      final now = DateTime.now();
      final query = _firestore
          .collection('budgets')
          .where('userId', isEqualTo: userId)
          .where('categoryId', isEqualTo: categoryId)
          .where('period', isEqualTo: period.toString().split('.').last)
          .where('isActive', isEqualTo: true)
          .where('startDate', isLessThanOrEqualTo: now)
          .where('endDate', isGreaterThanOrEqualTo: now);

      final snapshot = await query.get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking budget existence: $e');
      return false;
    }
  }

  // Get budget statistics for a user
  Future<Map<String, dynamic>> getBudgetStatistics(String userId) async {
    try {
      final now = DateTime.now();
      final activeBudgets = await _firestore
          .collection('budgets')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      double totalBudget = 0.0;
      int activeCount = 0;
      int exceededCount = 0;

      for (final doc in activeBudgets.docs) {
        final budget = Budget.fromFirestore(doc);
        // Filter by date range in application layer
        if (budget.startDate.isBefore(now.add(const Duration(days: 1))) &&
            budget.endDate.isAfter(now.subtract(const Duration(days: 1)))) {
          totalBudget += budget.amount;
          activeCount++;
        }
      }

      return {
        'totalBudget': totalBudget,
        'activeCount': activeCount,
        'exceededCount': exceededCount,
      };
    } catch (e) {
      print('Error getting budget statistics: $e');
      return {
        'totalBudget': 0.0,
        'activeCount': 0,
        'exceededCount': 0,
      };
    }
  }
} 
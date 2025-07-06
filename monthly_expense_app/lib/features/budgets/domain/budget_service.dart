import 'package:cloud_firestore/cloud_firestore.dart';
import 'budget_model.dart';
import 'budget_repository.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/domain/transaction_repository.dart';
import '../../categories/domain/category_model.dart';
import '../../categories/domain/category_repository.dart';

class BudgetService {
  final BudgetRepository _budgetRepo;
  final TransactionRepository _transactionRepo;
  final CategoryRepository _categoryRepo;

  // Cache for transactions and categories
  List<TransactionModel> _cachedTransactions = [];
  List<Category> _cachedCategories = [];
  bool _isTransactionsLoaded = false;
  bool _isCategoriesLoaded = false;

  BudgetService(this._budgetRepo, this._transactionRepo, this._categoryRepo);

  // Get all budgets for a user
  Stream<List<Budget>> getBudgets(String userId) => _budgetRepo.getBudgets(userId);

  // Get active budgets for current period
  Stream<List<Budget>> getActiveBudgets(String userId) => _budgetRepo.getActiveBudgets(userId);

  // Get budgets for a specific category
  Stream<List<Budget>> getBudgetsByCategory(String userId, String categoryId) =>
      _budgetRepo.getBudgetsByCategory(userId, categoryId);

  // Initialize cache for a user
  Future<void> initializeCache(String userId) async {
    if (!_isTransactionsLoaded) {
      final transactions = await _transactionRepo.getTransactions(userId).first;
      _cachedTransactions = transactions;
      _isTransactionsLoaded = true;
    }

    if (!_isCategoriesLoaded) {
      final categories = await _categoryRepo.getCategories(userId).first;
      _cachedCategories = categories;
      _isCategoriesLoaded = true;
    }
  }

  // Clear cache (useful for testing or when data becomes stale)
  void clearCache() {
    _cachedTransactions.clear();
    _cachedCategories.clear();
    _isTransactionsLoaded = false;
    _isCategoriesLoaded = false;
  }

  // Check if cache is ready
  bool get isCacheReady => _isTransactionsLoaded && _isCategoriesLoaded;

  // Add a new budget
  Future<bool> addBudget({
    required String userId,
    required String categoryId,
    required double amount,
    required String currency,
    required BudgetPeriod period,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Initialize cache if needed
      await initializeCache(userId);

      // Get category details from cache
      final category = _getCachedCategory(categoryId);
      if (category == null) {
        print('Debug: Category not found for ID: $categoryId');
        print('Debug: Available categories: ${_cachedCategories.map((c) => '${c.id}: ${c.name}').join(', ')}');
        throw Exception('Category not found. Please try again.');
      }

      // Check if budget already exists for this category and period
      final exists = await _budgetRepo.budgetExistsForCategory(userId, categoryId, period);
      if (exists) {
        throw Exception('Budget already exists for this category and period');
      }

      // Calculate start and end dates based on period
      final now = DateTime.now();
      final calculatedStartDate = startDate ?? _calculateStartDate(period, now);
      final calculatedEndDate = endDate ?? _calculateEndDate(period, calculatedStartDate);

      final budget = Budget(
        id: '',
        userId: userId,
        categoryId: categoryId,
        categoryName: category.name,
        categoryIcon: category.icon,
        categoryColor: category.color,
        amount: amount,
        currency: currency,
        period: period,
        startDate: calculatedStartDate,
        endDate: calculatedEndDate,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      await _budgetRepo.addBudget(budget);
      return true;
    } catch (e) {
      print('Error adding budget: $e');
      rethrow;
    }
  }

  // Update an existing budget
  Future<bool> updateBudget(Budget budget) async {
    try {
      await _budgetRepo.updateBudget(budget);
      return true;
    } catch (e) {
      print('Error updating budget: $e');
      rethrow;
    }
  }

  // Delete a budget
  Future<bool> deleteBudget(String budgetId) async {
    try {
      await _budgetRepo.deleteBudget(budgetId);
      return true;
    } catch (e) {
      print('Error deleting budget: $e');
      rethrow;
    }
  }

  // Get budget with spending data
  Future<BudgetWithSpending> getBudgetWithSpending(String budgetId, String userId) async {
    try {
      await initializeCache(userId);
      
      final budget = await _budgetRepo.getBudget(budgetId);
      if (budget == null) {
        throw Exception('Budget not found');
      }

      final spending = _calculateSpendingForBudgetFromCache(budget);
      return BudgetWithSpending(budget: budget, spentAmount: spending);
    } catch (e) {
      print('Error getting budget with spending: $e');
      rethrow;
    }
  }

  // Get all budgets with spending data (optimized with caching)
  Stream<List<BudgetWithSpending>> getBudgetsWithSpending(String userId) {
    print('DEBUG: getBudgetsWithSpending called for user: $userId');
    return _budgetRepo.getActiveBudgets(userId).asyncMap((budgets) async {
      print('DEBUG: Got ${budgets.length} budgets from repository');
      
      // Ensure cache is initialized
      if (!_isTransactionsLoaded || !_isCategoriesLoaded) {
        print('DEBUG: Cache not ready, initializing...');
        await initializeCache(userId);
      }
      
      print('DEBUG: Cache status - Transactions: $_isTransactionsLoaded, Categories: $_isCategoriesLoaded');
      print('DEBUG: Cached transactions: ${_cachedTransactions.length}');
      
      final budgetsWithSpending = <BudgetWithSpending>[];
      
      for (final budget in budgets) {
        final spending = _calculateSpendingForBudgetFromCache(budget);
        print('DEBUG: Budget ${budget.categoryName} - spent: $spending');
        budgetsWithSpending.add(BudgetWithSpending(budget: budget, spentAmount: spending));
      }
      
      print('DEBUG: Returning ${budgetsWithSpending.length} budgets with spending data');
      return budgetsWithSpending;
    }).handleError((error) {
      print('DEBUG: Error in getBudgetsWithSpending: $error');
      // Return empty list on error instead of throwing
      return <BudgetWithSpending>[];
    });
  }

  // Get budget statistics (optimized with caching)
  Future<BudgetStatistics> getBudgetStatistics(String userId) async {
    try {
      await initializeCache(userId);
      
      final stats = await _budgetRepo.getBudgetStatistics(userId);
      final budgetsWithSpending = await _budgetRepo.getActiveBudgets(userId).first;
      
      double totalSpent = 0.0;
      int exceededCount = 0;
      int nearLimitCount = 0;

      for (final budget in budgetsWithSpending) {
        final spending = _calculateSpendingForBudgetFromCache(budget);
        totalSpent += spending;
        
        if (budget.isExceeded(spending)) {
          exceededCount++;
        } else if (budget.isNearLimit(spending)) {
          nearLimitCount++;
        }
      }

      return BudgetStatistics(
        totalBudget: stats['totalBudget'] ?? 0.0,
        totalSpent: totalSpent,
        activeCount: stats['activeCount'] ?? 0,
        exceededCount: exceededCount,
        nearLimitCount: nearLimitCount,
      );
    } catch (e) {
      print('Error getting budget statistics: $e');
      return BudgetStatistics(
        totalBudget: 0.0,
        totalSpent: 0.0,
        activeCount: 0,
        exceededCount: 0,
        nearLimitCount: 0,
      );
    }
  }

  // Calculate spending for a budget from cache (optimized)
  double _calculateSpendingForBudgetFromCache(Budget budget) {
    double totalSpent = 0.0;
    
    for (final transaction in _cachedTransactions) {
      if (transaction.type == TransactionType.expense &&
          transaction.categoryId == budget.categoryId &&
          transaction.date.isAfter(budget.startDate.subtract(const Duration(days: 1))) &&
          transaction.date.isBefore(budget.endDate.add(const Duration(days: 1)))) {
        totalSpent += transaction.amount;
      }
    }
    
    return totalSpent;
  }

  // Get category details from cache
  Category? _getCachedCategory(String categoryId) {
    try {
      return _cachedCategories.firstWhere((cat) => cat.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  // Calculate start date based on period
  DateTime _calculateStartDate(BudgetPeriod period, DateTime now) {
    switch (period) {
      case BudgetPeriod.weekly:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return DateTime(weekStart.year, weekStart.month, weekStart.day);
      case BudgetPeriod.monthly:
        return DateTime(now.year, now.month, 1);
      case BudgetPeriod.yearly:
        return DateTime(now.year, 1, 1);
    }
  }

  // Calculate end date based on period
  DateTime _calculateEndDate(BudgetPeriod period, DateTime startDate) {
    switch (period) {
      case BudgetPeriod.weekly:
        return startDate.add(const Duration(days: 6));
      case BudgetPeriod.monthly:
        return DateTime(startDate.year, startDate.month + 1, 0);
      case BudgetPeriod.yearly:
        return DateTime(startDate.year, 12, 31);
    }
  }
}

// Data class for budget with spending information
class BudgetWithSpending {
  final Budget budget;
  final double spentAmount;

  BudgetWithSpending({
    required this.budget,
    required this.spentAmount,
  });

  double get remainingBudget => budget.getRemainingBudget(spentAmount);
  double get usagePercentage => budget.getUsagePercentage(spentAmount);
  bool get isExceeded => budget.isExceeded(spentAmount);
  bool get isNearLimit => budget.isNearLimit(spentAmount);
  String get statusColor => budget.getStatusColor(spentAmount);
}

// Data class for budget statistics
class BudgetStatistics {
  final double totalBudget;
  final double totalSpent;
  final int activeCount;
  final int exceededCount;
  final int nearLimitCount;

  BudgetStatistics({
    required this.totalBudget,
    required this.totalSpent,
    required this.activeCount,
    required this.exceededCount,
    required this.nearLimitCount,
  });

  double get totalRemaining => (totalBudget - totalSpent).clamp(0.0, double.infinity);
  double get overallUsagePercentage => totalBudget > 0 ? (totalSpent / totalBudget * 100) : 0.0;
  bool get isOverallExceeded => totalSpent > totalBudget;
} 
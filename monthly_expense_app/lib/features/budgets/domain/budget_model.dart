import 'package:cloud_firestore/cloud_firestore.dart';

enum BudgetPeriod {
  monthly,
  weekly,
  yearly,
}

class Budget {
  final String id;
  final String userId;
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final String categoryColor;
  final double amount;
  final String currency;
  final BudgetPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Budget({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.amount,
    required this.currency,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create from Firestore document
  factory Budget.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Budget(
      id: doc.id,
      userId: data['userId'] ?? '',
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? '',
      categoryIcon: data['categoryIcon'] ?? '',
      categoryColor: data['categoryColor'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'USD',
      period: BudgetPeriod.values.firstWhere(
        (e) => e.toString().split('.').last == (data['period'] ?? 'monthly'),
        orElse: () => BudgetPeriod.monthly,
      ),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryIcon': categoryIcon,
      'categoryColor': categoryColor,
      'amount': amount,
      'currency': currency,
      'period': period.toString().split('.').last,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create a copy with updated fields
  Budget copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    double? amount,
    String? currency,
    BudgetPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Calculate remaining budget
  double getRemainingBudget(double spentAmount) {
    return (amount - spentAmount).clamp(0.0, double.infinity);
  }

  // Calculate budget usage percentage
  double getUsagePercentage(double spentAmount) {
    if (amount == 0) return 0.0;
    return ((spentAmount / amount) * 100).clamp(0.0, 100.0);
  }

  // Check if budget is exceeded
  bool isExceeded(double spentAmount) {
    return spentAmount > amount;
  }

  // Check if budget is close to being exceeded (80% threshold)
  bool isNearLimit(double spentAmount) {
    return getUsagePercentage(spentAmount) >= 80.0;
  }

  // Get budget status color
  String getStatusColor(double spentAmount) {
    if (isExceeded(spentAmount)) return '#EF4444'; // Red
    if (isNearLimit(spentAmount)) return '#F59E0B'; // Orange
    return '#10B981'; // Green
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Budget &&
        other.id == id &&
        other.userId == userId &&
        other.categoryId == categoryId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ userId.hashCode ^ categoryId.hashCode;
  }

  @override
  String toString() {
    return 'Budget(id: $id, categoryName: $categoryName, amount: $amount, currency: $currency, period: $period)';
  }
} 
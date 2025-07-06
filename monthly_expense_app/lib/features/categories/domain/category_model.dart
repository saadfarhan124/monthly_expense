import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  final String icon;
  final String color;
  final String userId;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.userId,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create from Firestore document
  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      name: data['name'] ?? '',
      icon: data['icon'] ?? '📁',
      color: data['color'] ?? '#6366F1',
      userId: data['userId'] ?? '',
      isDefault: data['isDefault'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'icon': icon,
      'color': color,
      'userId': userId,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create a copy with updated fields
  Category copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    String? userId,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      userId: userId ?? this.userId,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Predefined categories
  static List<Category> getDefaultCategories(String userId) {
    final now = DateTime.now();
    return [
      Category(
        id: 'car',
        name: 'Car',
        icon: '🚗',
        color: '#EF4444',
        userId: userId,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'home',
        name: 'Home',
        icon: '🏠',
        color: '#10B981',
        userId: userId,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'rent',
        name: 'Rent',
        icon: '🏢',
        color: '#F59E0B',
        userId: userId,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'medical',
        name: 'Medical',
        icon: '🏥',
        color: '#3B82F6',
        userId: userId,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'family',
        name: 'Family',
        icon: '👨‍👩‍👧‍👦',
        color: '#8B5CF6',
        userId: userId,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'personal',
        name: 'Personal',
        icon: '👤',
        color: '#6366F1',
        userId: userId,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'mobile',
        name: 'Mobile',
        icon: '📱',
        color: '#06B6D4',
        userId: userId,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'fuel',
        name: 'Fuel',
        icon: '⛽',
        color: '#F97316',
        userId: userId,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'bills',
        name: 'Bills',
        icon: '📄',
        color: '#84CC16',
        userId: userId,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'other',
        name: 'Other Expenses',
        icon: '📁',
        color: '#6B7280',
        userId: userId,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'transfer',
        name: 'Transfer',
        icon: '💸',
        color: '#059669',
        userId: userId,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'transfer_fees',
        name: 'Transfer Fees',
        icon: '💳',
        color: '#DC2626',
        userId: userId,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'lending',
        name: 'Lending',
        icon: '🤝',
        color: '#059669',
        userId: userId,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 'borrowing',
        name: 'Borrowing',
        icon: '📋',
        color: '#DC2626',
        userId: userId,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
} 
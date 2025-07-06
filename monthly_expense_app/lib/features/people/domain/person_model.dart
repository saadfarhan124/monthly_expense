import 'package:cloud_firestore/cloud_firestore.dart';

class Person {
  final String id;
  final String name;
  final String icon;
  final String color;
  final String userId;
  final double balance; // Positive = they owe you, Negative = you owe them
  final DateTime createdAt;
  final DateTime updatedAt;

  const Person({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.userId,
    required this.balance,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create from Firestore document
  factory Person.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Person(
      id: doc.id,
      name: data['name'] ?? '',
      icon: data['icon'] ?? '👤',
      color: data['color'] ?? '#6366F1',
      userId: data['userId'] ?? '',
      balance: (data['balance'] ?? 0.0).toDouble(),
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
      'balance': balance,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create a copy with updated fields
  Person copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    String? userId,
    double? balance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get display text for balance
  String get balanceDisplayText {
    if (balance == 0) return 'Settled up';
    if (balance > 0) return 'Owes you ${balance.toStringAsFixed(2)}';
    return 'You owe ${balance.abs().toStringAsFixed(2)}';
  }

  // Get balance color
  String get balanceColor {
    if (balance == 0) return '#6B7280'; // Gray for settled
    if (balance > 0) return '#10B981'; // Green for they owe you
    return '#EF4444'; // Red for you owe them
  }
} 
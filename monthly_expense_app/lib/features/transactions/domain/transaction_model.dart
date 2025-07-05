import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  expense,
  income,
}

class TransactionModel {
  final String id;
  final String accountId;
  final String categoryId;
  final double amount;
  final String description;
  final TransactionType type;
  final String userId;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionModel({
    required this.id,
    required this.accountId,
    required this.categoryId,
    required this.amount,
    required this.description,
    required this.type,
    required this.userId,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create from Firestore document
  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      accountId: data['accountId'] ?? '',
      categoryId: data['categoryId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      description: data['description'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'expense'),
        orElse: () => TransactionType.expense,
      ),
      userId: data['userId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'accountId': accountId,
      'categoryId': categoryId,
      'amount': amount,
      'description': description,
      'type': type.toString().split('.').last,
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create a copy with updated fields
  TransactionModel copyWith({
    String? id,
    String? accountId,
    String? categoryId,
    double? amount,
    String? description,
    TransactionType? type,
    String? userId,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 
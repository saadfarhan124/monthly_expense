import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  expense,
  income,
  transfer,
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
  
  // Transfer-specific fields
  final String? toAccountId;
  final double? exchangeRate;
  final double? transferFee;
  final String? transferFeeCurrency;

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
    this.toAccountId,
    this.exchangeRate,
    this.transferFee,
    this.transferFeeCurrency,
  });

  // Create from Firestore document
  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final exchangeRate = data['exchangeRate']?.toDouble();
    final transferFee = data['transferFee']?.toDouble();
    
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
      toAccountId: data['toAccountId'],
      exchangeRate: exchangeRate,
      transferFee: transferFee,
      transferFeeCurrency: data['transferFeeCurrency'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    final data = {
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
    
    // Add transfer-specific fields if this is a transfer
    if (type == TransactionType.transfer) {
      if (toAccountId != null) data['toAccountId'] = toAccountId as String;
      if (exchangeRate != null) {
        data['exchangeRate'] = exchangeRate as double;
      }
      if (transferFee != null) {
        data['transferFee'] = transferFee as double;
      }
      if (transferFeeCurrency != null) data['transferFeeCurrency'] = transferFeeCurrency as String;
    }
    
    return data;
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
    String? toAccountId,
    double? exchangeRate,
    double? transferFee,
    String? transferFeeCurrency,
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
      toAccountId: toAccountId ?? this.toAccountId,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      transferFee: transferFee ?? this.transferFee,
      transferFeeCurrency: transferFeeCurrency ?? this.transferFeeCurrency,
    );
  }
  
  // Check if this is a transfer
  bool get isTransfer => type == TransactionType.transfer;
  
  // Get the effective amount for the source account (including fees)
  double get sourceAmount {
    if (!isTransfer) return amount;
    return amount + (transferFee ?? 0.0);
  }
  
  // Get the amount that will be added to the destination account
  double get destinationAmount {
    if (!isTransfer) return amount;
    return exchangeRate != null ? amount * exchangeRate! : amount;
  }
} 
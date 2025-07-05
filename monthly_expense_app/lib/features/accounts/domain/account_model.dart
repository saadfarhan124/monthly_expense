import 'package:cloud_firestore/cloud_firestore.dart';

enum AccountType {
  cash,
  bank,
  creditCard,
  savings,
  investment,
}

class Account {
  final String id;
  final String name;
  final String currency;
  final double balance;
  final AccountType type;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;
  final String? accountNumber;
  final String? bankName;

  const Account({
    required this.id,
    required this.name,
    required this.currency,
    required this.balance,
    required this.type,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.accountNumber,
    this.bankName,
  });

  // Create from Firestore document
  factory Account.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Account(
      id: doc.id,
      name: data['name'] ?? '',
      currency: data['currency'] ?? 'USD',
      balance: (data['balance'] ?? 0.0).toDouble(),
      type: AccountType.values.firstWhere(
        (e) => e.toString() == 'AccountType.${data['type'] ?? 'cash'}',
        orElse: () => AccountType.cash,
      ),
      userId: data['userId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      description: data['description'],
      accountNumber: data['accountNumber'],
      bankName: data['bankName'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'currency': currency,
      'balance': balance,
      'type': type.toString().split('.').last,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'description': description,
      'accountNumber': accountNumber,
      'bankName': bankName,
    };
  }

  // Create a copy with updated fields
  Account copyWith({
    String? id,
    String? name,
    String? currency,
    double? balance,
    AccountType? type,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    String? accountNumber,
    String? bankName,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      currency: currency ?? this.currency,
      balance: balance ?? this.balance,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      accountNumber: accountNumber ?? this.accountNumber,
      bankName: bankName ?? this.bankName,
    );
  }

  // Get icon for account type
  String get icon {
    switch (type) {
      case AccountType.cash:
        return '💵';
      case AccountType.bank:
        return '🏦';
      case AccountType.creditCard:
        return '💳';
      case AccountType.savings:
        return '💰';
      case AccountType.investment:
        return '📈';
    }
  }

  // Get display name with type
  String get displayName {
    return '$icon $name';
  }
} 
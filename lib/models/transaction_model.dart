import 'package:uuid/uuid.dart';
import '../database/db_constants.dart';

enum TransactionType {
  income,
  expense,
  ccPayment,
}

extension TransactionTypeInfo on TransactionType {
  String get label {
    switch (this) {
      case TransactionType.income:
        return 'આવક';
      case TransactionType.expense:
        return 'ખર્ચ';
      case TransactionType.ccPayment:
        return 'ક્રેડિટ કાર્ડ બિલ';
    }
  }
}

class TransactionModel {
  final String id;
  final String userId;
  final String title;
  final String? subtitle;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String categoryName;
  final String categoryEmoji;
  final String accountId;
  final DateTime date;
  final String? note;
  final DateTime createdAt;

  TransactionModel({
    String? id,
    required this.userId,
    required this.title,
    this.subtitle,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.categoryName,
    required this.categoryEmoji,
    required this.accountId,
    required this.date,
    this.note,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  String get displayCategory => categoryName;
  String get displayCategoryIcon => categoryEmoji;

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;
  bool get isCcPayment => type == TransactionType.ccPayment;

  TransactionModel copyWith({
    String? userId,
    String? title,
    String? subtitle,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? categoryName,
    String? categoryEmoji,
    String? accountId,
    DateTime? date,
    String? note,
  }) {
    return TransactionModel(
      id: id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryEmoji: categoryEmoji ?? this.categoryEmoji,
      accountId: accountId ?? this.accountId,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        DbConstants.cId: id,
        DbConstants.cUserId: userId,
        DbConstants.cTxnTitle: title,
        'subtitle': subtitle,
        DbConstants.cTxnAmount: amount,
        DbConstants.cTxnType: type.name,
        'category_id': categoryId,
        'category_name': categoryName,
        'category_emoji': categoryEmoji,
        DbConstants.cTxnAccId: accountId,
        DbConstants.cTxnDate: date.toIso8601String(),
        DbConstants.cTxnNote: note,
        DbConstants.cCreatedAt: createdAt.toIso8601String(),
      };

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    final rawType = (map[DbConstants.cTxnType] ?? 'expense').toString();

    return TransactionModel(
      id: map[DbConstants.cId],
      userId: map[DbConstants.cUserId] ?? '',
      title: map[DbConstants.cTxnTitle] ?? '',
      subtitle: map['subtitle'],
      amount: ((map[DbConstants.cTxnAmount] ?? 0) as num).toDouble(),
      type: _parseTransactionType(rawType),
      categoryId: map['category_id'] ?? '',
      categoryName: map['category_name'] ?? 'કેટેગરી',
      categoryEmoji: map['category_emoji'] ?? '📁',
      accountId: map[DbConstants.cTxnAccId] ?? '',
      date: DateTime.parse(map[DbConstants.cTxnDate]),
      note: map[DbConstants.cTxnNote],
      createdAt: DateTime.parse(map[DbConstants.cCreatedAt]),
    );
  }

  static TransactionType _parseTransactionType(String raw) {
    for (final type in TransactionType.values) {
      if (type.name == raw) return type;
    }
    return TransactionType.expense;
  }
}

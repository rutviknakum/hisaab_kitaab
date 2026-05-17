import 'package:uuid/uuid.dart';
import '../database/db_constants.dart';

enum TransactionType { income, expense }

enum TransactionCategory {
  salary,
  business,
  investment,
  gift,
  otherIncome,
  food,
  transport,
  shopping,
  health,
  education,
  entertainment,
  rent,
  electricity,
  mobile,
  grocery,
  otherExpense,
}

extension CategoryInfo on TransactionCategory {
  String get label {
    switch (this) {
      case TransactionCategory.salary:
        return 'પગાર';
      case TransactionCategory.business:
        return 'ધંધો';
      case TransactionCategory.investment:
        return 'રોકાણ';
      case TransactionCategory.gift:
        return 'ભેટ';
      case TransactionCategory.otherIncome:
        return 'અન્ય આવક';
      case TransactionCategory.food:
        return 'ખાણી-પીણી';
      case TransactionCategory.transport:
        return 'વાહન-વ્યવહાર';
      case TransactionCategory.shopping:
        return 'શોપિંગ';
      case TransactionCategory.health:
        return 'આરોગ્ય';
      case TransactionCategory.education:
        return 'શિક્ષણ';
      case TransactionCategory.entertainment:
        return 'મનોરંજન';
      case TransactionCategory.rent:
        return 'ભાડું';
      case TransactionCategory.electricity:
        return 'વીજળી/પાણી';
      case TransactionCategory.mobile:
        return 'મોબાઈલ/ઇન્ટરનેટ';
      case TransactionCategory.grocery:
        return 'કરિયાણા';
      case TransactionCategory.otherExpense:
        return 'અન્ય ખર્ચ';
    }
  }

  String get icon {
    switch (this) {
      case TransactionCategory.salary:
        return '💼';
      case TransactionCategory.business:
        return '🏪';
      case TransactionCategory.investment:
        return '📈';
      case TransactionCategory.gift:
        return '🎁';
      case TransactionCategory.otherIncome:
        return '💰';
      case TransactionCategory.food:
        return '🍽️';
      case TransactionCategory.transport:
        return '🚗';
      case TransactionCategory.shopping:
        return '🛍️';
      case TransactionCategory.health:
        return '🏥';
      case TransactionCategory.education:
        return '📚';
      case TransactionCategory.entertainment:
        return '🎬';
      case TransactionCategory.rent:
        return '🏠';
      case TransactionCategory.electricity:
        return '⚡';
      case TransactionCategory.mobile:
        return '📱';
      case TransactionCategory.grocery:
        return '🛒';
      case TransactionCategory.otherExpense:
        return '📦';
    }
  }

  TransactionType get transactionType {
    const incomeCategories = [
      TransactionCategory.salary,
      TransactionCategory.business,
      TransactionCategory.investment,
      TransactionCategory.gift,
      TransactionCategory.otherIncome,
    ];
    return incomeCategories.contains(this)
        ? TransactionType.income
        : TransactionType.expense;
  }

  static List<TransactionCategory> byType(TransactionType type) =>
      TransactionCategory.values
          .where((c) => c.transactionType == type)
          .toList();
}

class TransactionModel {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final String accountId;
  final DateTime date;
  final String? note;
  final DateTime createdAt;

  TransactionModel({
    String? id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.accountId,
    required this.date,
    this.note,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  TransactionModel copyWith({
    String? userId,
    String? title,
    double? amount,
    TransactionType? type,
    TransactionCategory? category,
    String? accountId,
    DateTime? date,
    String? note,
  }) =>
      TransactionModel(
        id: id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        category: category ?? this.category,
        accountId: accountId ?? this.accountId,
        date: date ?? this.date,
        note: note ?? this.note,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        DbConstants.cId: id,
        DbConstants.cUserId: userId,
        DbConstants.cTxnTitle: title,
        DbConstants.cTxnAmount: amount,
        DbConstants.cTxnType: type.name,
        DbConstants.cTxnCategory: category.name,
        DbConstants.cTxnAccId: accountId,
        DbConstants.cTxnDate: date.toIso8601String(),
        DbConstants.cTxnNote: note,
        DbConstants.cCreatedAt: createdAt.toIso8601String(),
      };

  factory TransactionModel.fromMap(Map<String, dynamic> map) =>
      TransactionModel(
        id: map[DbConstants.cId],
        userId: map[DbConstants.cUserId] ?? '',
        title: map[DbConstants.cTxnTitle],
        amount: (map[DbConstants.cTxnAmount] as num).toDouble(),
        type: TransactionType.values.byName(map[DbConstants.cTxnType]),
        category:
            TransactionCategory.values.byName(map[DbConstants.cTxnCategory]),
        accountId: map[DbConstants.cTxnAccId],
        date: DateTime.parse(map[DbConstants.cTxnDate]),
        note: map[DbConstants.cTxnNote],
        createdAt: DateTime.parse(map[DbConstants.cCreatedAt]),
      );
}

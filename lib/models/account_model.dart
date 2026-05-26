import 'package:uuid/uuid.dart';
import '../database/db_constants.dart';

enum AccountType {
  cash,
  bank,
  upi,
  check,
  creditCard,
}

extension AccountTypeInfo on AccountType {
  String get label {
    switch (this) {
      case AccountType.cash:
        return 'રોકડ';
      case AccountType.bank:
        return 'બૅન્ક';
      case AccountType.upi:
        return 'UPI / વૉલેટ';
      case AccountType.check:
        return 'ચેક';
      case AccountType.creditCard:
        return 'ક્રેડિટ કાર્ડ';
    }
  }

  String get icon {
    switch (this) {
      case AccountType.cash:
        return '💵';
      case AccountType.bank:
        return '🏦';
      case AccountType.upi:
        return '📲';
      case AccountType.check:
        return '🧾';
      case AccountType.creditCard:
        return '💳';
    }
  }
}

class AccountModel {
  final String id;
  final String userId;
  final String name;
  final AccountType type;
  final double balance;
  final double creditLimit;
  final double outstandingAmount;
  final String color;
  final String icon;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  AccountModel({
    String? id,
    required this.userId,
    required this.name,
    required this.type,
    this.balance = 0.0,
    this.creditLimit = 0.0,
    this.outstandingAmount = 0.0,
    this.color = '#01696F',
    String? icon,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        icon = icon ?? type.icon,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // ── Computed (Credit Card) ─────────────────────
  bool get isCreditCard => type == AccountType.creditCard;

  double get availableLimit =>
      isCreditCard ? (creditLimit - outstandingAmount) : 0.0;

  AccountModel copyWith({
    String? userId,
    String? name,
    AccountType? type,
    double? balance,
    double? creditLimit,
    double? outstandingAmount,
    String? color,
    String? icon,
    bool? isActive,
  }) {
    return AccountModel(
      id: id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      creditLimit: creditLimit ?? this.creditLimit,
      outstandingAmount: outstandingAmount ?? this.outstandingAmount,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        DbConstants.cId: id,
        DbConstants.cUserId: userId,
        DbConstants.cAccName: name,
        DbConstants.cAccType: type.name,
        DbConstants.cAccBalance: balance,
        DbConstants.cAccColor: color,
        DbConstants.cAccIcon: icon,
        DbConstants.cAccIsActive: isActive ? 1 : 0,
        DbConstants.cCreatedAt: createdAt.toIso8601String(),
        DbConstants.cUpdatedAt: updatedAt.toIso8601String(),
        DbConstants.cAccCreditLimit: creditLimit,
        DbConstants.cAccOutstandingAmt: outstandingAmount,
      };

  factory AccountModel.fromMap(Map<String, dynamic> map) => AccountModel(
        id: map[DbConstants.cId],
        userId: map[DbConstants.cUserId] ?? '',
        name: map[DbConstants.cAccName],
        type: _parseAccountType(map[DbConstants.cAccType]),
        balance: ((map[DbConstants.cAccBalance] ?? 0) as num).toDouble(),
        creditLimit:
            ((map[DbConstants.cAccCreditLimit] ?? 0) as num).toDouble(),
        outstandingAmount:
            ((map[DbConstants.cAccOutstandingAmt] ?? 0) as num).toDouble(),
        color: map[DbConstants.cAccColor] ?? '#01696F',
        icon: map[DbConstants.cAccIcon],
        isActive: map[DbConstants.cAccIsActive] == true ||
            map[DbConstants.cAccIsActive] == 1,
        createdAt: DateTime.parse(map[DbConstants.cCreatedAt]),
        updatedAt: DateTime.parse(map[DbConstants.cUpdatedAt]),
      );

  static AccountType _parseAccountType(dynamic raw) {
    final value = (raw ?? '').toString();
    for (final type in AccountType.values) {
      if (type.name == value) return type;
    }
    return AccountType.cash;
  }
}

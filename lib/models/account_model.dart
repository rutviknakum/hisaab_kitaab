import 'package:uuid/uuid.dart';
import '../database/db_constants.dart';

enum AccountType { cash, bank, upi }

extension AccountTypeInfo on AccountType {
  String get label {
    switch (this) {
      case AccountType.cash:
        return 'રોકડ';
      case AccountType.bank:
        return 'બૅન્ક';
      case AccountType.upi:
        return 'UPI / વૉલેટ';
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
    }
  }
}

class AccountModel {
  final String id;
  final String userId;
  final String name;
  final AccountType type;
  final double balance;
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
    this.color = '#01696F',
    String? icon,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        icon = icon ?? type.icon,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  AccountModel copyWith({
    String? userId,
    String? name,
    AccountType? type,
    double? balance,
    String? color,
    String? icon,
    bool? isActive,
  }) =>
      AccountModel(
        id: id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        type: type ?? this.type,
        balance: balance ?? this.balance,
        color: color ?? this.color,
        icon: icon ?? this.icon,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        DbConstants.cId: id,
        DbConstants.cUserId: userId,
        DbConstants.cAccName: name,
        DbConstants.cAccType: type.name,
        DbConstants.cAccBalance: balance,
        DbConstants.cAccColor: color,
        DbConstants.cAccIcon: icon,
        DbConstants.cAccIsActive: isActive,
        DbConstants.cCreatedAt: createdAt.toIso8601String(),
        DbConstants.cUpdatedAt: updatedAt.toIso8601String(),
      };

  factory AccountModel.fromMap(Map<String, dynamic> map) => AccountModel(
        id: map[DbConstants.cId],
        userId: map[DbConstants.cUserId] ?? '',
        name: map[DbConstants.cAccName],
        type: AccountType.values.byName(map[DbConstants.cAccType]),
        balance: (map[DbConstants.cAccBalance] as num).toDouble(),
        color: map[DbConstants.cAccColor] ?? '#01696F',
        icon: map[DbConstants.cAccIcon],
        isActive: map[DbConstants.cAccIsActive] == true ||
            map[DbConstants.cAccIsActive] == 1,
        createdAt: DateTime.parse(map[DbConstants.cCreatedAt]),
        updatedAt: DateTime.parse(map[DbConstants.cUpdatedAt]),
      );
}

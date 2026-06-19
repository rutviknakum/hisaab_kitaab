import 'package:uuid/uuid.dart';
import '../database/db_constants.dart';

enum PaymentTowards { principal, interest, both }

extension PaymentTowardsInfo on PaymentTowards {
  String get label {
    switch (this) {
      case PaymentTowards.principal:
        return 'મૂળ રકમ';
      case PaymentTowards.interest:
        return 'વ્યાજ';
      case PaymentTowards.both:
        return 'બંને';
    }
  }

  String get icon {
    switch (this) {
      case PaymentTowards.principal:
        return '💰';
      case PaymentTowards.interest:
        return '📊';
      case PaymentTowards.both:
        return '✅';
    }
  }
}

class LoanPaymentModel {
  final String id;
  final String userId;
  final String loanId;
  final double amount;
  final DateTime paymentDate;
  final PaymentTowards towards;
  final String? note;
  final String accountId;
  final DateTime createdAt;

  LoanPaymentModel({
    String? id,
    required this.userId,
    required this.loanId,
    required this.amount,
    required this.paymentDate,
    required this.towards,
    this.note,
    required this.accountId,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        DbConstants.cId: id,
        DbConstants.cUserId: userId,
        DbConstants.cPayLoanId: loanId,
        DbConstants.cPayAmount: amount,
        DbConstants.cPayDate: paymentDate.toIso8601String(),
        DbConstants.cPayTowards: towards.name,
        DbConstants.cPayNote: note,
        DbConstants.cPayAccountId: accountId,
        DbConstants.cCreatedAt: createdAt.toIso8601String(),
      };

  factory LoanPaymentModel.fromMap(Map<String, dynamic> map) =>
      LoanPaymentModel(
        id: map[DbConstants.cId] as String,
        userId: (map[DbConstants.cUserId] ?? '') as String,
        loanId: map[DbConstants.cPayLoanId] as String,
        amount: (map[DbConstants.cPayAmount] as num).toDouble(),
        paymentDate: DateTime.parse(map[DbConstants.cPayDate] as String),
        towards: PaymentTowards.values
            .byName(map[DbConstants.cPayTowards] as String),
        note: map[DbConstants.cPayNote] as String?,
        accountId: map[DbConstants.cPayAccountId] as String,
        createdAt: DateTime.parse(map[DbConstants.cCreatedAt] as String),
      );
}

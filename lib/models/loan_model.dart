import 'package:uuid/uuid.dart';
import '../database/db_constants.dart';

enum LoanType { gave, took }

enum InterestType { simple, compound, flat }

enum InterestPeriod { monthly, yearly }

enum PaymentStyle { fixed, flexible }

enum LoanStatus { active, closed }

extension LoanTypeInfo on LoanType {
  String get label {
    switch (this) {
      case LoanType.gave:
        return 'આપ્યા (ઉઘરાણી)';
      case LoanType.took:
        return 'લીધા (ઉધાર)';
    }
  }

  String get icon {
    switch (this) {
      case LoanType.gave:
        return '💸';
      case LoanType.took:
        return '🤲';
    }
  }
}

extension InterestTypeInfo on InterestType {
  String get label {
    switch (this) {
      case InterestType.simple:
        return 'સાદું વ્યાજ';
      case InterestType.compound:
        return 'ચક્રવૃદ્ધિ વ્યાજ';
      case InterestType.flat:
        return 'ફ્લૅટ રેટ (EMI)';
    }
  }
}

extension InterestPeriodInfo on InterestPeriod {
  String get label {
    switch (this) {
      case InterestPeriod.monthly:
        return 'માસિક (%)';
      case InterestPeriod.yearly:
        return 'વાર્ષિક (%)';
    }
  }
}

class LoanModel {
  final String id;
  final String userId;
  final String personId;
  final LoanType type;
  final double principal;
  final double interestRate;
  final InterestType interestType;
  final InterestPeriod period;
  final DateTime startDate;
  final DateTime? endDate;
  final PaymentStyle paymentStyle;
  final double emiAmount;
  final int emiDay;
  final int totalMonths;
  final LoanStatus status;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  LoanModel({
    String? id,
    required this.userId,
    required this.personId,
    required this.type,
    required this.principal,
    this.interestRate = 0,
    required this.interestType,
    required this.period,
    required this.startDate,
    this.endDate,
    required this.paymentStyle,
    this.emiAmount = 0,
    this.emiDay = 1,
    this.totalMonths = 0,
    this.status = LoanStatus.active,
    this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double simpleInterest(DateTime asOf) {
    final days = asOf.difference(startDate).inDays;
    final years = days / 365;
    final rate =
        period == InterestPeriod.yearly ? interestRate : interestRate * 12;
    return (principal * rate * years) / 100;
  }

  double compoundInterest(DateTime asOf) {
    final days = asOf.difference(startDate).inDays;
    final years = days / 365;
    final n = period == InterestPeriod.monthly ? 12.0 : 1.0;
    final r = interestRate / 100;
    final amount = principal * (1 + r / n) * (n * years);
    return amount - principal < 0 ? 0 : amount - principal;
  }

  double flatRateInterest() {
    if (totalMonths == 0) return 0;
    final years = totalMonths / 12;
    return (principal * interestRate * years) / 100;
  }

  double get accruedInterest {
    final asOf = DateTime.now();
    switch (interestType) {
      case InterestType.simple:
        return simpleInterest(asOf);
      case InterestType.compound:
        return compoundInterest(asOf);
      case InterestType.flat:
        return flatRateInterest();
    }
  }

  double get totalAmount => principal + accruedInterest;

  LoanModel copyWith({
    String? userId,
    String? personId,
    LoanType? type,
    double? principal,
    double? interestRate,
    InterestType? interestType,
    InterestPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    PaymentStyle? paymentStyle,
    double? emiAmount,
    int? emiDay,
    int? totalMonths,
    LoanStatus? status,
    String? note,
  }) =>
      LoanModel(
        id: id,
        userId: userId ?? this.userId,
        personId: personId ?? this.personId,
        type: type ?? this.type,
        principal: principal ?? this.principal,
        interestRate: interestRate ?? this.interestRate,
        interestType: interestType ?? this.interestType,
        period: period ?? this.period,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        paymentStyle: paymentStyle ?? this.paymentStyle,
        emiAmount: emiAmount ?? this.emiAmount,
        emiDay: emiDay ?? this.emiDay,
        totalMonths: totalMonths ?? this.totalMonths,
        status: status ?? this.status,
        note: note ?? this.note,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        DbConstants.cId: id,
        DbConstants.cUserId: userId,
        DbConstants.cLoanPersonId: personId,
        DbConstants.cLoanType: type.name,
        DbConstants.cLoanPrincipal: principal,
        DbConstants.cLoanInterestRate: interestRate,
        DbConstants.cLoanInterestType: interestType.name,
        DbConstants.cLoanPeriod: period.name,
        DbConstants.cLoanStartDate: startDate.toIso8601String(),
        DbConstants.cLoanEndDate: endDate?.toIso8601String(),
        DbConstants.cLoanPaymentStyle: paymentStyle.name,
        DbConstants.cLoanEmiAmount: emiAmount,
        DbConstants.cLoanEmiDay: emiDay,
        DbConstants.cLoanTotalMonths: totalMonths,
        DbConstants.cLoanStatus: status.name,
        DbConstants.cLoanNote: note,
        DbConstants.cCreatedAt: createdAt.toIso8601String(),
        DbConstants.cUpdatedAt: updatedAt.toIso8601String(),
      };

  factory LoanModel.fromMap(Map<String, dynamic> map) => LoanModel(
        id: map[DbConstants.cId],
        userId: map[DbConstants.cUserId] ?? '',
        personId: map[DbConstants.cLoanPersonId],
        type: LoanType.values.byName(map[DbConstants.cLoanType]),
        principal: (map[DbConstants.cLoanPrincipal] as num).toDouble(),
        interestRate: (map[DbConstants.cLoanInterestRate] as num).toDouble(),
        interestType:
            InterestType.values.byName(map[DbConstants.cLoanInterestType]),
        period: InterestPeriod.values.byName(map[DbConstants.cLoanPeriod]),
        startDate: DateTime.parse(map[DbConstants.cLoanStartDate]),
        endDate: map[DbConstants.cLoanEndDate] != null
            ? DateTime.parse(map[DbConstants.cLoanEndDate])
            : null,
        paymentStyle:
            PaymentStyle.values.byName(map[DbConstants.cLoanPaymentStyle]),
        emiAmount: (map[DbConstants.cLoanEmiAmount] as num).toDouble(),
        emiDay: map[DbConstants.cLoanEmiDay] as int,
        totalMonths: map[DbConstants.cLoanTotalMonths] as int,
        status: LoanStatus.values.byName(map[DbConstants.cLoanStatus]),
        note: map[DbConstants.cLoanNote],
        createdAt: DateTime.parse(map[DbConstants.cCreatedAt]),
        updatedAt: DateTime.parse(map[DbConstants.cUpdatedAt]),
      );
}

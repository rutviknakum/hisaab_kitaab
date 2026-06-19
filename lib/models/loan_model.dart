import 'dart:math' as math;
import 'package:uuid/uuid.dart';
import '../database/db_constants.dart';

enum LoanType { gave, took }

enum InterestType { simple, compound, flat, reducing }

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
      case InterestType.reducing:
        return 'ઘટતા બેલેન્સ પર વ્યાજ';
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
  final String accountId;
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
    required this.accountId,
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
    if (days <= 0 || interestRate <= 0) return 0;

    if (period == InterestPeriod.monthly) {
      final months = days / 30.0;
      return (principal * interestRate * months) / 100.0;
    } else {
      final years = days / 365.0;
      return (principal * interestRate * years) / 100.0;
    }
  }

  double compoundInterest(DateTime asOf) {
    final days = asOf.difference(startDate).inDays;
    if (days <= 0 || interestRate <= 0) return 0;

    if (period == InterestPeriod.monthly) {
      final months = days / 30.0;
      final r = interestRate / 100.0;
      final amount = principal * math.pow(1 + r, months);
      final interest = amount - principal;
      return interest < 0 ? 0 : interest.toDouble();
    } else {
      final years = days / 365.0;
      final r = interestRate / 100.0;
      final amount = principal * math.pow(1 + r, years);
      final interest = amount - principal;
      return interest < 0 ? 0 : interest.toDouble();
    }
  }

  double flatRateInterest() {
    if (totalMonths <= 0 || interestRate <= 0) return 0;

    if (period == InterestPeriod.monthly) {
      return principal * (interestRate / 100.0) * totalMonths;
    } else {
      final years = totalMonths / 12.0;
      return principal * (interestRate / 100.0) * years;
    }
  }

  double get monthlyRate {
    if (interestRate <= 0) return 0;
    if (period == InterestPeriod.monthly) return interestRate / 100.0;
    return (interestRate / 12.0) / 100.0;
  }

  double reducingEmiAmount() {
    if (totalMonths <= 0 || principal <= 0) return 0;

    final r = monthlyRate;
    final n = totalMonths;

    if (r <= 0) {
      return principal / n;
    }

    final emi = principal * r * math.pow(1 + r, n) / (math.pow(1 + r, n) - 1);

    return emi.toDouble();
  }

  List<Map<String, dynamic>> reducingSchedule() {
    if (interestType != InterestType.reducing || totalMonths <= 0) return [];

    final schedule = <Map<String, dynamic>>[];
    final emi = emiAmount > 0 ? emiAmount : reducingEmiAmount();
    final r = monthlyRate;

    double balance = principal;

    for (var i = 0; i < totalMonths; i++) {
      final interest = r <= 0 ? 0.0 : balance * r;
      double principalPart = emi - interest;

      if (principalPart < 0) principalPart = 0;

      if (i == totalMonths - 1 || principalPart > balance) {
        principalPart = balance;
      }

      final installment = principalPart + interest;
      final closingBalance =
          (balance - principalPart).clamp(0.0, double.infinity).toDouble();

      schedule.add({
        'month': i + 1,
        'opening_balance': balance,
        'interest': interest,
        'principal': principalPart,
        'amount': installment,
        'closing_balance': closingBalance,
        'due_date': DateTime(startDate.year, startDate.month + i + 1, emiDay),
      });

      balance = closingBalance;
      if (balance <= 0) break;
    }

    return schedule;
  }

  double reducingTotalInterest() {
    final schedule = reducingSchedule();
    return schedule.fold<double>(
      0,
      (sum, e) => sum + (e['interest'] as double),
    );
  }

  double projectedInterest() {
    if (interestRate <= 0) return 0;

    if (interestType == InterestType.reducing &&
        paymentStyle == PaymentStyle.fixed &&
        totalMonths > 0) {
      return reducingTotalInterest();
    }

    if (paymentStyle == PaymentStyle.fixed && totalMonths > 0) {
      switch (interestType) {
        case InterestType.simple:
        case InterestType.flat:
          if (period == InterestPeriod.monthly) {
            return principal * (interestRate / 100.0) * totalMonths;
          } else {
            return principal * (interestRate / 100.0) * (totalMonths / 12.0);
          }

        case InterestType.compound:
          if (period == InterestPeriod.monthly) {
            final amount =
                principal * math.pow(1 + (interestRate / 100.0), totalMonths);
            return (amount - principal).toDouble();
          } else {
            final amount = principal *
                math.pow(1 + ((interestRate / 100.0) / 12.0), totalMonths);
            return (amount - principal).toDouble();
          }

        case InterestType.reducing:
          return reducingTotalInterest();
      }
    }

    return accruedInterest;
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
      case InterestType.reducing:
        return reducingTotalInterest();
    }
  }

  double get totalAmount => principal + projectedInterest();

  LoanModel copyWith({
    String? userId,
    String? personId,
    String? accountId,
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
        accountId: accountId ?? this.accountId,
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
        DbConstants.cLoanAccountId: accountId,
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
        id: map[DbConstants.cId] as String,
        userId: (map[DbConstants.cUserId] ?? '') as String,
        personId: map[DbConstants.cLoanPersonId] as String,
        accountId: (map[DbConstants.cLoanAccountId] ?? '') as String,
        type: LoanType.values.byName(map[DbConstants.cLoanType] as String),
        principal: (map[DbConstants.cLoanPrincipal] as num).toDouble(),
        interestRate:
            ((map[DbConstants.cLoanInterestRate] ?? 0) as num).toDouble(),
        interestType: InterestType.values
            .byName(map[DbConstants.cLoanInterestType] as String),
        period: InterestPeriod.values
            .byName(map[DbConstants.cLoanPeriod] as String),
        startDate: DateTime.parse(map[DbConstants.cLoanStartDate] as String),
        endDate: map[DbConstants.cLoanEndDate] != null
            ? DateTime.parse(map[DbConstants.cLoanEndDate] as String)
            : null,
        paymentStyle: PaymentStyle.values
            .byName(map[DbConstants.cLoanPaymentStyle] as String),
        emiAmount: ((map[DbConstants.cLoanEmiAmount] ?? 0) as num).toDouble(),
        emiDay: (map[DbConstants.cLoanEmiDay] ?? 1) as int,
        totalMonths: (map[DbConstants.cLoanTotalMonths] ?? 0) as int,
        status:
            LoanStatus.values.byName(map[DbConstants.cLoanStatus] as String),
        note: map[DbConstants.cLoanNote] as String?,
        createdAt: DateTime.parse(map[DbConstants.cCreatedAt] as String),
        updatedAt: DateTime.parse(map[DbConstants.cUpdatedAt] as String),
      );
}

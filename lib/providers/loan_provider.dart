import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../database/db_constants.dart';
import '../models/ledger_person_model.dart';
import '../models/loan_model.dart';
import '../models/loan_payment_model.dart';
import '../models/transaction_model.dart';
import 'account_provider.dart';
import 'transaction_provider.dart';

class LoanProvider with ChangeNotifier {
  final DatabaseHelper db = DatabaseHelper.instance;

  List<LedgerPersonModel> _persons = [];
  List<LoanModel> _loans = [];
  List<LoanPaymentModel> _payments = [];

  List<LedgerPersonModel> get persons => List.unmodifiable(_persons);
  List<LoanModel> get loans => List.unmodifiable(_loans);
  List<LoanPaymentModel> get payments => List.unmodifiable(_payments);

  Future<void> loadAll() async {
    final pMaps = await db.getAll(
      DbConstants.tPersons,
      orderBy: DbConstants.cPerName,
    );
    final lMaps = await db.getAll(
      DbConstants.tLoans,
      orderBy: '${DbConstants.cLoanStartDate} DESC',
    );
    final pyMaps = await db.getAll(
      DbConstants.tPayments,
      orderBy: '${DbConstants.cPayDate} DESC',
    );

    _persons = pMaps.map((e) => LedgerPersonModel.fromMap(e)).toList();
    _loans = lMaps.map((e) => LoanModel.fromMap(e)).toList();
    _payments = pyMaps.map((e) => LoanPaymentModel.fromMap(e)).toList();
    notifyListeners();
  }

  Future<void> refresh() async => loadAll();

  LedgerPersonModel? getPersonById(String id) {
    try {
      return _persons.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  LoanModel? getLoanById(String id) {
    try {
      return _loans.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  List<LoanModel> loansOfPerson(String personId) =>
      _loans.where((l) => l.personId == personId).toList()
        ..sort((a, b) => b.startDate.compareTo(a.startDate));

  List<LoanModel> activeLoansOfPerson(String personId) =>
      loansOfPerson(personId)
          .where((l) => l.status == LoanStatus.active)
          .toList();

  List<LoanPaymentModel> paymentsOfLoan(String loanId) =>
      _payments.where((p) => p.loanId == loanId).toList()
        ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

  double totalPaid(String loanId) {
    return _payments
        .where((p) => p.loanId == loanId)
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  double outstandingAmount(String loanId) {
    final loan = getLoanById(loanId);
    if (loan == null) return 0.0;
    final out = loan.totalAmount - totalPaid(loanId);
    return out < 0 ? 0.0 : out;
  }

  double personNetBalance(String personId) {
    double net = 0.0;
    for (final loan in loansOfPerson(personId)) {
      final out = outstandingAmount(loan.id);
      if (loan.type == LoanType.gave) {
        net += out;
      } else {
        net -= out;
      }
    }
    return net;
  }

  double get totalToReceive => _loans
      .where((l) => l.type == LoanType.gave && l.status == LoanStatus.active)
      .fold(0.0, (sum, l) => sum + outstandingAmount(l.id));

  double get totalToPay => _loans
      .where((l) => l.type == LoanType.took && l.status == LoanStatus.active)
      .fold(0.0, (sum, l) => sum + outstandingAmount(l.id));

  List<Map<String, dynamic>> emiSchedule(LoanModel loan) {
    if (loan.paymentStyle != PaymentStyle.fixed || loan.totalMonths <= 0) {
      return [];
    }

    final paidAmount = totalPaid(loan.id);
    final now = DateTime.now();

    if (loan.interestType == InterestType.reducing) {
      final base = loan.reducingSchedule();
      double consumed = 0.0;

      return base.map((row) {
        final amount = ((row['amount'] ?? 0) as num).toDouble();
        final dueDate = row['due_date'] as DateTime;
        consumed += amount;

        final isPaid = consumed <= paidAmount + 0.01;
        final isOverdue = !isPaid && dueDate.isBefore(now);

        return {
          ...row,
          'is_paid': isPaid,
          'is_overdue': isOverdue,
        };
      }).toList();
    }

    double consumed = 0.0;

    return List.generate(loan.totalMonths, (i) {
      final dueDate = DateTime(
        loan.startDate.year,
        loan.startDate.month + i + 1,
        loan.emiDay,
      );

      final amount = loan.emiAmount;
      consumed += amount;

      final isPaid = consumed <= paidAmount + 0.01;
      final isOverdue = !isPaid && dueDate.isBefore(now);

      return {
        'month': i + 1,
        'opening_balance': null,
        'interest': null,
        'principal': null,
        'amount': amount,
        'closing_balance': null,
        'due_date': dueDate,
        'is_paid': isPaid,
        'is_overdue': isOverdue,
      };
    });
  }

  List<Map<String, dynamic>> get overdueEmis {
    final items = <Map<String, dynamic>>[];

    for (final loan in _loans) {
      if (loan.status != LoanStatus.active) continue;
      if (loan.paymentStyle != PaymentStyle.fixed) continue;

      final schedule = emiSchedule(loan);
      for (final emi in schedule) {
        if (((emi['is_overdue'] as bool?) ?? false) == true) {
          items.add({
            'loan': loan,
            'person': getPersonById(loan.personId),
            'due_date': emi['due_date'],
            'amount': emi['amount'],
            'month': emi['month'],
          });
        }
      }
    }

    items.sort((a, b) {
      final ad = a['due_date'] as DateTime;
      final bd = b['due_date'] as DateTime;
      return ad.compareTo(bd);
    });

    return items;
  }

  Future<void> addPerson(LedgerPersonModel person) async {
    await db.insert(DbConstants.tPersons, person.toMap());
    _persons.add(person);
    _persons
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    notifyListeners();
  }

  Future<void> updatePerson(LedgerPersonModel person) async {
    await db.update(DbConstants.tPersons, person.toMap(), person.id);
    final idx = _persons.indexWhere((p) => p.id == person.id);
    if (idx != -1) {
      _persons[idx] = person;
      _persons
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    notifyListeners();
  }

  Future<void> deletePerson(
    String personId, {
    AccountProvider? accountProvider,
    TransactionProvider? transactionProvider,
  }) async {
    final relatedLoans = loansOfPerson(personId);
    for (final loan in relatedLoans) {
      await deleteLoan(
        loan.id,
        accountProvider: accountProvider,
        transactionProvider: transactionProvider,
      );
    }
    await db.delete(DbConstants.tPersons, personId);
    _persons.removeWhere((p) => p.id == personId);
    notifyListeners();
  }

  Future<void> addLoan(
    LoanModel loan, {
    AccountProvider? accountProvider,
    TransactionProvider? transactionProvider,
  }) async {
    await db.insert(DbConstants.tLoans, loan.toMap());
    _loans.add(loan);

    final person = getPersonById(loan.personId);

    if (accountProvider != null && loan.accountId.isNotEmpty) {
      await accountProvider.adjustBalance(
        accountId: loan.accountId,
        amount: loan.principal,
        add: loan.type == LoanType.took,
      );
    }

    if (transactionProvider != null && loan.accountId.isNotEmpty) {
      final txn = TransactionModel(
        userId: loan.userId,
        title: loan.type == LoanType.gave ? 'લોન આપ્યું' : 'લોન લીધું',
        subtitle: person?.name ?? 'Loan entry',
        amount: loan.principal,
        type: loan.type == LoanType.gave
            ? TransactionType.loanGiven
            : TransactionType.loanTaken,
        categoryId: null,
        categoryName: 'લોન',
        categoryEmoji: loan.type == LoanType.gave ? '💸' : '🤲',
        accountId: loan.accountId,
        linkedCreditCardAccountId: null,
        date: loan.startDate,
        note: loan.note,
      );
      await transactionProvider.addTransaction(txn);
    }

    notifyListeners();
  }

  Future<void> updateLoan(
    LoanModel updatedLoan, {
    AccountProvider? accountProvider,
  }) async {
    final idx = _loans.indexWhere((l) => l.id == updatedLoan.id);
    if (idx == -1) return;

    final oldLoan = _loans[idx];
    await db.update(DbConstants.tLoans, updatedLoan.toMap(), updatedLoan.id);
    _loans[idx] = updatedLoan;

    if (accountProvider != null) {
      final meaningfullyChanged = oldLoan.accountId != updatedLoan.accountId ||
          oldLoan.principal != updatedLoan.principal ||
          oldLoan.type != updatedLoan.type;

      if (meaningfullyChanged) {
        if (oldLoan.accountId.isNotEmpty) {
          await accountProvider.adjustBalance(
            accountId: oldLoan.accountId,
            amount: oldLoan.principal,
            add: oldLoan.type == LoanType.gave,
          );
        }
        if (updatedLoan.accountId.isNotEmpty) {
          await accountProvider.adjustBalance(
            accountId: updatedLoan.accountId,
            amount: updatedLoan.principal,
            add: updatedLoan.type == LoanType.took,
          );
        }
      }
    }

    notifyListeners();
  }

  Future<void> closeLoan(String loanId) async {
    final idx = _loans.indexWhere((l) => l.id == loanId);
    if (idx == -1) return;

    final current = _loans[idx];
    if (current.status == LoanStatus.closed) return;

    final updated = current.copyWith(status: LoanStatus.closed);
    await db.update(DbConstants.tLoans, updated.toMap(), updated.id);
    _loans[idx] = updated;
    notifyListeners();
  }

  Future<void> reopenLoan(String loanId) async {
    final idx = _loans.indexWhere((l) => l.id == loanId);
    if (idx == -1) return;

    final current = _loans[idx];
    if (current.status == LoanStatus.active) return;

    final updated = current.copyWith(status: LoanStatus.active);
    await db.update(DbConstants.tLoans, updated.toMap(), updated.id);
    _loans[idx] = updated;
    notifyListeners();
  }

  Future<void> deleteLoan(
    String loanId, {
    AccountProvider? accountProvider,
    TransactionProvider? transactionProvider,
  }) async {
    final loan = getLoanById(loanId);
    if (loan == null) return;

    final person = getPersonById(loan.personId);
    final relatedPayments = paymentsOfLoan(loanId);

    if (accountProvider != null) {
      for (final payment in relatedPayments) {
        if (payment.accountId.isNotEmpty) {
          await accountProvider.adjustBalance(
            accountId: payment.accountId,
            amount: payment.amount,
            add: loan.type == LoanType.took,
          );
        }
      }

      if (loan.accountId.isNotEmpty) {
        await accountProvider.adjustBalance(
          accountId: loan.accountId,
          amount: loan.principal,
          add: loan.type == LoanType.gave,
        );
      }
    }

    if (transactionProvider != null && loan.accountId.isNotEmpty) {
      final deletedTxn = TransactionModel(
        userId: loan.userId,
        title: loan.type == LoanType.gave
            ? 'લોન ડિલીટ કર્યું'
            : 'લીધી લોન ડિલીટ કરી',
        subtitle: person?.name ?? 'Loan deleted',
        amount: loan.principal,
        type: loan.type == LoanType.gave
            ? TransactionType.income
            : TransactionType.expense,
        categoryId: null,
        categoryName: 'ડિલીટેડ લોન',
        categoryEmoji: '🗑️',
        accountId: loan.accountId,
        linkedCreditCardAccountId: null,
        date: DateTime.now(),
        note: 'Deleted loan rollback entry',
      );
      await transactionProvider.addTransaction(deletedTxn);

      for (final payment in relatedPayments) {
        final paymentTxn = TransactionModel(
          userId: payment.userId,
          title: 'લોન પેમેન્ટ ડિલીટ થયું',
          subtitle: person?.name ?? 'Loan payment deleted',
          amount: payment.amount,
          type: loan.type == LoanType.gave
              ? TransactionType.expense
              : TransactionType.income,
          categoryId: null,
          categoryName: 'ડિલીટેડ પેમેન્ટ',
          categoryEmoji: '↩️',
          accountId: payment.accountId,
          linkedCreditCardAccountId: null,
          date: DateTime.now(),
          note: 'Deleted loan payment rollback entry',
        );
        await transactionProvider.addTransaction(paymentTxn);
      }
    }

    await deleteAllPaymentsOfLoan(loanId);
    await db.delete(DbConstants.tLoans, loanId);
    _loans.removeWhere((l) => l.id == loanId);

    notifyListeners();
  }

  Future<void> addPayment(
    LoanPaymentModel payment, {
    AccountProvider? accountProvider,
    TransactionProvider? transactionProvider,
  }) async {
    await db.insert(DbConstants.tPayments, payment.toMap());
    _payments.add(payment);

    final loan = getLoanById(payment.loanId);
    final person = loan != null ? getPersonById(loan.personId) : null;

    if (loan != null &&
        accountProvider != null &&
        payment.accountId.isNotEmpty) {
      await accountProvider.adjustBalance(
        accountId: payment.accountId,
        amount: payment.amount,
        add: loan.type == LoanType.gave,
      );
    }

    if (loan != null &&
        transactionProvider != null &&
        payment.accountId.isNotEmpty) {
      final txn = TransactionModel(
        userId: payment.userId,
        title: loan.type == LoanType.gave ? 'લોન વસૂલ્યું' : 'લોન ભર્યું',
        subtitle: person?.name ?? 'Loan payment',
        amount: payment.amount,
        type: loan.type == LoanType.gave
            ? TransactionType.income
            : TransactionType.expense,
        categoryId: null,
        categoryName: 'લોન પેમેન્ટ',
        categoryEmoji: '💰',
        accountId: payment.accountId,
        linkedCreditCardAccountId: null,
        date: payment.paymentDate,
        note: payment.note,
      );
      await transactionProvider.addTransaction(txn);
    }

    final outstanding = outstandingAmount(payment.loanId);
    if (outstanding <= 0.01) {
      await closeLoan(payment.loanId);
    }

    notifyListeners();
  }

  Future<void> deletePayment(
    String paymentId, {
    AccountProvider? accountProvider,
    TransactionProvider? transactionProvider,
  }) async {
    final idx = _payments.indexWhere((p) => p.id == paymentId);
    if (idx == -1) return;

    final payment = _payments[idx];
    final loan = getLoanById(payment.loanId);
    final person = loan != null ? getPersonById(loan.personId) : null;

    await db.delete(DbConstants.tPayments, paymentId);
    _payments.removeAt(idx);

    if (loan != null &&
        accountProvider != null &&
        payment.accountId.isNotEmpty) {
      await accountProvider.adjustBalance(
        accountId: payment.accountId,
        amount: payment.amount,
        add: loan.type == LoanType.took,
      );
    }

    if (loan != null &&
        transactionProvider != null &&
        payment.accountId.isNotEmpty) {
      final txn = TransactionModel(
        userId: payment.userId,
        title: 'લોન પેમેન્ટ ડિલીટ થયું',
        subtitle: person?.name ?? 'Loan payment deleted',
        amount: payment.amount,
        type: loan.type == LoanType.gave
            ? TransactionType.expense
            : TransactionType.income,
        categoryId: null,
        categoryName: 'ડિલીટેડ પેમેન્ટ',
        categoryEmoji: '↩️',
        accountId: payment.accountId,
        linkedCreditCardAccountId: null,
        date: DateTime.now(),
        note: 'Deleted payment rollback entry',
      );
      await transactionProvider.addTransaction(txn);
    }

    if (loan != null && loan.status == LoanStatus.closed) {
      final outstanding = outstandingAmount(loan.id);
      if (outstanding > 0.01) {
        await reopenLoan(loan.id);
      }
    }

    notifyListeners();
  }

  Future<void> deleteAllPaymentsOfLoan(String loanId) async {
    final dbRaw = await db.database;
    await dbRaw.delete(
      DbConstants.tPayments,
      where: '${DbConstants.cPayLoanId} = ?',
      whereArgs: [loanId],
    );
    _payments.removeWhere((p) => p.loanId == loanId);
    notifyListeners();
  }
}

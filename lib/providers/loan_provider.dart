import 'package:flutter/foundation.dart';
import '../database/db_constants.dart';
import '../models/ledger_person_model.dart';
import '../models/loan_model.dart';
import '../models/loan_payment_model.dart';
import '../main.dart';

class LoanProvider with ChangeNotifier {
  List<LedgerPersonModel> _persons = [];
  List<LoanModel> _loans = [];
  List<LoanPaymentModel> _payments = [];

  List<LedgerPersonModel> get persons => List.unmodifiable(_persons);
  List<LoanModel> get loans => List.unmodifiable(_loans);
  List<LoanPaymentModel> get payments => List.unmodifiable(_payments);

  String? get _currentUserId => supabase.auth.currentUser?.id;

  Future<void> loadAll() async {
    final userId = _currentUserId;
    if (userId == null) {
      _persons = [];
      _loans = [];
      _payments = [];
      notifyListeners();
      return;
    }

    final pMaps = await supabase
        .from(DbConstants.tPersons)
        .select()
        .eq(DbConstants.cUserId, userId)
        .order(DbConstants.cPerName, ascending: true);

    final lMaps = await supabase
        .from(DbConstants.tLoans)
        .select()
        .eq(DbConstants.cUserId, userId)
        .order(DbConstants.cLoanStartDate, ascending: true);

    final pyMaps = await supabase
        .from(DbConstants.tPayments)
        .select()
        .eq(DbConstants.cUserId, userId)
        .order(DbConstants.cPayDate, ascending: true);

    _persons = (pMaps as List)
        .map((e) => LedgerPersonModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    _loans = (lMaps as List)
        .map((e) => LoanModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    _payments = (pyMaps as List)
        .map((e) => LoanPaymentModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    notifyListeners();
  }

  LedgerPersonModel? getPersonById(String id) {
    try {
      return _persons.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<LoanModel> loansOfPerson(String personId) =>
      _loans.where((l) => l.personId == personId).toList();

  List<LoanModel> activeLoansOfPerson(String personId) => _loans
      .where((l) => l.personId == personId && l.status == LoanStatus.active)
      .toList();

  double personNetBalance(String personId) {
    final personLoans = loansOfPerson(personId);
    double total = 0;
    for (final loan in personLoans) {
      final outstanding = outstandingAmount(loan.id);
      if (outstanding <= 0) continue;
      total += loan.type == LoanType.gave ? outstanding : -outstanding;
    }
    return total;
  }

  List<LoanPaymentModel> paymentsOfLoan(String loanId) =>
      _payments.where((p) => p.loanId == loanId).toList()
        ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

  double totalPaid(String loanId) => _payments
      .where((p) => p.loanId == loanId)
      .fold(0, (s, p) => s + p.amount);

  double _reducingOutstandingAmount(LoanModel loan) {
    final schedule = loan.reducingSchedule();
    final paidTotal = totalPaid(loan.id);

    double paidLeft = paidTotal;
    double remaining = 0;

    for (final row in schedule) {
      final installment = row['amount'] as double;

      if (paidLeft >= installment) {
        paidLeft -= installment;
      } else {
        remaining += (installment - paidLeft);
        paidLeft = 0;
      }
    }

    return remaining < 0 ? 0 : remaining;
  }

  double outstandingAmount(String loanId) {
    final loan = _loans.firstWhere(
      (l) => l.id == loanId,
      orElse: () => throw Exception('Loan not found'),
    );

    if (loan.interestType == InterestType.reducing &&
        loan.paymentStyle == PaymentStyle.fixed &&
        loan.totalMonths > 0) {
      return _reducingOutstandingAmount(loan);
    }

    final paid = totalPaid(loanId);
    final outstanding = loan.totalAmount - paid;
    return outstanding < 0 ? 0 : outstanding;
  }

  List<Map<String, dynamic>> emiSchedule(LoanModel loan) {
    if (loan.paymentStyle != PaymentStyle.fixed || loan.totalMonths == 0) {
      return [];
    }

    final payments = paymentsOfLoan(loan.id);

    if (loan.interestType == InterestType.reducing) {
      final base = loan.reducingSchedule();

      return base.map((row) {
        final dueDate = row['due_date'] as DateTime;
        final paid = payments.any(
          (p) => p.paymentDate.difference(dueDate).inDays.abs() <= 5,
        );

        return {
          ...row,
          'is_paid': paid,
          'is_overdue': !paid && dueDate.isBefore(DateTime.now()),
        };
      }).toList();
    }

    final schedule = <Map<String, dynamic>>[];

    for (var i = 0; i < loan.totalMonths; i++) {
      final dueDate = DateTime(
        loan.startDate.year,
        loan.startDate.month + i + 1,
        loan.emiDay,
      );

      final paid = payments.any(
        (p) => p.paymentDate.difference(dueDate).inDays.abs() <= 5,
      );

      schedule.add({
        'month': i + 1,
        'due_date': dueDate,
        'amount': loan.emiAmount,
        'is_paid': paid,
        'is_overdue': !paid && dueDate.isBefore(DateTime.now()),
      });
    }

    return schedule;
  }

  Future<void> addPerson(LedgerPersonModel person) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not logged in');

    final newPerson = person.copyWith(userId: userId);

    await supabase.from(DbConstants.tPersons).insert(newPerson.toMap());
    _persons.add(newPerson);
    _persons.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  Future<void> updatePerson(LedgerPersonModel person) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not logged in');

    final updatedPerson = person.copyWith(userId: userId);

    await supabase
        .from(DbConstants.tPersons)
        .update(updatedPerson.toMap())
        .eq(DbConstants.cId, updatedPerson.id)
        .eq(DbConstants.cUserId, userId);

    final idx = _persons.indexWhere((p) => p.id == updatedPerson.id);
    if (idx != -1) _persons[idx] = updatedPerson;
    notifyListeners();
  }

  Future<void> deletePerson(String id) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not logged in');

    final activeLoans = activeLoansOfPerson(id);
    if (activeLoans.isNotEmpty) {
      throw Exception(
        'Active loan હોય ત્યાં સુધી વ્યક્તિ delete કરી શકાતી નથી.',
      );
    }

    final personLoans = loansOfPerson(id);
    for (final loan in personLoans) {
      await _deleteAllPaymentsOfLoan(loan.id);
    }

    await supabase
        .from(DbConstants.tLoans)
        .delete()
        .eq(DbConstants.cLoanPersonId, id)
        .eq(DbConstants.cUserId, userId);

    await supabase
        .from(DbConstants.tPersons)
        .delete()
        .eq(DbConstants.cId, id)
        .eq(DbConstants.cUserId, userId);

    _persons.removeWhere((p) => p.id == id);
    _loans.removeWhere((l) => l.personId == id);
    _payments
        .removeWhere((p) => personLoans.any((loan) => loan.id == p.loanId));
    notifyListeners();
  }

  Future<void> addLoan(LoanModel loan) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not logged in');

    final newLoan = loan.copyWith(userId: userId);

    await supabase.from(DbConstants.tLoans).insert(newLoan.toMap());
    _loans.add(newLoan);
    notifyListeners();
  }

  Future<void> updateLoan(LoanModel loan) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not logged in');

    final updatedLoan = loan.copyWith(userId: userId);

    await supabase
        .from(DbConstants.tLoans)
        .update(updatedLoan.toMap())
        .eq(DbConstants.cId, updatedLoan.id)
        .eq(DbConstants.cUserId, userId);

    final idx = _loans.indexWhere((l) => l.id == updatedLoan.id);
    if (idx != -1) _loans[idx] = updatedLoan;
    notifyListeners();
  }

  Future<void> closeLoan(String loanId) async {
    final idx = _loans.indexWhere((l) => l.id == loanId);
    if (idx == -1) return;

    final updated = _loans[idx].copyWith(status: LoanStatus.closed);
    await updateLoan(updated);
  }

  Future<void> deleteLoan(String id) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not logged in');

    await _deleteAllPaymentsOfLoan(id);

    await supabase
        .from(DbConstants.tLoans)
        .delete()
        .eq(DbConstants.cId, id)
        .eq(DbConstants.cUserId, userId);

    _loans.removeWhere((l) => l.id == id);
    notifyListeners();
  }

  Future<void> addPayment(LoanPaymentModel payment) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not logged in');

    if (payment.accountId.isEmpty) {
      throw Exception('Account પસંદ કરો');
    }

    final newPayment = LoanPaymentModel(
      id: payment.id,
      userId: userId,
      loanId: payment.loanId,
      amount: payment.amount,
      paymentDate: payment.paymentDate,
      towards: payment.towards,
      note: payment.note,
      accountId: payment.accountId,
      createdAt: payment.createdAt,
    );

    await supabase.from(DbConstants.tPayments).insert(newPayment.toMap());
    _payments.add(newPayment);

    final outstanding = outstandingAmount(newPayment.loanId);
    if (outstanding <= 0) {
      await closeLoan(newPayment.loanId);
    }

    notifyListeners();
  }

  Future<void> deletePayment(String id) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not logged in');

    final payment = _payments.firstWhere((p) => p.id == id);

    await supabase
        .from(DbConstants.tPayments)
        .delete()
        .eq(DbConstants.cId, id)
        .eq(DbConstants.cUserId, userId);

    _payments.removeWhere((p) => p.id == id);

    final loan = _loans.firstWhere(
      (l) => l.id == payment.loanId,
      orElse: () => throw Exception('Loan not found'),
    );

    if (loan.status == LoanStatus.closed) {
      await updateLoan(loan.copyWith(status: LoanStatus.active));
    }

    notifyListeners();
  }

  Future<void> _deleteAllPaymentsOfLoan(String loanId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not logged in');

    await supabase
        .from(DbConstants.tPayments)
        .delete()
        .eq(DbConstants.cPayLoanId, loanId)
        .eq(DbConstants.cUserId, userId);

    _payments.removeWhere((p) => p.loanId == loanId);
  }

  double get totalToReceive {
    double total = 0;
    for (final loan in _loans.where(
      (l) => l.type == LoanType.gave && l.status == LoanStatus.active,
    )) {
      final outstanding = outstandingAmount(loan.id);
      if (outstanding > 0) total += outstanding;
    }
    return total;
  }

  double get totalToPay {
    double total = 0;
    for (final loan in _loans.where(
      (l) => l.type == LoanType.took && l.status == LoanStatus.active,
    )) {
      final outstanding = outstandingAmount(loan.id);
      if (outstanding > 0) total += outstanding;
    }
    return total;
  }

  List<Map<String, dynamic>> get overdueEmis {
    final overdue = <Map<String, dynamic>>[];

    for (final loan in _loans.where(
      (l) =>
          l.paymentStyle == PaymentStyle.fixed && l.status == LoanStatus.active,
    )) {
      final schedule = emiSchedule(loan);

      for (final emi in schedule) {
        if (emi['is_overdue'] == true) {
          final person = getPersonById(loan.personId);
          overdue.add({
            'loan': loan,
            'person': person,
            'due_date': emi['due_date'],
            'amount': emi['amount'],
          });
        }
      }
    }

    return overdue;
  }

  Future<void> clearAll() async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not logged in');

    await supabase
        .from(DbConstants.tPayments)
        .delete()
        .eq(DbConstants.cUserId, userId);

    await supabase
        .from(DbConstants.tLoans)
        .delete()
        .eq(DbConstants.cUserId, userId);

    await supabase
        .from(DbConstants.tPersons)
        .delete()
        .eq(DbConstants.cUserId, userId);

    _payments.clear();
    _loans.clear();
    _persons.clear();
    notifyListeners();
  }
}

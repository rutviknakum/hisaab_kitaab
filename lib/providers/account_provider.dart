import 'package:flutter/foundation.dart';
import '../main.dart';
import '../database/db_constants.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';

class AccountProvider with ChangeNotifier {
  List<AccountModel> _accounts = [];

  List<AccountModel> get accounts => List.unmodifiable(_accounts);

  List<AccountModel> get activeAccounts =>
      _accounts.where((a) => a.isActive).toList();

  List<AccountModel> get normalAccounts =>
      _accounts.where((a) => a.isActive && !a.isCreditCard).toList();

  List<AccountModel> get creditCardAccounts =>
      _accounts.where((a) => a.isActive && a.isCreditCard).toList();

  double get totalBalance {
    final normalTotal = _accounts
        .where((a) => !a.isCreditCard)
        .fold(0.0, (sum, a) => sum + a.balance);

    final ccOutstanding = _accounts
        .where((a) => a.isCreditCard)
        .fold(0.0, (sum, a) => sum + a.outstandingAmount);

    return normalTotal - ccOutstanding;
  }

  double get totalCcOutstanding => _accounts
      .where((a) => a.isCreditCard)
      .fold(0.0, (sum, a) => sum + a.outstandingAmount);

  double get totalCcLimit => _accounts
      .where((a) => a.isCreditCard)
      .fold(0.0, (sum, a) => sum + a.creditLimit);

  String? get _currentUserId => supabase.auth.currentUser?.id;

  AccountModel? getById(String id) {
    try {
      return _accounts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadAccounts() async {
    final userId = _currentUserId;
    if (userId == null) {
      _accounts = [];
      notifyListeners();
      return;
    }

    final maps = await supabase
        .from(DbConstants.tAccounts)
        .select()
        .eq(DbConstants.cUserId, userId)
        .order(DbConstants.cCreatedAt, ascending: true);

    _accounts = (maps as List)
        .map((e) => AccountModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    notifyListeners();
  }

  Future<void> refresh() async => await loadAccounts();

  Future<void> addAccount(AccountModel account) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not logged in');

    final newAccount = account.copyWith(userId: userId);

    await supabase.from(DbConstants.tAccounts).insert(newAccount.toMap());
    _accounts.add(newAccount);
    notifyListeners();
  }

  Future<void> updateAccount(AccountModel account) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not logged in');

    final updated = account.copyWith(userId: userId);

    await supabase
        .from(DbConstants.tAccounts)
        .update(updated.toMap())
        .eq(DbConstants.cId, updated.id)
        .eq(DbConstants.cUserId, userId);

    final idx = _accounts.indexWhere((a) => a.id == updated.id);
    if (idx != -1) _accounts[idx] = updated;
    notifyListeners();
  }

  Future<void> recalculateBalancesFromTransactions() async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not logged in');

    final txnMaps = await supabase
        .from(DbConstants.tTransactions)
        .select()
        .eq(DbConstants.cUserId, userId);

    final transactions = (txnMaps as List)
        .map((e) => TransactionModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    final Map<String, double> balances = {
      for (final acc in _accounts.where((a) => !a.isCreditCard)) acc.id: 0.0,
    };

    final Map<String, double> outstandings = {
      for (final acc in _accounts.where((a) => a.isCreditCard)) acc.id: 0.0,
    };

    for (final txn in transactions) {
      final acc = getById(txn.accountId);
      if (acc == null) continue;

      if (acc.isCreditCard) {
        if (txn.type == TransactionType.expense) {
          outstandings[txn.accountId] =
              (outstandings[txn.accountId] ?? 0) + txn.amount;
        }
      } else {
        final current = balances[txn.accountId] ?? 0.0;
        if (txn.type == TransactionType.income) {
          balances[txn.accountId] = current + txn.amount;
        } else if (txn.type == TransactionType.expense ||
            txn.type == TransactionType.ccPayment) {
          balances[txn.accountId] = current - txn.amount;
        }
      }

      if (txn.type == TransactionType.ccPayment) {
        final ccId =
            txn.categoryId == 'cc_bill_payment' ? txn.accountId : txn.accountId;
        final ccAcc = getById(ccId);
        if (ccAcc != null && ccAcc.isCreditCard) {
          outstandings[ccId] = (outstandings[ccId] ?? 0.0) - txn.amount;
        }
      }
    }

    for (final acc in _accounts.where((a) => !a.isCreditCard)) {
      await supabase
          .from(DbConstants.tAccounts)
          .update({DbConstants.cAccBalance: balances[acc.id] ?? 0.0})
          .eq(DbConstants.cId, acc.id)
          .eq(DbConstants.cUserId, userId);
    }

    for (final acc in _accounts.where((a) => a.isCreditCard)) {
      await supabase
          .from(DbConstants.tAccounts)
          .update({
            DbConstants.cAccOutstandingAmt: outstandings[acc.id] ?? 0.0,
          })
          .eq(DbConstants.cId, acc.id)
          .eq(DbConstants.cUserId, userId);
    }

    await loadAccounts();
  }

  Future<void> deleteAccount(String id) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not logged in');

    await supabase
        .from(DbConstants.tAccounts)
        .delete()
        .eq(DbConstants.cId, id)
        .eq(DbConstants.cUserId, userId);

    _accounts.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  Future<void> clearAll() async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not logged in');

    await supabase
        .from(DbConstants.tAccounts)
        .delete()
        .eq(DbConstants.cUserId, userId);

    _accounts.clear();
    notifyListeners();
  }
}

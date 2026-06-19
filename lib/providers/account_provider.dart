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

  double get totalNormalBalance => normalAccounts.fold(
        0.0,
        (sum, a) => sum + a.balance,
      );

  double get totalCcOutstanding => creditCardAccounts.fold(
        0.0,
        (sum, a) => sum + a.outstandingAmount,
      );

  double get totalCcLimit => creditCardAccounts.fold(
        0.0,
        (sum, a) => sum + a.creditLimit,
      );

  double get totalCcAvailable => creditCardAccounts.fold(
        0.0,
        (sum, a) => sum + a.availableLimit,
      );

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

  Future<void> refresh() async => loadAccounts();

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

    final map = Map<String, dynamic>.from(updated.toMap());
    map.remove(DbConstants.cId);
    map.remove(DbConstants.cUserId);
    map.remove(DbConstants.cCreatedAt);

    await supabase
        .from(DbConstants.tAccounts)
        .update(map)
        .eq(DbConstants.cId, updated.id)
        .eq(DbConstants.cUserId, userId);

    final idx = _accounts.indexWhere((a) => a.id == updated.id);
    if (idx != -1) {
      _accounts[idx] = updated;
    }

    notifyListeners();
  }

  Future<void> adjustBalance({
    required String accountId,
    required double amount,
    required bool add,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not logged in');

    final acc = _accounts.firstWhere((a) => a.id == accountId);
    final nextBalance = add ? acc.balance + amount : acc.balance - amount;

    await supabase
        .from(DbConstants.tAccounts)
        .update({
          DbConstants.cAccBalance: nextBalance,
        })
        .eq(DbConstants.cId, accountId)
        .eq(DbConstants.cUserId, userId);

    final idx = _accounts.indexWhere((a) => a.id == accountId);
    if (idx != -1) {
      _accounts[idx] = acc.copyWith(balance: nextBalance);
    }

    notifyListeners();
  }

  Future<void> recalculateBalancesFromTransactions() async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not logged in');

    if (_accounts.isEmpty) {
      await loadAccounts();
    }

    final txnMaps = await supabase
        .from(DbConstants.tTransactions)
        .select()
        .eq(DbConstants.cUserId, userId)
        .order(DbConstants.cTxnDate, ascending: true)
        .order(DbConstants.cCreatedAt, ascending: true);

    final transactions = (txnMaps as List)
        .map((e) => TransactionModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    final currentAccounts = List<AccountModel>.from(_accounts);

    final Map<String, double> balances = {
      for (final acc in currentAccounts.where((a) => !a.isCreditCard))
        acc.id: 0.0,
    };

    final Map<String, double> outstandings = {
      for (final acc in currentAccounts.where((a) => a.isCreditCard))
        acc.id: 0.0,
    };

    for (final txn in transactions) {
      final sourceAcc = currentAccounts
          .cast<AccountModel?>()
          .firstWhere((a) => a?.id == txn.accountId, orElse: () => null);

      switch (txn.type) {
        case TransactionType.income:
          if (sourceAcc != null && !sourceAcc.isCreditCard) {
            balances[txn.accountId] =
                (balances[txn.accountId] ?? 0.0) + txn.amount;
          }
          break;
        case TransactionType.expense:
          if (sourceAcc == null) break;

          if (sourceAcc.isCreditCard) {
            outstandings[txn.accountId] =
                (outstandings[txn.accountId] ?? 0.0) + txn.amount;
          } else {
            balances[txn.accountId] =
                (balances[txn.accountId] ?? 0.0) - txn.amount;
          }
          break;
        case TransactionType.ccPayment:
          if (sourceAcc != null && !sourceAcc.isCreditCard) {
            balances[txn.accountId] =
                (balances[txn.accountId] ?? 0.0) - txn.amount;
          }

          final linkedCcId = txn.linkedCreditCardAccountId;
          if (linkedCcId != null && linkedCcId.isNotEmpty) {
            final ccAcc = currentAccounts
                .cast<AccountModel?>()
                .firstWhere((a) => a?.id == linkedCcId, orElse: () => null);

            if (ccAcc != null && ccAcc.isCreditCard) {
              final updatedOutstanding =
                  (outstandings[linkedCcId] ?? 0.0) - txn.amount;
              outstandings[linkedCcId] =
                  updatedOutstanding < 0 ? 0.0 : updatedOutstanding;
            }
          }
          break;
        case TransactionType.loanGiven:
          // TODO: Handle this case.
          throw UnimplementedError();
        case TransactionType.loanTaken:
          // TODO: Handle this case.
          throw UnimplementedError();
      }
    }

    for (final acc in currentAccounts.where((a) => !a.isCreditCard)) {
      final newBalance = balances[acc.id] ?? 0.0;

      await supabase
          .from(DbConstants.tAccounts)
          .update({
            DbConstants.cAccBalance: newBalance,
          })
          .eq(DbConstants.cId, acc.id)
          .eq(DbConstants.cUserId, userId);
    }

    for (final acc in currentAccounts.where((a) => a.isCreditCard)) {
      final newOutstanding = outstandings[acc.id] ?? 0.0;

      await supabase
          .from(DbConstants.tAccounts)
          .update({
            DbConstants.cAccOutstandingAmt: newOutstanding,
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

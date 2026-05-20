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

  double get totalBalance => _accounts.fold(0, (sum, a) => sum + a.balance);

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

  Future<void> updateBalance(String accountId, double newBalance) async {
    final account = getById(accountId);
    if (account == null) return;

    final updated = account.copyWith(balance: newBalance);
    await updateAccount(updated);
  }

  Future<void> adjustBalance(
    String accountId,
    double amount,
    bool isIncome,
  ) async {
    final account = getById(accountId);
    if (account == null) return;

    final newBalance =
        isIncome ? account.balance + amount : account.balance - amount;

    await updateBalance(accountId, newBalance);
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
      for (final acc in _accounts) acc.id: 0.0,
    };

    for (final txn in transactions) {
      final current = balances[txn.accountId] ?? 0.0;
      balances[txn.accountId] = txn.type == TransactionType.income
          ? current + txn.amount
          : current - txn.amount;
    }

    for (final acc in _accounts) {
      final correctedBalance = balances[acc.id] ?? 0.0;
      final updated = acc.copyWith(balance: correctedBalance);

      await supabase
          .from(DbConstants.tAccounts)
          .update(updated.toMap())
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

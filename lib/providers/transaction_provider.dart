import 'package:flutter/foundation.dart';
import '../main.dart';
import '../database/db_constants.dart';
import '../models/transaction_model.dart';

class TransactionProvider with ChangeNotifier {
  List<TransactionModel> _transactions = [];

  List<TransactionModel> get transactions => List.unmodifiable(_transactions);

  String? get _currentUserId => supabase.auth.currentUser?.id;

  List<TransactionModel> get thisMonthTransactions {
    final now = DateTime.now();
    return _transactions
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<TransactionModel> getByMonth(int year, int month) => _transactions
      .where((t) => t.date.year == year && t.date.month == month)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  List<TransactionModel> getByAccount(String accountId) =>
      _transactions.where((t) => t.accountId == accountId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  double monthlyIncome(int year, int month) => getByMonth(year, month)
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (s, t) => s + t.amount);

  double monthlyExpense(int year, int month) => getByMonth(year, month)
      .where((t) =>
          t.type == TransactionType.expense ||
          t.type == TransactionType.ccPayment)
      .fold(0.0, (s, t) => s + t.amount);

  double monthlyCcBillPayments(int year, int month) => getByMonth(year, month)
      .where((t) => t.type == TransactionType.ccPayment)
      .fold(0.0, (s, t) => s + t.amount);

  Future<void> loadTransactions() async {
    final userId = _currentUserId;
    if (userId == null) {
      _transactions = [];
      notifyListeners();
      return;
    }

    final maps = await supabase
        .from(DbConstants.tTransactions)
        .select('''
          id,
          user_id,
          title,
          subtitle,
          amount,
          type,
          category_id,
          category_name,
          category_emoji,
          account_id,
          date,
          note,
          created_at
        ''')
        .eq(DbConstants.cUserId, userId)
        .order(DbConstants.cTxnDate, ascending: false);

    _transactions = (maps as List)
        .map((e) => TransactionModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    notifyListeners();
  }

  Future<void> addTransaction(TransactionModel txn) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not logged in');

    final newTxn = txn.copyWith(userId: userId);
    await supabase.from(DbConstants.tTransactions).insert(newTxn.toMap());

    _transactions.insert(0, newTxn);
    notifyListeners();
  }

  Future<void> updateTransaction(TransactionModel txn) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not logged in');

    final updatedTxn = txn.copyWith(userId: userId);

    final map = Map<String, dynamic>.from(updatedTxn.toMap());
    map.remove(DbConstants.cId);
    map.remove(DbConstants.cUserId);
    map.remove(DbConstants.cCreatedAt);

    await supabase
        .from(DbConstants.tTransactions)
        .update(map)
        .eq(DbConstants.cId, updatedTxn.id)
        .eq(DbConstants.cUserId, userId);

    final idx = _transactions.indexWhere((t) => t.id == updatedTxn.id);
    if (idx != -1) {
      _transactions[idx] = updatedTxn;
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    }

    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not logged in');

    await supabase
        .from(DbConstants.tTransactions)
        .delete()
        .eq(DbConstants.cId, id)
        .eq(DbConstants.cUserId, userId);

    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Future<void> deleteByAccount(String accountId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not logged in');

    await supabase
        .from(DbConstants.tTransactions)
        .delete()
        .eq(DbConstants.cTxnAccId, accountId)
        .eq(DbConstants.cUserId, userId);

    _transactions.removeWhere((t) => t.accountId == accountId);
    notifyListeners();
  }
}

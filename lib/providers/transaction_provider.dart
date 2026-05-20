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

  List<TransactionModel> getByDateRange(DateTime from, DateTime to) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day, 23, 59, 59);
    return _transactions
        .where((t) => !t.date.isBefore(start) && !t.date.isAfter(end))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double get totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (s, t) => s + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (s, t) => s + t.amount);

  double get balance => totalIncome - totalExpense;

  double monthlyIncome(int year, int month) => getByMonth(year, month)
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (s, t) => s + t.amount);

  double monthlyExpense(int year, int month) => getByMonth(year, month)
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (s, t) => s + t.amount);

  double monthlyBalance(int year, int month) =>
      monthlyIncome(year, month) - monthlyExpense(year, month);

  Map<String, double> expenseByCategory({
    int? year,
    int? month,
  }) {
    final list = (year != null && month != null)
        ? getByMonth(year, month)
        : List<TransactionModel>.from(_transactions);

    final Map<String, double> map = {};
    for (final t in list.where((t) => t.type == TransactionType.expense)) {
      map[t.categoryName] = (map[t.categoryName] ?? 0) + t.amount;
    }
    return map;
  }

  Map<String, double> incomeByCategory({
    int? year,
    int? month,
  }) {
    final list = (year != null && month != null)
        ? getByMonth(year, month)
        : List<TransactionModel>.from(_transactions);

    final Map<String, double> map = {};
    for (final t in list.where((t) => t.type == TransactionType.income)) {
      map[t.categoryName] = (map[t.categoryName] ?? 0) + t.amount;
    }
    return map;
  }

  List<Map<String, dynamic>> get last6MonthsData {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final date = DateTime(now.year, now.month - (5 - i));
      final income = monthlyIncome(date.year, date.month);
      final expense = monthlyExpense(date.year, date.month);
      return <String, dynamic>{
        'month': date,
        'income': income,
        'expense': expense,
        'balance': income - expense,
      };
    });
  }

  List<Map<String, dynamic>> yearlyData(int year) {
    return List.generate(12, (i) {
      final month = i + 1;
      final income = monthlyIncome(year, month);
      final expense = monthlyExpense(year, month);
      return <String, dynamic>{
        'month': month,
        'income': income,
        'expense': expense,
        'balance': income - expense,
      };
    });
  }

  Future<void> loadTransactions() async {
    final userId = _currentUserId;
    if (userId == null) {
      _transactions = [];
      notifyListeners();
      return;
    }

    final maps = await supabase
        .from(DbConstants.tTransactions)
        .select()
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

    await supabase
        .from(DbConstants.tTransactions)
        .update(updatedTxn.toMap())
        .eq(DbConstants.cId, updatedTxn.id)
        .eq(DbConstants.cUserId, userId);

    final idx = _transactions.indexWhere((t) => t.id == updatedTxn.id);
    if (idx != -1) _transactions[idx] = updatedTxn;
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

  Future<void> clearAll() async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not logged in');

    await supabase
        .from(DbConstants.tTransactions)
        .delete()
        .eq(DbConstants.cUserId, userId);

    _transactions.clear();
    notifyListeners();
  }
}

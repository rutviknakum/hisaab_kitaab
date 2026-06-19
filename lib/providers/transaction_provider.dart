import 'package:flutter/foundation.dart';
import '../main.dart';
import '../database/db_constants.dart';
import '../models/transaction_model.dart';

class TransactionProvider with ChangeNotifier {
  List<TransactionModel> transactions = [];

  List<TransactionModel> get all => List.unmodifiable(transactions);

  String? get currentUserId => supabase.auth.currentUser?.id;

  List<TransactionModel> get thisMonthTransactions {
    final now = DateTime.now();
    return transactions
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<TransactionModel> getByMonth(int year, int month) => transactions
      .where((t) => t.date.year == year && t.date.month == month)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  List<TransactionModel> getByAccount(String accountId) =>
      transactions.where((t) => t.accountId == accountId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  List<TransactionModel> getByDateRange(DateTime from, DateTime to) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day, 23, 59, 59);
    return transactions
        .where((t) => !t.date.isBefore(start) && !t.date.isAfter(end))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double get totalIncome => transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (s, t) => s + t.amount);

  double get totalExpense => transactions
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

  Future<void> loadTransactions() async {
    final userId = currentUserId;
    if (userId == null) {
      transactions = [];
      notifyListeners();
      return;
    }

    final maps = await supabase
        .from(DbConstants.tTransactions)
        .select()
        .eq(DbConstants.cUserId, userId)
        .order(DbConstants.cTxnDate, ascending: false);

    transactions = (maps as List)
        .map((e) => TransactionModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    notifyListeners();
  }

  Future<void> addTransaction(TransactionModel txn) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not logged in');

    final newTxn = txn.copyWith(userId: userId);
    await supabase.from(DbConstants.tTransactions).insert(newTxn.toMap());
    transactions.insert(0, newTxn);
    notifyListeners();
  }

  Future<void> updateTransaction(TransactionModel txn) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not logged in');

    final updatedTxn = txn.copyWith(userId: userId);
    await supabase
        .from(DbConstants.tTransactions)
        .update(updatedTxn.toMap())
        .eq(DbConstants.cId, updatedTxn.id)
        .eq(DbConstants.cUserId, userId);

    final idx = transactions.indexWhere((t) => t.id == updatedTxn.id);
    if (idx != -1) transactions[idx] = updatedTxn;
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not logged in');

    await supabase
        .from(DbConstants.tTransactions)
        .delete()
        .eq(DbConstants.cId, id)
        .eq(DbConstants.cUserId, userId);

    transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Future<void> deleteByAccount(String accountId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not logged in');

    await supabase
        .from(DbConstants.tTransactions)
        .delete()
        .eq(DbConstants.cTxnAccId, accountId)
        .eq(DbConstants.cUserId, userId);

    transactions.removeWhere((t) => t.accountId == accountId);
    notifyListeners();
  }

  Future<void> clearAll() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not logged in');

    await supabase
        .from(DbConstants.tTransactions)
        .delete()
        .eq(DbConstants.cUserId, userId);

    transactions.clear();
    notifyListeners();
  }
}

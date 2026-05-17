import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  // ── Keys ─────────────────────────────────────
  static const _kDark = 'dark_mode';
  static const _kLang = 'language';
  static const _kCurSymbol = 'currency_symbol';
  static const _kCurName = 'currency_name';
  static const _kName = 'user_name';
  static const _kEmail = 'user_email';
  static const _kPin = 'app_pin';
  static const _kEmiReminder = 'emi_reminder';
  static const _kBudgetAlert = 'budget_alert';
  static const _kBiometric = 'biometric_lock';
  static const _kOnboarded = 'onboarded';

  // ── State ────────────────────────────────────
  bool _isDarkMode = false;
  String _language = 'ગુજરાતી';
  String _currency = '₹';
  String _currencyName = 'Indian Rupee';
  String _userName = '';
  String _userEmail = '';
  String _pin = '';
  bool _emiReminder = true;
  bool _budgetAlert = false;
  bool _biometricLock = false;
  bool _onboarded = false;

  // ── Getters ───────────────────────────────────
  bool get isDarkMode => _isDarkMode;
  String get language => _language;
  String get currency => _currency;
  String get currencyName => _currencyName;
  String get userName => _userName;
  String get userEmail => _userEmail;
  bool get hasPin => _pin.isNotEmpty;
  String get pin => _pin;
  bool get emiReminder => _emiReminder;
  bool get budgetAlert => _budgetAlert;
  bool get biometricLock => _biometricLock;
  bool get onboarded => _onboarded;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  // ── Load ─────────────────────────────────────
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _isDarkMode = p.getBool(_kDark) ?? false;
    _language = p.getString(_kLang) ?? 'ગુજરાતી';
    _currency = p.getString(_kCurSymbol) ?? '₹';
    _currencyName = p.getString(_kCurName) ?? 'Indian Rupee';
    _userName = p.getString(_kName) ?? '';
    _userEmail = p.getString(_kEmail) ?? '';
    _pin = p.getString(_kPin) ?? '';
    _emiReminder = p.getBool(_kEmiReminder) ?? true;
    _budgetAlert = p.getBool(_kBudgetAlert) ?? false;
    _biometricLock = p.getBool(_kBiometric) ?? false;
    _onboarded = p.getBool(_kOnboarded) ?? false;
    notifyListeners();
  }

  // ── Setters ───────────────────────────────────
  Future<void> setDarkMode(bool v) async {
    _isDarkMode = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kDark, v);
    notifyListeners();
  }

  Future<void> setLanguage(String v) async {
    _language = v;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLang, v);
    notifyListeners();
  }

  Future<void> setCurrency(String symbol, String name) async {
    _currency = symbol;
    _currencyName = name;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kCurSymbol, symbol);
    await p.setString(_kCurName, name);
    notifyListeners();
  }

  Future<void> setUserName(String v) async {
    _userName = v;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kName, v);
    notifyListeners();
  }

  Future<void> setUserEmail(String v) async {
    _userEmail = v;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kEmail, v);
    notifyListeners();
  }

  Future<void> setPin(String v) async {
    _pin = v;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kPin, v);
    notifyListeners();
  }

  Future<void> clearPin() async {
    _pin = '';
    final p = await SharedPreferences.getInstance();
    await p.remove(_kPin);
    notifyListeners();
  }

  bool verifyPin(String input) => _pin == input;

  Future<void> setEmiReminder(bool v) async {
    _emiReminder = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kEmiReminder, v);
    notifyListeners();
  }

  Future<void> setBudgetAlert(bool v) async {
    _budgetAlert = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kBudgetAlert, v);
    notifyListeners();
  }

  Future<void> setBiometricLock(bool v) async {
    _biometricLock = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kBiometric, v);
    notifyListeners();
  }

  Future<void> setOnboarding(bool v) async {
    _onboarded = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kOnboarded, v);
    notifyListeners();
  }

  Future<void> removePin() async {
    // ✅ setPin('') — existing method use
    await setPin('');
    notifyListeners();
  }
}

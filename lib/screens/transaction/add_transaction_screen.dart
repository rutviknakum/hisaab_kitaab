import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../main.dart';
import '../../models/account_model.dart';
import '../../models/app_category_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? existing;
  final TransactionType? initialType;

  const AddTransactionScreen({
    super.key,
    this.existing,
    this.initialType,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  late final TabController _typeTab;

  TransactionType _type = TransactionType.expense;
  AppCategoryModel? _selectedCategory;

  String? _accountId;
  String? _paymentFromAccountId;
  String? _creditCardAccountId;

  bool _isExpenseFromCreditCard = false;

  DateTime _date = DateTime.now();
  bool _saving = false;

  bool get _isEdit => widget.existing != null;
  bool get _isIncome => _type == TransactionType.income;
  bool get _isCcPayment => _type == TransactionType.ccPayment;
  bool get _isExpense => _type == TransactionType.expense;

  List<AccountModel> get _allAccountsRead =>
      context.read<AccountProvider>().activeAccounts;

  List<AccountModel> get _normalAccountsRead =>
      _allAccountsRead.where((a) => !a.isCreditCard).toList();

  List<AccountModel> get _creditCardAccountsRead =>
      _allAccountsRead.where((a) => a.isCreditCard).toList();

  List<AccountModel> get _expenseAccountsRead {
    if (_isExpenseFromCreditCard) return _creditCardAccountsRead;
    return _normalAccountsRead;
  }

  List<AppCategoryModel> _categoriesRead() {
    if (_isCcPayment) return [];
    final type = _isIncome ? 'income' : 'expense';
    return context.read<CategoryProvider>().byType(type);
  }

  @override
  void initState() {
    super.initState();

    _typeTab = TabController(length: 3, vsync: this);
    _typeTab.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<CategoryProvider>().loadCategories();
      await context.read<AccountProvider>().loadAccounts();
      if (!mounted) return;

      final txn = widget.existing;

      if (txn != null) {
        _titleCtrl.text = txn.title;
        _amountCtrl.text = txn.amount.toStringAsFixed(2);
        _noteCtrl.text = txn.note ?? '';
        _type = txn.type;
        _date = txn.date;

        _setTabWithoutTrigger(_tabIndexFromType(_type));

        if (_isCcPayment) {
          _paymentFromAccountId = txn.accountId;
          _creditCardAccountId = txn.linkedCreditCardAccountId ??
              (_creditCardAccountsRead.isNotEmpty
                  ? _creditCardAccountsRead.first.id
                  : null);
        } else {
          _accountId = txn.accountId;

          final selectedAccount = _allAccountsRead
              .where((a) => a.id == txn.accountId)
              .cast<AccountModel?>()
              .firstWhere((a) => a != null, orElse: () => null);

          _isExpenseFromCreditCard = txn.type == TransactionType.expense &&
              (selectedAccount?.isCreditCard ?? false);

          final cats = _categoriesRead();
          try {
            _selectedCategory = cats.firstWhere((c) => c.id == txn.categoryId);
          } catch (_) {
            _selectedCategory = AppCategoryModel(
              id: txn.categoryId ?? '',
              userId: txn.userId,
              name: txn.categoryName,
              emoji: txn.categoryEmoji,
              type: txn.type == TransactionType.income ? 'income' : 'expense',
              isDefault: false,
              isDeleted: false,
              createdAt: txn.createdAt,
              updatedAt: txn.createdAt,
            );
          }
        }
      } else {
        _type = widget.initialType ?? TransactionType.expense;
        _setTabWithoutTrigger(_tabIndexFromType(_type));
        _applyDefaultsForType();
      }

      if (mounted) setState(() {});
    });
  }

  int _tabIndexFromType(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return 0;
      case TransactionType.expense:
        return 1;
      case TransactionType.ccPayment:
        return 2;
    }
  }

  void _setTabWithoutTrigger(int index) {
    _typeTab.removeListener(_onTabChanged);
    _typeTab.index = index;
    _typeTab.addListener(_onTabChanged);
  }

  void _applyDefaultsForType() {
    if (_isCcPayment) {
      _accountId = null;
      _selectedCategory = null;
      _paymentFromAccountId =
          _normalAccountsRead.isNotEmpty ? _normalAccountsRead.first.id : null;
      _creditCardAccountId = _creditCardAccountsRead.isNotEmpty
          ? _creditCardAccountsRead.first.id
          : null;
    } else {
      _paymentFromAccountId = null;
      _creditCardAccountId = null;

      if (_isIncome) {
        _isExpenseFromCreditCard = false;
        _accountId = _normalAccountsRead.isNotEmpty
            ? _normalAccountsRead.first.id
            : null;
      } else if (_isExpense) {
        final expenseAccounts = _expenseAccountsRead;
        _accountId =
            expenseAccounts.isNotEmpty ? expenseAccounts.first.id : null;
      }

      final cats = _categoriesRead();
      if (cats.isNotEmpty) {
        _selectedCategory ??= cats.first;
      }
    }
  }

  void _onTabChanged() {
    if (_typeTab.indexIsChanging) return;

    setState(() {
      _type = _typeTab.index == 0
          ? TransactionType.income
          : _typeTab.index == 1
              ? TransactionType.expense
              : TransactionType.ccPayment;

      if (_isIncome || _isCcPayment) {
        _isExpenseFromCreditCard = false;
      }

      _selectedCategory = null;
      _applyDefaultsForType();
    });
  }

  @override
  void dispose() {
    _typeTab.removeListener(_onTabChanged);
    _typeTab.dispose();
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) => NumberFormat('#,##,##0.00', 'en_IN').format(v.abs());

  String? _checkBalanceWarning(double amount) {
    final cur = context.read<SettingsProvider>().currency;
    final accounts = context.read<AccountProvider>().activeAccounts;

    if (_isCcPayment) {
      final fromAcc = accounts
          .where((a) => a.id == _paymentFromAccountId)
          .cast<AccountModel?>()
          .firstWhere((_) => true, orElse: () => null);

      if (fromAcc != null && amount > fromAcc.balance) {
        return '"${fromAcc.name}" ખાતામાં બેલેન્સ ઓછું છે!\n'
            'હાલ બેલેન્સ: $cur${_fmt(fromAcc.balance)}\n'
            'ચૂકવવાની રકમ: $cur${_fmt(amount)}';
      }
      return null;
    }

    if (_isExpense) {
      final acc = accounts
          .where((a) => a.id == _accountId)
          .cast<AccountModel?>()
          .firstWhere((_) => true, orElse: () => null);

      if (acc == null) return null;

      if (acc.isCreditCard) {
        final available = acc.availableLimit < 0 ? 0.0 : acc.availableLimit;
        if (amount > available) {
          return '"${acc.name}" ની ઉપલબ્ધ limit ઓછી છે!\n'
              'ઉપલબ્ધ limit: $cur${_fmt(available)}\n'
              'ખર્ચની રકમ: $cur${_fmt(amount)}';
        }
      } else {
        if (amount > acc.balance) {
          return '"${acc.name}" ખાતામાં બેલેન્સ ઓછું છે!\n'
              'હાલ બેલેન્સ: $cur${_fmt(acc.balance)}\n'
              'ખર્ચની રકમ: $cur${_fmt(amount)}';
        }
      }
    }

    return null;
  }

  Future<bool> _showBalanceWarningDialog(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Text('⚠️', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text(
              'બેલેન્સ ઓછું છે',
              style: TextStyle(
                fontFamily: 'NotoSansGujarati',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'NotoSansGujarati',
            height: 1.7,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'રદ કરો',
              style: TextStyle(fontFamily: 'NotoSansGujarati'),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'છતાં સાચવો',
              style: TextStyle(fontFamily: 'NotoSansGujarati'),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              Theme.of(ctx).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      _showSnack('સાચી રકમ લખો', isError: true);
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      _showSnack('User login મળ્યો નથી', isError: true);
      return;
    }

    if (_isCcPayment) {
      if (_paymentFromAccountId == null) {
        _showSnack('કયા ખાતામાંથી ચૂકવ્યું તે પસંદ કરો', isError: true);
        return;
      }
      if (_creditCardAccountId == null) {
        _showSnack('ક્રેડિટ કાર્ડ પસંદ કરો', isError: true);
        return;
      }
    } else {
      if (_accountId == null) {
        _showSnack('ખાતું પસંદ કરો', isError: true);
        return;
      }
      if (_selectedCategory == null) {
        _showSnack('કેટેગરી પસંદ કરો', isError: true);
        return;
      }
    }

    final warning = _checkBalanceWarning(amount);
    if (warning != null) {
      final proceed = await _showBalanceWarningDialog(warning);
      if (!proceed) return;
    }

    setState(() => _saving = true);

    try {
      final txnP = context.read<TransactionProvider>();
      final accP = context.read<AccountProvider>();

      final txn = _isCcPayment
          ? TransactionModel(
              id: widget.existing?.id,
              userId: user.id,
              title: _titleCtrl.text.trim().isEmpty
                  ? 'ક્રેડિટ કાર્ડ બિલ ભર્યું'
                  : _titleCtrl.text.trim(),
              amount: amount,
              type: TransactionType.ccPayment,
              categoryId: null,
              categoryName: 'ક્રેડિટ કાર્ડ બિલ',
              categoryEmoji: '💳',
              accountId: _paymentFromAccountId!,
              linkedCreditCardAccountId: _creditCardAccountId!,
              date: _date,
              note:
                  _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
            )
          : TransactionModel(
              id: widget.existing?.id,
              userId: user.id,
              title: _titleCtrl.text.trim().isEmpty
                  ? (_isIncome ? 'આવક' : 'ખર્ચ')
                  : _titleCtrl.text.trim(),
              amount: amount,
              type: _type,
              categoryId: _selectedCategory!.id,
              categoryName: _selectedCategory!.name,
              categoryEmoji: _selectedCategory!.emoji,
              accountId: _accountId!,
              linkedCreditCardAccountId: null,
              date: _date,
              note:
                  _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
            );

      if (_isEdit) {
        await txnP.updateTransaction(txn);
        _showSnack(
          _isCcPayment ? 'ક્રેડિટ કાર્ડ બિલ સુધારાઈ ✅' : 'નોંધ સુધારાઈ ✅',
        );
      } else {
        await txnP.addTransaction(txn);
        _showSnack(
          _isCcPayment ? 'ક્રેડિટ કાર્ડ બિલ સાચવાયું ✅' : 'નોંધ સાચવાઈ ✅',
        );
      }

      await accP.recalculateBalancesFromTransactions();
      await accP.loadAccounts();
      await txnP.loadTransactions();

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showSnack('સાચવવામાં તકલીફ આવી: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontFamily: 'NotoSansGujarati'),
        ),
        backgroundColor: isError ? AppColors.expense : AppColors.income,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration _inputDec({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon:
          icon != null ? Icon(icon, color: AppColors.primary, size: 18) : null,
      labelStyle: const TextStyle(
        fontFamily: 'NotoSansGujarati',
        fontSize: 13,
      ),
      hintStyle: const TextStyle(
        fontFamily: 'NotoSansGujarati',
        fontSize: 12,
      ),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  Widget _fieldCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: child,
    );
  }

  Widget _accountDropdownChild({
    required String icon,
    required String name,
    required String subText,
    required bool isLow,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Flexible(
          child: RichText(
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: name,
                  style: const TextStyle(
                    fontFamily: 'NotoSansGujarati',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color:
                        Colors.black87, // will be overridden by theme if needed
                  ),
                ),
                TextSpan(
                  text: '  $subText',
                  style: TextStyle(
                    fontFamily: 'NotoSansGujarati',
                    fontSize: 11,
                    color: isLow ? AppColors.expense : Colors.grey,
                    fontWeight: isLow ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openNewCategorySheet() async {
    if (_isCcPayment) return;

    final nameCtrl = TextEditingController();
    final emojiCtrl = TextEditingController(text: '📁');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'નવી કેટેગરી ઉમેરો',
                style: TextStyle(
                  fontFamily: 'NotoSansGujarati',
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emojiCtrl,
                decoration: InputDecoration(
                  labelText: 'ઈમોજી',
                  hintText: 'જેમ કે 💼 / 🍔 / 🚗',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'કેટેગરી નામ',
                  hintText: 'જેમ કે પગાર, પેટ્રોલ, દવા',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final emoji = emojiCtrl.text.trim().isEmpty
                        ? '📁'
                        : emojiCtrl.text.trim();

                    if (name.isEmpty) return;

                    final type = _isIncome ? 'income' : 'expense';

                    await context.read<CategoryProvider>().addCategory(
                          name: name,
                          emoji: emoji,
                          type: type,
                        );

                    if (!mounted) return;
                    await context.read<CategoryProvider>().loadCategories();

                    final updatedCats = _categoriesRead();
                    try {
                      _selectedCategory = updatedCats.lastWhere(
                        (c) =>
                            c.name == name &&
                            c.emoji == emoji &&
                            c.type == type,
                      );
                    } catch (_) {}

                    if (mounted) {
                      setState(() {});
                      Navigator.pop(sheetContext);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'ઉમેરો',
                    style: TextStyle(
                      fontFamily: 'NotoSansGujarati',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    final allAccounts = accountProvider.activeAccounts;
    final normalAccounts = allAccounts.where((a) => !a.isCreditCard).toList();
    final creditCardAccounts =
        allAccounts.where((a) => a.isCreditCard).toList();

    final expenseAccounts =
        _isExpenseFromCreditCard ? creditCardAccounts : normalAccounts;

    final categories = _isCcPayment
        ? <AppCategoryModel>[]
        : categoryProvider.byType(_isIncome ? 'income' : 'expense');

    final cur = context.read<SettingsProvider>().currency;

    final accent = _isIncome
        ? AppColors.income
        : _isCcPayment
            ? AppColors.primary
            : AppColors.expense;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'નોંધ સુધારો' : 'નવી નોંધ',
          style: const TextStyle(
            fontFamily: 'NotoSansGujarati',
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(
              _saving ? 'સાચવી રહ્યા છીએ...' : 'સાચવો',
              style: const TextStyle(
                fontFamily: 'NotoSansGujarati',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.35),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _typeTab,
                indicator: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                labelStyle: const TextStyle(
                  fontFamily: 'NotoSansGujarati',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: '📈 આવક'),
                  Tab(text: '📉 ખર્ચ'),
                  Tab(text: '💳 બિલ'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_isExpense) ...[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withOpacity(0.35),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isExpenseFromCreditCard = false;
                            _accountId = normalAccounts.isNotEmpty
                                ? normalAccounts.first.id
                                : null;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isExpenseFromCreditCard
                                ? accent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'સામાન્ય ખર્ચ',
                            style: TextStyle(
                              fontFamily: 'NotoSansGujarati',
                              fontWeight: FontWeight.w700,
                              color: !_isExpenseFromCreditCard
                                  ? Colors.white
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.70),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isExpenseFromCreditCard = true;
                            _accountId = creditCardAccounts.isNotEmpty
                                ? creditCardAccounts.first.id
                                : null;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isExpenseFromCreditCard
                                ? accent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'ક્રેડિટ કાર્ડ ખર્ચ',
                            style: TextStyle(
                              fontFamily: 'NotoSansGujarati',
                              fontWeight: FontWeight.w700,
                              color: _isExpenseFromCreditCard
                                  ? Colors.white
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.70),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      Theme.of(context).colorScheme.outline.withOpacity(0.10),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _isCcPayment
                              ? '💳'
                              : (_isExpense && _isExpenseFromCreditCard)
                                  ? '💳'
                                  : cur,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: accent,
                            height: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isIncome
                                  ? 'આવકની રકમ'
                                  : _isCcPayment
                                      ? 'ક્રેડિટ કાર્ડ બિલ રકમ'
                                      : _isExpenseFromCreditCard
                                          ? 'ક્રેડિટ કાર્ડ ખર્ચ રકમ'
                                          : 'ખર્ચની રકમ',
                              style: TextStyle(
                                fontFamily: 'NotoSansGujarati',
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _isIncome
                                  ? 'કેટલી આવક થઈ?'
                                  : _isCcPayment
                                      ? 'કેટલું બિલ ચૂકવ્યું?'
                                      : _isExpenseFromCreditCard
                                          ? 'કાર્ડ પરથી કેટલો ખર્ચ થયો?'
                                          : 'કેટલો ખર્ચ થયો?',
                              style: TextStyle(
                                fontFamily: 'NotoSansGujarati',
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      height: 78,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: accent.withOpacity(0.10),
                        ),
                      ),
                      child: TextFormField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}$'),
                          ),
                        ],
                        cursorColor: accent,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          letterSpacing: -1.0,
                          color: accent,
                        ),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                            letterSpacing: -1.0,
                            color: accent.withOpacity(0.20),
                          ),
                          border: InputBorder.none,
                          isCollapsed: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 22,
                          ),
                          counterText: '',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'રકમ લખો';
                          final n = double.tryParse(v);
                          if (n == null || n <= 0) return 'સાચી રકમ લખો';
                          return null;
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _fieldCard(
              child: TextFormField(
                controller: _titleCtrl,
                decoration: _inputDec(
                  label: 'શીર્ષક *',
                  hint: _isCcPayment
                      ? 'દા.ત. SBI Card Bill'
                      : _isExpenseFromCreditCard
                          ? 'દા.ત. Amazon order, Fuel...'
                          : 'દા.ત. કિરાણા, ઑફિસ ખર્ચ...',
                  icon: Icons.edit_rounded,
                ),
                validator: (v) {
                  if (_isCcPayment) return null;
                  return v == null || v.trim().isEmpty ? 'શીર્ષક લખો' : null;
                },
              ),
            ),
            const SizedBox(height: 12),
            if (_isCcPayment) ...[
              _fieldCard(
                child: DropdownButtonFormField<String>(
                  value: _paymentFromAccountId,
                  isExpanded: true,
                  decoration: _inputDec(
                    label: 'કયા ખાતામાંથી ચૂકવ્યું? *',
                    icon: Icons.account_balance_wallet_rounded,
                  ),
                  items: normalAccounts.map((a) {
                    final isLow = a.balance <= 0;
                    return DropdownMenuItem<String>(
                      value: a.id,
                      child: _accountDropdownChild(
                        icon: a.icon,
                        name: a.name,
                        subText: 'બેલેન્સ: $cur${_fmt(a.balance)}',
                        isLow: isLow,
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _paymentFromAccountId = v),
                  validator: (v) => v == null ? 'ખાતું પસંદ કરો' : null,
                ),
              ),
              const SizedBox(height: 12),
              _fieldCard(
                child: DropdownButtonFormField<String>(
                  value: _creditCardAccountId,
                  isExpanded: true,
                  decoration: _inputDec(
                    label: 'કયું ક્રેડિટ કાર્ડ? *',
                    icon: Icons.credit_card_rounded,
                  ),
                  items: creditCardAccounts.map((a) {
                    final outstanding = a.outstandingAmount;
                    return DropdownMenuItem<String>(
                      value: a.id,
                      child: _accountDropdownChild(
                        icon: a.icon,
                        name: a.name,
                        subText: 'બાકી: $cur${_fmt(outstanding)}',
                        isLow: outstanding > 0,
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _creditCardAccountId = v),
                  validator: (v) => v == null ? 'ક્રેડિટ કાર્ડ પસંદ કરો' : null,
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              _fieldCard(
                child: DropdownButtonFormField<String>(
                  value: _accountId,
                  isExpanded: true,
                  decoration: _inputDec(
                    label: _isExpense && _isExpenseFromCreditCard
                        ? 'ક્રેડિટ કાર્ડ *'
                        : 'ખાતું *',
                    icon: _isExpense && _isExpenseFromCreditCard
                        ? Icons.credit_card_rounded
                        : Icons.account_balance_wallet_rounded,
                  ),
                  items:
                      (_isIncome ? normalAccounts : expenseAccounts).map((a) {
                    final isCc = a.isCreditCard;
                    final balanceText = isCc
                        ? 'ઉપલબ્ધ: $cur${_fmt(a.availableLimit < 0 ? 0 : a.availableLimit)}'
                        : 'બેલેન્સ: $cur${_fmt(a.balance)}';
                    final isLow = isCc ? a.availableLimit <= 0 : a.balance <= 0;

                    return DropdownMenuItem<String>(
                      value: a.id,
                      child: _accountDropdownChild(
                        icon: a.icon,
                        name: a.name,
                        subText: balanceText,
                        isLow: isLow,
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _accountId = v),
                  validator: (v) => v == null ? 'ખાતું પસંદ કરો' : null,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'કેટેગરી *',
                style: TextStyle(
                  fontFamily: 'NotoSansGujarati',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...categories.map((c) {
                    final selected = _selectedCategory?.id == c.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? accent.withOpacity(0.10)
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withOpacity(0.32),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? accent : Colors.transparent,
                            width: 1.4,
                          ),
                        ),
                        child: Text(
                          '${c.emoji} ${c.name}',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'NotoSansGujarati',
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.normal,
                            color: selected ? accent : null,
                          ),
                        ),
                      ),
                    );
                  }),
                  GestureDetector(
                    onTap: _openNewCategorySheet,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withOpacity(0.32),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '+ નવી કેટેગરી',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'NotoSansGujarati',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            _fieldCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: accent,
                    size: 18,
                  ),
                ),
                title: const Text(
                  'તારીખ',
                  style: TextStyle(
                    fontFamily: 'NotoSansGujarati',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(
                  DateFormat('dd MMM yyyy, EEEE').format(_date),
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickDate,
              ),
            ),
            const SizedBox(height: 12),
            _fieldCard(
              child: TextFormField(
                controller: _noteCtrl,
                maxLines: 2,
                decoration: _inputDec(
                  label: 'નોંધ (વૈકલ્પિક)',
                  hint: 'વધારાની માહિતી...',
                  icon: Icons.notes_rounded,
                ),
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'NotoSansGujarati',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_isEdit ? 'સુધારો' : 'સાચવો'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

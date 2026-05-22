import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/app_category_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../main.dart';

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
  DateTime _date = DateTime.now();
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  List<AppCategoryModel> get _categories {
    final type = _type == TransactionType.income ? 'income' : 'expense';
    return context.watch<CategoryProvider>().byType(type);
  }

  @override
  void initState() {
    super.initState();

    _typeTab = TabController(length: 2, vsync: this);
    _typeTab.addListener(() {
      if (_typeTab.indexIsChanging) return;
      setState(() {
        _type = _typeTab.index == 0
            ? TransactionType.income
            : TransactionType.expense;
        _selectedCategory = null;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<CategoryProvider>().loadCategories();
      await context.read<AccountProvider>().loadAccounts();
      if (!mounted) return;

      if (_isEdit) {
        final t = widget.existing!;
        _titleCtrl.text = t.title;
        _amountCtrl.text = t.amount.toStringAsFixed(2);
        _noteCtrl.text = t.note ?? '';
        _type = t.type;
        _accountId = t.accountId;
        _date = t.date;
        _typeTab.index = t.type == TransactionType.income ? 0 : 1;

        final categories = _categories;
        try {
          _selectedCategory =
              categories.firstWhere((c) => c.id == t.categoryId);
        } catch (_) {
          _selectedCategory = AppCategoryModel(
            id: t.categoryId,
            userId: t.userId,
            name: t.categoryName,
            emoji: t.categoryEmoji,
            type: t.type == TransactionType.income ? 'income' : 'expense',
            isDefault: false,
            isDeleted: false,
            createdAt: t.createdAt,
            updatedAt: t.createdAt,
          );
        }
      } else {
        _type = widget.initialType ?? TransactionType.expense;
        _typeTab.index = _type == TransactionType.income ? 0 : 1;

        final accounts = context.read<AccountProvider>().activeAccounts;
        if (accounts.isNotEmpty) {
          _accountId = accounts.first.id;
        }
      }

      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _typeTab.dispose();
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: AppColors.primary,
              ),
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

    if (_accountId == null) {
      _showSnack('ખાતું પસંદ કરો', isError: true);
      return;
    }

    if (_selectedCategory == null) {
      _showSnack('કેટેગરી પસંદ કરો', isError: true);
      return;
    }

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

    setState(() => _saving = true);

    try {
      final txnP = context.read<TransactionProvider>();
      final accP = context.read<AccountProvider>();

      final txn = TransactionModel(
        id: widget.existing?.id,
        userId: widget.existing?.userId.isNotEmpty == true
            ? widget.existing!.userId
            : user.id,
        title: _titleCtrl.text.trim(),
        amount: amount,
        type: _type,
        categoryId: _selectedCategory!.id,
        categoryName: _selectedCategory!.name,
        categoryEmoji: _selectedCategory!.emoji,
        accountId: _accountId!,
        date: _date,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );

      if (_isEdit) {
        await txnP.updateTransaction(txn);
        _showSnack('નોંધ સુધારાઈ ✅');
      } else {
        await txnP.addTransaction(txn);
        _showSnack('નોંધ સાચવાઈ ✅');
      }

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

  Future<void> _openNewCategorySheet() async {
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

                    final type =
                        _type == TransactionType.income ? 'income' : 'expense';

                    await context.read<CategoryProvider>().addCategory(
                          name: name,
                          emoji: emoji,
                          type: type,
                        );

                    if (!mounted) return;

                    await context.read<CategoryProvider>().loadCategories();

                    final updatedCategories = _categories;
                    try {
                      _selectedCategory = updatedCategories.lastWhere(
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
    final cur = context.read<SettingsProvider>().currency;
    final accounts = context.read<AccountProvider>().activeAccounts;
    final isIncome = _type == TransactionType.income;
    final accent = isIncome ? AppColors.income : AppColors.expense;

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
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: '📈 આવક'),
                  Tab(text: '📉 ખર્ચ'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      Theme.of(context).colorScheme.outline.withOpacity(0.10),
                  width: 1,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          cur,
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
                              isIncome ? 'આવકની રકમ' : 'ખર્ચની રકમ',
                              style: TextStyle(
                                fontFamily: 'NotoSansGujarati',
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.onSurface,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isIncome ? 'કેટલી આવક થઈ?' : 'કેટલો ખર્ચ થયો?',
                              style: TextStyle(
                                fontFamily: 'NotoSansGujarati',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
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
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
                        textAlign: TextAlign.left,
                        textAlignVertical: TextAlignVertical.center,
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
                          if (v == null || v.trim().isEmpty) {
                            return 'રકમ લખો';
                          }
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
                  hint: 'દા.ત. કિરાણા, ઑફિસ ખર્ચ...',
                  icon: Icons.edit_rounded,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'શીર્ષક લખો' : null,
              ),
            ),
            const SizedBox(height: 12),
            _fieldCard(
              child: DropdownButtonFormField<String>(
                value: _accountId,
                decoration: _inputDec(
                  label: 'ખાતું *',
                  icon: Icons.account_balance_wallet_rounded,
                ),
                items: accounts
                    .map(
                      (a) => DropdownMenuItem(
                        value: a.id,
                        child: Text(
                          '${a.icon} ${a.name}',
                          style:
                              const TextStyle(fontFamily: 'NotoSansGujarati'),
                        ),
                      ),
                    )
                    .toList(),
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
                ..._categories.map((c) {
                  final selected = _selectedCategory?.id == c.id;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = c;
                      });
                    },
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

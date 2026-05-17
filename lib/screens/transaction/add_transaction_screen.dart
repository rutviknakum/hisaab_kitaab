import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/transaction_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/settings_provider.dart';

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

  late TabController _typeTab;
  TransactionType _type = TransactionType.expense;
  TransactionCategory? _category;
  String? _accountId;
  DateTime _date = DateTime.now();
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _typeTab = TabController(length: 2, vsync: this);
    _typeTab.addListener(() {
      if (!_typeTab.indexIsChanging) return;
      setState(() {
        _type = _typeTab.index == 0
            ? TransactionType.income
            : TransactionType.expense;
        _category = null;
      });
    });

    if (_isEdit) {
      final t = widget.existing!;
      _titleCtrl.text = t.title;
      _amountCtrl.text = t.amount.toStringAsFixed(2);
      _noteCtrl.text = t.note ?? '';
      _type = t.type;
      _category = t.category;
      _accountId = t.accountId;
      _date = t.date;
      _typeTab.index = t.type == TransactionType.income ? 0 : 1;
    } else {
      _type = widget.initialType ?? TransactionType.expense;
      _typeTab.index = _type == TransactionType.income ? 0 : 1;

      // Default first account
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final accounts = context.read<AccountProvider>().activeAccounts;
        if (accounts.isNotEmpty) {
          setState(() => _accountId = accounts.first.id);
        }
      });
    }
  }

  @override
  void dispose() {
    _typeTab.dispose();
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  List<TransactionCategory> get _categories => CategoryInfo.byType(_type);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      _showSnack('Category પસંદ કરો', isError: true);
      return;
    }
    if (_accountId == null) {
      _showSnack('ખાતું પસંદ કરો', isError: true);
      return;
    }

    setState(() => _saving = true);
    final txnP = context.read<TransactionProvider>();
    final accP = context.read<AccountProvider>();
    final amount = double.parse(_amountCtrl.text);

    final txn = TransactionModel(
      id: widget.existing?.id,
      title: _titleCtrl.text.trim(),
      amount: amount,
      type: _type,
      category: _category!,
      accountId: _accountId!,
      date: _date,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      userId: '',
    );

    if (_isEdit) {
      // Reverse old balance effect
      await accP.adjustBalance(
        widget.existing!.accountId,
        widget.existing!.amount,
        widget.existing!.type == TransactionType.expense,
      );
      // Apply new
      await accP.adjustBalance(
          _accountId!, amount, _type == TransactionType.income);
      await txnP.updateTransaction(txn);
      _showSnack('નોંધ સુધારાઈ ✅');
    } else {
      await accP.adjustBalance(
          _accountId!, amount, _type == TransactionType.income);
      await txnP.addTransaction(txn);
      _showSnack('નોંધ સાચવાઈ ✅');
    }

    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(msg, style: const TextStyle(fontFamily: 'NotoSansGujarati')),
      backgroundColor: isError ? AppColors.expense : AppColors.income,
      behavior: SnackBarBehavior.floating,
    ));
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
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final cur = context.read<SettingsProvider>().currency;
    final accounts = context.read<AccountProvider>().activeAccounts;
    final isIncome = _type == TransactionType.income;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'નોંધ સુધારો' : 'નવી નોંધ',
            style: const TextStyle(
                fontFamily: 'NotoSansGujarati', fontWeight: FontWeight.w800)),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary)),
            )
          else
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check, color: AppColors.primary),
              label: const Text('સાચવો',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontFamily: 'NotoSansGujarati',
                      fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Type Tabs ─────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _typeTab,
                indicator: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isIncome
                        ? [AppColors.income, AppColors.income.withOpacity(0.7)]
                        : [
                            AppColors.expense,
                            AppColors.expense.withOpacity(0.7)
                          ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(4),
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontFamily: 'NotoSansGujarati',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
                labelColor: Colors.white,
                unselectedLabelColor:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                tabs: const [
                  Tab(text: '📈  આવક'),
                  Tab(text: '📉  ખર્ચ'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Amount (big input) ─────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    isIncome ? AppColors.incomeLight : AppColors.expenseLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(cur,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: isIncome ? AppColors.income : AppColors.expense,
                      )),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _amountCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: isIncome ? AppColors.income : AppColors.expense,
                      ),
                      decoration: const InputDecoration(
                        hintText: '0.00',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'રકમ લખો';
                        }
                        final n = double.tryParse(v);
                        if (n == null || n <= 0) {
                          return 'સાચી રકમ લખો';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Title ──────────────────────────────
            _buildField(
              child: TextFormField(
                controller: _titleCtrl,
                decoration: _inputDec(
                  label: 'શીર્ષક *',
                  hint: 'દા.ત. કિરાણા, ઑફિસ ખર્ચ...',
                  icon: Icons.edit_rounded,
                ),
                validator: (v) => v!.trim().isEmpty ? 'શીર્ષક લખો' : null,
              ),
            ),
            const SizedBox(height: 12),

            // ── Account picker ─────────────────────
            _buildField(
              child: DropdownButtonFormField<String>(
                initialValue: _accountId,
                decoration: _inputDec(
                  label: 'ખાતું *',
                  icon: Icons.account_balance_wallet_rounded,
                ),
                items: accounts
                    .map((a) => DropdownMenuItem(
                          value: a.id,
                          child: Text('${a.icon} ${a.name}',
                              style: const TextStyle(
                                  fontFamily: 'NotoSansGujarati')),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _accountId = v),
                validator: (v) => v == null ? 'ખાતું પસંદ કરો' : null,
              ),
            ),
            const SizedBox(height: 12),

            // ── Category Grid ──────────────────────
            const Text('Category *',
                style: TextStyle(
                  fontFamily: 'NotoSansGujarati',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                )),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((c) {
                final sel = _category == c;
                return GestureDetector(
                  onTap: () => setState(() => _category = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel
                          ? (isIncome
                              ? AppColors.incomeLight
                              : AppColors.expenseLight)
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel
                            ? (isIncome ? AppColors.income : AppColors.expense)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Text('${c.icon} ${c.label}',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'NotoSansGujarati',
                          fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                          color: sel
                              ? (isIncome
                                  ? AppColors.income
                                  : AppColors.expense)
                              : null,
                        )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ── Date ───────────────────────────────
            _buildField(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calendar_today,
                      color: AppColors.primary, size: 18),
                ),
                title: const Text('તારીખ',
                    style: TextStyle(
                        fontFamily: 'NotoSansGujarati',
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                subtitle: Text(
                  DateFormat('dd MMMM yyyy, EEEE').format(_date),
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickDate,
              ),
            ),
            const SizedBox(height: 12),

            // ── Note ───────────────────────────────
            _buildField(
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

            // ── Save Button ────────────────────────
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isIncome ? AppColors.income : AppColors.expense,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
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
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded),
              label: Text(_isEdit ? 'સુધારો' : 'સાચવો'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildField({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: child,
        ),
      );

  InputDecoration _inputDec({
    required String label,
    String? hint,
    IconData? icon,
  }) =>
      InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontFamily: 'NotoSansGujarati', fontSize: 13),
        hintText: hint,
        hintStyle:
            const TextStyle(fontFamily: 'NotoSansGujarati', fontSize: 12),
        prefixIcon: icon != null
            ? Icon(icon, color: AppColors.primary, size: 18)
            : null,
        border: InputBorder.none,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      );
}

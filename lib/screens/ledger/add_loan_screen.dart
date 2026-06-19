import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/loan_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/transaction_provider.dart';

class AddLoanScreen extends StatefulWidget {
  final String personId;
  final LoanModel? existing;

  const AddLoanScreen({
    super.key,
    required this.personId,
    this.existing,
  });

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  final _formKey = GlobalKey<FormState>();

  final _principalCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _emiCtrl = TextEditingController();
  final _monthsCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  LoanType _loanType = LoanType.gave;
  InterestType _interestType = InterestType.simple;
  InterestPeriod _period = InterestPeriod.monthly;
  PaymentStyle _paymentStyle = PaymentStyle.flexible;

  DateTime _startDate = DateTime.now();
  int _emiDay = 1;
  bool _saving = false;
  bool _showInterest = false;
  String? _selectedAccountId;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final l = widget.existing;
    if (l != null) {
      _principalCtrl.text = l.principal.toStringAsFixed(2);
      _rateCtrl.text = l.interestRate.toString();
      _emiCtrl.text = l.emiAmount > 0 ? l.emiAmount.toStringAsFixed(2) : '';
      _monthsCtrl.text = l.totalMonths > 0 ? l.totalMonths.toString() : '';
      _noteCtrl.text = l.note ?? '';
      _loanType = l.type;
      _interestType = l.interestType;
      _period = l.period;
      _paymentStyle = l.paymentStyle;
      _startDate = l.startDate;
      _emiDay = l.emiDay;
      _showInterest = l.interestRate > 0;
      _selectedAccountId = l.accountId.isNotEmpty ? l.accountId : null;
    }
  }

  @override
  void dispose() {
    _principalCtrl.dispose();
    _rateCtrl.dispose();
    _emiCtrl.dispose();
    _monthsCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _calcEmi() {
    final principal = double.tryParse(_principalCtrl.text.trim()) ?? 0;
    final months = int.tryParse(_monthsCtrl.text.trim()) ?? 0;
    final rate = double.tryParse(_rateCtrl.text.trim()) ?? 0;

    if (principal <= 0 || months <= 0) return;

    double emi = 0;

    if (_interestType == InterestType.reducing) {
      final monthlyRate = _period == InterestPeriod.monthly
          ? (rate / 100.0)
          : ((rate / 12.0) / 100.0);
      if (monthlyRate <= 0) {
        emi = principal / months;
      } else {
        final x = monthlyRate;
        final pow = (1 + x);
        final top = principal * x * (pow == 0 ? 0 : _pow(pow, months));
        final bottom = _pow(pow, months) - 1;
        emi = bottom == 0 ? (principal / months) : (top / bottom);
      }
    } else {
      double total = principal;
      if (_showInterest && rate > 0) {
        if (_interestType == InterestType.flat ||
            _interestType == InterestType.simple) {
          final years = months / 12.0;
          final effectiveRate =
              _period == InterestPeriod.monthly ? rate * 12 : rate;
          total = principal + (principal * effectiveRate * years / 100.0);
        }
      }
      emi = total / months;
    }

    if (emi.isFinite && emi > 0) {
      _emiCtrl.text = emi.toStringAsFixed(2);
      setState(() {});
    }
  }

  double _pow(double base, int exponent) {
    double result = 1;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2010),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              Theme.of(ctx).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccountId == null || _selectedAccountId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('કૃપા કરીને ખાતું પસંદ કરો')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final loanP = context.read<LoanProvider>();
      final accountP = context.read<AccountProvider>();
      final txnP = context.read<TransactionProvider>();

      final existing = widget.existing;

      final loan = LoanModel(
        id: existing?.id,
        userId: existing?.userId ?? '',
        personId: widget.personId,
        accountId: _selectedAccountId!,
        type: _loanType,
        principal: double.parse(_principalCtrl.text.trim()),
        interestRate:
            _showInterest ? (double.tryParse(_rateCtrl.text.trim()) ?? 0) : 0,
        interestType: _interestType,
        period: _period,
        startDate: _startDate,
        endDate: existing?.endDate,
        paymentStyle: _paymentStyle,
        emiAmount: _paymentStyle == PaymentStyle.fixed
            ? (double.tryParse(_emiCtrl.text.trim()) ?? 0)
            : 0,
        emiDay: _emiDay,
        totalMonths: _paymentStyle == PaymentStyle.fixed
            ? (int.tryParse(_monthsCtrl.text.trim()) ?? 0)
            : 0,
        status: existing?.status ?? LoanStatus.active,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        createdAt: existing?.createdAt,
        updatedAt: DateTime.now(),
      );

      if (_isEdit) {
        await loanP.updateLoan(
          loan,
          accountProvider: accountP,
        );
      } else {
        await loanP.addLoan(
          loan,
          accountProvider: accountP,
          transactionProvider: txnP,
        );
      }

      await accountP.loadAccounts();
      await txnP.loadTransactions();
      await loanP.loadAll();

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('સેવ કરતી વખતે ભૂલ આવી: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountP = context.watch<AccountProvider>();
    final accounts = accountP.accounts.where((a) => a.isActive).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'લોન ફેરફાર' : 'નવી લોન',
          style: const TextStyle(
            fontFamily: 'NotoSansGujarati',
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _save,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        icon: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.save_rounded, size: 20),
        label: Text(
          _isEdit ? 'લોન અપડેટ' : 'લોન સેવ કરો',
          style: const TextStyle(
            fontFamily: 'NotoSansGujarati',
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('લોન પ્રકાર'),
            const SizedBox(height: 10),
            Row(
              children: LoanType.values.map((t) {
                final sel = _loanType == t;
                final color =
                    t == LoanType.gave ? AppColors.income : AppColors.expense;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _loanType = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: sel
                            ? color
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(t.icon, style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 4),
                          Text(
                            t.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'NotoSansGujarati',
                              fontWeight: FontWeight.w700,
                              color: sel ? Colors.white : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _sectionTitle('મૂળ માહિતી'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _principalCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
              ],
              onChanged: (_) {
                if (_paymentStyle == PaymentStyle.fixed) _calcEmi();
              },
              decoration: _inputDec(
                  label: 'મૂળ રકમ', hint: '0.00', icon: Icons.currency_rupee),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'મૂળ રકમ નાખો';
                final n = double.tryParse(v.trim()) ?? 0;
                if (n <= 0) return 'માન્ય રકમ નાખો';
                return null;
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _selectedAccountId,
              decoration: _inputDec(
                  label: 'ખાતું પસંદ કરો',
                  icon: Icons.account_balance_wallet_rounded),
              items: accounts
                  .map((a) => DropdownMenuItem<String>(
                        value: a.id,
                        child: Text(a.name),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedAccountId = v),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'ખાતું પસંદ કરો' : null,
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderLight),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('dd MMMM yyyy').format(_startDate),
                      style: const TextStyle(fontFamily: 'NotoSansGujarati'),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _sectionTitle('વ્યાજ રાખવું છે?'),
                const Spacer(),
                Switch(
                  value: _showInterest,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) {
                    setState(() {
                      _showInterest = v;
                      if (!v) {
                        _rateCtrl.clear();
                      }
                    });
                  },
                ),
              ],
            ),
            if (_showInterest) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: InterestType.values.map((t) {
                  final sel = _interestType == t;
                  return ChoiceChip(
                    label: Text(
                      t.label,
                      style: const TextStyle(
                          fontFamily: 'NotoSansGujarati', fontSize: 12),
                    ),
                    selected: sel,
                    onSelected: (_) {
                      setState(() => _interestType = t);
                      if (_paymentStyle == PaymentStyle.fixed) _calcEmi();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _rateCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                      ],
                      onChanged: (_) {
                        if (_paymentStyle == PaymentStyle.fixed) _calcEmi();
                      },
                      decoration: _inputDec(
                          label: 'વ્યાજ દર', hint: '2.0', icon: Icons.percent),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<InterestPeriod>(
                      initialValue: _period,
                      decoration:
                          _inputDec(label: 'પિરિયડ', icon: Icons.access_time),
                      items: InterestPeriod.values
                          .map((p) =>
                              DropdownMenuItem(value: p, child: Text(p.label)))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _period = v);
                        if (_paymentStyle == PaymentStyle.fixed) _calcEmi();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
            _sectionTitle('ચુકવણી પ્રકાર'),
            const SizedBox(height: 10),
            Row(
              children: PaymentStyle.values.map((s) {
                final sel = _paymentStyle == s;
                final label =
                    s == PaymentStyle.fixed ? 'ફિક્સ EMI' : 'ફ્લેક્સિબલ';
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _paymentStyle = s);
                      if (s == PaymentStyle.fixed) _calcEmi();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.primarySurface
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: sel ? AppColors.primary : Colors.transparent,
                            width: 1.5),
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'NotoSansGujarati',
                          color: sel ? AppColors.primary : null,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_paymentStyle == PaymentStyle.fixed) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _monthsCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => _calcEmi(),
                      decoration: _inputDec(
                          label: 'કુલ મહિના',
                          hint: '12',
                          icon: Icons.calendar_view_month),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (_paymentStyle == PaymentStyle.fixed &&
                            (n == null || n <= 0)) {
                          return 'મહિના નાખો';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _emiCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                      ],
                      decoration: _inputDec(
                          label: 'EMI રકમ',
                          hint: 'Auto',
                          icon: Icons.payments_rounded),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (_paymentStyle == PaymentStyle.fixed &&
                            (n == null || n <= 0)) {
                          return 'EMI નાખો';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text(
                    'EMI તારીખ',
                    style: TextStyle(
                      fontFamily: 'NotoSansGujarati',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<int>(
                    value: _emiDay,
                    items: List.generate(28, (i) => i + 1)
                        .map((d) =>
                            DropdownMenuItem(value: d, child: Text('$d')))
                        .toList(),
                    onChanged: (v) => setState(() => _emiDay = v ?? 1),
                  ),
                  const Text(
                    'દર મહિને',
                    style:
                        TextStyle(fontFamily: 'NotoSansGujarati', fontSize: 12),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            TextFormField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: _inputDec(
                  label: 'નોંધ', hint: 'વૈકલ્પિક', icon: Icons.notes_rounded),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'NotoSansGujarati',
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    );
  }

  InputDecoration _inputDec(
      {required String label, String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon:
          icon != null ? Icon(icon, size: 18, color: AppColors.primary) : null,
      labelStyle: const TextStyle(fontFamily: 'NotoSansGujarati', fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/loan_model.dart';
import '../../providers/loan_provider.dart';

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
  PaymentStyle _payStyle = PaymentStyle.flexible;
  DateTime _startDate = DateTime.now();
  int _emiDay = 1;
  bool _saving = false;
  bool _showInterest = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final l = widget.existing!;
      _principalCtrl.text = l.principal.toStringAsFixed(2);
      _rateCtrl.text = l.interestRate.toString();
      _emiCtrl.text = l.emiAmount > 0 ? l.emiAmount.toStringAsFixed(2) : '';
      _monthsCtrl.text = l.totalMonths > 0 ? l.totalMonths.toString() : '';
      _noteCtrl.text = l.note ?? '';
      _loanType = l.type;
      _interestType = l.interestType;
      _period = l.period;
      _payStyle = l.paymentStyle;
      _startDate = l.startDate;
      _emiDay = l.emiDay;
      _showInterest = l.interestRate > 0;
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

  double _calcReducingEmi({
    required double principal,
    required double rate,
    required int months,
    required InterestPeriod period,
  }) {
    if (principal <= 0 || months <= 0) return 0;

    final monthlyRate = period == InterestPeriod.monthly
        ? (rate / 100.0)
        : ((rate / 12.0) / 100.0);

    if (monthlyRate <= 0) return principal / months;

    final emi = principal *
        monthlyRate *
        math.pow(1 + monthlyRate, months) /
        (math.pow(1 + monthlyRate, months) - 1);

    return emi.toDouble();
  }

  void _calcEmi() {
    final principal = double.tryParse(_principalCtrl.text.trim()) ?? 0;
    final rate = double.tryParse(_rateCtrl.text.trim()) ?? 0;
    final months = int.tryParse(_monthsCtrl.text.trim()) ?? 0;

    if (_payStyle != PaymentStyle.fixed) return;

    if (principal <= 0 || months <= 0) {
      setState(() => _emiCtrl.text = '');
      return;
    }

    double emi = 0;
    double total = principal;

    if (_showInterest && rate > 0) {
      switch (_interestType) {
        case InterestType.flat:
        case InterestType.simple:
          if (_period == InterestPeriod.monthly) {
            total += principal * (rate / 100.0) * months;
          } else {
            total += principal * (rate / 100.0) * (months / 12.0);
          }
          emi = total / months;
          break;

        case InterestType.compound:
          if (_period == InterestPeriod.monthly) {
            total =
                (principal * math.pow(1 + (rate / 100.0), months)).toDouble();
          } else {
            total = (principal * math.pow(1 + ((rate / 100.0) / 12.0), months))
                .toDouble();
          }
          emi = total / months;
          break;

        case InterestType.reducing:
          emi = _calcReducingEmi(
            principal: principal,
            rate: rate,
            months: months,
            period: _period,
          );
          break;
      }
    } else {
      emi = total / months;
    }

    setState(() => _emiCtrl.text = emi.toStringAsFixed(2));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2010),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

    setState(() => _saving = true);

    try {
      final interestRate =
          _showInterest ? (double.tryParse(_rateCtrl.text.trim()) ?? 0) : 0.0;

      final totalMonths = _payStyle == PaymentStyle.fixed
          ? (int.tryParse(_monthsCtrl.text.trim()) ?? 0)
          : 0;

      final emiAmount = _payStyle == PaymentStyle.fixed
          ? (double.tryParse(_emiCtrl.text.trim()) ?? 0)
          : 0.0;

      final loan = LoanModel(
        id: widget.existing?.id,
        personId: widget.personId,
        type: _loanType,
        principal: double.parse(_principalCtrl.text.trim()),
        interestRate: interestRate,
        interestType: _interestType,
        period: _period,
        startDate: _startDate,
        paymentStyle: _payStyle,
        emiAmount: emiAmount,
        emiDay: _emiDay,
        totalMonths: totalMonths,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        userId: '',
      );

      final loanP = context.read<LoanProvider>();
      if (_isEdit) {
        await loanP.updateLoan(loan);
      } else {
        await loanP.addLoan(loan);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('લોન સેવ કરી શક્યા નથી: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showFixedSection = _payStyle == PaymentStyle.fixed;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'લોન સુધારો' : 'નવો લોન',
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        icon: Icon(_isEdit ? Icons.save_rounded : Icons.add, size: 20),
        label: Text(
          _saving
              ? 'સેવ થઈ રહ્યું છે...'
              : (_isEdit ? 'લોન સુધારો' : 'લોન ઉમેરો'),
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
            _sectionTitle('લોન નો પ્રકાર'),
            const SizedBox(height: 10),
            Row(
              children: LoanType.values.map((t) {
                final sel = _loanType == t;
                final tColor =
                    t == LoanType.gave ? AppColors.income : AppColors.expense;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _loanType = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: sel
                            ? tColor
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
            _sectionTitle('મૂળ રકમ'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _principalCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              onChanged: (_) => _calcEmi(),
              decoration: _inputDec(
                label: 'મૂળ રકમ (₹) *',
                hint: '0.00',
                icon: Icons.currency_rupee,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'રકમ લખો';
                if ((double.tryParse(v.trim()) ?? 0) <= 0) {
                  return 'સાચી રકમ લખો';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _sectionTitle('તારીખ'),
            const SizedBox(height: 8),
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
                    const Icon(
                      Icons.calendar_today,
                      color: AppColors.primary,
                      size: 18,
                    ),
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
                _sectionTitle('વ્યાજ ઉમેરવું છે?'),
                const Spacer(),
                Switch(
                  value: _showInterest,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) {
                    setState(() {
                      _showInterest = v;
                      if (!v) {
                        _rateCtrl.clear();
                        _interestType = InterestType.simple;
                      }
                    });
                    _calcEmi();
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
                  return GestureDetector(
                    onTap: () {
                      setState(() => _interestType = t);
                      _calcEmi();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.primarySurface
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel ? AppColors.primary : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        t.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'NotoSansGujarati',
                          color: sel ? AppColors.primary : null,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _rateCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      onChanged: (_) => _calcEmi(),
                      decoration: _inputDec(
                        label: 'દર %',
                        hint: '2',
                        icon: Icons.percent,
                      ),
                      validator: (v) {
                        if (!_showInterest) return null;
                        final value = double.tryParse(v?.trim() ?? '') ?? 0;
                        if (value <= 0) return 'દર લખો';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<InterestPeriod>(
                      initialValue: _period,
                      decoration:
                          _inputDec(label: 'અવધિ', icon: Icons.access_time),
                      items: InterestPeriod.values
                          .map(
                            (p) => DropdownMenuItem(
                              value: p,
                              child: Text(
                                p.label,
                                style: const TextStyle(
                                  fontFamily: 'NotoSansGujarati',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() => _period = v!);
                        _calcEmi();
                      },
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            _sectionTitle('ચુકવણી રીત'),
            const SizedBox(height: 10),
            Row(
              children: PaymentStyle.values.map((s) {
                final sel = _payStyle == s;
                final label = s == PaymentStyle.fixed ? 'સ્થિર EMI' : 'લવચીક';
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _payStyle = s);
                      _calcEmi();
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
                          width: 1.5,
                        ),
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
            if (showFixedSection) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _monthsCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (_) => _calcEmi(),
                      decoration: _inputDec(
                        label: 'કુલ મહિના *',
                        hint: '12',
                        icon: Icons.calendar_view_month,
                      ),
                      validator: (v) {
                        if (_payStyle != PaymentStyle.fixed) return null;
                        if (v == null || v.trim().isEmpty) {
                          return 'મહિના લખો';
                        }
                        if ((int.tryParse(v.trim()) ?? 0) <= 0) {
                          return 'સાચા મહિના લખો';
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
                      readOnly: true,
                      decoration: _inputDec(
                        label: _interestType == InterestType.reducing
                            ? 'EMI રકમ (Auto)'
                            : 'EMI રકમ (₹)',
                        hint: 'Auto',
                        icon: Icons.payments_rounded,
                      ),
                      validator: (v) {
                        if (_payStyle != PaymentStyle.fixed) return null;
                        if ((double.tryParse(v?.trim() ?? '') ?? 0) <= 0) {
                          return 'EMI generate નથી થયું';
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
                    'EMI તારીખ: ',
                    style: TextStyle(
                      fontFamily: 'NotoSansGujarati',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const Text(
                    'દર મહિના ની ',
                    style: TextStyle(
                      fontFamily: 'NotoSansGujarati',
                      fontSize: 12,
                    ),
                  ),
                  DropdownButton<int>(
                    value: _emiDay,
                    items: List.generate(28, (i) => i + 1)
                        .map(
                          (d) => DropdownMenuItem(
                            value: d,
                            child: Text(
                              '$d',
                              style: const TextStyle(
                                fontFamily: 'NotoSansGujarati',
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _emiDay = v!),
                  ),
                  const Text(
                    ' તારીખ',
                    style: TextStyle(
                      fontFamily: 'NotoSansGujarati',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (_showInterest && _interestType == InterestType.reducing)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'ઘટતા બેલેન્સમાં દર હપ્તા પછી principal ઓછું થતા interest પણ ઓછું થાય છે.',
                    style: TextStyle(
                      fontFamily: 'NotoSansGujarati',
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 14),
            TextFormField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: _inputDec(
                label: 'નોંધ (વૈકલ્પિક)',
                hint: 'કારણ, શરત...',
                icon: Icons.notes_rounded,
              ),
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
          fontFamily: 'NotoSansGujarati',
          fontWeight: FontWeight.w700,
          fontSize: 14,
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
        prefixIcon: icon != null
            ? Icon(icon, size: 18, color: AppColors.primary)
            : null,
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );
}

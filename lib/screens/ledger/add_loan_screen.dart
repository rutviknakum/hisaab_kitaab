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
      _emiCtrl.text = l.emiAmount.toString();
      _monthsCtrl.text = l.totalMonths.toString();
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

  void _calcEmi() {
    final principal = double.tryParse(_principalCtrl.text) ?? 0;
    final rate = double.tryParse(_rateCtrl.text) ?? 0;
    final months = int.tryParse(_monthsCtrl.text) ?? 0;

    if (principal <= 0 || months <= 0) return;

    double total = principal;
    if (rate > 0 && _interestType == InterestType.flat) {
      final years = months / 12;
      total += (principal * rate * years) / 100;
    }
    final emi = total / months;
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
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final loan = LoanModel(
      id: widget.existing?.id,
      personId: widget.personId,
      type: _loanType,
      principal: double.parse(_principalCtrl.text),
      interestRate: double.tryParse(_rateCtrl.text) ?? 0,
      interestType: _interestType,
      period: _period,
      startDate: _startDate,
      paymentStyle: _payStyle,
      emiAmount: double.tryParse(_emiCtrl.text) ?? 0,
      emiDay: _emiDay,
      totalMonths: int.tryParse(_monthsCtrl.text) ?? 0,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      userId: '',
    );

    final loanP = context.read<LoanProvider>();
    if (_isEdit) {
      await loanP.updateLoan(loan);
    } else {
      await loanP.addLoan(loan);
    }

    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
        icon: const Icon(Icons.add, size: 20),
        label: Text(
          _isEdit ? 'લોન સુધારો' : 'લોન ઉમેરો',
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
              onChanged: (_) {
                if (_payStyle == PaymentStyle.fixed) {
                  _calcEmi();
                }
              },
              decoration: _inputDec(
                label: 'મૂળ રકમ (₹) *',
                hint: '0.00',
                icon: Icons.currency_rupee,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'રકમ લખો';
                if ((double.tryParse(v) ?? 0) <= 0) return 'સાચી રકમ લખો';
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
                _sectionTitle('વ્યાજ ઉમેરવું છે?'),
                const Spacer(),
                Switch(
                  value: _showInterest,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => setState(() => _showInterest = v),
                ),
              ],
            ),
            if (_showInterest) ...[
              const SizedBox(height: 10),
              Row(
                children: InterestType.values.map((t) {
                  final sel = _interestType == t;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _interestType = t),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 10),
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
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'NotoSansGujarati',
                            color: sel ? AppColors.primary : null,
                            fontWeight:
                                sel ? FontWeight.w700 : FontWeight.normal,
                          ),
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
                      onChanged: (_) => _calcEmi(),
                      decoration: _inputDec(
                        label: 'દર %',
                        hint: '2',
                        icon: Icons.percent,
                      ),
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
                      onChanged: (v) => setState(() => _period = v!),
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
                    onTap: () => setState(() => _payStyle = s),
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
            if (_payStyle == PaymentStyle.fixed) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _monthsCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _calcEmi(),
                      decoration: _inputDec(
                        label: 'કુલ મહિના *',
                        hint: '12',
                        icon: Icons.calendar_view_month,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _emiCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDec(
                        label: 'EMI રકમ (₹)',
                        hint: 'Auto',
                        icon: Icons.payments_rounded,
                      ),
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

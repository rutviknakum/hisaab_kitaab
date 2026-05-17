import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/loan_model.dart';
import '../../models/loan_payment_model.dart';
import '../../providers/loan_provider.dart';

class AddPaymentScreen extends StatefulWidget {
  final LoanModel loan;
  const AddPaymentScreen({super.key, required this.loan});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill EMI amount
    if (widget.loan.paymentStyle == PaymentStyle.fixed &&
        widget.loan.emiAmount > 0) {
      _amountCtrl.text = widget.loan.emiAmount.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final loanP = context.read<LoanProvider>();
    final payment = LoanPaymentModel(
      loanId: widget.loan.id,
      amount: double.parse(_amountCtrl.text),
      paymentDate: _date,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      towards: PaymentTowards.principal,
      userId: '',
    );

    await loanP.addPayment(payment);
    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final outstanding =
        context.read<LoanProvider>().outstandingAmount(widget.loan.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment ઉમેરો',
            style: TextStyle(
                fontFamily: 'NotoSansGujarati', fontWeight: FontWeight.w800)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Outstanding info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primaryDark,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Text('💳', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('બાકી રકમ',
                          style: TextStyle(
                            color: Colors.white70,
                            fontFamily: 'NotoSansGujarati',
                            fontSize: 12,
                          )),
                      Text(
                        '₹${NumberFormat('#,##,##0.00', 'en_IN').format(outstanding)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Amount
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                labelText: 'Payment Amount (₹) *',
                labelStyle: const TextStyle(
                    fontFamily: 'NotoSansGujarati', fontSize: 13),
                prefixIcon:
                    const Icon(Icons.currency_rupee, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Amount લખો';
                }
                final n = double.tryParse(v);
                if (n == null || n <= 0) {
                  return 'સાચી Amount';
                }
                if (n > outstanding) {
                  return 'Outstanding (${outstanding.toStringAsFixed(2)}) કરતાં વધુ ન હોય';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Date
            GestureDetector(
              onTap: () async {
                final p = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (p != null) setState(() => _date = p);
              },
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
                      DateFormat('dd MMMM yyyy').format(_date),
                      style: const TextStyle(fontFamily: 'NotoSansGujarati'),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Note
            TextFormField(
              controller: _noteCtrl,
              decoration: InputDecoration(
                labelText: 'નોંધ (વૈકલ્પિક)',
                labelStyle: const TextStyle(
                    fontFamily: 'NotoSansGujarati', fontSize: 13),
                prefixIcon:
                    const Icon(Icons.notes, color: AppColors.primary, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.income,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_rounded),
              label: const Text('Payment સાચવો',
                  style: TextStyle(
                    fontFamily: 'NotoSansGujarati',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../database/db_constants.dart';
import '../../models/loan_model.dart';
import '../../models/loan_payment_model.dart';
import '../../providers/loan_provider.dart';
import '../../main.dart';

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
  bool _loadingAccounts = true;

  String? _selectedAccountId;
  List<Map<String, dynamic>> _accounts = [];

  @override
  void initState() {
    super.initState();

    if (widget.loan.paymentStyle == PaymentStyle.fixed &&
        widget.loan.emiAmount > 0) {
      _amountCtrl.text = widget.loan.emiAmount.toStringAsFixed(2);
    }

    _loadAccounts();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      setState(() {
        _accounts = [];
        _loadingAccounts = false;
      });
      return;
    }

    try {
      final data = await supabase
          .from(DbConstants.tAccounts)
          .select()
          .eq(DbConstants.cUserId, user.id)
          .eq(DbConstants.cAccIsActive, true)
          .order(DbConstants.cAccName, ascending: true);

      final accounts = List<Map<String, dynamic>>.from(data);

      setState(() {
        _accounts = accounts;
        _selectedAccountId = accounts.isNotEmpty
            ? accounts.first[DbConstants.cId] as String
            : null;
        _loadingAccounts = false;
      });
    } catch (e) {
      setState(() {
        _accounts = [];
        _loadingAccounts = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Accounts load કરવામાં ભૂલ: $e',
            style: const TextStyle(fontFamily: 'NotoSansGujarati'),
          ),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'User login નથી',
            style: TextStyle(fontFamily: 'NotoSansGujarati'),
          ),
        ),
      );
      return;
    }

    if (_selectedAccountId == null || _selectedAccountId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account પસંદ કરો',
            style: TextStyle(fontFamily: 'NotoSansGujarati'),
          ),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final loanP = context.read<LoanProvider>();

      final payment = LoanPaymentModel(
        loanId: widget.loan.id,
        amount: double.parse(_amountCtrl.text.trim()),
        paymentDate: _date,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        towards: PaymentTowards.principal,
        userId: user.id,
        accountId: _selectedAccountId!,
      );

      await loanP.addPayment(payment);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment સાચવાઈ ગયું',
            style: TextStyle(fontFamily: 'NotoSansGujarati'),
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ભૂલ: $e',
            style: const TextStyle(fontFamily: 'NotoSansGujarati'),
          ),
          backgroundColor: AppColors.expense,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontFamily: 'NotoSansGujarati',
        fontSize: 13,
      ),
      prefixIcon: Icon(
        icon,
        color: AppColors.primary,
        size: 18,
      ),
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
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.expense,
          width: 1.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.expense,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final outstanding =
        context.read<LoanProvider>().outstandingAmount(widget.loan.id);

    final isReceivableLoan = widget.loan.type == LoanType.gave;
    final actionLabel = isReceivableLoan ? 'ઉઘરાણી ઉમેરો' : 'ચુકવણી ઉમેરો';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payment ઉમેરો',
          style: TextStyle(
            fontFamily: 'NotoSansGujarati',
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                      Text(
                        isReceivableLoan ? 'બાકી ઉઘરાણી' : 'બાકી ચુકવણી',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontFamily: 'NotoSansGujarati',
                          fontSize: 12,
                        ),
                      ),
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
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
              decoration: _inputDecoration(
                label: 'Payment Amount (₹) *',
                icon: Icons.currency_rupee,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Amount લખો';
                }

                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) {
                  return 'સાચી Amount લખો';
                }

                if (n > outstanding) {
                  return 'Outstanding (${outstanding.toStringAsFixed(2)}) કરતાં વધુ ન હોય';
                }

                return null;
              },
            ),
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickDate,
              child: InputDecorator(
                decoration: _inputDecoration(
                  label: 'Payment Date *',
                  icon: Icons.calendar_today,
                ),
                child: Row(
                  children: [
                    Text(
                      DateFormat('dd MMMM yyyy').format(_date),
                      style: const TextStyle(
                        fontFamily: 'NotoSansGujarati',
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (_loadingAccounts)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: _selectedAccountId,
                isExpanded: true,
                decoration: _inputDecoration(
                  label: 'Account *',
                  icon: Icons.account_balance_wallet,
                ),
                items: _accounts
                    .map(
                      (acc) => DropdownMenuItem<String>(
                        value: acc[DbConstants.cId] as String,
                        child: Text(
                          acc[DbConstants.cAccName]?.toString() ?? '',
                          style: const TextStyle(
                            fontFamily: 'NotoSansGujarati',
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedAccountId = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Account પસંદ કરો';
                  }
                  return null;
                },
              ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _noteCtrl,
              decoration: _inputDecoration(
                label: 'નોંધ (વૈકલ્પિક)',
                icon: Icons.notes,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: (_saving || _loadingAccounts) ? null : _save,
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
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_rounded),
              label: Text(
                actionLabel,
                style: const TextStyle(
                  fontFamily: 'NotoSansGujarati',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

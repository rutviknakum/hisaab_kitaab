import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/ledger_person_model.dart';
import '../../providers/loan_provider.dart';

class AddPersonScreen extends StatefulWidget {
  final LedgerPersonModel? existing;
  const AddPersonScreen({super.key, this.existing});

  @override
  State<AddPersonScreen> createState() => _AddPersonScreenState();
}

class _AddPersonScreenState extends State<AddPersonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final p = widget.existing!;
      _nameCtrl.text = p.name;
      _phoneCtrl.text = p.phone ?? '';
      _noteCtrl.text = p.note ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final loanP = context.read<LoanProvider>();
    final person = LedgerPersonModel(
      id: widget.existing?.id,
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      userId: '',
    );

    if (_isEdit) {
      await loanP.updatePerson(person);
    } else {
      await loanP.addPerson(person);
    }

    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'વ્યક્તિ સુધારો' : 'નવી વ્યક્તિ',
            style: const TextStyle(
                fontFamily: 'NotoSansGujarati', fontWeight: FontWeight.w800)),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
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
            // ── Avatar Preview ─────────────────────
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primaryDark,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    _nameCtrl.text.isNotEmpty
                        ? _nameCtrl.text[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'NotoSansGujarati',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Name ───────────────────────────────
            TextFormField(
              controller: _nameCtrl,
              onChanged: (_) => setState(() {}),
              textCapitalization: TextCapitalization.words,
              decoration: _inputDec(
                label: 'પૂરું નામ *',
                hint: 'દા.ત. રમેશ પટેલ',
                icon: Icons.person_rounded,
              ),
              validator: (v) => v!.trim().isEmpty ? 'નામ લખો' : null,
            ),
            const SizedBox(height: 14),

            // ── Phone ──────────────────────────────
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: _inputDec(
                label: 'મોબાઈલ નંબર (વૈકલ્પિક)',
                hint: '9876543210',
                icon: Icons.phone_rounded,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return null;
                }
                if (v.length != 10) {
                  return '10 આંકડા નો નંબર લખો';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // ── Note ───────────────────────────────
            TextFormField(
              controller: _noteCtrl,
              maxLines: 3,
              decoration: _inputDec(
                label: 'નોંધ (વૈકલ્પિક)',
                hint: 'ઘર, સંબંધ, વ્યવસાય...',
                icon: Icons.notes_rounded,
              ),
            ),
            const SizedBox(height: 32),

            // ── Save Button ────────────────────────
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
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
                  : const Icon(Icons.person_add_rounded),
              label: Text(_isEdit ? 'સુધારો' : 'વ્યક્તિ ઉમેરો'),
            ),
          ],
        ),
      ),
    );
  }

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

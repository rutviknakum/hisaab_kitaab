import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/account_model.dart';
import '../../providers/account_provider.dart';

class AddAccountScreen extends StatefulWidget {
  final AccountModel? existing;
  const AddAccountScreen({super.key, this.existing});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _balCtrl = TextEditingController();

  AccountType _type = AccountType.cash;
  String _color = '#01696F';
  String _icon = '💵';
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  static const _colorOptions = [
    '#01696F',
    '#E53935',
    '#8E24AA',
    '#1E88E5',
    '#F4511E',
    '#00897B',
    '#FFB300',
    '#6D4C41',
    '#546E7A',
    '#43A047',
  ];

  static const _iconOptions = [
    '💵',
    '🏦',
    '📲',
    '💳',
    '🧾',
    '🏪',
    '🏠',
    '💰',
    '🐷',
    '📦',
    '🤝',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final a = widget.existing!;
      _nameCtrl.text = a.name;
      _balCtrl.text = a.balance.toStringAsFixed(2);
      _type = a.type;
      _color = a.color;
      _icon = a.icon;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final accP = context.read<AccountProvider>();
      final account = AccountModel(
        id: widget.existing?.id,
        name: _nameCtrl.text.trim(),
        type: _type,
        balance: double.tryParse(_balCtrl.text) ?? 0,
        color: _color,
        icon: _icon,
        userId: '',
      );

      if (_isEdit) {
        await accP.updateAccount(account);
      } else {
        await accP.addAccount(account);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Color(int.parse(_color.replaceFirst('#', '0xFF')));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'ખાતું સુધારો' : 'નવું ખાતું',
          style: const TextStyle(
            fontFamily: 'NotoSansGujarati',
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.check, color: AppColors.primary),
            label: const Text(
              'સાચવો',
              style: TextStyle(
                color: AppColors.primary,
                fontFamily: 'NotoSansGujarati',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accentColor.withValues(alpha: 0.30)),
              ),
              child: Row(
                children: [
                  Text(_icon, style: const TextStyle(fontSize: 40)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nameCtrl.text.isEmpty
                              ? 'ખાતાનું નામ'
                              : _nameCtrl.text,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'NotoSansGujarati',
                            color: accentColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _type.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'NotoSansGujarati',
                            color: accentColor.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _sectionTitle('ખાતાની વિગત'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              onChanged: (_) => setState(() {}),
              decoration: _inputDec(
                label: 'ખાતાનું નામ *',
                hint: 'દા.ત. SBI Saving, રોકડ...',
                icon: Icons.account_balance_wallet_outlined,
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'નામ લખો' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _balCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDec(
                label: 'Opening Balance (₹)',
                hint: '0.00',
                icon: Icons.currency_rupee,
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitle('ખાતાનો પ્રકાર'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AccountType.values.map((t) {
                final sel = _type == t;
                return GestureDetector(
                  onTap: () => setState(() {
                    _type = t;
                    _icon = t.icon;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: (MediaQuery.of(context).size.width - 48) / 2,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: sel
                          ? accentColor
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: sel
                            ? accentColor
                            : Colors.grey.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(t.icon, style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 6),
                        Text(
                          t.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'NotoSansGujarati',
                            color: sel ? Colors.white : null,
                            fontWeight:
                                sel ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _sectionTitle('Icon પસંદ કરો'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _iconOptions.map((ic) {
                final sel = _icon == ic;
                return GestureDetector(
                  onTap: () => setState(() => _icon = ic),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: sel
                          ? accentColor.withValues(alpha: 0.15)
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel ? accentColor : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(ic, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _sectionTitle('રંગ પસંદ કરો'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _colorOptions.map((c) {
                final color = Color(int.parse(c.replaceFirst('#', '0xFF')));
                final sel = _color == c;
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: sel ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: sel
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.50),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: sel
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
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
                  : const Icon(Icons.save_rounded),
              label: Text(
                _isEdit ? 'ખાતું સુધારો' : 'ખાતું સાચવો',
                style: const TextStyle(
                  fontFamily: 'NotoSansGujarati',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 32),
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

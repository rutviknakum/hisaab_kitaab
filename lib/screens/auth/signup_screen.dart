import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_colors.dart';
import '../../main.dart';
import 'auth_field.dart';
import 'social_auth_buttons.dart';

class SignupScreen extends StatefulWidget {
  final VoidCallback? onSwitchToLogin;
  const SignupScreen({super.key, this.onSwitchToLogin});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final res = await supabase.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        data: {'full_name': _nameCtrl.text.trim()},
      );
      if (res.user != null && mounted) {
        if (res.session == null) {
          _showSuccess('Email verify કરો — inbox check કરો');
          widget.onSwitchToLogin?.call();
        }
      }
    } on AuthException catch (e) {
      if (mounted) _showError(_authMsg(e.message));
    } catch (_) {
      if (mounted) _showError('કંઈ ખોટું ગયું. ફરી try કરો.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _authMsg(String msg) {
    if (msg.contains('already registered'))
      return 'આ email પહેલેથી registered છે';
    if (msg.contains('Password should'))
      return 'Password ઓછામાં ઓછા 6 characters';
    if (msg.contains('Invalid email')) return 'Valid email દાખલ કરો';
    return msg;
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(msg, style: const TextStyle(fontFamily: 'NotoSansGujarati')),
      backgroundColor: AppColors.expense,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(msg, style: const TextStyle(fontFamily: 'NotoSansGujarati')),
      backgroundColor: AppColors.income,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            AuthField(
              controller: _nameCtrl,
              label: 'પૂરું નામ',
              hint: 'તમારું નામ',
              icon: Icons.person_outline_rounded,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'નામ જરૂરી છે' : null,
            ),
            const SizedBox(height: 12),
            AuthField(
              controller: _emailCtrl,
              label: 'Email',
              hint: 'example@gmail.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email જરૂરી છે';
                if (!v.contains('@') || !v.contains('.')) {
                  return 'Valid email દાખલ કરો';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            AuthField(
              controller: _passCtrl,
              label: 'Password',
              hint: 'ઓછામાં ઓછા 6 characters',
              icon: Icons.lock_outline_rounded,
              obscure: _obscure,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: Colors.grey.shade400,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password જરૂરી છે';
                if (v.length < 6) return 'ઓછામાં ઓછા 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 12),
            AuthField(
              controller: _confirmCtrl,
              label: 'Password ફરી',
              hint: 'Password confirm કરો',
              icon: Icons.lock_outline_rounded,
              obscure: _obscureConfirm,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: Colors.grey.shade400,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password confirm કરો';
                if (v != _passCtrl.text) return 'Password match નથી';
                return null;
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.5),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Account બનાવો',
                        style: TextStyle(
                          fontFamily: 'NotoSansGujarati',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Account છે? ',
                  style: TextStyle(
                    fontFamily: 'NotoSansGujarati',
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
                GestureDetector(
                  onTap: widget.onSwitchToLogin,
                  child: const Text(
                    'લૉગિન કરો',
                    style: TextStyle(
                      fontFamily: 'NotoSansGujarati',
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Google + Apple buttons
            const SocialAuthButtons(),
          ],
        ),
      ),
    );
  }
}

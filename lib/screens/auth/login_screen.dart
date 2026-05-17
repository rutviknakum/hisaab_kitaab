import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_colors.dart';
import '../../main.dart';
import 'auth_field.dart';
import 'social_auth_buttons.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onSwitchToSignup;
  const LoginScreen({super.key, this.onSwitchToSignup});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await supabase.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
    } on AuthException catch (e) {
      if (mounted) _showError(_authMsg(e.message));
    } catch (_) {
      if (mounted) _showError('કંઈ ખોટું ગયું. ફરી try કરો.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showError('પહેલા email દાખલ કરો');
      return;
    }
    try {
      await supabase.auth.resetPasswordForEmail(email);
      if (mounted) _showSuccess('Password reset email મોકલ્યો');
    } on AuthException catch (e) {
      if (mounted) _showError(_authMsg(e.message));
    }
  }

  String _authMsg(String msg) {
    if (msg.contains('Invalid login')) return 'Email અથવા Password ખોટો';
    if (msg.contains('Email not confirmed')) return 'Email verify કરો';
    if (msg.contains('Too many requests'))
      return 'ઘણા attempts. થોડો સમય રાહ જુઓ';
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
            const SizedBox(height: 14),
            AuthField(
              controller: _passCtrl,
              label: 'Password',
              hint: 'Password દાખલ કરો',
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
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _forgotPassword,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                ),
                child: const Text(
                  'Password ભૂલ્યા?',
                  style: TextStyle(
                    fontFamily: 'NotoSansGujarati',
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
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
                        'લૉગિન કરો',
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
                  'Account નથી? ',
                  style: TextStyle(
                    fontFamily: 'NotoSansGujarati',
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
                GestureDetector(
                  onTap: widget.onSwitchToSignup,
                  child: const Text(
                    'સાઇનઅપ કરો',
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

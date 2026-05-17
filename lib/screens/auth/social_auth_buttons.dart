import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../core/app_colors.dart';
import '../../services/social_auth_service.dart';

class SocialAuthButtons extends StatefulWidget {
  const SocialAuthButtons({super.key});

  @override
  State<SocialAuthButtons> createState() => _SocialAuthButtonsState();
}

class _SocialAuthButtonsState extends State<SocialAuthButtons> {
  bool _googleLoading = false;
  bool _appleLoading = false;

  Future<void> _handleGoogle() async {
    setState(() => _googleLoading = true);
    try {
      await SocialAuthService.signInWithGoogle();
    } catch (e, st) {
      debugPrint('Google sign-in error: $e');
      debugPrintStack(stackTrace: st);

      if (mounted) {
        final errorText = e.toString().contains('canceled')
            ? 'Google sign in cancel કર્યું'
            : 'Google error: $e';

        _showError(errorText);
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _handleApple() async {
    setState(() => _appleLoading = true);
    try {
      await SocialAuthService.signInWithApple();
    } catch (e, st) {
      debugPrint('Apple sign-in error: $e');
      debugPrintStack(stackTrace: st);

      if (mounted) {
        final errorText = e.toString().contains('canceled')
            ? 'Apple sign in cancel કર્યું'
            : 'Apple error: $e';

        _showError(errorText);
      }
    } finally {
      if (mounted) setState(() => _appleLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontFamily: 'NotoSansGujarati'),
        ),
        backgroundColor: AppColors.expense,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(
                color: Colors.grey.withValues(alpha: 0.3),
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'અથવા',
                style: TextStyle(
                  fontFamily: 'NotoSansGujarati',
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: Colors.grey.withValues(alpha: 0.3),
                thickness: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SocialButton(
          onTap: _handleGoogle,
          loading: _googleLoading,
          icon: _GoogleIcon(),
          label: 'Google થી ચાલુ કરો',
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        if (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)
          _SocialButton(
            onTap: _handleApple,
            loading: _appleLoading,
            icon: _AppleIcon(isDark: isDark),
            label: 'Apple થી ચાલુ કરો',
            isDark: isDark,
          ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool loading;
  final Widget icon;
  final String label;
  final bool isDark;

  const _SocialButton({
    required this.onTap,
    required this.loading,
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: loading ? null : onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: Colors.grey.withValues(alpha: 0.35),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor:
              isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        ),
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'NotoSansGujarati',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final center = rect.center;
    final radius = size.width / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.57,
      3.14,
      false,
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.18,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      1.57,
      1.05,
      false,
      Paint()
        ..color = const Color(0xFFEA4335)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.18,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.62,
      0.52,
      false,
      Paint()
        ..color = const Color(0xFFFBBC05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.18,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.52,
      0.52,
      false,
      Paint()
        ..color = const Color(0xFF34A853)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.18,
    );

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center.dx + radius * 0.25, center.dy),
        width: radius * 0.9,
        height: size.height * 0.18,
      ),
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AppleIcon extends StatelessWidget {
  final bool isDark;
  const _AppleIcon({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.apple,
      size: 22,
      color: isDark ? Colors.white : Colors.black,
    );
  }
}

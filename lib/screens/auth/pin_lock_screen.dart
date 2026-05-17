import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../database/database_helper.dart';
import '../../database/db_constants.dart';
import '../../providers/settings_provider.dart';

enum PinMode { setup, verify, change }

class PinLockScreen extends StatefulWidget {
  final PinMode mode;
  final String correctPin;
  final VoidCallback onSuccess;

  const PinLockScreen({
    super.key,
    required this.mode,
    required this.correctPin,
    required this.onSuccess,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen>
    with SingleTickerProviderStateMixin {
  final _localAuth = LocalAuthentication();

  String _pin = '';
  String _confirmPin = '';
  bool _isConfirm = false;
  bool _hasError = false;
  String _errorMsg = '';
  int _attempts = 0;

  static const _maxAttempts = 5;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _shakeCtrl,
        curve: Curves.elasticIn,
      ),
    );

    if (widget.mode == PinMode.verify) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryBiometric();
      });
    }
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _tryBiometric() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();

      if (!canCheck || !isSupported) return;

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Hisaab Kitaab ખોલવા ઓળખ આપો',
      );

      if (authenticated && mounted) {
        _goHome();
      }
    } catch (_) {}
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode('${pin}hisaab_salt_2024');
    return sha256.convert(bytes).toString();
  }

  void _onKey(String key) {
    if (_pin.length >= 4) return;

    HapticFeedback.lightImpact();

    setState(() {
      _pin += key;
      _hasError = false;
    });

    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 150), _processPin);
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;

    HapticFeedback.lightImpact();

    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _processPin() async {
    switch (widget.mode) {
      case PinMode.setup:
      case PinMode.change:
        await _handleSetup();
        break;
      case PinMode.verify:
        await _handleVerify();
        break;
    }
  }

  Future<void> _handleSetup() async {
    if (!_isConfirm) {
      setState(() {
        _confirmPin = _pin;
        _pin = '';
        _isConfirm = true;
      });
    } else {
      if (_pin == _confirmPin) {
        final db = DatabaseHelper.instance;

        await db.setSetting(DbConstants.kPinHash, _hashPin(_pin));
        await context.read<SettingsProvider>().setPin(_pin);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'PIN સેટ થઈ ગઈ! ✅',
              style: TextStyle(fontFamily: 'NotoSansGujarati'),
            ),
            backgroundColor: AppColors.income,
          ),
        );

        _goHome();
      } else {
        _showError('PIN મેળ ખાતી નથી, ફરી કરો');

        setState(() {
          _pin = '';
          _confirmPin = '';
          _isConfirm = false;
        });
      }
    }
  }

  Future<void> _handleVerify() async {
    final enteredHash = _hashPin(_pin);
    final storedHash = _hashPin(widget.correctPin);

    if (enteredHash == storedHash) {
      _attempts = 0;
      _goHome();
    } else {
      _attempts++;
      _shakeCtrl.forward(from: 0);
      HapticFeedback.heavyImpact();

      if (_attempts >= _maxAttempts) {
        _showError('ઘણા ખોટા attempts! 30 સેકન્ડ રાહ જુઓ');
        await Future.delayed(const Duration(seconds: 30));
        _attempts = 0;
      } else {
        _showError('ખોટી PIN — ${_maxAttempts - _attempts} attempts બાકી');
      }

      setState(() {
        _pin = '';
      });
    }
  }

  void _showError(String msg) {
    setState(() {
      _hasError = true;
      _errorMsg = msg;
    });
  }

  void _goHome() {
    if (!mounted) return;

    if (widget.mode == PinMode.verify) {
      widget.onSuccess();
    } else {
      Navigator.pop(context);
    }
  }

  String get _titleText {
    switch (widget.mode) {
      case PinMode.setup:
        return _isConfirm ? 'PIN ફરી નાખો' : 'નવી PIN સેટ કરો';
      case PinMode.verify:
        return 'હિસાબ કિતાબ';
      case PinMode.change:
        return _isConfirm ? 'PIN ફરી નાખો' : 'નવી PIN નાખો';
    }
  }

  String get _subtitleText {
    switch (widget.mode) {
      case PinMode.setup:
        return _isConfirm
            ? 'Confirm PIN — ફરી 4 આંકડા નાખો'
            : '4 આંકડા ની PIN બનાવો';
      case PinMode.verify:
        return 'PIN નાખો';
      case PinMode.change:
        return _isConfirm ? 'Confirm PIN' : '4 આંકડા ની નવી PIN';
    }
  }

  Widget _buildKeypad() {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys
          .map(
            (row) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((key) {
                if (key.isEmpty) return const SizedBox(width: 72);

                if (key == 'del') {
                  return _KeyButton(
                    onTap: _onDelete,
                    onLongPress: () => setState(() => _pin = ''),
                    child: const Icon(
                      Icons.backspace_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  );
                }

                return _KeyButton(
                  onTap: () => _onKey(key),
                  child: Text(
                    key,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    Color(0xFF171614),
                    Color(0xFF1C1B19),
                  ]
                : const [
                    AppColors.primary,
                    Color(0xFF0C4E54),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 48),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    '₹',
                    style: TextStyle(
                      fontSize: 36,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _titleText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'NotoSansGujarati',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _subtitleText,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontFamily: 'NotoSansGujarati',
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 48),
              AnimatedBuilder(
                animation: _shakeAnim,
                builder: (_, child) => Transform.translate(
                  offset: Offset(
                    _shakeCtrl.isAnimating
                        ? 12 *
                            (_shakeAnim.value <= 0.5
                                ? _shakeAnim.value * 2
                                : (1 - _shakeAnim.value) * 2) *
                            ((_shakeAnim.value * 10).round().isEven ? 1 : -1)
                        : 0,
                    0,
                  ),
                  child: child!,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    4,
                    (i) => _PinDot(
                      filled: i < _pin.length,
                      hasError: _hasError,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AnimatedOpacity(
                opacity: _hasError ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _errorMsg,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontFamily: 'NotoSansGujarati',
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: _buildKeypad(),
                ),
              ),
              if (widget.mode == PinMode.verify)
                TextButton.icon(
                  onPressed: _tryBiometric,
                  icon: const Icon(
                    Icons.fingerprint,
                    color: Colors.white70,
                    size: 28,
                  ),
                  label: Text(
                    'Fingerprint / Face',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontFamily: 'NotoSansGujarati',
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinDot extends StatelessWidget {
  final bool filled;
  final bool hasError;

  const _PinDot({
    required this.filled,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 10),
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled
            ? (hasError ? Colors.redAccent : Colors.white)
            : Colors.white.withValues(alpha: 0.3),
        border: Border.all(
          color:
              filled ? Colors.transparent : Colors.white.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _KeyButton({
    required this.child,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}

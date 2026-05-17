import 'package:flutter/material.dart';
import 'pin_lock_screen.dart';

// Settings screen માંથી PIN change/setup call
class PinSetupScreen extends StatelessWidget {
  const PinSetupScreen({super.key});

  @override
  Widget build(BuildContext context) => PinLockScreen(
        mode: PinMode.setup,
        correctPin: '',
        onSuccess: () {},
      );
}

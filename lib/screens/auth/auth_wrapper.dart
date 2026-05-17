import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../../providers/settings_provider.dart';
import '../home/main_navigation.dart';
import 'auth_screen.dart';
import 'pin_lock_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final currentSession = supabase.auth.currentSession;

    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      initialData: AuthState(AuthChangeEvent.initialSession, currentSession),
      builder: (context, snapshot) {
        final session = snapshot.data?.session;

        if (session == null) {
          return const AuthScreen();
        }

        final settP = context.read<SettingsProvider>();

        if (settP.hasPin) {
          return PinLockScreen(
            correctPin: settP.pin,
            mode: PinMode.verify,
            onSuccess: () {
              navigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const MainNavigation(),
                ),
                (route) => false,
              );
            },
          );
        }

        return const MainNavigation();
      },
    );
  }
}

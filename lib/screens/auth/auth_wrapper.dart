import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../../providers/profile_provider.dart';
import '../../providers/settings_provider.dart';
import '../home/main_navigation.dart';
import '../setup/first_setup_screen.dart';
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
                  builder: (_) => const _PostLoginGate(),
                ),
                (route) => false,
              );
            },
          );
        }

        return const _PostLoginGate();
      },
    );
  }
}

class _PostLoginGate extends StatefulWidget {
  const _PostLoginGate();

  @override
  State<_PostLoginGate> createState() => _PostLoginGateState();
}

class _PostLoginGateState extends State<_PostLoginGate> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ProfileProvider>().loadProfile();
      if (mounted) {
        setState(() => _loading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final profileP = context.watch<ProfileProvider>();

    if (!profileP.setupCompleted) {
      return const FirstSetupScreen();
    }

    return const MainNavigation();
  }
}

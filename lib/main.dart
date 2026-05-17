import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hisaab_kitaab/screens/splash/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'providers/account_provider.dart';
import 'providers/loan_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/transaction_provider.dart';

// Global Navigator Key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global Supabase client shortcut
final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await Supabase.initialize(
    url: 'https://eukqpwresoorokammjoe.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV1a3Fwd3Jlc29vcm9rYW1tam9lIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg5MDYwMzIsImV4cCI6MjA5NDQ4MjAzMn0.znoYdBL2K8kVzIabjS-Wbj_E3oS2zYZCvq4hb3aF8mc',
  );

  final settP = SettingsProvider();
  await settP.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settP),
        ChangeNotifierProvider(
          create: (_) => TransactionProvider()..loadTransactions(),
        ),
        ChangeNotifierProvider(
          create: (_) => AccountProvider()..loadAccounts(),
        ),
        ChangeNotifierProvider(
          create: (_) => LoanProvider()..loadAll(),
        ),
      ],
      child: const HisaabKitaabApp(),
    ),
  );
}

class HisaabKitaabApp extends StatelessWidget {
  const HisaabKitaabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (ctx, settP, _) => MaterialApp(
        title: 'હિસાબ કિતાબ',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        themeMode: settP.themeMode,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}

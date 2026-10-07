import 'package:flutter/material.dart';
import 'package:cargoo_shared/cargoo_shared.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseService.init(
    url: const String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://SEU-PROJETO.supabase.co'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'SUA_ANON_KEY'),
  );

  runApp(const CargooDriverApp());
}

class CargooDriverApp extends StatelessWidget {
  const CargooDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cargoo Motorista',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const DriverSplashScreen(),
    );
  }
}

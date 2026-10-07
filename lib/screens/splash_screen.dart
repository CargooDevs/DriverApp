import 'package:flutter/material.dart';
import 'package:cargoo_shared/cargoo_shared.dart';
import 'auth/driver_login_screen.dart';

class DriverSplashScreen extends StatefulWidget {
  const DriverSplashScreen({super.key});

  @override
  State<DriverSplashScreen> createState() => _DriverSplashScreenState();
}

class _DriverSplashScreenState extends State<DriverSplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const DriverLoginScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.driverAccent,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 88, height: 88, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(24)), child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 46)),
          const SizedBox(height: 20),
          const Text('Cargoo', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
            child: const Text('MOTORISTA', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          ),
          const SizedBox(height: 10),
          const Text('Carga, corridas e aluguer — tudo num só lugar', style: TextStyle(color: Colors.white70, fontSize: 13)),
        ]),
      ),
    );
  }
}

import 'package:eye_health/pages/home_screen/home_screen.dart';
import 'package:eye_health/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  /// Keep short — native splash already showed the same frame.
  static const Duration _holdDuration = Duration(milliseconds: 900);
  static const String _iconPath = 'assets/icons/launcher_icon.png';

  @override
  void initState() {
    super.initState();
    // Hand off from native splash to this matching Flutter screen.
    FlutterNativeSplash.remove();
    _navigateToHome();
  }

  void _navigateToHome() {
    Future.delayed(_holdDuration, () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Matches native splash: solid primary + centered logo only.
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Image.asset(
          _iconPath,
          width: 160,
          height: 160,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

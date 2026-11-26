import 'package:eye_health/pages/main_shell/main_shell.dart';
import 'package:eye_health/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

/// Single branded splash: circular logo on theme blue.
/// Native splash is color-only and is removed after this screen paints,
/// so you effectively see one splash.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Duration _holdDuration = Duration(milliseconds: 1400);
  static const String _iconPath = 'assets/icons/launcher_icon.png';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Drop the color-only native splash once this circular logo is on screen.
      FlutterNativeSplash.remove();
    });
    _navigateToHome();
  }

  void _navigateToHome() {
    Future.delayed(_holdDuration, () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainShell()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: ClipOval(
          child: Image.asset(
            _iconPath,
            width: 160,
            height: 160,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

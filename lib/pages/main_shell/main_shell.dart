import 'package:eye_health/pages/home_screen/home_screen.dart';
import 'package:eye_health/pages/image_picker_screen/image_picker_screen.dart';
import 'package:eye_health/theme/app_theme.dart';
import 'package:flutter/material.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  void _onTakeFundus(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ImagePickerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const HomeScreen(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _TakeFundusButton(
        onPressed: () => _onTakeFundus(context),
      ),
    );
  }
}

class _TakeFundusButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _TakeFundusButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}

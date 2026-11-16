import 'package:eye_health/pages/image_picker_screen/image_picker_screen.dart';
import 'package:eye_health/pages/image_processing_screen/image_processing_screen.dart';
import 'package:eye_health/pages/statistics_screen/statistics_screen.dart';
import 'package:eye_health/theme/app_theme.dart';
import 'package:eye_health/utils/utility_methods/color_print.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _appTitle = 'EYEHEALTH';

  List<_MenuItem> _getMenuItems() {
    return [
      _MenuItem(
        icon: Icons.camera_alt,
        text: 'Take a Fundus Photo',
        onTap: () => _navigateToImagePicker('Take a Fundus Photo'),
      ),
      _MenuItem(
        icon: Icons.upload,
        text: 'Upload a Fundus Photo',
        onTap: () => _navigateToImagePicker('Upload a Fundus Photo'),
      ),
      _MenuItem(
        icon: Icons.bar_chart,
        text: 'Personal Health Statistics',
        onTap: () {
          _navigateToScreen(
            buttonName: 'Personal Health Statistics',
            screen: const StatisticsScreen(),
          );
        },
      ),
      _MenuItem(
        icon: Icons.chat,
        text: 'Start a Conversation',
        onTap: () {
          _navigateToScreen(
            buttonName: 'Conversation',
            screen: const PhotoProcessingScreen(photos: []),
          );
        },
      ),
    ];
  }

  void _navigateToImagePicker(String buttonName) {
    if (kDebugMode) {
      colorPrint('$buttonName button pressed - Navigating to Image Picker');
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ImagePickerScreen()),
    );
  }

  void _navigateToScreen({required String buttonName, required Widget screen}) {
    if (kDebugMode) {
      colorPrint('$buttonName button pressed - Navigating to Screen');
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final items = _getMenuItems();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final fontSize =
        screenWidth < 360
            ? 18.0
            : screenWidth < 480
            ? 20.0
            : screenWidth < 600
            ? 22.0
            : 24.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: Image.asset(
                'assets/icons/launcher_icon.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Text(_appTitle),
          ],
        ),
        toolbarHeight: 70,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _MenuCard(
              icon: item.icon,
              text: item.text,
              fontSize: fontSize,
              onTap: item.onTap,
            );
          },
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.text,
    required this.onTap,
  });
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final double fontSize;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.text,
    required this.fontSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 32, color: AppColors.primaryDark),
                ),
                const SizedBox(height: 10),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

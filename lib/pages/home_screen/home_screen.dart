import 'package:eye_health/pages/image_picker_screen/image_picker_screen.dart';
import 'package:eye_health/pages/image_processing_screen/image_processing_screen.dart';
import 'package:eye_health/pages/statistics_screen/statistics_screen.dart';
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
  static const double _padding = 20.0;
  static const String _underConstructionMessage = 'Under Construction';

  List<_ButtonData> _getButtons() {
    return [
      _ButtonData(
        icon: Icons.camera_alt,
        text: 'Take a Fundus Photo',
        onPressed: () => _navigateToImagePicker('Take a Fundus Photo'),
      ),
      _ButtonData(
        icon: Icons.upload,
        text: 'Upload a Fundus Photo',
        onPressed: () => _navigateToImagePicker('Upload a Fundus Photo'),
      ),
      _ButtonData(
        icon: Icons.bar_chart,
        text: 'Personal Health Statistics',
        onPressed: () {
          _navigateToScreen(
            buttonName: 'Personal Health Statistics',
            screen: StatisticsScreen(),
          );
        },
      ),
      _ButtonData(
        icon: Icons.chat,
        text: 'Start a Conversation',
        onPressed: () {
          _navigateToScreen(
            buttonName: 'Conversation',
            screen: PhotoProcessingScreen(photos: []),
           // screen: StaticImageProcessingScreen(photos: []),
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

  void _defaultOnPressed(String buttonName) {
    if (kDebugMode) {
      colorPrint('$buttonName button pressed - $_underConstructionMessage');
    }
    // You could show a snackbar or dialog here instead
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$buttonName - $_underConstructionMessage')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              icon: ClipOval(
                child: Image.asset(
                  'assets/icons/launcher_icon.png',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              onPressed: () {
                if (kDebugMode) {
                  colorPrint('Menu button pressed');
                }
                // Handle menu button press
              },
            ),
            //const SizedBox(width: 8),
            const Text(_appTitle),
          ],
        ),
        toolbarHeight: 75,
        centerTitle: true,
        // leading: IconButton(
        //   icon: ClipOval(
        //     child: Image.asset(
        //       'assets/icons/launcher_icon.png',
        //       width: 100,
        //       height: 100,
        //       fit: BoxFit.cover,
        //     ),
        //   ),
        //   onPressed: () {
        //     if (kDebugMode) {
        //       colorPrint('Menu button pressed');
        //     }
        //     // Handle menu button press
        //   },
        // ),
        /// Increase the height of the AppBar
        flexibleSpace: Container(height: 100),
      ),
      body: Padding(
        padding: const EdgeInsets.all(_padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 12,
          children:
              _getButtons()
                  .map(
                    (buttonData) => _FeatureButton(
                      icon: buttonData.icon,
                      text: buttonData.text,
                      onPressed: buttonData.onPressed,
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }
}

class _ButtonData {
  final IconData icon;
  final String text;
  final VoidCallback onPressed;

  const _ButtonData({
    required this.icon,
    required this.text,
    required this.onPressed,
  });
}

class _FeatureButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onPressed;

  const _FeatureButton({
    required this.icon,
    required this.text,
    required this.onPressed,
  });

  static const double _borderRadius = 12.0;
  static const double _iconSize = 40.0;
  static const double _spacing = 12.0;
  static const double _horizontalPadding = 16.0;
  static const double _verticalPadding = 14.0;
  static const double _marginBottom = 12.0;

  @override
  Widget build(BuildContext context) {
    // Get the screen width to calculate responsive text size
    final screenWidth = MediaQuery.sizeOf(context).width;
    // Calculate responsive font size (between 18 and 32 based on screen width)
    final fontSize =
        screenWidth < 360
            ? 20.0
            : screenWidth < 480
            ? 24.0
            : screenWidth < 600
            ? 26.0
            : 32.0;

    colorPrint('Fontsize : $fontSize');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: _marginBottom),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: _horizontalPadding,
            vertical: _verticalPadding,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[800],
                borderRadius: BorderRadius.circular(_borderRadius),
              ),
              child: Icon(icon, size: _iconSize, color: Colors.white),
            ),
            const SizedBox(width: _spacing),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: fontSize, color: Colors.white),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

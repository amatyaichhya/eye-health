import 'package:eye_health/utils/utility_methods/color_print.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class EyeHealthAppbar extends StatelessWidget implements PreferredSizeWidget {
  const EyeHealthAppbar({super.key});
  static const String _appTitle = 'EYEHEALTH';

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
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
      //leading: Icon(Icons.arrow_back),
      // automaticallyImplyLeading: false,
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
      // flexibleSpace: Container(height: 100),
    );
  }

  @override
  // TODO: implement preferredSize
  Size get preferredSize => const Size.fromHeight(75.0);
}

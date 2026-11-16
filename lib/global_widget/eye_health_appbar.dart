import 'package:flutter/material.dart';

class EyeHealthAppbar extends StatelessWidget implements PreferredSizeWidget {
  const EyeHealthAppbar({super.key});

  static const String _appTitle = 'EYEHEALTH';

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: Image.asset(
              'assets/icons/launcher_icon.png',
              width: 36,
              height: 36,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          const Text(_appTitle),
        ],
      ),
      toolbarHeight: 70,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}

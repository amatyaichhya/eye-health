import 'package:flutter/material.dart';

class EyeHealthAppbar extends StatelessWidget implements PreferredSizeWidget {
  const EyeHealthAppbar({
    super.key,
    this.title = 'Eye Health',
    this.showBack = true,
  });

  final String title;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return AppBar(
      leading:
          showBack && canPop
              ? IconButton(
                icon: const Icon(Icons.chevron_left, size: 32),
                onPressed: () => Navigator.pop(context),
              )
              : null,
      automaticallyImplyLeading: false,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      titleSpacing: 0,
      centerTitle: false,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

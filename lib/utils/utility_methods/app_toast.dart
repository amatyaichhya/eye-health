import 'package:eye_health/theme/app_theme.dart';
import 'package:flutter/material.dart';

enum AppToastType { info, success, error }

/// Shows a toast / snackbar pinned near the top of the screen.
void showAppToast(
  BuildContext context,
  String message, {
  AppToastType type = AppToastType.info,
  Color? backgroundColor,
  Duration duration = const Duration(seconds: 2),
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();

  final media = MediaQuery.of(context);
  final topInset = media.padding.top + 12;
  const snackHeight = 52.0;

  final color =
      backgroundColor ??
      switch (type) {
        AppToastType.success => const Color(0xFF2E7D32),
        AppToastType.error => const Color(0xFFC62828),
        AppToastType.info => AppColors.primary,
      };

  messenger.showSnackBar(
    SnackBar(
      content: Text(message, textAlign: TextAlign.center),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.only(
        top: topInset,
        left: 16,
        right: 16,
        bottom: media.size.height - topInset - snackHeight,
      ),
      duration: duration,
    ),
  );
}

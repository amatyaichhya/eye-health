import 'package:eye_health/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Shared elevated surface card used across the app (home tiles, reports, etc.).
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;
  final Color? color;
  final double? width;
  final double? height;

  static const BorderRadius defaultRadius = BorderRadius.all(Radius.circular(8));

  static const List<BoxShadow> defaultShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 8,
      spreadRadius: 0,
      offset: Offset(0, 2),
    ),
  ];

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.borderRadius = defaultRadius,
    this.color,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final content = padding == null
        ? child
        : Padding(padding: padding!, child: child);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: borderRadius,
        boxShadow: defaultShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? content
            : InkWell(
                onTap: onTap,
                borderRadius: borderRadius,
                child: content,
              ),
      ),
    );
  }
}

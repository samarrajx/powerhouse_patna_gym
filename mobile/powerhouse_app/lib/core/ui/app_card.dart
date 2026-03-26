import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'design_system.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? radius;
  final Color? backgroundColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.radius,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppPadding.p16),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surf(context),
        borderRadius: BorderRadius.circular(radius ?? AppRadius.r12),
        border: Border.all(
          color: AppColors.surfHigh(context),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

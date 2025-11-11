import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;
  final double? elevation;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.onTap,
    this.elevation,
    this.borderRadius,
    this.boxShadow,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBorderRadius = BorderRadius.circular(AppTheme.radiusMedium);
    
    Widget cardContent = Container(
      padding: padding ?? const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppTheme.getCardColor(context)) : null,
        gradient: gradient,
        borderRadius: borderRadius ?? defaultBorderRadius,
        boxShadow: boxShadow ?? AppTheme.cardShadow(context),
      ),
      child: child,
    );

    if (onTap != null) {
      return Container(
        margin: margin,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius ?? defaultBorderRadius,
            child: cardContent,
          ),
        ),
      );
    }

    return Container(
      margin: margin,
      child: cardContent,
    );
  }
}

import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class GradientHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Color>? gradientColors;
  final Widget? action;
  const GradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.gradientColors,
    this.action,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingLarge,
        AppTheme.spacingXLarge,
        AppTheme.spacingLarge,
        AppTheme.spacingLarge + 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors ?? [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (gradientColors?.first ?? Theme.of(context).primaryColor)
                .withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMedium),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 16,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

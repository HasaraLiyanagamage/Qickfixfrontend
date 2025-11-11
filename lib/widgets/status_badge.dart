import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  final bool useGradient;

  const StatusBadge({
    super.key,
    required this.text,
    required this.color,
    this.icon,
    this.useGradient = false,
  });

  factory StatusBadge.success(String text, {IconData? icon}) {
    return StatusBadge(
      text: text,
      color: AppTheme.success,
      icon: icon,
      useGradient: true,
    );
  }

  factory StatusBadge.warning(String text, {IconData? icon}) {
    return StatusBadge(
      text: text,
      color: AppTheme.warning,
      icon: icon,
      useGradient: true,
    );
  }

  factory StatusBadge.error(String text, {IconData? icon}) {
    return StatusBadge(
      text: text,
      color: AppTheme.error,
      icon: icon,
      useGradient: true,
    );
  }

  factory StatusBadge.info(String text, {IconData? icon}) {
    return StatusBadge(
      text: text,
      color: AppTheme.info,
      icon: icon,
      useGradient: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        gradient: useGradient
            ? LinearGradient(
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.15),
                ],
              )
            : null,
        color: useGradient ? null : color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:streetbite/core/constants/app_constants.dart';
import 'package:streetbite/core/theme/app_theme.dart';

/// Compact live status badge showing whether a street stall is Open or Closed.
class OpenStatusPill extends StatelessWidget {
  const OpenStatusPill({
    super.key,
    required this.isOpen,
    this.compact = false,
  });

  final bool isOpen;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final foreground =
        isOpen ? AppTheme.openGreenColor : AppTheme.closedGreyColor;
    final background = isOpen
        ? AppTheme.openGreenLight.withValues(alpha: 0.16)
        : Theme.of(context).colorScheme.surfaceContainerHighest;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : 10.0,
        vertical: compact ? 3.0 : 5.0,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(
          color: foreground.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: compact ? 7.0 : 8.0,
            height: compact ? 7.0 : 8.0,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5.0),
          Text(
            isOpen ? 'Open Now' : 'Closed',
            style: (compact ? textTheme.labelSmall : textTheme.labelMedium)
                ?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

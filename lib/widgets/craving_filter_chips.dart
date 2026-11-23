import 'package:flutter/material.dart';
import 'package:streetbite/core/constants/app_constants.dart';

/// Horizontal scrollable craving chips plus an "Open Now Only" filter chip.
class CravingFilterChips extends StatelessWidget {
  const CravingFilterChips({
    super.key,
    required this.selectedQuery,
    required this.openNowOnly,
    required this.onCravingTap,
    required this.onOpenNowToggle,
  });

  final String selectedQuery;
  final bool openNowOnly;
  final ValueChanged<String> onCravingTap;
  final VoidCallback onOpenNowToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalizedSelected = selectedQuery.trim().toLowerCase();

    return SizedBox(
      height: 44.0,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilterChip(
              avatar: Icon(
                Icons.access_time_filled,
                size: 16.0,
                color: openNowOnly
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.primary,
              ),
              label: const Text('Open Now Only'),
              selected: openNowOnly,
              onSelected: (_) => onOpenNowToggle(),
            ),
          ),
          ...AppSearchConfig.cravingTags.map((tag) {
            final isSelected = normalizedSelected == tag.toLowerCase();
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (_) => onCravingTap(tag),
              ),
            );
          }),
        ],
      ),
    );
  }
}

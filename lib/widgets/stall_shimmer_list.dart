import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:streetbite/core/constants/app_constants.dart';

/// Shimmer loading placeholders displayed while fetching nearby stalls.
class StallShimmerList extends StatelessWidget {
  const StallShimmerList({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.surfaceContainerHighest;
    final highlightColor = colorScheme.surfaceContainerLow;

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, _) {
        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            height: 248.0,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
          ),
        );
      },
    );
  }
}

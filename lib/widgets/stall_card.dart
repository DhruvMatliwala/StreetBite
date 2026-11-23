import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:streetbite/core/constants/app_constants.dart';
import 'package:streetbite/core/theme/app_theme.dart';
import 'package:streetbite/models/stall.dart';
import 'package:streetbite/services/storage_service.dart';
import 'package:streetbite/utils/geohash_util.dart';
import 'package:streetbite/widgets/status_pill.dart';

/// Renders network, in-memory demo, or fallback food imagery reliably.
class StallImage extends StatelessWidget {
  const StallImage({
    super.key,
    required this.imageUrl,
    this.height = 170.0,
    this.width = double.infinity,
    this.fit = BoxFit.cover,
  });

  final String imageUrl;
  final double height;
  final double width;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget fallbackWidget() {
      return Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              colorScheme.primaryContainer,
              colorScheme.secondaryContainer,
            ],
          ),
        ),
        child: Icon(
          Icons.fastfood_rounded,
          size: 48.0,
          color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
        ),
      );
    }

    if (imageUrl.isEmpty) {
      return fallbackWidget();
    }

    if (imageUrl.startsWith('memory://')) {
      final bytes = StorageService.getDemoImageBytes(imageUrl);
      if (bytes != null) {
        return Image.memory(
          bytes,
          height: height,
          width: width,
          fit: fit,
          errorBuilder: (_, __, ___) => fallbackWidget(),
        );
      }
      return fallbackWidget();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      height: height,
      width: width,
      fit: fit,
      placeholder: (_, __) => Container(
        height: height,
        width: width,
        color: colorScheme.surfaceContainerHighest,
        child: const Center(
          child: SizedBox(
            width: 24.0,
            height: 24.0,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      ),
      errorWidget: (_, __, ___) => fallbackWidget(),
    );
  }
}

/// Material 3 card presenting a street food stall with distance, dishes, and status.
class StallCard extends StatelessWidget {
  const StallCard({
    super.key,
    required this.stallWithDistance,
    required this.onTap,
  });

  final StallWithDistance stallWithDistance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final stall = stallWithDistance.stall;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dishHighlights =
        stall.menuItems.take(3).map((item) => item.name).join(' • ');

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Stack(
              children: <Widget>[
                StallImage(
                  imageUrl: stall.bannerImageUrl,
                  height: 156.0,
                ),
                Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                  child: OpenStatusPill(isOpen: stall.isOpen),
                ),
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 5.0,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.near_me_rounded,
                          size: 14.0,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          GeohashUtil.formatDistance(
                            stallWithDistance.distanceKm,
                          ),
                          style: textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          stall.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 3.0,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.ratingAmberColor
                              .withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(
                              Icons.star_rounded,
                              size: 15.0,
                              color: AppTheme.ratingAmberColor,
                            ),
                            const SizedBox(width: 3.0),
                            Text(
                              stall.overallRating.toStringAsFixed(1),
                              style: textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.place_outlined,
                        size: 15.0,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4.0),
                      Expanded(
                        child: Text(
                          stall.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (dishHighlights.isNotEmpty) ...<Widget>[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      dishHighlights,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Wrap(
                          spacing: 6.0,
                          runSpacing: 4.0,
                          children: stall.crowdTags
                              .take(2)
                              .map(
                                (tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 3.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondaryContainer
                                        .withValues(alpha: 0.6),
                                    borderRadius:
                                        BorderRadius.circular(AppRadii.pill),
                                  ),
                                  child: Text(
                                    tag,
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      if (stall.startingPrice != null)
                        Text(
                          'From ₹${stall.startingPrice!.round()}',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:streetbite/core/constants/app_constants.dart';
import 'package:streetbite/core/theme/app_theme.dart';
import 'package:streetbite/models/review.dart';
import 'package:streetbite/models/stall.dart';
import 'package:streetbite/providers/auth_provider.dart';
import 'package:streetbite/providers/stall_provider.dart';
import 'package:streetbite/services/navigation_service.dart';
import 'package:streetbite/utils/geohash_util.dart';
import 'package:streetbite/widgets/menu_item_editor.dart';
import 'package:streetbite/widgets/stall_card.dart';
import 'package:streetbite/widgets/status_pill.dart';

/// Detailed view of a street food stall with special discounts, menu, ratings, reviews & 1-tap navigation.
class StallDetailScreen extends StatefulWidget {
  const StallDetailScreen({
    super.key,
    required this.stallWithDistance,
  });

  final StallWithDistance stallWithDistance;

  @override
  State<StallDetailScreen> createState() => _StallDetailScreenState();
}

class _StallDetailScreenState extends State<StallDetailScreen> {
  final NavigationService _navigationService = NavigationService();
  late Stall _stall;
  List<Review> _reviews = <Review>[];
  bool _loadingReviews = true;

  @override
  void initState() {
    super.initState();
    _stall = widget.stallWithDistance.stall;
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _loadingReviews = true);
    try {
      final fetched =
          await context.read<StallProvider>().fetchReviews(_stall.id);
      if (!mounted) return;
      setState(() {
        _reviews = fetched;
        _loadingReviews = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingReviews = false);
    }
  }

  Future<void> _launchNavigation() async {
    final launched = await _navigationService.openTurnByTurnDirections(
      latitude: _stall.latitude,
      longitude: _stall.longitude,
      label: _stall.name,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Google Maps on this device.'),
        ),
      );
    }
  }

  Future<void> _openWriteReviewSheet() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in on the Profile tab to post a review.'),
        ),
      );
      return;
    }

    final result = await showModalBottomSheet<Review>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _WriteReviewSheet(
        stallId: _stall.id,
        authorUid: auth.effectiveVendorId,
        authorName: auth.displayName,
      ),
    );
    if (result == null || !mounted) return;

    final updatedStall =
        await context.read<StallProvider>().submitReview(result);
    if (!mounted) return;
    if (updatedStall != null) {
      setState(() => _stall = updatedStall);
    }
    await _loadReviews();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final offer = _stall.hasValidOffer ? _stall.activeOffer : null;

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 240.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _stall.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  shadows: <Shadow>[
                    Shadow(color: Colors.black54, blurRadius: 8.0),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  StallImage(
                    imageUrl: _stall.bannerImageUrl,
                    height: 240.0,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.transparent,
                          Colors.black54,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820.0),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          OpenStatusPill(isOpen: _stall.isOpen),
                          const SizedBox(width: AppSpacing.sm),
                          Chip(
                            avatar: const Icon(Icons.near_me_rounded, size: 16.0),
                            label: Text(
                              GeohashUtil.formatDistance(
                                widget.stallWithDistance.distanceKm,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _stall.description,
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _InfoRow(
                        icon: Icons.place_outlined,
                        label: _stall.address,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _InfoRow(
                        icon: Icons.schedule_rounded,
                        label: 'Hours: ${_stall.operatingHours}',
                      ),
                      if (offer != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.md),
                        _SpecialOfferBannerCard(offer: offer),
                      ],
                      if (_stall.crowdTags.isNotEmpty) ...<Widget>[
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: _stall.crowdTags
                              .map(
                                (tag) => Chip(
                                  backgroundColor:
                                      colorScheme.secondaryContainer,
                                  label: Text(
                                    tag,
                                    style: TextStyle(
                                      color: colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _launchNavigation,
                          icon: const Icon(Icons.directions_rounded),
                          label: const Text('1-Tap Navigate in Google Maps'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _RatingMetricCard(
                              title: 'Taste Rating',
                              score: _stall.tasteRating,
                              icon: Icons.restaurant_rounded,
                              accentColor: AppTheme.ratingAmberColor,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _RatingMetricCard(
                              title: 'Hygiene Rating',
                              score: _stall.hygieneRating,
                              icon: Icons.clean_hands_rounded,
                              accentColor: AppTheme.openGreenColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Full Menu (${_stall.menuItems.length})',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (_stall.menuItems.isEmpty)
                        const Text('No menu items listed yet.')
                      else
                        ..._stall.menuItems.map(
                          (item) => Card(
                            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: ListTile(
                              leading: VegBadge(isVeg: item.isVeg),
                              title: Text(
                                item.name,
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: item.description.isNotEmpty
                                  ? Text(item.description)
                                  : Text(item.category),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  Text(
                                    '₹${item.price.round()}',
                                    style: textTheme.titleMedium?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (!item.isAvailable)
                                    Text(
                                      'Sold out',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: colorScheme.error,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'Community Reviews (${_stall.reviewCount})',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _openWriteReviewSheet,
                            icon: const Icon(Icons.rate_review_outlined),
                            label: const Text('Add Review'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (_loadingReviews)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.md),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_reviews.isEmpty)
                        const Text('No reviews yet. Be the first foodie to rate!')
                      else
                        ..._reviews.map(
                          (review) => Card(
                            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          review.authorName,
                                          style: textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        DateFormat.yMMMd()
                                            .format(review.createdAt),
                                        style: textTheme.labelSmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    'Taste ${review.tasteRating.toStringAsFixed(1)} ★  •  '
                                    'Hygiene ${review.hygieneRating.toStringAsFixed(1)} ★',
                                    style: textTheme.labelMedium?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (review.comment.isNotEmpty) ...<Widget>[
                                    const SizedBox(height: 6.0),
                                    Text(review.comment),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecialOfferBannerCard extends StatelessWidget {
  const _SpecialOfferBannerCard({required this.offer});

  final StallOffer offer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFE65100), Color(0xFFFF8F00)],
        ),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  offer.discountBadge,
                  style: textTheme.labelMedium?.copyWith(
                    color: const Color(0xFFBF360C),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  offer.durationType.label,
                  style: textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            offer.title,
            style: textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4.0),
          Row(
            children: <Widget>[
              const Icon(
                Icons.timer_outlined,
                size: 15.0,
                color: Colors.white,
              ),
              const SizedBox(width: 4.0),
              Text(
                offer.remainingTimeLabel,
                style: textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 18.0, color: colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label)),
      ],
    );
  }
}

class _RatingMetricCard extends StatelessWidget {
  const _RatingMetricCard({
    required this.title,
    required this.score,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final double score;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              backgroundColor: accentColor.withValues(alpha: 0.16),
              child: Icon(icon, color: accentColor),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: textTheme.labelMedium),
                  Text(
                    '${score.toStringAsFixed(1)} / 5.0',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
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

class _WriteReviewSheet extends StatefulWidget {
  const _WriteReviewSheet({
    required this.stallId,
    required this.authorUid,
    required this.authorName,
  });

  final String stallId;
  final String authorUid;
  final String authorName;

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  final _commentController = TextEditingController();
  double _tasteRating = 4.5;
  double _hygieneRating = 4.5;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        bottomInset + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Rate Taste & Hygiene',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Taste Rating: ${_tasteRating.toStringAsFixed(1)} ★'),
          Slider(
            value: _tasteRating,
            min: 1.0,
            max: 5.0,
            divisions: 8,
            onChanged: (v) => setState(() => _tasteRating = v),
          ),
          Text('Hygiene Rating: ${_hygieneRating.toStringAsFixed(1)} ★'),
          Slider(
            value: _hygieneRating,
            min: 1.0,
            max: 5.0,
            divisions: 8,
            onChanged: (v) => setState(() => _hygieneRating = v),
          ),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Share your bite experience',
              hintText: 'How was the flavor, spice, and cart cleanliness?',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final review = Review(
                  id: '',
                  stallId: widget.stallId,
                  authorUid: widget.authorUid,
                  authorName: widget.authorName,
                  tasteRating: _tasteRating,
                  hygieneRating: _hygieneRating,
                  comment: _commentController.text.trim(),
                  createdAt: DateTime.now(),
                );
                Navigator.of(context).pop(review);
              },
              child: const Text('Submit Review'),
            ),
          ),
        ],
      ),
    );
  }
}

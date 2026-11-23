import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streetbite/core/constants/app_constants.dart';
import 'package:streetbite/models/stall.dart';
import 'package:streetbite/providers/auth_provider.dart';
import 'package:streetbite/providers/stall_provider.dart';
import 'package:streetbite/screens/stall_detail_screen.dart';
import 'package:streetbite/services/firestore_stall_service.dart';
import 'package:streetbite/widgets/craving_filter_chips.dart';
import 'package:streetbite/widgets/distance_radius_slider.dart';
import 'package:streetbite/widgets/stall_card.dart';
import 'package:streetbite/widgets/stall_map_view.dart';
import 'package:streetbite/widgets/stall_shimmer_list.dart';
import 'package:streetbite/widgets/streetbite_logo.dart';

/// Main discovery screen supporting debounced dish search, geo-radius slider, offers, and List/Map toggle.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({
    super.key,
    required this.onMapModeChanged,
  });

  final ValueChanged<bool> onMapModeChanged;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final initialQuery = context.read<StallProvider>().cravingQuery;
    _searchController = TextEditingController(text: initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openStallDetail(StallWithDistance item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StallDetailScreen(stallWithDistance: item),
      ),
    );
  }

  void _syncSearchFieldText(String value) {
    _searchController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  Future<void> _openDiscountAlertsSheet() async {
    final stallProvider = context.read<StallProvider>();
    stallProvider.markAllAlertsRead();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final alerts = stallProvider.discountAlerts;
        final textTheme = Theme.of(sheetContext).textTheme;
        final colorScheme = Theme.of(sheetContext).colorScheme;

        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.notifications_active_rounded,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Live Stall Discounts',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Limited-time hourly, daily, weekly, and monthly deals from nearby carts.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: alerts.isEmpty
                        ? const Center(
                            child: Text(
                              'No special discounts active yet. Check back soon!',
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: alerts.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (_, index) {
                              final alert = alerts[index];
                              return Card(
                                margin: EdgeInsets.zero,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        colorScheme.primaryContainer,
                                    foregroundColor:
                                        colorScheme.onPrimaryContainer,
                                    child: const Icon(
                                      Icons.local_offer_rounded,
                                    ),
                                  ),
                                  title: Text(
                                    '${alert.offer.discountBadge} • ${alert.stallName}',
                                    style: textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${alert.offer.title}\n'
                                    '${alert.offer.durationType.label} • ${alert.offer.remainingTimeLabel}',
                                  ),
                                  isThreeLine: true,
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                  ),
                                  onTap: () {
                                    Navigator.of(sheetContext).pop();
                                    final item = stallProvider
                                        .findStallById(alert.stallId);
                                    if (item != null && mounted) {
                                      _openStallDetail(item);
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stallProvider = context.watch<StallProvider>();
    final authProvider = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            const StreetBiteLogo(size: 30.0),
            const SizedBox(width: AppSpacing.sm),
            const Text(
              'StreetBite',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            if (authProvider.isDemoMode) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 2.0,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  'DEMO',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Discount alerts',
            onPressed: _openDiscountAlertsSheet,
            icon: Badge.count(
              count: stallProvider.unreadAlertCount,
              isLabelVisible: stallProvider.unreadAlertCount > 0,
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          IconButton(
            tooltip: 'Refresh GPS location',
            icon: const Icon(Icons.my_location_rounded),
            onPressed: stallProvider.refreshLocationAndStalls,
          ),
          PopupMenuButton<StallSortOrder>(
            tooltip: 'Sort stalls',
            initialValue: stallProvider.sortOrder,
            onSelected: stallProvider.setSortOrder,
            icon: const Icon(Icons.sort_rounded),
            itemBuilder: (_) => const <PopupMenuEntry<StallSortOrder>>[
              PopupMenuItem<StallSortOrder>(
                value: StallSortOrder.distance,
                child: Text('Nearest First'),
              ),
              PopupMenuItem<StallSortOrder>(
                value: StallSortOrder.rating,
                child: Text('Top Rated'),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const <ButtonSegment<bool>>[
                ButtonSegment<bool>(
                  value: false,
                  icon: Icon(Icons.view_list_rounded, size: 18.0),
                  tooltip: 'List View',
                ),
                ButtonSegment<bool>(
                  value: true,
                  icon: Icon(Icons.map_rounded, size: 18.0),
                  tooltip: 'Map View',
                ),
              ],
              selected: <bool>{stallProvider.isMapView},
              onSelectionChanged: (selection) {
                final mapSelected = selection.first;
                stallProvider.setMapView(mapSelected);
                widget.onMapModeChanged(mapSelected);
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: stallProvider.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Craving momos, chaat, vada pav, locho...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: stallProvider.cravingQuery.isNotEmpty
                    ? IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          stallProvider.clearSearch();
                        },
                      )
                    : null,
              ),
            ),
          ),
          CravingFilterChips(
            selectedQuery: stallProvider.cravingQuery,
            openNowOnly: stallProvider.openNowOnly,
            offersOnly: stallProvider.offersOnly,
            onCravingTap: (tag) {
              stallProvider.selectCravingChip(tag);
              _syncSearchFieldText(stallProvider.cravingQuery);
            },
            onOpenNowToggle: stallProvider.toggleOpenNowOnly,
            onOffersOnlyToggle: stallProvider.toggleOffersOnly,
          ),
          const SizedBox(height: AppSpacing.sm),
          DistanceRadiusSlider(
            radiusKm: stallProvider.radiusKm,
            stallCount: stallProvider.stalls.length,
            onChanged: stallProvider.updateRadiusPreview,
            onChangeEnd: stallProvider.commitRadiusKm,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6.0,
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  stallProvider.isUsingFallbackLocation
                      ? Icons.location_searching_rounded
                      : Icons.gps_fixed_rounded,
                  size: 14.0,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6.0),
                Expanded(
                  child: Text(
                    stallProvider.locationStatus,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _DiscoverBody(
              stallProvider: stallProvider,
              isDemoMode: authProvider.isDemoMode,
              onStallTap: _openStallDetail,
              onResetFilters: () {
                _searchController.clear();
                stallProvider.resetAllFilters();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverBody extends StatelessWidget {
  const _DiscoverBody({
    required this.stallProvider,
    required this.isDemoMode,
    required this.onStallTap,
    required this.onResetFilters,
  });

  final StallProvider stallProvider;
  final bool isDemoMode;
  final ValueChanged<StallWithDistance> onStallTap;
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    if (stallProvider.isLoading) {
      return const StallShimmerList();
    }

    if (stallProvider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.cloud_off_rounded,
                size: 48.0,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                stallProvider.errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: stallProvider.loadStalls,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (stallProvider.stalls.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.no_food_rounded,
                size: 52.0,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No street food stalls matched nearby',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Try expanding your km radius or clearing craving filters.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.tonal(
                onPressed: onResetFilters,
                child: const Text('Reset Filters'),
              ),
            ],
          ),
        ),
      );
    }

    if (stallProvider.isMapView) {
      return StallMapView(
        stalls: stallProvider.stalls,
        userLat: stallProvider.userLat,
        userLng: stallProvider.userLng,
        radiusKm: stallProvider.radiusKm,
        isDemoMode: isDemoMode,
        onStallTap: onStallTap,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppBreakpoints.tablet;
        return RefreshIndicator(
          onRefresh: stallProvider.loadStalls,
          child: isWide
              ? GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 420.0,
                    mainAxisExtent: 356.0,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                  ),
                  itemCount: stallProvider.stalls.length,
                  itemBuilder: (context, index) {
                    final item = stallProvider.stalls[index];
                    return StallCard(
                      stallWithDistance: item,
                      onTap: () => onStallTap(item),
                    );
                  },
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  itemCount: stallProvider.stalls.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final item = stallProvider.stalls[index];
                    return StallCard(
                      stallWithDistance: item,
                      onTap: () => onStallTap(item),
                    );
                  },
                ),
        );
      },
    );
  }
}

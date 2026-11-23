import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:streetbite/core/constants/app_constants.dart';
import 'package:streetbite/core/theme/app_theme.dart';
import 'package:streetbite/models/stall.dart';
import 'package:streetbite/services/navigation_service.dart';
import 'package:streetbite/utils/geohash_util.dart';
import 'package:streetbite/widgets/stall_card.dart';
import 'package:streetbite/widgets/status_pill.dart';

/// Clean, zero-API-key street map powered by ArcGIS / Esri basemap tiles & flutter_map.
class StallMapView extends StatefulWidget {
  const StallMapView({
    super.key,
    required this.stalls,
    required this.userLat,
    required this.userLng,
    required this.radiusKm,
    this.isDemoMode = false,
    required this.onStallTap,
  });

  final List<StallWithDistance> stalls;
  final double userLat;
  final double userLng;
  final double radiusKm;
  final bool isDemoMode;
  final ValueChanged<StallWithDistance> onStallTap;

  @override
  State<StallMapView> createState() => _StallMapViewState();
}

class _StallMapViewState extends State<StallMapView> {
  final NavigationService _navigationService = NavigationService();
  final MapController _mapController = MapController();
  StallWithDistance? _selected;

  double get _defaultZoom {
    if (widget.radiusKm <= 3.0) return 14.0;
    if (widget.radiusKm <= 10.0) return 12.6;
    return 11.4;
  }

  @override
  void initState() {
    super.initState();
    if (widget.stalls.isNotEmpty) {
      _selected = widget.stalls.first;
    }
  }

  @override
  void didUpdateWidget(covariant StallMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selected != null &&
        !widget.stalls.any((item) => item.stall.id == _selected!.stall.id)) {
      _selected = widget.stalls.isNotEmpty ? widget.stalls.first : null;
    } else if (_selected == null && widget.stalls.isNotEmpty) {
      _selected = widget.stalls.first;
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _recenterMap() {
    _mapController.move(
      LatLng(widget.userLat, widget.userLng),
      _defaultZoom,
    );
  }

  List<Marker> _buildMarkers(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final markers = <Marker>[
      Marker(
        point: LatLng(widget.userLat, widget.userLng),
        width: 34.0,
        height: 34.0,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3.0),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.45),
                blurRadius: 8.0,
              ),
            ],
          ),
          child: const Icon(
            Icons.my_location_rounded,
            size: 16.0,
            color: Colors.white,
          ),
        ),
      ),
    ];

    for (final item in widget.stalls) {
      final stall = item.stall;
      final isSelected = _selected?.stall.id == stall.id;
      final pinColor =
          stall.isOpen ? AppTheme.openGreenColor : AppTheme.closedGreyColor;

      markers.add(
        Marker(
          point: LatLng(stall.latitude, stall.longitude),
          width: isSelected ? 156.0 : 40.0,
          height: isSelected ? 70.0 : 40.0,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () => setState(() => _selected = item),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.all(isSelected ? 7.0 : 5.0),
                  decoration: BoxDecoration(
                    color: pinColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: isSelected ? 2.5 : 1.5,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: isSelected ? 8.0 : 4.0,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.restaurant_rounded,
                    size: isSelected ? 18.0 : 14.0,
                    color: Colors.white,
                  ),
                ),
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.only(top: 3.0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7.0,
                      vertical: 2.0,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          blurRadius: 4.0,
                        ),
                      ],
                    ),
                    child: Text(
                      stall.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(widget.userLat, widget.userLng),
              initialZoom: _defaultZoom,
              minZoom: 3.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onTap: (_, __) => setState(() => _selected = null),
            ),
            children: <Widget>[
              if (!isDark)
                TileLayer(
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}',
                  maxNativeZoom: 16,
                  userAgentPackageName: 'com.streetbite.app',
                )
              else ...<Widget>[
                TileLayer(
                  urlTemplate:
                      'https://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
                  maxNativeZoom: 16,
                  userAgentPackageName: 'com.streetbite.app',
                ),
                TileLayer(
                  urlTemplate:
                      'https://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Reference/MapServer/tile/{z}/{y}/{x}',
                  maxNativeZoom: 16,
                  userAgentPackageName: 'com.streetbite.app',
                ),
              ],
              CircleLayer(
                circles: <CircleMarker>[
                  CircleMarker(
                    point: LatLng(widget.userLat, widget.userLng),
                    radius: widget.radiusKm * 1000.0,
                    useRadiusInMeter: true,
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    borderColor: colorScheme.primary.withValues(alpha: 0.45),
                    borderStrokeWidth: 2.0,
                  ),
                ],
              ),
              MarkerLayer(markers: _buildMarkers(context)),
            ],
          ),
        ),
        Positioned(
          top: AppSpacing.sm,
          left: AppSpacing.md,
          right: AppSpacing.md,
          child: Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 6.0,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8.0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _LegendDot(
                      color: AppTheme.openGreenColor,
                      label: 'Open',
                      textTheme: textTheme,
                    ),
                    const SizedBox(width: 10.0),
                    _LegendDot(
                      color: AppTheme.closedGreyColor,
                      label: 'Closed',
                      textTheme: textTheme,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ActionChip(
                avatar: const Icon(Icons.my_location_rounded, size: 16.0),
                label: const Text('Recenter'),
                backgroundColor: colorScheme.surface.withValues(alpha: 0.94),
                onPressed: _recenterMap,
              ),
            ],
          ),
        ),
        Positioned(
          right: AppSpacing.sm,
          bottom: _selected != null ? 112.0 : AppSpacing.sm,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Text(
              '© Esri • OpenStreetMap',
              style: textTheme.labelSmall?.copyWith(
                fontSize: 10.0,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        if (_selected != null)
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: _MapStallPreviewCard(
              item: _selected!,
              onTapDetails: () => widget.onStallTap(_selected!),
              onNavigate: () async {
                final stall = _selected!.stall;
                final ok = await _navigationService.openTurnByTurnDirections(
                  latitude: stall.latitude,
                  longitude: stall.longitude,
                  label: stall.name,
                );
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not open Google Maps directions.'),
                    ),
                  );
                }
              },
            ),
          ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.textTheme,
  });

  final Color color;
  final String label;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 10.0,
          height: 10.0,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4.0),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _MapStallPreviewCard extends StatelessWidget {
  const _MapStallPreviewCard({
    required this.item,
    required this.onTapDetails,
    required this.onNavigate,
  });

  final StallWithDistance item;
  final VoidCallback onTapDetails;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    final stall = item.stall;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTapDetails,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.sm),
                child: StallImage(
                  imageUrl: stall.bannerImageUrl,
                  height: 76.0,
                  width: 76.0,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        OpenStatusPill(isOpen: stall.isOpen, compact: true),
                        const SizedBox(width: 6.0),
                        Text(
                          GeohashUtil.formatDistance(item.distanceKm),
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      stall.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      stall.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filled(
                tooltip: 'Navigate in Google Maps',
                onPressed: onNavigate,
                icon: const Icon(Icons.directions_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

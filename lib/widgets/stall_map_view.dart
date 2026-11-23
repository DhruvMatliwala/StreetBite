import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:streetbite/core/constants/app_constants.dart';
import 'package:streetbite/core/theme/app_theme.dart';
import 'package:streetbite/models/stall.dart';
import 'package:streetbite/services/navigation_service.dart';
import 'package:streetbite/utils/geohash_util.dart';
import 'package:streetbite/widgets/stall_card.dart';
import 'package:streetbite/widgets/status_pill.dart';

/// Interactive Google Maps discovery view with status-colored markers and Demo fallback.
class StallMapView extends StatefulWidget {
  const StallMapView({
    super.key,
    required this.stalls,
    required this.userLat,
    required this.userLng,
    required this.radiusKm,
    required this.isDemoMode,
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
  StallWithDistance? _selected;
  GoogleMapController? _mapController;
  bool _preferDemoRadar = true;

  @override
  void initState() {
    super.initState();
    _preferDemoRadar = widget.isDemoMode;
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
    _mapController?.dispose();
    super.dispose();
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(widget.userLat, widget.userLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    };

    for (final item in widget.stalls) {
      final stall = item.stall;
      markers.add(
        Marker(
          markerId: MarkerId(stall.id),
          position: LatLng(stall.latitude, stall.longitude),
          alpha: stall.isOpen ? 1.0 : 0.45,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            stall.isOpen
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(
            title: stall.name,
            snippet:
                '${stall.isOpen ? 'Open Now' : 'Closed'} • ${GeohashUtil.formatDistance(item.distanceKm)}',
          ),
          onTap: () {
            setState(() => _selected = item);
          },
        ),
      );
    }
    return markers;
  }

  Set<Circle> _buildRadiusCircles(ColorScheme colorScheme) {
    return <Circle>{
      Circle(
        circleId: const CircleId('search_radius'),
        center: LatLng(widget.userLat, widget.userLng),
        radius: widget.radiusKm * 1000.0,
        fillColor: colorScheme.primary.withValues(alpha: 0.08),
        strokeColor: colorScheme.primary.withValues(alpha: 0.45),
        strokeWidth: 2,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: _preferDemoRadar
              ? _DemoInteractiveGeoMap(
                  stalls: widget.stalls,
                  userLat: widget.userLat,
                  userLng: widget.userLng,
                  radiusKm: widget.radiusKm,
                  selectedId: _selected?.stall.id,
                  onSelect: (item) => setState(() => _selected = item),
                )
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(widget.userLat, widget.userLng),
                    zoom: widget.radiusKm <= 5 ? 13.2 : 11.8,
                  ),
                  markers: _buildMarkers(),
                  circles: _buildRadiusCircles(colorScheme),
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  onMapCreated: (controller) => _mapController = controller,
                  onTap: (_) => setState(() => _selected = null),
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
              if (widget.isDemoMode)
                ActionChip(
                  avatar: Icon(
                    _preferDemoRadar
                        ? Icons.map_outlined
                        : Icons.radar_outlined,
                    size: 16.0,
                  ),
                  label: Text(
                    _preferDemoRadar ? 'Google Map SDK' : 'Demo Radar',
                  ),
                  onPressed: () {
                    setState(() => _preferDemoRadar = !_preferDemoRadar);
                  },
                ),
            ],
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

/// Interactive fallback geo-radar map rendered in Demo Mode without Maps API key.
class _DemoInteractiveGeoMap extends StatelessWidget {
  const _DemoInteractiveGeoMap({
    required this.stalls,
    required this.userLat,
    required this.userLng,
    required this.radiusKm,
    required this.selectedId,
    required this.onSelect,
  });

  final List<StallWithDistance> stalls;
  final double userLat;
  final double userLng;
  final double radiusKm;
  final String? selectedId;
  final ValueChanged<StallWithDistance> onSelect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final center = Offset(size.width / 2, size.height * 0.44);
        final maxPlotRadius =
            math.min(size.width, size.height * 0.72) * 0.42;

        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.0, -0.12),
              radius: 0.9,
              colors: <Color>[
                colorScheme.primaryContainer.withValues(alpha: 0.25),
                colorScheme.surfaceContainerLowest,
              ],
            ),
          ),
          child: Stack(
            children: <Widget>[
              CustomPaint(
                size: size,
                painter: _RadarGridPainter(
                  center: center,
                  maxRadius: maxPlotRadius,
                  lineColor: colorScheme.outlineVariant.withValues(alpha: 0.45),
                  fillColor: colorScheme.primary.withValues(alpha: 0.06),
                ),
              ),
              Positioned(
                left: center.dx - 14.0,
                top: center.dy - 14.0,
                child: Container(
                  width: 28.0,
                  height: 28.0,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3.0),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.4),
                        blurRadius: 10.0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.my_location_rounded,
                    size: 14.0,
                    color: Colors.white,
                  ),
                ),
              ),
              ...stalls.map((item) {
                final bearingRad = math.atan2(
                  item.stall.longitude - userLng,
                  item.stall.latitude - userLat,
                );
                final normalizedDist =
                    (item.distanceKm / math.max(radiusKm, 1.0)).clamp(0.08, 1.0);
                final r = normalizedDist * maxPlotRadius;
                final dx = center.dx + r * math.sin(bearingRad);
                final dy = center.dy - r * math.cos(bearingRad);
                final isSelected = item.stall.id == selectedId;
                final pinColor = item.stall.isOpen
                    ? AppTheme.openGreenColor
                    : AppTheme.closedGreyColor;

                return Positioned(
                  left: dx - (isSelected ? 22.0 : 18.0),
                  top: dy - (isSelected ? 40.0 : 34.0),
                  child: GestureDetector(
                    onTap: () => onSelect(item),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: EdgeInsets.all(isSelected ? 6.0 : 4.0),
                          decoration: BoxDecoration(
                            color: pinColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: isSelected ? 2.5 : 1.5,
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.22),
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
                            margin: const EdgeInsets.only(top: 2.0),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.0,
                              vertical: 2.0,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surface.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                            ),
                            child: Text(
                              item.stall.name,
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
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _RadarGridPainter extends CustomPainter {
  const _RadarGridPainter({
    required this.center,
    required this.maxRadius,
    required this.lineColor,
    required this.fillColor,
  });

  final Offset center;
  final double maxRadius;
  final Color lineColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()..color = fillColor;
    final strokePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(center, maxRadius, fillPaint);
    for (final factor in <double>[0.33, 0.66, 1.0]) {
      canvas.drawCircle(center, maxRadius * factor, strokePaint);
    }

    canvas.drawLine(
      Offset(center.dx - maxRadius, center.dy),
      Offset(center.dx + maxRadius, center.dy),
      strokePaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - maxRadius),
      Offset(center.dx, center.dy + maxRadius),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RadarGridPainter oldDelegate) {
    return oldDelegate.center != center || oldDelegate.maxRadius != maxRadius;
  }
}

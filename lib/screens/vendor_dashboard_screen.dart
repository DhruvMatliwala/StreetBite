import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streetbite/core/constants/app_constants.dart';
import 'package:streetbite/models/stall.dart';
import 'package:streetbite/providers/auth_provider.dart';
import 'package:streetbite/providers/stall_provider.dart';
import 'package:streetbite/providers/vendor_provider.dart';
import 'package:streetbite/screens/add_edit_stall_screen.dart';
import 'package:streetbite/screens/profile_screen.dart';
import 'package:streetbite/widgets/stall_card.dart';
import 'package:streetbite/widgets/status_pill.dart';
import 'package:streetbite/widgets/streetbite_logo.dart';

/// Opens a shopkeeper discount builder sheet for Hourly, Daily, Weekly, or Monthly deals.
Future<StallOffer?> showOfferBuilderSheet(
  BuildContext context, {
  StallOffer? existingOffer,
}) {
  return showModalBottomSheet<StallOffer>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _OfferBuilderSheet(existingOffer: existingOffer),
  );
}

/// Dedicated zero-friction Vendor Portal for toggling availability, discounts, and stalls.
class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vendorId = context.read<AuthProvider>().effectiveVendorId;
      if (vendorId.isNotEmpty) {
        context.read<VendorProvider>().loadVendorStalls(vendorId);
      }
    });
  }

  Future<void> _openEditor({Stall? existing}) async {
    final saved = await Navigator.of(context).push<Stall>(
      MaterialPageRoute<Stall>(
        builder: (_) => AddEditStallScreen(existingStall: existing),
      ),
    );
    if (saved != null && mounted) {
      final stallProvider = context.read<StallProvider>();
      if (saved.hasValidOffer) {
        stallProvider.notifyNewOfferPublished(saved);
      } else {
        stallProvider.syncStallUpdate(saved);
      }
    }
  }

  Future<void> _openDiscountSheet(Stall stall) async {
    final offer = await showOfferBuilderSheet(
      context,
      existingOffer: stall.hasValidOffer ? stall.activeOffer : null,
    );
    if (offer == null || !mounted) return;

    final stallProvider = context.read<StallProvider>();
    final updated = await context.read<VendorProvider>().updateStallOffer(
          stall,
          offer,
          onSynced: stallProvider.notifyNewOfferPublished,
        );
    if (!mounted) return;
    if (updated != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Published ${offer.discountBadge} (${offer.durationType.label}) & notified nearby foodies!',
          ),
        ),
      );
    }
  }

  Future<void> _clearDiscount(Stall stall) async {
    final stallProvider = context.read<StallProvider>();
    await context.read<VendorProvider>().updateStallOffer(
          stall,
          null,
          onSynced: stallProvider.syncStallUpdate,
        );
  }

  Future<void> _openAuthSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            bottomInset + AppSpacing.lg,
          ),
          child: AuthFormCard(
            initialRegisterMode: true,
            onAuthenticated: () {
              Navigator.of(sheetContext).pop();
              final vendorId = context.read<AuthProvider>().effectiveVendorId;
              if (vendorId.isNotEmpty) {
                context.read<VendorProvider>().loadVendorStalls(vendorId);
              }
            },
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(Stall stall) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Stall'),
        content: Text('Remove "${stall.name}" from StreetBite?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final stallProvider = context.read<StallProvider>();
    await context.read<VendorProvider>().deleteStall(
          stall.id,
          onDeleted: stallProvider.removeStall,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final vendorProvider = context.watch<VendorProvider>();
    final stallProvider = context.read<StallProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: <Widget>[
            StreetBiteLogo(size: 28.0),
            SizedBox(width: AppSpacing.sm),
            Text(
              'Vendor Portal',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh stalls',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: auth.effectiveVendorId.isNotEmpty
                ? () => vendorProvider.loadVendorStalls(auth.effectiveVendorId)
                : null,
          ),
        ],
      ),
      floatingActionButton: auth.isAuthenticated
          ? FloatingActionButton.extended(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add_business_rounded),
              label: const Text('Register Stall'),
            )
          : null,
      body: !auth.isAuthenticated
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.storefront_rounded,
                      size: 56.0,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Register or sign in to manage your street food stall',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.icon(
                      onPressed: _openAuthSheet,
                      icon: const Icon(Icons.person_add_rounded),
                      label: const Text('Create Account / Sign In'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await auth.signInAnonymously();
                        if (!mounted) return;
                        if (auth.effectiveVendorId.isNotEmpty) {
                          await vendorProvider
                              .loadVendorStalls(auth.effectiveVendorId);
                        }
                      },
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Quick Guest Vendor Sign-In'),
                    ),
                  ],
                ),
              ),
            )
          : vendorProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820.0),
                    child: RefreshIndicator(
                      onRefresh: () => vendorProvider
                          .loadVendorStalls(auth.effectiveVendorId),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          96.0,
                        ),
                        children: <Widget>[
                          Card(
                            color: colorScheme.primaryContainer
                                .withValues(alpha: 0.45),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Row(
                                children: <Widget>[
                                  CircleAvatar(
                                    radius: 24.0,
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                    child: const Icon(Icons.storefront_rounded),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          auth.displayName,
                                          style: textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          '${vendorProvider.openStallCount} of '
                                          '${vendorProvider.vendorStalls.length} '
                                          'stalls live now',
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (vendorProvider.vendorStalls.isEmpty)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Column(
                                  children: <Widget>[
                                    Icon(
                                      Icons.add_location_alt_outlined,
                                      size: 44.0,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      'No stalls registered yet',
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    const Text(
                                      'Tap Register Stall to pin your GPS spot, upload photos, and publish your menu.',
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...vendorProvider.vendorStalls.map(
                              (stall) {
                                final offer = stall.hasValidOffer
                                    ? stall.activeOffer
                                    : null;
                                return Card(
                                  margin: const EdgeInsets.only(
                                    bottom: AppSpacing.md,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppSpacing.md),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                AppRadii.sm,
                                              ),
                                              child: StallImage(
                                                imageUrl: stall.bannerImageUrl,
                                                height: 70.0,
                                                width: 70.0,
                                              ),
                                            ),
                                            const SizedBox(width: AppSpacing.md),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                    stall.name,
                                                    style: textTheme.titleMedium
                                                        ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2.0),
                                                  Text(
                                                    stall.address,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: textTheme.bodySmall
                                                        ?.copyWith(
                                                      color: colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6.0),
                                                  OpenStatusPill(
                                                    isOpen: stall.isOpen,
                                                    compact: true,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (offer != null) ...<Widget>[
                                          const SizedBox(height: AppSpacing.sm),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.sm,
                                              vertical: 6.0,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colorScheme
                                                  .primaryContainer
                                                  .withValues(alpha: 0.6),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                AppRadii.sm,
                                              ),
                                            ),
                                            child: Row(
                                              children: <Widget>[
                                                Icon(
                                                  Icons.local_offer_rounded,
                                                  size: 16.0,
                                                  color: colorScheme.primary,
                                                ),
                                                const SizedBox(width: 6.0),
                                                Expanded(
                                                  child: Text(
                                                    '${offer.discountBadge} • ${offer.durationType.label} (${offer.remainingTimeLabel})',
                                                    style: textTheme.labelMedium
                                                        ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      _clearDiscount(stall),
                                                  child:
                                                      const Text('End Offer'),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        const Divider(height: AppSpacing.lg),
                                        SwitchListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(
                                            stall.isOpen
                                                ? 'Live & Taking Orders'
                                                : 'Currently Closed',
                                            style:
                                                textTheme.labelLarge?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          value: stall.isOpen,
                                          onChanged: (nextOpen) {
                                            vendorProvider.toggleOpenStatus(
                                              stall,
                                              nextOpen,
                                              onSynced:
                                                  stallProvider.syncStallUpdate,
                                            );
                                          },
                                        ),
                                        Wrap(
                                          alignment: WrapAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          spacing: AppSpacing.sm,
                                          runSpacing: AppSpacing.xs,
                                          children: <Widget>[
                                            Text(
                                              '${stall.menuItems.length} dishes',
                                              style: textTheme.labelMedium
                                                  ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: <Widget>[
                                                IconButton(
                                                  tooltip: 'Delete stall',
                                                  onPressed: () =>
                                                      _confirmDelete(stall),
                                                  icon: Icon(
                                                    Icons.delete_outline,
                                                    color: colorScheme.error,
                                                  ),
                                                ),
                                                OutlinedButton.icon(
                                                  onPressed: () =>
                                                      _openDiscountSheet(stall),
                                                  icon: const Icon(
                                                    Icons.local_offer_outlined,
                                                    size: 18.0,
                                                  ),
                                                  label: Text(
                                                    offer != null
                                                        ? 'Edit Offer'
                                                        : 'Special Discount',
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: AppSpacing.xs,
                                                ),
                                                FilledButton.tonalIcon(
                                                  onPressed: () => _openEditor(
                                                    existing: stall,
                                                  ),
                                                  icon: const Icon(
                                                    Icons.edit_outlined,
                                                    size: 18.0,
                                                  ),
                                                  label: const Text('Edit'),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}

class _OfferBuilderSheet extends StatefulWidget {
  const _OfferBuilderSheet({this.existingOffer});

  final StallOffer? existingOffer;

  @override
  State<_OfferBuilderSheet> createState() => _OfferBuilderSheetState();
}

class _OfferBuilderSheetState extends State<_OfferBuilderSheet> {
  late final TextEditingController _titleController;
  late OfferDurationType _durationType;
  late int _discountPercent;
  late int _durationCount;

  static const List<int> _discountPresets = <int>[10, 15, 20, 25, 30, 50, 0];

  static const List<String> _titleSuggestions = <String>[
    'Happy Hour Special Discount',
    'Today Only: Fresh Hot Combo Deal',
    'Weekend Family Feast Offer',
    'Monthly Regular Foodie Discount',
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.existingOffer;
    _durationType = existing?.durationType ?? OfferDurationType.hour;
    _discountPercent = existing?.discountPercent ?? 20;
    _durationCount = _defaultCountFor(_durationType);
    _titleController = TextEditingController(
      text: existing?.title ?? 'Happy Hour: 20% OFF All Signature Dishes',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  int _defaultCountFor(OfferDurationType type) {
    return switch (type) {
      OfferDurationType.hour => 3,
      OfferDurationType.day => 1,
      OfferDurationType.week => 1,
      OfferDurationType.month => 1,
    };
  }

  int _maxCountFor(OfferDurationType type) {
    return switch (type) {
      OfferDurationType.hour => 12,
      OfferDurationType.day => 6,
      OfferDurationType.week => 4,
      OfferDurationType.month => 3,
    };
  }

  String _unitLabel(OfferDurationType type, int count) {
    final base = switch (type) {
      OfferDurationType.hour => 'Hour',
      OfferDurationType.day => 'Day',
      OfferDurationType.week => 'Week',
      OfferDurationType.month => 'Month',
    };
    return count == 1 ? '$count $base' : '$count ${base}s';
  }

  DateTime _computeExpiry() {
    final now = DateTime.now();
    return switch (_durationType) {
      OfferDurationType.hour => now.add(Duration(hours: _durationCount)),
      OfferDurationType.day => now.add(Duration(days: _durationCount)),
      OfferDurationType.week => now.add(Duration(days: _durationCount * 7)),
      OfferDurationType.month => now.add(Duration(days: _durationCount * 30)),
    };
  }

  void _publish() {
    final rawTitle = _titleController.text.trim();
    final fallbackTitle = _discountPercent > 0
        ? '$_discountPercent% OFF • ${_durationType.label}'
        : 'Special Combo Deal • ${_durationType.label}';

    final offer = StallOffer(
      title: rawTitle.isEmpty ? fallbackTitle : rawTitle,
      discountPercent: _discountPercent,
      durationType: _durationType,
      expiresAt: _computeExpiry(),
      isActive: true,
    );
    Navigator.of(context).pop(offer);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final textTheme = Theme.of(context).textTheme;
    final maxCount = _maxCountFor(_durationType);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        bottomInset + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Launch Special Stall Discount',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4.0),
          Text(
            'Nearby foodies receive an alert as soon as you publish.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Offer Duration Window',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<OfferDurationType>(
            showSelectedIcon: false,
            segments: OfferDurationType.values
                .map(
                  (type) => ButtonSegment<OfferDurationType>(
                    value: type,
                    label: Text(type.shortLabel),
                  ),
                )
                .toList(),
            selected: <OfferDurationType>{_durationType},
            onSelectionChanged: (selected) {
              setState(() {
                _durationType = selected.first;
                _durationCount = _defaultCountFor(_durationType);
              });
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Valid for: ${_unitLabel(_durationType, _durationCount)}',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _durationType.label,
                style: textTheme.labelMedium,
              ),
            ],
          ),
          Slider(
            value: _durationCount.toDouble(),
            min: 1.0,
            max: maxCount.toDouble(),
            divisions: maxCount > 1 ? maxCount - 1 : 1,
            label: _unitLabel(_durationType, _durationCount),
            onChanged: (value) {
              setState(() => _durationCount = value.round());
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Discount Percentage',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: _discountPresets.map((pct) {
              final label = pct > 0 ? '$pct% OFF' : 'Combo Deal';
              return ChoiceChip(
                label: Text(label),
                selected: _discountPercent == pct,
                onSelected: (_) => setState(() => _discountPercent = pct),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Offer Headline',
              hintText: 'e.g., 20% OFF on Steamed & Kurkure Momos',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: _titleSuggestions
                .map(
                  (suggestion) => ActionChip(
                    label: Text(suggestion),
                    onPressed: () {
                      setState(() => _titleController.text = suggestion);
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: _publish,
            icon: const Icon(Icons.notifications_active_rounded),
            label: const Text('Publish & Notify Nearby Foodies'),
          ),
        ],
      ),
    );
  }
}

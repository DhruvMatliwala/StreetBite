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

/// Dedicated zero-friction Vendor Portal for toggling availability and managing stalls.
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
      context.read<StallProvider>().syncStallUpdate(saved);
    }
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
                              (stall) => Card(
                                margin:
                                    const EdgeInsets.only(bottom: AppSpacing.md),
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
                                                    AppRadii.sm),
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
                                                    fontWeight: FontWeight.w700,
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
                                      const Divider(height: AppSpacing.lg),
                                      Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: SwitchListTile(
                                              contentPadding: EdgeInsets.zero,
                                              title: Text(
                                                stall.isOpen
                                                    ? 'Live & Taking Orders'
                                                    : 'Currently Closed',
                                                style: textTheme.labelLarge
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              value: stall.isOpen,
                                              onChanged: (nextOpen) {
                                                vendorProvider.toggleOpenStatus(
                                                  stall,
                                                  nextOpen,
                                                  onSynced: stallProvider
                                                      .syncStallUpdate,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: <Widget>[
                                          Text(
                                            '${stall.menuItems.length} dishes',
                                            style:
                                                textTheme.labelMedium?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          const Spacer(),
                                          TextButton.icon(
                                            onPressed: () =>
                                                _confirmDelete(stall),
                                            icon: Icon(
                                              Icons.delete_outline,
                                              color: colorScheme.error,
                                            ),
                                            label: Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: colorScheme.error,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          FilledButton.tonalIcon(
                                            onPressed: () =>
                                                _openEditor(existing: stall),
                                            icon:
                                                const Icon(Icons.edit_outlined),
                                            label: const Text('Edit Menu & Pin'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}

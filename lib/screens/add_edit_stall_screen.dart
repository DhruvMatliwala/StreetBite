import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:streetbite/core/constants/app_constants.dart';
import 'package:streetbite/models/menu_item.dart';
import 'package:streetbite/models/stall.dart';
import 'package:streetbite/providers/auth_provider.dart';
import 'package:streetbite/providers/vendor_provider.dart';
import 'package:streetbite/screens/vendor_dashboard_screen.dart';
import 'package:streetbite/utils/geohash_util.dart';
import 'package:streetbite/widgets/menu_item_editor.dart';
import 'package:streetbite/widgets/stall_card.dart';

/// Form screen allowing vendors to register or edit stall details, GPS pin, offer, photo, and menu.
class AddEditStallScreen extends StatefulWidget {
  const AddEditStallScreen({super.key, this.existingStall});

  final Stall? existingStall;

  @override
  State<AddEditStallScreen> createState() => _AddEditStallScreenState();
}

class _AddEditStallScreenState extends State<AddEditStallScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;
  late final TextEditingController _hoursController;
  late final TextEditingController _bannerUrlController;

  late double _latitude;
  late double _longitude;
  late bool _isOpen;
  late List<MenuItem> _menuItems;
  late Set<String> _selectedCrowdTags;
  StallOffer? _activeOffer;
  bool _resolvingGps = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingStall;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _descriptionController =
        TextEditingController(text: existing?.description ?? '');
    _addressController = TextEditingController(text: existing?.address ?? '');
    _hoursController = TextEditingController(
      text: existing?.operatingHours ?? '5:00 PM - 11:30 PM',
    );
    _bannerUrlController =
        TextEditingController(text: existing?.bannerImageUrl ?? '');

    _latitude = existing?.latitude ?? AppGeoDefaults.defaultLatitude;
    _longitude = existing?.longitude ?? AppGeoDefaults.defaultLongitude;
    _isOpen = existing?.isOpen ?? true;
    _menuItems = List<MenuItem>.from(existing?.menuItems ?? const <MenuItem>[]);
    _selectedCrowdTags =
        Set<String>.from(existing?.crowdTags ?? const <String>[]);
    _activeOffer =
        existing?.hasValidOffer == true ? existing!.activeOffer : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _hoursController.dispose();
    _bannerUrlController.dispose();
    super.dispose();
  }

  Future<void> _pinCurrentLocation() async {
    setState(() => _resolvingGps = true);
    final result = await context.read<VendorProvider>().resolveCurrentLocation();
    if (!mounted) return;
    setState(() {
      _latitude = result.latitude;
      _longitude = result.longitude;
      _resolvingGps = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.statusMessage)),
    );
  }

  Future<void> _uploadPhoto(ImageSource source) async {
    final auth = context.read<AuthProvider>();
    final vendorProvider = context.read<VendorProvider>();
    final url = await vendorProvider.pickAndUploadPhoto(
      source: source,
      vendorId: auth.effectiveVendorId,
      stallId: widget.existingStall?.id ?? 'new-stall',
    );
    if (!mounted) return;
    if (url != null) {
      setState(() => _bannerUrlController.text = url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stall photo updated!')),
      );
    }
  }

  Future<void> _configureOffer() async {
    final offer = await showOfferBuilderSheet(
      context,
      existingOffer: _activeOffer,
    );
    if (offer != null && mounted) {
      setState(() => _activeOffer = offer);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final vendorProvider = context.read<VendorProvider>();
    final existing = widget.existingStall;

    final now = DateTime.now();
    final bannerUrl = _bannerUrlController.text.trim();
    final stall = Stall(
      id: existing?.id ?? '',
      vendorId: existing?.vendorId ?? auth.effectiveVendorId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      address: _addressController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      geohash: GeohashUtil.encode(_latitude, _longitude),
      isOpen: _isOpen,
      operatingHours: _hoursController.text.trim(),
      bannerImageUrl: bannerUrl,
      galleryUrls: bannerUrl.isNotEmpty ? <String>[bannerUrl] : const <String>[],
      menuItems: _menuItems,
      searchableItems: Stall.buildSearchableTokens(
        name: _nameController.text.trim(),
        menuItems: _menuItems,
        crowdTags: _selectedCrowdTags.toList(),
        activeOffer: _activeOffer,
      ),
      crowdTags: _selectedCrowdTags.toList(),
      tasteRating: existing?.tasteRating ?? 4.5,
      hygieneRating: existing?.hygieneRating ?? 4.5,
      reviewCount: existing?.reviewCount ?? 0,
      activeOffer: _activeOffer,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    final saved = await vendorProvider.saveStall(stall);
    if (!mounted) return;
    if (saved != null) {
      Navigator.of(context).pop(saved);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            vendorProvider.errorMessage ?? 'Could not save stall.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendorProvider = context.watch<VendorProvider>();
    final textTheme = Theme.of(context).textTheme;
    final geohash = GeohashUtil.encode(_latitude, _longitude, precision: 7);
    final isEditing = widget.existingStall != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Stall' : 'Register New Stall'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780.0),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  child: StallImage(
                    imageUrl: _bannerUrlController.text.trim(),
                    height: 180.0,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: vendorProvider.isUploadingPhoto
                            ? null
                            : () => _uploadPhoto(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Gallery'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: vendorProvider.isUploadingPhoto
                            ? null
                            : () => _uploadPhoto(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Camera'),
                      ),
                    ),
                  ],
                ),
                if (vendorProvider.isUploadingPhoto)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: LinearProgressIndicator(),
                  ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Stall / Cart Name *',
                    hintText: 'e.g., Pahadi Steam & Tandoor Momos',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 2) {
                      return 'Enter at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Landmark / Street Address *',
                    hintText: 'Opp. VR Mall Gate 2, Dumas Road',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 3) {
                      return 'Enter a street or landmark address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _hoursController,
                  decoration: const InputDecoration(
                    labelText: 'Operating Hours *',
                    hintText: '5:00 PM - 11:30 PM',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter operating hours';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Stall Story / Specialties',
                    hintText: 'Freshly steamed momos, spicy chutney...',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Stall GPS Pin',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          'Lat: ${_latitude.toStringAsFixed(5)}, '
                          'Lng: ${_longitude.toStringAsFixed(5)} • '
                          'Geohash: $geohash',
                          style: textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FilledButton.tonalIcon(
                          onPressed: _resolvingGps ? null : _pinCurrentLocation,
                          icon: _resolvingGps
                              ? const SizedBox(
                                  width: 16.0,
                                  height: 16.0,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                  ),
                                )
                              : const Icon(Icons.my_location_rounded),
                          label: const Text('Pin Current GPS Location'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Special Discount / Offer (Optional)',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          _activeOffer != null
                              ? '${_activeOffer!.discountBadge} • ${_activeOffer!.durationType.label}: ${_activeOffer!.title}'
                              : 'Attract nearby foodies with an Hourly, Daily, Weekly, or Monthly discount.',
                          style: textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: <Widget>[
                            FilledButton.tonalIcon(
                              onPressed: _configureOffer,
                              icon: const Icon(Icons.local_offer_outlined),
                              label: Text(
                                _activeOffer != null
                                    ? 'Edit Discount'
                                    : 'Add Special Discount',
                              ),
                            ),
                            if (_activeOffer != null) ...<Widget>[
                              const SizedBox(width: AppSpacing.sm),
                              TextButton(
                                onPressed: () =>
                                    setState(() => _activeOffer = null),
                                child: const Text('Remove'),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Open Right Now'),
                  subtitle: const Text(
                    'Show this stall as active to nearby foodies',
                  ),
                  value: _isOpen,
                  onChanged: (v) => setState(() => _isOpen = v),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Crowd Tags',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: AppSearchConfig.crowdTagSuggestions.map((tag) {
                    final selected = _selectedCrowdTags.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: selected,
                      onSelected: (isNowSelected) {
                        setState(() {
                          if (isNowSelected) {
                            _selectedCrowdTags.add(tag);
                          } else {
                            _selectedCrowdTags.remove(tag);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                MenuItemEditor(
                  items: _menuItems,
                  onChanged: (updated) => setState(() => _menuItems = updated),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: vendorProvider.isSaving ? null : _save,
                  icon: vendorProvider.isSaving
                      ? const SizedBox(
                          width: 18.0,
                          height: 18.0,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(isEditing ? 'Save Changes' : 'Publish Stall'),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

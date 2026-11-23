import 'package:flutter/material.dart';
import 'package:streetbite/core/constants/app_constants.dart';
import 'package:streetbite/core/theme/app_theme.dart';
import 'package:streetbite/models/menu_item.dart';

/// Interactive vendor menu editor supporting add, edit, availability toggle, and delete.
class MenuItemEditor extends StatelessWidget {
  const MenuItemEditor({
    super.key,
    required this.items,
    required this.onChanged,
  });

  final List<MenuItem> items;
  final ValueChanged<List<MenuItem>> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Menu Items (${items.length})',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () => _openItemDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Dish'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: Column(
              children: <Widget>[
                Icon(
                  Icons.restaurant_menu_rounded,
                  size: 32.0,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'No dishes added yet. Add dishes so foodies find you by cravings!',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: VegBadge(isVeg: item.isVeg),
                  title: Text(
                    item.name,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '₹${item.price.round()} • ${item.category}'
                    '${item.isAvailable ? '' : ' • Sold out'}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        tooltip: 'Edit dish',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _openItemDialog(
                          context,
                          existing: item,
                          index: index,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove dish',
                        icon: Icon(
                          Icons.delete_outline,
                          color: colorScheme.error,
                        ),
                        onPressed: () {
                          final updated = List<MenuItem>.from(items)
                            ..removeAt(index);
                          onChanged(updated);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Future<void> _openItemDialog(
    BuildContext context, {
    MenuItem? existing,
    int? index,
  }) async {
    final result = await showDialog<MenuItem>(
      context: context,
      builder: (_) => _MenuItemFormDialog(existing: existing),
    );
    if (result == null) return;

    final updated = List<MenuItem>.from(items);
    if (index != null) {
      updated[index] = result;
    } else {
      updated.add(result);
    }
    onChanged(updated);
  }
}

/// Standard Indian green-square/red-triangle vegetarian/non-vegetarian badge.
class VegBadge extends StatelessWidget {
  const VegBadge({super.key, required this.isVeg});

  final bool isVeg;

  @override
  Widget build(BuildContext context) {
    final color = isVeg ? AppTheme.vegGreenColor : AppTheme.nonVegRedColor;
    return Container(
      width: 18.0,
      height: 18.0,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Center(
        child: Container(
          width: 8.0,
          height: 8.0,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _MenuItemFormDialog extends StatefulWidget {
  const _MenuItemFormDialog({this.existing});

  final MenuItem? existing;

  @override
  State<_MenuItemFormDialog> createState() => _MenuItemFormDialogState();
}

class _MenuItemFormDialogState extends State<_MenuItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _categoryController;
  late final TextEditingController _descriptionController;
  late bool _isVeg;
  late bool _isAvailable;

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _nameController = TextEditingController(text: item?.name ?? '');
    _priceController = TextEditingController(
      text: item != null ? item.price.round().toString() : '',
    );
    _categoryController =
        TextEditingController(text: item?.category ?? 'Specials');
    _descriptionController =
        TextEditingController(text: item?.description ?? '');
    _isVeg = item?.isVeg ?? true;
    _isAvailable = item?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final item = MenuItem(
      id: widget.existing?.id.isNotEmpty == true
          ? widget.existing!.id
          : 'dish-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      price: price,
      isVeg: _isVeg,
      category: _categoryController.text.trim().isEmpty
          ? 'Specials'
          : _categoryController.text.trim(),
      description: _descriptionController.text.trim(),
      isAvailable: _isAvailable,
    );
    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit Dish' : 'Add Dish'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Dish Name *',
                  hintText: 'e.g., Paneer Kurkure Momos',
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 2) {
                    return 'Enter a dish name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price (₹) *',
                        hintText: '80',
                      ),
                      validator: (value) {
                        final parsed = double.tryParse(value?.trim() ?? '');
                        if (parsed == null || parsed <= 0) {
                          return 'Enter valid price';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _categoryController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        hintText: 'Momos / Chaat',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Short Description (optional)',
                  hintText: 'Spicy garlic dip, freshly steamed...',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Vegetarian Dish'),
                value: _isVeg,
                onChanged: (val) => setState(() => _isVeg = val),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Available Now'),
                value: _isAvailable,
                onChanged: (val) => setState(() => _isAvailable = val),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}

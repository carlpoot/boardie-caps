import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import 'landlord_properties_providers.dart';

/// Create/edit form for the fields the task scopes to this CRUD screen:
/// name, address, latitude, longitude, storeys, min_price.
/// `verification_status` is never editable here -- see
/// [createProperty]/[updateProperty].
class PropertyFormScreen extends ConsumerStatefulWidget {
  const PropertyFormScreen({super.key, this.existing});

  final Property? existing;

  @override
  ConsumerState<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends ConsumerState<PropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  late final TextEditingController _storeysController;
  late final TextEditingController _minPriceController;
  bool _submitting = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _addressController = TextEditingController(text: existing?.address ?? '');
    _latController = TextEditingController(text: existing?.latitude.toString() ?? '');
    _lngController = TextEditingController(text: existing?.longitude.toString() ?? '');
    _storeysController = TextEditingController(text: existing?.storeys.toString() ?? '1');
    _minPriceController = TextEditingController(text: existing?.minPrice.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _storeysController.dispose();
    _minPriceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final latitude = double.parse(_latController.text.trim());
    final longitude = double.parse(_lngController.text.trim());
    final storeys = int.parse(_storeysController.text.trim());
    final minPrice = num.parse(_minPriceController.text.trim());

    if (_isEditing) {
      await updateProperty(
        ref,
        widget.existing!,
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        storeys: storeys,
        minPrice: minPrice,
      );
    } else {
      await createProperty(
        ref,
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        storeys: storeys,
        minPrice: minPrice,
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  String? _requiredValidator(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    if (num.tryParse(value.trim()) == null) return 'Enter a valid number';
    return null;
  }

  String? _intValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    if (int.tryParse(value.trim()) == null) return 'Enter a whole number';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Property' : 'New Property')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: const Key('property_name_field'),
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Property name'),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('property_address_field'),
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('property_latitude_field'),
                    controller: _latController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(labelText: 'Latitude'),
                    validator: _numberValidator,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: const Key('property_longitude_field'),
                    controller: _lngController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(labelText: 'Longitude'),
                    validator: _numberValidator,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('property_storeys_field'),
              controller: _storeysController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Storeys'),
              validator: _intValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('property_min_price_field'),
              controller: _minPriceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Minimum price (PHP/mo)'),
              validator: _numberValidator,
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('property_form_submit_button'),
              onPressed: _submitting ? null : _submit,
              child: Text(_isEditing ? 'Save Changes' : 'Create Property'),
            ),
          ],
        ),
      ),
    );
  }
}

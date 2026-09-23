import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import 'landlord_rooms_providers.dart';

/// Create/edit form for the fields the task scopes to this CRUD screen:
/// room_type, capacity, current_occupancy, rent_price. `held_count` is
/// never shown -- it's derived from active `RoomRequests`, not manually set.
class RoomFormScreen extends ConsumerStatefulWidget {
  const RoomFormScreen({super.key, required this.propertyId, this.existing});

  final String propertyId;
  final Room? existing;

  @override
  ConsumerState<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends ConsumerState<RoomFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _roomTypeController;
  late final TextEditingController _capacityController;
  late final TextEditingController _occupancyController;
  late final TextEditingController _rentPriceController;
  bool _submitting = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _roomTypeController = TextEditingController(text: existing?.roomType ?? '');
    _capacityController = TextEditingController(text: existing?.capacity.toString() ?? '1');
    _occupancyController =
        TextEditingController(text: existing?.currentOccupancy.toString() ?? '0');
    _rentPriceController = TextEditingController(text: existing?.rentPrice.toString() ?? '');
  }

  @override
  void dispose() {
    _roomTypeController.dispose();
    _capacityController.dispose();
    _occupancyController.dispose();
    _rentPriceController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  String? _intValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    if (int.tryParse(value.trim()) == null) return 'Enter a whole number';
    return null;
  }

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    if (num.tryParse(value.trim()) == null) return 'Enter a valid number';
    return null;
  }

  String? _occupancyValidator(String? value) {
    final basic = _intValidator(value);
    if (basic != null) return basic;
    final capacity = int.tryParse(_capacityController.text.trim());
    final occupancy = int.parse(value!.trim());
    if (capacity != null && occupancy > capacity) {
      return 'Cannot exceed capacity';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final roomType = _roomTypeController.text.trim();
    final capacity = int.parse(_capacityController.text.trim());
    final currentOccupancy = int.parse(_occupancyController.text.trim());
    final rentPrice = num.parse(_rentPriceController.text.trim());

    if (_isEditing) {
      await updateRoom(
        ref,
        widget.existing!,
        roomType: roomType,
        capacity: capacity,
        currentOccupancy: currentOccupancy,
        rentPrice: rentPrice,
      );
    } else {
      await createRoom(
        ref,
        propertyId: widget.propertyId,
        roomType: roomType,
        capacity: capacity,
        currentOccupancy: currentOccupancy,
        rentPrice: rentPrice,
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Room' : 'New Room')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: const Key('room_type_field'),
              controller: _roomTypeController,
              decoration: const InputDecoration(labelText: 'Room type (e.g. Solo, Shared (2-bed))'),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('room_capacity_field'),
                    controller: _capacityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Capacity'),
                    validator: _intValidator,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: const Key('room_occupancy_field'),
                    controller: _occupancyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Current occupancy'),
                    validator: _occupancyValidator,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('room_rent_price_field'),
              controller: _rentPriceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Rent price (PHP/mo)'),
              validator: _numberValidator,
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('room_form_submit_button'),
              onPressed: _submitting ? null : _submit,
              child: Text(_isEditing ? 'Save Changes' : 'Create Room'),
            ),
          ],
        ),
      ),
    );
  }
}

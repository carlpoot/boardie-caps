import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/models.dart';
import 'visit_request_providers.dart';

/// Opens the "Request a Visit" bottom sheet for [property]. Used from the
/// Property Details screen's "Request Visit" button.
Future<void> showRequestVisitSheet(
  BuildContext context,
  WidgetRef ref,
  Property property,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _RequestVisitSheet(property: property),
  );
}

class _RequestVisitSheet extends ConsumerStatefulWidget {
  const _RequestVisitSheet({required this.property});

  final Property property;

  @override
  ConsumerState<_RequestVisitSheet> createState() => _RequestVisitSheetState();
}

class _RequestVisitSheetState extends ConsumerState<_RequestVisitSheet> {
  DateTime? _selectedDateTime;
  bool _submitting = false;

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null || !mounted) return;

    setState(() {
      _selectedDateTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    final dateTime = _selectedDateTime;
    if (dateTime == null) return;

    setState(() => _submitting = true);
    await createVisitRequest(
      ref,
      property: widget.property,
      requestedDatetime: dateTime,
    );

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Visit request sent.')));
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM d, y · h:mm a');
    final selected = _selectedDateTime;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Request a Visit', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(widget.property.name, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            key: const Key('pick_visit_datetime_button'),
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(selected == null ? 'Choose a date & time' : dateFormat.format(selected)),
            onPressed: _pickDateTime,
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('submit_visit_request_button'),
            onPressed: selected == null || _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send Request'),
          ),
        ],
      ),
    );
  }
}

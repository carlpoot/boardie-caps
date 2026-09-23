import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'profile_providers.dart';

/// Set Campus Anchor (Use Case diagram). No supporting wireframe prose for
/// this one -- this is a working interpretation: a simple picker over the
/// `Campuses` table that writes to `StudentProfiles.campus_id`. Flagged
/// back per the task's own note in case it should work differently (e.g. a
/// map-based pin drop rather than a list).
class CampusAnchorScreen extends ConsumerWidget {
  const CampusAnchorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(campusAnchorScreenDataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Set Campus Anchor')),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load campuses: $error')),
        data: (data) {
          return RadioGroup<String>(
            groupValue: data.currentCampusId,
            onChanged: (value) async {
              if (value == null) return;
              final campus = data.campuses.firstWhere((c) => c.campusId == value);
              await setCampusAnchor(ref, value);
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text('Campus anchor set to ${campus.name}.')));
                Navigator.of(context).pop();
              }
            },
            child: ListView(
              children: data.campuses.map((campus) {
                return RadioListTile<String>(
                  key: Key('campus_option_${campus.campusId}'),
                  title: Text(campus.name),
                  value: campus.campusId,
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

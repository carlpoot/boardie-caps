import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../visit_requests/visit_request_card.dart';
import '../visit_requests/visit_request_providers.dart';

class VisitRequestsTab extends ConsumerWidget {
  const VisitRequestsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(studentVisitRequestsProvider);

    return itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Could not load visit requests: $error')),
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('No visit requests yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: VisitRequestCard(item: items[index]),
          ),
        );
      },
    );
  }
}

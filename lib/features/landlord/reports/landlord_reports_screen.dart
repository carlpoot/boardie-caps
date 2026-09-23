import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'landlord_reports_providers.dart';

/// Generate Landlord Reports: four report types (listings,
/// room_availability, occupancy, reservation), each scoped to only this
/// landlord's own properties/rooms/requests. Uses the `pdf` package to
/// build a real PDF and `printing` to open it, right now -- no
/// Firebase/network dependency, so there's no reason to defer it.
class LandlordReportsScreen extends ConsumerStatefulWidget {
  const LandlordReportsScreen({super.key});

  @override
  ConsumerState<LandlordReportsScreen> createState() => _LandlordReportsScreenState();
}

class _LandlordReportsScreenState extends ConsumerState<LandlordReportsScreen> {
  String? _generating;

  Future<void> _generate(String reportType) async {
    setState(() => _generating = reportType);
    try {
      await generateReport(ref, reportType);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text('${reportTypeLabel(reportType)} report generated.'),
          ));
      }
    } finally {
      if (mounted) setState(() => _generating = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(landlordReportsProvider);
    final dateFormat = DateFormat('MMM d, y · h:mm a');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Generate a Report', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kReportTypes.map((type) {
            final isGeneratingThis = _generating == type;
            return FilledButton(
              key: Key('generate_report_$type'),
              onPressed: _generating == null ? () => _generate(type) : null,
              child: isGeneratingThis
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(reportTypeLabel(type)),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text('Generated Reports', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        reportsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('Could not load reports: $error'),
          data: (reports) {
            if (reports.isEmpty) {
              return const Text('No reports generated yet.');
            }
            final sorted = [...reports]
              ..sort((a, b) => b.dateGenerated.compareTo(a.dateGenerated));
            return Column(
              children: sorted
                  .map((report) => Card(
                        child: ListTile(
                          title: Text(reportTypeLabel(report.reportType)),
                          subtitle: Text(
                            '${dateFormat.format(report.dateGenerated)}\n${report.fileUrl}',
                          ),
                          isThreeLine: true,
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'admin_reports_providers.dart';

/// Generate Admin Reports: three report types (users, listing_verification,
/// reported_listings), each covering the whole platform -- unlike the
/// landlord reports, none of these are scoped to a single landlord. Reuses
/// the same `pdf`/`printing` pattern (and the same print-dialog-timing fix)
/// as [LandlordReportsScreen](../../landlord/reports/landlord_reports_screen.dart).
class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  String? _generating;

  Future<void> _generate(String reportType) async {
    setState(() => _generating = reportType);
    try {
      await generateAdminReport(ref, reportType);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text('${adminReportTypeLabel(reportType)} report generated.'),
          ));
      }
    } finally {
      if (mounted) setState(() => _generating = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(adminReportsProvider);
    final dateFormat = DateFormat('MMM d, y · h:mm a');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Generate a Report', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kAdminReportTypes.map((type) {
            final isGeneratingThis = _generating == type;
            return FilledButton(
              key: Key('generate_admin_report_$type'),
              onPressed: _generating == null ? () => _generate(type) : null,
              child: isGeneratingThis
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(adminReportTypeLabel(type)),
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
                          title: Text(adminReportTypeLabel(report.reportType)),
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

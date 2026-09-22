class Report {
  final String reportId;
  final String createdBy;
  final String reportType;
  final DateTime dateGenerated;
  final String fileUrl;

  const Report({
    required this.reportId,
    required this.createdBy,
    required this.reportType,
    required this.dateGenerated,
    required this.fileUrl,
  });

  factory Report.fromMap(Map<String, dynamic> map) => Report(
        reportId: map['report_id'] as String,
        createdBy: map['created_by'] as String,
        reportType: map['report_type'] as String,
        dateGenerated: DateTime.parse(map['date_generated'] as String),
        fileUrl: map['file_url'] as String,
      );

  Map<String, dynamic> toMap() => {
        'report_id': reportId,
        'created_by': createdBy,
        'report_type': reportType,
        'date_generated': dateGenerated.toIso8601String(),
        'file_url': fileUrl,
      };

  Report copyWith({
    String? reportId,
    String? createdBy,
    String? reportType,
    DateTime? dateGenerated,
    String? fileUrl,
  }) =>
      Report(
        reportId: reportId ?? this.reportId,
        createdBy: createdBy ?? this.createdBy,
        reportType: reportType ?? this.reportType,
        dateGenerated: dateGenerated ?? this.dateGenerated,
        fileUrl: fileUrl ?? this.fileUrl,
      );
}

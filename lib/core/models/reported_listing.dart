import 'enums.dart';

class ReportedListing {
  final String reportIssueId;
  final String propertyId;
  final String reportedBy;
  final String reason;
  final ReportedListingReviewStatus reviewStatus;

  const ReportedListing({
    required this.reportIssueId,
    required this.propertyId,
    required this.reportedBy,
    required this.reason,
    required this.reviewStatus,
  });

  factory ReportedListing.fromMap(Map<String, dynamic> map) => ReportedListing(
        reportIssueId: map['report_issue_id'] as String,
        propertyId: map['property_id'] as String,
        reportedBy: map['reported_by'] as String,
        reason: map['reason'] as String,
        reviewStatus: ReportedListingReviewStatus.fromValue(
          map['review_status'] as String,
        ),
      );

  Map<String, dynamic> toMap() => {
        'report_issue_id': reportIssueId,
        'property_id': propertyId,
        'reported_by': reportedBy,
        'reason': reason,
        'review_status': reviewStatus.value,
      };

  ReportedListing copyWith({
    String? reportIssueId,
    String? propertyId,
    String? reportedBy,
    String? reason,
    ReportedListingReviewStatus? reviewStatus,
  }) =>
      ReportedListing(
        reportIssueId: reportIssueId ?? this.reportIssueId,
        propertyId: propertyId ?? this.propertyId,
        reportedBy: reportedBy ?? this.reportedBy,
        reason: reason ?? this.reason,
        reviewStatus: reviewStatus ?? this.reviewStatus,
      );
}

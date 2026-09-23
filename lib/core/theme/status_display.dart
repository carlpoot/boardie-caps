import 'package:flutter/material.dart';

import '../models/enums.dart';
import 'app_colors.dart';

/// The ONE place every status enum maps to a display color and label.
///
/// Every screen that shows a `RoomAvailabilityStatus`, `RoomRequestStatus`,
/// `VisitRequestStatus`, `VerificationStatus`, `UserStatus`, or
/// `ReportedListingReviewStatus` badge must go through these extensions
/// rather than declaring its own color/label map --
/// before this file existed, the room-availability map in particular was
/// duplicated verbatim between the student and landlord sides.
///
/// The four families share one green/orange/red/teal/grey vocabulary
/// rather than each inventing its own hues:
/// - green ([AppColors.statusAvailable]): the strongest positive/final
///   state (available, confirmed, accepted, verified).
/// - orange ([AppColors.statusPending]): awaiting/not yet settled
///   (pending, limited).
/// - red ([AppColors.statusFull]): negative outcomes (full, declined,
///   rejected).
/// - teal ([AppColors.statusReserved]): an affirmative-but-not-final state
///   (reserved, approved, rescheduled).
/// - grey ([AppColors.statusNeutral]): terminal/inactive (expired,
///   cancelled, completed).
extension RoomAvailabilityStatusDisplay on RoomAvailabilityStatus {
  Color get color => switch (this) {
        RoomAvailabilityStatus.available => AppColors.statusAvailable,
        RoomAvailabilityStatus.limited => AppColors.statusLimited,
        RoomAvailabilityStatus.full => AppColors.statusFull,
        RoomAvailabilityStatus.reserved => AppColors.statusReserved,
      };

  String get label => switch (this) {
        RoomAvailabilityStatus.available => 'Available',
        RoomAvailabilityStatus.limited => 'Limited',
        RoomAvailabilityStatus.full => 'Full',
        RoomAvailabilityStatus.reserved => 'Reserved',
      };
}

extension RoomRequestStatusDisplay on RoomRequestStatus {
  Color get color => switch (this) {
        RoomRequestStatus.pending => AppColors.statusPending,
        RoomRequestStatus.approved => AppColors.statusReserved,
        RoomRequestStatus.confirmed => AppColors.statusAvailable,
        RoomRequestStatus.declined => AppColors.statusFull,
        RoomRequestStatus.expired => AppColors.statusNeutral,
        RoomRequestStatus.cancelled => AppColors.statusNeutral,
      };

  String get label => switch (this) {
        RoomRequestStatus.pending => 'Pending',
        RoomRequestStatus.approved => 'Approved',
        RoomRequestStatus.confirmed => 'Confirmed',
        RoomRequestStatus.declined => 'Declined',
        RoomRequestStatus.expired => 'Expired',
        RoomRequestStatus.cancelled => 'Cancelled',
      };
}

extension VisitRequestStatusDisplay on VisitRequestStatus {
  Color get color => switch (this) {
        VisitRequestStatus.pending => AppColors.statusPending,
        VisitRequestStatus.accepted => AppColors.statusAvailable,
        VisitRequestStatus.rescheduled => AppColors.statusReserved,
        VisitRequestStatus.declined => AppColors.statusFull,
        VisitRequestStatus.completed => AppColors.statusNeutral,
        VisitRequestStatus.cancelled => AppColors.statusNeutral,
      };

  String get label => switch (this) {
        VisitRequestStatus.pending => 'Pending',
        VisitRequestStatus.accepted => 'Accepted',
        VisitRequestStatus.rescheduled => 'Rescheduled',
        VisitRequestStatus.declined => 'Declined',
        VisitRequestStatus.completed => 'Completed',
        VisitRequestStatus.cancelled => 'Cancelled',
      };
}

extension VerificationStatusDisplay on VerificationStatus {
  Color get color => switch (this) {
        VerificationStatus.pending => AppColors.statusPending,
        VerificationStatus.verified => AppColors.statusAvailable,
        VerificationStatus.rejected => AppColors.statusFull,
      };

  String get label => switch (this) {
        VerificationStatus.pending => 'Pending',
        VerificationStatus.verified => 'Verified',
        VerificationStatus.rejected => 'Rejected',
      };
}

extension UserStatusDisplay on UserStatus {
  Color get color => switch (this) {
        UserStatus.active => AppColors.statusAvailable,
        UserStatus.suspended => AppColors.statusFull,
      };

  String get label => switch (this) {
        UserStatus.active => 'Active',
        UserStatus.suspended => 'Suspended',
      };
}

/// `reviewed` reads as a positive/final outcome (the admin looked at it and
/// handled it) while `dismissed` reads as terminal/inactive (closed, no
/// action taken) -- the same grey used for `expired`/`cancelled` elsewhere.
extension ReportedListingReviewStatusDisplay on ReportedListingReviewStatus {
  Color get color => switch (this) {
        ReportedListingReviewStatus.pending => AppColors.statusPending,
        ReportedListingReviewStatus.reviewed => AppColors.statusAvailable,
        ReportedListingReviewStatus.dismissed => AppColors.statusNeutral,
      };

  String get label => switch (this) {
        ReportedListingReviewStatus.pending => 'Pending',
        ReportedListingReviewStatus.reviewed => 'Reviewed',
        ReportedListingReviewStatus.dismissed => 'Dismissed',
      };
}

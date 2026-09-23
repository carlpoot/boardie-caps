import 'package:flutter_test/flutter_test.dart';

import 'package:boardie/core/models/enums.dart';
import 'package:boardie/core/theme/app_colors.dart';
import 'package:boardie/core/theme/status_display.dart';

void main() {
  group('RoomAvailabilityStatusDisplay', () {
    test('matches Figure E4\'s map legend exactly', () {
      expect(RoomAvailabilityStatus.available.color, AppColors.statusAvailable);
      expect(RoomAvailabilityStatus.limited.color, AppColors.statusLimited);
      expect(RoomAvailabilityStatus.full.color, AppColors.statusFull);
      expect(RoomAvailabilityStatus.reserved.color, AppColors.statusReserved);
    });

    test('labels are human-readable', () {
      expect(RoomAvailabilityStatus.available.label, 'Available');
      expect(RoomAvailabilityStatus.limited.label, 'Limited');
      expect(RoomAvailabilityStatus.full.label, 'Full');
      expect(RoomAvailabilityStatus.reserved.label, 'Reserved');
    });
  });

  group('RoomRequestStatusDisplay', () {
    test('reuses the shared green/orange/red/teal/grey vocabulary', () {
      expect(RoomRequestStatus.pending.color, AppColors.statusPending);
      expect(RoomRequestStatus.approved.color, AppColors.statusReserved);
      expect(RoomRequestStatus.confirmed.color, AppColors.statusAvailable);
      expect(RoomRequestStatus.declined.color, AppColors.statusFull);
      expect(RoomRequestStatus.expired.color, AppColors.statusNeutral);
      expect(RoomRequestStatus.cancelled.color, AppColors.statusNeutral);
    });

    test('every RoomRequestStatus value has a label', () {
      for (final status in RoomRequestStatus.values) {
        expect(status.label, isNotEmpty);
      }
    });
  });

  group('VisitRequestStatusDisplay', () {
    test('reuses the shared vocabulary', () {
      expect(VisitRequestStatus.pending.color, AppColors.statusPending);
      expect(VisitRequestStatus.accepted.color, AppColors.statusAvailable);
      expect(VisitRequestStatus.rescheduled.color, AppColors.statusReserved);
      expect(VisitRequestStatus.declined.color, AppColors.statusFull);
      expect(VisitRequestStatus.completed.color, AppColors.statusNeutral);
      expect(VisitRequestStatus.cancelled.color, AppColors.statusNeutral);
    });

    test('every VisitRequestStatus value has a label', () {
      for (final status in VisitRequestStatus.values) {
        expect(status.label, isNotEmpty);
      }
    });
  });

  group('VerificationStatusDisplay', () {
    test('reuses the shared vocabulary', () {
      expect(VerificationStatus.pending.color, AppColors.statusPending);
      expect(VerificationStatus.verified.color, AppColors.statusAvailable);
      expect(VerificationStatus.rejected.color, AppColors.statusFull);
    });

    test('labels are short and consistent across screens', () {
      expect(VerificationStatus.pending.label, 'Pending');
      expect(VerificationStatus.verified.label, 'Verified');
      expect(VerificationStatus.rejected.label, 'Rejected');
    });
  });

  test('no two conceptually different outcomes share a color within the same family', () {
    // Sanity check on RoomRequestStatus specifically, since it's the
    // richest family (6 values): a "good" outcome and a "bad" outcome
    // must never render the same color.
    expect(RoomRequestStatus.confirmed.color, isNot(RoomRequestStatus.declined.color));
    expect(RoomRequestStatus.pending.color, isNot(RoomRequestStatus.confirmed.color));
  });
}

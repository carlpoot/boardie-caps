import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:boardie/core/models/models.dart';
import 'package:boardie/core/providers/repository_providers.dart';
import 'package:boardie/features/admin/reports/admin_reports_providers.dart';

Property _property({required String landlordId, required String name}) => Property(
      propertyId: '',
      landlordId: landlordId,
      name: name,
      address: 'Test St',
      latitude: 13.1,
      longitude: 123.7,
      storeys: 1,
      verificationStatus: VerificationStatus.verified,
      minPrice: 1000,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  testWidgets(
      'gatherListingVerificationRows spans every landlord, not just one -- '
      'proving the listing_verification report is genuinely system-wide',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // `gatherListingVerificationRows` takes a WidgetRef, so it needs a real
    // widget in the tree to call it from -- Printing.layoutPdf's onLayout
    // (the only other caller) never fires under flutter_test at all (no
    // platform channel), so this is the only way to exercise this function.
    late WidgetRef capturedRef;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(builder: (context, ref, _) {
            capturedRef = ref;
            return const SizedBox();
          }),
        ),
      ),
    );

    // Seed two new properties under two DIFFERENT landlords -- landlord-001
    // (Ramon Bicol) and landlord-002 (Liza Formento) -- on top of whatever
    // the mock seed data already has, so this test's premise doesn't
    // silently depend on the seed data's current shape never changing.
    final propertyRepository = container.read(propertyRepositoryProvider);
    final propertyA = await propertyRepository.create(
      _property(landlordId: 'landlord-001', name: 'Test Property A (Ramon)'),
    );
    final propertyB = await propertyRepository.create(
      _property(landlordId: 'landlord-002', name: 'Test Property B (Liza)'),
    );

    final rows = await gatherListingVerificationRows(capturedRef);

    final rowA = rows.where((r) => r.property.propertyId == propertyA.propertyId);
    final rowB = rows.where((r) => r.property.propertyId == propertyB.propertyId);
    expect(rowA, hasLength(1));
    expect(rowB, hasLength(1));
    expect(rowA.single.landlordName, 'Ramon Bicol');
    expect(rowB.single.landlordName, 'Liza Formento');

    // The full row set spans more than one distinct landlord_id -- this is
    // the actual "system-wide, not scoped to a single landlord" guarantee
    // the admin reports feature makes, as opposed to the landlord side's
    // reports, which are always filtered to one landlord_id.
    final distinctLandlordIds = rows.map((r) => r.property.landlordId).toSet();
    expect(distinctLandlordIds.length, greaterThan(1));
    expect(distinctLandlordIds, containsAll(['landlord-001', 'landlord-002']));
  });
}
